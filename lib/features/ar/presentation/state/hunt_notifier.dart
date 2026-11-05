import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../ar_providers.dart';
import '../../domain/ar_scene.dart';
import '../../domain/hunt_models.dart';
import '../../domain/hunt_repository.dart';
import '../../domain/hunt_rules.dart';
import '../../domain/poster_lock.dart';

enum HuntPhase { scanning, hunting, finished }

class HuntViewState {
  const HuntViewState({
    this.phase = HuntPhase.scanning,
    this.lockProgress = 0,
    this.posterTooFar = false,
    this.zone,
    this.tracking = ArTracking.initializing,
    this.nearestId,
    this.nearestDistance,
    this.nearestOnScreen = false,
    this.bearing,
    this.points = 0,
    this.foundCount = 0,
    this.totalCount = 0,
    this.leftHere = 0,
    this.nearestHint,
    this.nearestKind,
    this.message,
    this.failure,
  });

  final HuntPhase phase;
  final double lockProgress;
  final bool posterTooFar;
  final HuntZone? zone;
  final ArTracking tracking;
  final String? nearestId;
  final double? nearestDistance;
  final bool nearestOnScreen;
  final double? bearing;
  final int points;
  final int foundCount;
  final int totalCount;
  final int leftHere;
  final String? nearestHint;
  final HuntItemKind? nearestKind;

  /// A short note over the camera. Clears itself.
  final String? message;

  /// The AR session could not run.
  final String? failure;

  HuntHeat? get heat =>
      nearestDistance == null ? null : HuntHeat.fromDistance(nearestDistance!);

  /// Near is not enough: the item must be in view, so it has really been found.
  bool get canCollect =>
      nearestOnScreen &&
      nearestDistance != null &&
      nearestDistance! <= huntCollectRadiusMetres;

  HuntViewState copyWith({
    HuntPhase? phase,
    double? lockProgress,
    bool? posterTooFar,
    HuntZone? zone,
    ArTracking? tracking,
    int? points,
    int? foundCount,
    int? totalCount,
    int? leftHere,
    String? failure,
  }) => HuntViewState(
    phase: phase ?? this.phase,
    lockProgress: lockProgress ?? this.lockProgress,
    posterTooFar: posterTooFar ?? this.posterTooFar,
    zone: zone ?? this.zone,
    tracking: tracking ?? this.tracking,
    nearestId: nearestId,
    nearestDistance: nearestDistance,
    nearestOnScreen: nearestOnScreen,
    bearing: bearing,
    points: points ?? this.points,
    foundCount: foundCount ?? this.foundCount,
    totalCount: totalCount ?? this.totalCount,
    leftHere: leftHere ?? this.leftHere,
    nearestHint: nearestHint,
    nearestKind: nearestKind,
    message: message,
    failure: failure ?? this.failure,
  );

  HuntViewState withNearest({
    String? id,
    double? distance,
    bool onScreen = false,
    double? bearing,
    String? hint,
    HuntItemKind? kind,
  }) => HuntViewState(
    phase: phase,
    lockProgress: lockProgress,
    posterTooFar: posterTooFar,
    zone: zone,
    tracking: tracking,
    nearestId: id,
    nearestDistance: distance,
    nearestOnScreen: onScreen,
    bearing: bearing,
    points: points,
    foundCount: foundCount,
    totalCount: totalCount,
    leftHere: leftHere,
    nearestHint: hint,
    nearestKind: kind,
    message: message,
    failure: failure,
  );

  HuntViewState withMessage(String? text) => HuntViewState(
    phase: phase,
    lockProgress: lockProgress,
    posterTooFar: posterTooFar,
    zone: zone,
    tracking: tracking,
    nearestId: nearestId,
    nearestDistance: nearestDistance,
    nearestOnScreen: nearestOnScreen,
    bearing: bearing,
    points: points,
    foundCount: foundCount,
    totalCount: totalCount,
    leftHere: leftHere,
    nearestHint: nearestHint,
    nearestKind: nearestKind,
    message: text,
    failure: failure,
  );
}

