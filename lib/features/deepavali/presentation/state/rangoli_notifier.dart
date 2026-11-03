import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../deepavali_providers.dart';
import '../../domain/rangoli_state.dart';

/// The rangoli being made. Not autoDispose: the tab stays mounted, and the
/// design should survive switching tabs.
class RangoliNotifier extends Notifier<RangoliState> {
  @override
  RangoliState build() => RangoliState();

  void tapCell(int index) => state = state.tap(index);
  void select(int? paletteIndex) => state = state.select(paletteIndex);
  void setSymmetry({required bool on}) => state = state.setSymmetry(on: on);
  void undo() => state = state.undo();
  void reset() => state = state.reset();
  void randomize() => state = state.randomize(ref.read(rangoliSeedProvider)());
}

final rangoliProvider = NotifierProvider<RangoliNotifier, RangoliState>(
  RangoliNotifier.new,
);
