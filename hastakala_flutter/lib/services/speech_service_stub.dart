bool startSpeechListening({
  required String languageCode,
  required Function(String text) onResult,
  required Function() onEnd,
  required Function(String error) onError,
}) {
  onError("Native speech recognition requires web browser microphone permissions.");
  return false;
}

void stopSpeechListening() {}
