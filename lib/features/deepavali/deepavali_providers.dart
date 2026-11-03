import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/deepavali_prefs_store.dart';
import 'domain/deepavali_store.dart';

/// Persistence for the tab. Override in tests with a fake.
final deepavaliStoreProvider = Provider<DeepavaliStore>(
  (ref) => const PrefsDeepavaliStore(),
);

/// Current time source. Override in tests for deterministic countdowns.
final deepavaliNowProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);
