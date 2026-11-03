/// Representation of the server-authoritative event configuration.
class EventConfiguration {
  const EventConfiguration({
    required this.id,
    required this.eventName,
    required this.targetTime,
    required this.isActive,
    required this.testMode,
    this.updatedAt,
    this.updatedBy,
  });

  factory EventConfiguration.fromJson(Map<String, dynamic> json) {
    return EventConfiguration(
      id: json['id'] as String? ?? 'global_diwali',
      eventName: json['event_name'] as String? ?? 'Diwali Celebration',
      targetTime: json['target_time'] != null
          ? DateTime.parse(json['target_time'] as String).toUtc()
          : DateTime.now().toUtc(),
      isActive: json['is_active'] as bool? ?? true,
      testMode: json['test_mode'] as bool? ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)?.toUtc()
          : null,
      updatedBy: json['updated_by'] as String?,
    );
  }

  final String id;
  final String eventName;
  final DateTime targetTime;
  final bool isActive;
  final bool testMode;
  final DateTime? updatedAt;
  final String? updatedBy;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventConfiguration &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          eventName == other.eventName &&
          targetTime == other.targetTime &&
          isActive == other.isActive &&
          testMode == other.testMode;

  @override
  int get hashCode =>
      Object.hash(id, eventName, targetTime, isActive, testMode);
}

/// Dynamic gate status combined with the trusted server clock.
class EventGateStatus {
  const EventGateStatus({
    required this.id,
    required this.eventName,
    required this.serverTime,
    required this.targetTime,
    required this.isActive,
    required this.testMode,
    required this.isStarted,
    this.isAdmin = false,
  });

  factory EventGateStatus.fromJson(Map<String, dynamic> json) {
    final serverTime = json['server_time'] != null
        ? DateTime.parse(json['server_time'] as String).toUtc()
        : DateTime.now().toUtc();
    final targetTime = json['target_time'] != null
        ? DateTime.parse(json['target_time'] as String).toUtc()
        : DateTime.now().toUtc();
    final isActive = json['is_active'] as bool? ?? true;
    final testMode = json['test_mode'] as bool? ?? false;
    final isAdmin = json['is_admin'] as bool? ?? false;

    // is_started must strictly honour isActive and testMode
    final rawStarted = json['is_started'] as bool? ?? false;
    final isStarted = isActive && rawStarted && (!testMode || isAdmin);

    return EventGateStatus(
      id: json['id'] as String? ?? 'global_diwali',
      eventName: json['event_name'] as String? ?? 'Diwali Celebration',
      serverTime: serverTime,
      targetTime: targetTime,
      isActive: isActive,
      testMode: testMode,
      isStarted: isStarted,
      isAdmin: isAdmin,
    );
  }

  final String id;
  final String eventName;
  final DateTime serverTime;
  final DateTime targetTime;
  final bool isActive;
  final bool testMode;
  final bool isStarted;
  final bool isAdmin;

  Duration get remainingDuration {
    if (isStarted) return Duration.zero;
    final diff = targetTime.difference(serverTime);
    return diff.isNegative ? Duration.zero : diff;
  }

  EventGateStatus copyWithAdjustedServerTime(DateTime newServerTime) {
    final hasPassed =
        newServerTime.isAfter(targetTime) ||
        newServerTime.isAtSameMomentAs(targetTime);
    final isNowStarted = isActive && hasPassed && (!testMode || isAdmin);
    return EventGateStatus(
      id: id,
      eventName: eventName,
      serverTime: newServerTime,
      targetTime: targetTime,
      isActive: isActive,
      testMode: testMode,
      isStarted: isNowStarted,
      isAdmin: isAdmin,
    );
  }
}

/// Distinct high-level states resolved by the application root gate.
enum ApplicationAccessState {
  /// User is not authenticated; show Google Sign-In.
  unauthenticated,

  /// User is authenticated but has not uploaded/confirmed their avatar.
  authenticatedWithoutAvatar,

  /// User is authenticated with avatar, but the global Diwali event has not started.
  authenticatedEventWaiting,

  /// Event is active and has started; the existing application is fully unlocked.
  authenticatedEventStarted,

  /// Event configuration is explicitly disabled or unavailable.
  eventInactive,
}
