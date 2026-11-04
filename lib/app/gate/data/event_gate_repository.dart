import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/event_gate_models.dart';

abstract interface class EventGateRepository {
  Future<EventGateStatus> fetchStatus({String eventId = 'global_diwali'});
  Stream<EventConfiguration> subscribeToConfigChanges({
    String eventId = 'global_diwali',
  });
}

class SupabaseEventGateRepository implements EventGateRepository {
  const SupabaseEventGateRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<EventGateStatus> fetchStatus({
    String eventId = 'global_diwali',
  }) async {
    try {
      final dynamic response = await _client.rpc<dynamic>(
        'get_event_gate_status',
        params: {'p_event_id': eventId},
      );
      final map = response is Map
          ? Map<String, dynamic>.from(response)
          : <String, dynamic>{};
      return EventGateStatus.fromJson(map);
    } on Object catch (e) {
      debugPrint('EventGateRepository: Error fetching status: $e');
      rethrow;
    }
  }

  @override
  Stream<EventConfiguration> subscribeToConfigChanges({
    String eventId = 'global_diwali',
  }) {
    late StreamController<EventConfiguration> controller;
    RealtimeChannel? channel;

    controller = StreamController<EventConfiguration>.broadcast(
      onListen: () {
        channel = _client
            .channel('public:event_configurations:$eventId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'event_configurations',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
                value: eventId,
              ),
              callback: (payload) {
                try {
                  final newRecord = payload.newRecord;
                  if (newRecord.isNotEmpty) {
                    controller.add(EventConfiguration.fromJson(newRecord));
                  }
                } catch (e) {
                  debugPrint('Error parsing Realtime event configuration: $e');
                }
              },
            )
            .subscribe();
      },
      onCancel: () {
        if (channel != null) {
          _client.removeChannel(channel!);
          channel = null;
        }
        controller.close();
      },
    );

    return controller.stream;
  }
}

class FallbackEventGateRepository implements EventGateRepository {
  const FallbackEventGateRepository({this.isStarted = true});

  final bool isStarted;

  @override
  Future<EventGateStatus> fetchStatus({
    String eventId = 'global_diwali',
  }) async {
    final now = DateTime.now().toUtc();
    return EventGateStatus(
      id: eventId,
      eventName: 'Karnataka Rajyotsava & Deepavali',
      serverTime: now,
      targetTime: isStarted
          ? now.subtract(const Duration(minutes: 5))
          : now.add(const Duration(days: 1)),
      isActive: true,
      testMode: false,
      isStarted: isStarted,
    );
  }

  @override
  Stream<EventConfiguration> subscribeToConfigChanges({
    String eventId = 'global_diwali',
  }) => const Stream.empty();
}
