import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../domain/kannada_speaker.dart';

/// [KannadaSpeaker] using the platform speech engine: AVSpeechSynthesizer on
/// iOS (voice "Soumya") and the installed TTS engine, usually Google's, on
/// Android. Neither needs a network connection once the voice is installed.
class TtsKannadaSpeaker implements KannadaSpeaker {
  TtsKannadaSpeaker([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  /// BCP-47 tag of Kannada as spoken in India.
  static const String language = 'kn-IN';

  /// Slightly slower than normal, for learners. flutter_tts scales this so
  /// 0.5 is normal speed on both iOS and Android.
  static const double learnerRate = 0.4;

  Future<bool>? _ready;

  Future<bool> _prepare() async {
    try {
      final available = await _tts.isLanguageAvailable(language);
      if (available != true) return false;
      await _tts.setLanguage(language);
      await _tts.setSpeechRate(learnerRate);
      // speak() completes when speaking ends, so music can resume after.
      await _tts.awaitSpeakCompletion(true);
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // Play through the silent switch, lowering other audio meanwhile.
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
          IosTextToSpeechAudioCategoryOptions.duckOthers,
        ]);
      }
      return true;
    } on Object {
      // No speech engine at all (some emulators) or a plugin error.
      return false;
    }
  }

  @override
  Future<bool> isAvailable() => _ready ??= _prepare();

  @override
  Future<void> speak(String text) async {
    if (!await isAvailable()) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } on Object {
      // Nothing to stop.
    }
  }
}