final huntProvider = NotifierProvider.autoDispose<HuntNotifier, HuntViewState>(
  HuntNotifier.new,
);

class HuntNotifier extends Notifier<HuntViewState> {
  /// A poster left in view would otherwise lock over and over, nudging every
  /// item each time. Scanning it again later still corrects any drift.
  static const relockAfter = Duration(minutes: 1);

  final PosterLock _lock = PosterLock();
  final Set<String> _collecting = {};
  List<HuntItem> _items = const [];
  ArSceneController? _scene;
  StreamSubscription<ArSceneEvent>? _events;
  Timer? _messageTimer;
  DateTime? _lockedAt;

  /// Replaced in tests so sightings can be spaced without waiting.
  DateTime Function() clock = DateTime.now;

  @override
  HuntViewState build() {
    ref.onDispose(() {
      _messageTimer?.cancel();
      unawaited(_events?.cancel());
      unawaited(_scene?.dispose());
    });
    return const HuntViewState();
  }

  /// Starts a hunt from what the hub already loaded.
  void begin(HuntSnapshot snapshot) {
    _items = snapshot.items;
    state = state.copyWith(
      points: snapshot.points,
      foundCount: snapshot.foundCount,
      totalCount: snapshot.items.length,
      phase: snapshot.foundCount == snapshot.items.length
          ? HuntPhase.finished
          : HuntPhase.scanning,
    );
  }

  void attach(ArSceneController scene) {
    _scene = scene;
    _events = scene.events.listen(_onEvent);
  }

  void tap(double x, double y) => unawaited(_scene?.tap(x, y));

  /// The on-screen button, for when an item is close but hard to tap.
  void collectNearest() {
    final id = state.nearestId;
    if (id != null && state.canCollect) unawaited(_collect(id));
  }

  /// Back to scanning, to fix items that have drifted out of place.
  void rescan() {
    _lock.reset();
    _lockedAt = null;
    unawaited(_scene?.setOrigin(null));
    state = state
        .copyWith(
          phase: state.phase == HuntPhase.finished
              ? HuntPhase.finished
              : HuntPhase.scanning,
          lockProgress: 0,
          posterTooFar: false,
        )
        .withNearest();
  }

  void _onEvent(ArSceneEvent event) {
    switch (event) {
      case ArPosterSeen():
        _onPoster(event);
      case ArTrackingChanged(:final tracking):
        state = state.copyWith(tracking: tracking);
      case ArNearestChanged():
        _onNearest(event);
      case ArItemTapped(:final itemId, :final distance):
        if (distance <= huntCollectRadiusMetres) {
          unawaited(_collect(itemId));
        } else {
          _say('Walk closer to collect it.');
        }
      case ArSurfaceTapped():
        break;
      case ArInterrupted():
        rescan();
        if (state.phase != HuntPhase.finished) {
          _say('Scan a poster again to line everything back up.');
        }
      case ArFailed(:final code):
        state = state.copyWith(failure: code);
    }
  }

  void _onPoster(ArPosterSeen sighting) {
    final zone = huntZoneById(sighting.posterId);
    if (zone == null || state.phase == HuntPhase.finished) return;
    final hunting = state.phase == HuntPhase.hunting;
    final lockedAt = _lockedAt;
    if (hunting &&
        zone.id == state.zone?.id &&
        lockedAt != null &&
        clock().difference(lockedAt) < relockAfter) {
      return;
    }
    final origin = _lock.add(sighting, clock());
    if (!hunting) {
      state = state.copyWith(
        lockProgress: _lock.progress,
        posterTooFar: _lock.tooFar,
      );
    }
    if (origin == null) return;

    final moved = zone.id != state.zone?.id;
    _lockedAt = clock();
    unawaited(_scene?.setOrigin(origin));
    if (moved || !hunting) unawaited(_showZone(zone));
    state = state.copyWith(
      phase: HuntPhase.hunting,
      zone: zone,
      lockProgress: 0,
      posterTooFar: false,
      leftHere: _leftIn(zone),
    );
    if (moved || !hunting) {
      unawaited(ref.read(hapticsProvider).success());
      _announceZone(zone);
    }
  }

