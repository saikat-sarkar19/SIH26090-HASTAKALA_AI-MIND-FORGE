import 'package:flutter/foundation.dart';
import 'dart:js_interop' as js;

@js.JS('HastakalaSpeech.startListening')
external bool _startListeningJS(js.JSString langCode);

@js.JS('HastakalaSpeech.stopListening')
external void _stopListeningJS();

@js.JS('window.onHastakalaSpeechResult')
external set _onHastakalaSpeechResult(js.JSFunction? fn);

@js.JS('window.onHastakalaSpeechEnd')
external set _onHastakalaSpeechEnd(js.JSFunction? fn);

@js.JS('window.onHastakalaSpeechError')
external set _onHastakalaSpeechError(js.JSFunction? fn);

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

    try {
      // Register callbacks
      _onHastakalaSpeechResult = (js.JSString result) {
        onResult(result.toDart);
      }.toJS;

      _onHastakalaSpeechEnd = () {
        onEnd();
      }.toJS;

      _onHastakalaSpeechError = (js.JSString err) {
        onError(err.toDart);
      }.toJS;

      return _startListeningJS(languageCode.toJS);
    } catch (e) {
      onError('Speech initialization failed: $e');
      return false;
    }
  }

  static void stopListening() {
    if (kIsWeb) {
      try {
        _stopListeningJS();
      } catch (_) {}
    }
  }
}
