import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isEnabled = false;

  Function(String)? _onError;

  Future<bool> init() async {
    // Explicitly request microphone permission first
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      print('Microphone permission denied');
      return false;
    }

    _isEnabled = await _speechToText.initialize(
      onError: (val) {
        print('Voice Error: ${val.errorMsg}');
        _onError?.call(val.errorMsg);
      },
      onStatus: (val) => print('Voice Status: $val'),
    );
    return _isEnabled;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required Function(String)? onDone,
    Function(String)? onError,
  }) async {
    _onError = onError;

    if (!_isEnabled) {
      bool available = await init();
      if (!available) {
        print('Speech not available');
        if (onError != null)
          onError("Speech recognition not available");
        else if (onDone != null) onDone("Error: Speech not available");
        return;
      }
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
          if (result.finalResult && onDone != null) {
            onDone(result.recognizedWords);
          }
        },
        // localeId: 'en_US', // Removing explicit locale to use system default
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
      );
    } catch (e) {
      onError?.call(e.toString());
    }
  }

  Future<void> stop() async {
    await _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;
  bool get isAvailable => _isEnabled;
}
