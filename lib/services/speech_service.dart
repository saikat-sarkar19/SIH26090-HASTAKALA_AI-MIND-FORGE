import 'package:flutter/foundation.dart';
import 'speech_service_stub.dart'
    if (dart.library.js_interop) 'speech_service_web.dart' as impl;

class SpeechService {
  static bool isAvailable() {
    return kIsWeb;
  }

  static bool startListening({
    required String languageCode,
    required Function(String text) onResult,
    required Function() onEnd,
    required Function(String error) onError,
  }) {
    if (!kIsWeb) {
      onError("Native speech recognition requires web browser microphone permissions.");
      return false;
    }
    return impl.startSpeechListening(
      languageCode: languageCode,
      onResult: onResult,
      onEnd: onEnd,
      onError: onError,
    );
  }

  static void stopListening() {
    if (kIsWeb) {
      impl.stopSpeechListening();
    }
  }
}