  void _onNearest(ArNearestChanged event) {
    final before = state.heat;
    HuntItem? item;
    for (final candidate in _items) {
      if (candidate.id == event.itemId) item = candidate;
    }
    if (item == null || item.found) return;
    state = state.withNearest(
      id: event.itemId,
      distance: event.distance,
      onScreen: event.onScreen,
      bearing: event.bearing,
      hint: item.hint,
      kind: item.kind,
    );
    if (state.heat == HuntHeat.burning && before != HuntHeat.burning) {
      unawaited(ref.read(hapticsProvider).selection());
    }
  }

  Future<void> _showZone(HuntZone zone) async => _scene?.setItems([
    for (final item in _items)
      if (item.zone == zone.id && !item.found) ArSceneItem.of(item),
  ]);

  int _leftIn(HuntZone zone) =>
      _items.where((item) => item.zone == zone.id && !item.found).length;

  /// Another start point with something left to find, if there is one.
  HuntZone? nextZone() {
    for (final zone in huntZones) {
      if (zone.id != state.zone?.id && _leftIn(zone) > 0) return zone;
    }
    return null;
  }

  void _announceZone(HuntZone zone) {
    final left = _leftIn(zone);
    if (left > 0) {
      _say('${zone.label}: $left to find here. Go and look!');
      return;
    }
    final next = nextZone();
    if (next != null) {
      _say('All found here. Try ${next.label}: ${_leftIn(next)} left there.');
    }
  }

  Future<void> _collect(String itemId) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index < 0 || _items[index].found || !_collecting.add(itemId)) return;
    final item = _items[index];
    _items = [
      for (final other in _items)
        other.id == itemId ? other.copyWith(found: true) : other,
    ];
    final allFound = _items.every((other) => other.found);
    final zone = state.zone;
    state = state
        .copyWith(
          foundCount: state.foundCount + 1,
          leftHere: zone == null ? 0 : _leftIn(zone),
          phase: allFound ? HuntPhase.finished : state.phase,
        )
        .withNearest();
    final sounds = ref.read(huntSoundsProvider);
    unawaited(_scene?.celebrate(itemId));
    unawaited(ref.read(hapticsProvider).success());
    unawaited(allFound ? sounds.allFound() : sounds.found());

    final repository = ref.read(huntRepositoryProvider);
    final pending = ref.read(pendingFindsProvider);
    final name = _capitalised(item.kind.label);
    try {
      final result = await repository.collect(itemId);
      if (!ref.mounted) return;
      if (!result.isAdmin) {
        state = state.copyWith(points: result.totalPoints);
        if (!result.alreadyFound) {
          ref.read(arcadeScoreRevisionProvider.notifier).refresh();
        }
      }
      _say(switch (result) {
        CollectResult(isAdmin: true) => '$name found. Admins do not score.',
        CollectResult(alreadyFound: true) => '$name already collected.',
        CollectResult(firstFinder: true, :final points) =>
          '+$points! You are the first to find this ${item.kind.label}.',
        CollectResult(:final points) => '+$points! $name found.',
      });
    } on HuntItemGoneException {
      if (ref.mounted) _say('That one was just removed, so it does not count.');
    } on HuntClosedException {
      if (ref.mounted) {
        _say('The hunt has closed, so this find does not count.');
      }
    } on Object {
      // Offline or too quick: keep it and let the hub send it later.
      await pending.add(itemId);
      if (ref.mounted) {
        _say('$name found! Your points will be added once you are online.');
      }
    }
  }

  void _say(String text) {
    state = state.withMessage(text);
    _messageTimer?.cancel();
    _messageTimer = Timer(AppDurations.arMessage, () {
      if (ref.mounted) state = state.withMessage(null);
    });
  }

  static String _capitalised(String text) =>
      '${text[0].toUpperCase()}${text.substring(1)}';
}
