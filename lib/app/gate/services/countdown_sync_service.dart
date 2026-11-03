import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/event_gate_repository.dart';
import '../domain/event_gate_models.dart';

/// Service managing monotonic time synchronization with Supabase,
/// ticking every second without device clock skew, and listening for Realtime updates.
class CountdownSyncService with WidgetsBindingObserver {
  CountdownSyncService({
    required this.repository,
    this.eventId = 'global_diwali',
    this.periodicSyncInterval = const Duration(minutes: 5),
  }) {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  final EventGateRepository repository;
  final String eventId;
  final Duration periodicSyncInterval;

  final Stopwatch _monotonicStopwatch = Stopwatch();
  DateTime? _baseServerTime;
  EventGateStatus? _currentStatus;

  Timer? _oneSecondTimer;
  Timer? _activePeriodicSyncTimer;
  StreamSubscription<EventConfiguration>? _realtimeSubscription;

  final StreamController<EventGateStatus> _statusController =
      StreamController<EventGateStatus>.broadcast();

  Stream<EventGateStatus> get statusStream => _statusController.stream;
  EventGateStatus? get currentStatus => _currentStatus;

  Future<void> _init() async {
    // 1. Initial server fetch
    await resync();

    // 2. Start local 1-second monotonic countdown ticker
    _startOneSecondTicker();

    // 3. Start active-only periodic background resync
    _startActivePeriodicTimer();

    // 4. Subscribe to Supabase Realtime broadcast updates
    _realtimeSubscription = repository
        .subscribeToConfigChanges(eventId: eventId)
        .listen((_) => resync());
  }

  /// Trusted monotonic server time. Immune to local device clock tampering.
  DateTime? get currentTrustedServerTime {
    final base = _baseServerTime;
    if (base == null) return null;
    return base.add(_monotonicStopwatch.elapsed);
  }

  /// Synchronize with backend-authoritative server time and event status.
  Future<void> resync() async {
    try {
      final status = await repository.fetchStatus(eventId: eventId);
      _baseServerTime = status.serverTime;
      _monotonicStopwatch
        ..reset()
        ..start();

      _currentStatus = status;
      _emitStatus(status);
    } catch (e) {
      debugPrint('CountdownSyncService: Resync failed: $e');
    }
  }

  void _startOneSecondTicker() {
    _oneSecondTimer?.cancel();
    _oneSecondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final status = _currentStatus;
      final serverNow = currentTrustedServerTime;
      if (status == null || serverNow == null) return;

      final updatedStatus = status.copyWithAdjustedServerTime(serverNow);
      _currentStatus = updatedStatus;
      _emitStatus(updatedStatus);

      // If the event just transitioned to started, cancel local ticker
      if (updatedStatus.isStarted) {
        _oneSecondTimer?.cancel();
      }
    });
  }

  void _startActivePeriodicTimer() {
    _activePeriodicSyncTimer?.cancel();
    // Resynchronize periodically ONLY while app is actively resumed
    _activePeriodicSyncTimer = Timer.periodic(periodicSyncInterval, (_) {
      final state = WidgetsBinding.instance.lifecycleState;
      if (state == null || state == AppLifecycleState.resumed) {
        resync();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-synchronized immediately when player resumes the application
      resync();
      _startActivePeriodicTimer();
    } else if (state == AppLifecycleState.paused) {
      // Avoid draining battery while suspended
      _activePeriodicSyncTimer?.cancel();
    }
  }

  void _emitStatus(EventGateStatus status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _oneSecondTimer?.cancel();
    _activePeriodicSyncTimer?.cancel();
    _realtimeSubscription?.cancel();
    _statusController.close();
  }
}
