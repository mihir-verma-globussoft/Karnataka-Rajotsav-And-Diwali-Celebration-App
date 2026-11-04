import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../ar_providers.dart';
import '../../domain/ar_scene.dart';
import '../../domain/hunt_models.dart';
import '../../domain/poster_lock.dart';

/// A spot the admin has tapped but not saved yet.
class PlaceDraft {
  const PlaceDraft({required this.position, required this.onSurface});

  final Vec3 position;
  final bool onSurface;
}

class PlaceViewState {
  const PlaceViewState({
    this.lockProgress = 0,
    this.posterTooFar = false,
    this.zone,
    this.tracking = ArTracking.initializing,
    this.kind = HuntItemKind.diya,
    this.items = const [],
    this.draft,
    this.selected,
    this.saving = false,
    this.message,
    this.failure,
  });

  final double lockProgress;
  final bool posterTooFar;
  final HuntZone? zone;
  final ArTracking tracking;
  final HuntItemKind kind;

  /// Everything saved in the current zone.
  final List<HuntItem> items;
  final PlaceDraft? draft;

  /// A saved item the admin tapped.
  final HuntItem? selected;
  final bool saving;
  final String? message;
  final String? failure;

  bool get scanning => zone == null;

  PlaceViewState copyWith({
    double? lockProgress,
    bool? posterTooFar,
    ArTracking? tracking,
    HuntItemKind? kind,
    List<HuntItem>? items,
    bool? saving,
    String? failure,
  }) => PlaceViewState(
    lockProgress: lockProgress ?? this.lockProgress,
    posterTooFar: posterTooFar ?? this.posterTooFar,
    zone: zone,
    tracking: tracking ?? this.tracking,
    kind: kind ?? this.kind,
    items: items ?? this.items,
    draft: draft,
    selected: selected,
    saving: saving ?? this.saving,
    message: message,
    failure: failure ?? this.failure,
  );

  PlaceViewState withZone(HuntZone? value) => PlaceViewState(
    lockProgress: 0,
    zone: value,
    tracking: tracking,
    kind: kind,
    items: items,
    message: message,
    failure: failure,
  );

  PlaceViewState withDraft(PlaceDraft? value) => PlaceViewState(
    lockProgress: lockProgress,
    posterTooFar: posterTooFar,
    zone: zone,
    tracking: tracking,
    kind: kind,
    items: items,
    draft: value,
    saving: saving,
    message: message,
    failure: failure,
  );

  PlaceViewState withSelected(HuntItem? value) => PlaceViewState(
    lockProgress: lockProgress,
    posterTooFar: posterTooFar,
    zone: zone,
    tracking: tracking,
    kind: kind,
    items: items,
    selected: value,
    saving: saving,
    message: message,
    failure: failure,
  );

  PlaceViewState withMessage(String? text) => PlaceViewState(
    lockProgress: lockProgress,
    posterTooFar: posterTooFar,
    zone: zone,
    tracking: tracking,
    kind: kind,
    items: items,
    draft: draft,
    selected: selected,
    saving: saving,
    message: text,
    failure: failure,
  );
}

final placeProvider =
    NotifierProvider.autoDispose<PlaceNotifier, PlaceViewState>(
      PlaceNotifier.new,
    );

class PlaceNotifier extends Notifier<PlaceViewState> {
  static const _draftId = 'draft';

  final PosterLock _lock = PosterLock();
  List<HuntItem> _allItems = const [];
  ArSceneController? _scene;
  StreamSubscription<ArSceneEvent>? _events;
  Timer? _messageTimer;

  DateTime Function() clock = DateTime.now;

  @override
  PlaceViewState build() {
    ref.onDispose(() {
      _messageTimer?.cancel();
      unawaited(_events?.cancel());
      unawaited(_scene?.dispose());
    });
    return const PlaceViewState();
  }

  void begin(HuntSnapshot snapshot) => _allItems = snapshot.items;

  void attach(ArSceneController scene) {
    _scene = scene;
    _events = scene.events.listen(_onEvent);
  }

  void tap(double x, double y) => unawaited(_scene?.tap(x, y));

  void setKind(HuntItemKind kind) {
    state = state.copyWith(kind: kind);
    _drawItems();
  }

  void cancelDraft() {
    state = state.withDraft(null);
    _drawItems();
  }

