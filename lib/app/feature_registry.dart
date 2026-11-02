import '../features/ar/ar_feature.dart';
import '../features/deepavali/deepavali_feature.dart';
import '../features/flappy_bird/flappy_bird_feature.dart';
import '../features/home/home_feature.dart';
import '../features/pitch_game/pitch_game_feature.dart';
import '../features/rajyotsava/rajyotsava_feature.dart';
import 'feature_module.dart';

/// The single place features are registered: one line per feature.
/// Keep entries alphabetical to minimise merge conflicts.
const List<FeatureModule> featureModules = [
  ArFeature(),
  DeepavaliFeature(),
  FlappyBirdFeature(),
  HomeFeature(),
  PitchGameFeature(),
  RajyotsavaFeature(),
];
