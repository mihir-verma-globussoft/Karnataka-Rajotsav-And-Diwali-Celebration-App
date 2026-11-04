import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/recommendation.dart';

/// The "which city is for you" questions. Not persisted: it is a quick quiz.
class RecommendNotifier extends Notifier<RecommendFlow?> {
  @override
  RecommendFlow? build() => null;

  void start() => state = const RecommendFlow();
  void answer(int option) => state = state?.answer(option);
  void back() => state = state?.back();
  void reset() => state = null;
}

final recommendProvider = NotifierProvider<RecommendNotifier, RecommendFlow?>(
  RecommendNotifier.new,
);