  void clearSelection() => state = state.withSelected(null);

  /// Back to scanning, to line up again or to move to another poster.
  void rescan() {
    _lock.reset();
    unawaited(_scene?.setOrigin(null));
    unawaited(_scene?.setItems(const []));
    state = state.withZone(null);
  }

  Future<void> saveDraft(String hint) async {
    final draft = state.draft;
    final zone = state.zone;
    if (draft == null || zone == null || state.saving) return;
    state = state.copyWith(saving: true);
    try {
      final item = await ref
          .read(huntRepositoryProvider)
          .placeItem(
            zone: zone.id,
            kind: state.kind,
            x: draft.position.x,
            y: draft.position.y,
            z: draft.position.z,
            hint: hint,
          );
      if (!ref.mounted) return;
      _allItems = [..._allItems, item];
      state = state
          .copyWith(items: [...state.items, item], saving: false)
          .withDraft(null);
      _drawItems();
      unawaited(ref.read(hapticsProvider).success());
      _say('Saved. Players can find it now.');
    } on AppFailure catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(saving: false);
      unawaited(ref.read(hapticsProvider).error());
      _say(error.message);
    }
  }

  Future<void> removeSelected() async {
    final item = state.selected;
    if (item == null || state.saving) return;
    state = state.copyWith(saving: true);
    try {
      await ref.read(huntRepositoryProvider).removeItem(item.id);
      if (!ref.mounted) return;
      _allItems = [
        for (final other in _allItems)
          if (other.id != item.id) other,
      ];
      state = state
          .copyWith(
            items: [
              for (final other in state.items)
                if (other.id != item.id) other,
            ],
            saving: false,
          )
          .withSelected(null);
      _drawItems();
      unawaited(ref.read(hapticsProvider).success());
      _say('Removed.');
    } on AppFailure catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(saving: false);
      unawaited(ref.read(hapticsProvider).error());
      _say(error.message);
    }
  }

  void _onEvent(ArSceneEvent event) {
    switch (event) {
      case ArPosterSeen():
        _onPoster(event);
      case ArTrackingChanged(:final tracking):
        state = state.copyWith(tracking: tracking);
      case ArSurfaceTapped(:final position, :final onSurface):
        if (state.scanning || state.saving) return;
        state = state
            .withSelected(null)
            .withDraft(PlaceDraft(position: position, onSurface: onSurface));
        _drawItems();
        unawaited(ref.read(hapticsProvider).selection());
      case ArItemTapped(:final itemId):
        if (state.saving || itemId == _draftId) return;
        for (final item in state.items) {
          if (item.id == itemId) {
            state = state.withDraft(null).withSelected(item);
            _drawItems();
          }
        }
      case ArInterrupted():
        rescan();
        _say('Scan the poster again to line everything back up.');
      case ArFailed(:final code):
        state = state.copyWith(failure: code);
      case ArNearestChanged():
        break;
    }
  }

  void _onPoster(ArPosterSeen sighting) {
    final zone = huntZoneById(sighting.posterId);
    // Stays on one poster until the admin chooses to change, so nothing is
    // ever saved against a different poster by accident.
    if (zone == null || !state.scanning) return;
    final origin = _lock.add(sighting, clock());
    state = state.copyWith(
      lockProgress: _lock.progress,
      posterTooFar: _lock.tooFar,
    );
    if (origin == null) return;
    unawaited(_scene?.setOrigin(origin));
    state = state
        .withZone(zone)
        .copyWith(
          items: [
            for (final item in _allItems)
              if (item.zone == zone.id) item,
          ],
        );
    _drawItems();
    unawaited(ref.read(hapticsProvider).success());
    _say('Locked on ${zone.label}.');
  }

  void _drawItems() {
    final draft = state.draft;
    unawaited(
      _scene?.setItems([
        for (final item in state.items) ArSceneItem.of(item),
        if (draft != null)
          ArSceneItem(
            id: _draftId,
            kind: state.kind,
            x: draft.position.x,
            y: draft.position.y,
            z: draft.position.z,
          ),
      ]),
    );
  }

  void _say(String text) {
    state = state.withMessage(text);
    _messageTimer?.cancel();
    _messageTimer = Timer(AppDurations.arMessage, () {
      if (ref.mounted) state = state.withMessage(null);
    });
  }
}
