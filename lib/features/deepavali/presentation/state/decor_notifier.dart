import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/decoration.dart';

/// The house being decorated. Not persisted: it is made, shared and left.
class DecorNotifier extends Notifier<DecorState> {
  @override
  DecorState build() => DecorState();

  void add(DecorKind kind) => state = state.add(kind);
  void moveTo(int id, double x, double y) => state = state.moveTo(id, x, y);
  void nudge(DecorDirection d) => state = state.nudge(d);
  void select(int? id) => state = state.select(id);
  void removeSelected() => state = state.removeSelected();
  void clear() => state = state.clear();
}

final decorProvider = NotifierProvider<DecorNotifier, DecorState>(
  DecorNotifier.new,
);
