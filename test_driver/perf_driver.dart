import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver.dart';

/// Writes frame-timing summaries to build/perf/*.timeline_summary.json.
Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    for (final entry in data.entries) {
      final timeline = Timeline.fromJson(entry.value as Map<String, dynamic>);
      await TimelineSummary.summarize(timeline).writeTimelineToFile(
        entry.key,
        destinationDirectory: 'build/perf',
        pretty: true,
        includeSummary: true,
      );
    }
  },
);
