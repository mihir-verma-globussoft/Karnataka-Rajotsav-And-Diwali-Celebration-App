import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/greeting.dart';

/// The card being made. Not autoDispose: the tab stays mounted, and the card
/// should survive switching tabs.
class GreetingNotifier extends Notifier<GreetingCard> {
  @override
  GreetingCard build() => GreetingCard.initial();

  void setDesign(GreetingDesign design) => state = state.withDesign(design);
  void setMessage(String value) => state = state.withMessage(value);
  void setFrom(String value) => state = state.withFrom(value);
}

final greetingProvider = NotifierProvider<GreetingNotifier, GreetingCard>(
  GreetingNotifier.new,
);
