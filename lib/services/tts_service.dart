import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      print('ℹ️ TTS already initialized');
      return;
    }

    try {
      print('🔄 Initializing TTS...');

// Set language first
      await _flutterTts.setLanguage("en-US");
      print('✅ Language set to en-US');

// Platform-specific voice selection
      await _setBestFemaleVoice();

// Set speech parameters for natural sound
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      print('✅ Speech parameters configured');

// Set handlers
      _flutterTts.setStartHandler(() {
        print('🎤 TTS Started speaking');
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        print('✅ TTS Completed speaking');
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((msg) {
        print('❌ TTS Error: $msg');
        _isSpeaking = false;
      });

      _flutterTts.setCancelHandler(() {
        print('⚠️ TTS Cancelled');
        _isSpeaking = false;
      });

      _isInitialized = true;
      print('✅ TTS Service fully initialized');
    } catch (e) {
      print('❌ TTS initialization error: $e');
    }
  }

  Future<void> _setBestFemaleVoice() async {
    try {
      print('🔍 Looking for voices...');

// Get available voices
      final dynamic voices = await _flutterTts.getVoices;

      if (voices != null && voices is List) {
        print('🎤 Found ${voices.length} voices');

// Print first 5 voices for debugging
        for (int i = 0; i < voices.length && i < 5; i++) {
          print(' Voice $i: ${voices[i]['name']} (${voices[i]['locale']})');
        }

// Priority list of female voices
        final preferredVoices = [
          'Samantha', 'Victoria', 'Karen', 'Moira', 'Allison',
          'en-us-x-sfg-network', 'en-us-x-tpf-network',
          'en-US-Neural2-F', 'en-US-Wavenet-F',
          'Microsoft Zira', 'Microsoft Jenny',
          'Google US English',
        ];

        Map<String, dynamic>? selectedVoice;

        for (final preferred in preferredVoices) {
          for (final voice in voices) {
            final name = voice['name']?.toString() ?? '';
            final locale = voice['locale']?.toString() ?? '';

            if (locale.toLowerCase().contains('en-us') ||
                locale.toLowerCase().contains('en_us') ||
                locale.toLowerCase().contains('en-gb')) {
              if (name.toLowerCase().contains(preferred.toLowerCase())) {
                selectedVoice = voice as Map<String, dynamic>;
                print('✅ Selected voice: $name ($locale)');
                break;
              }
            }
          }
          if (selectedVoice != null) break;
        }

// Set the selected voice
        if (selectedVoice != null) {
          await _flutterTts.setVoice({
            "name": selectedVoice['name'],
            "locale": selectedVoice['locale'],
          });
          print('✅ Voice set successfully');
        } else {
          print('⚠️ Using system default voice');
        }
      } else {
        print('⚠️ No voices available or voices is null');
      }
    } catch (e) {
      print('⚠️ Error setting voice: $e');
    }
  }

  Future<void> speak(String text) async {
    print('🔊 speak() called with text length: ${text.length}');

    if (!_isInitialized) {
      print('⚠️ TTS not initialized, initializing now...');
      await initialize();
    }

    try {
      if (_isSpeaking) {
        print('⚠️ Already speaking, stopping previous speech...');
        await stop();
      }

// Clean text for better speech
      final enhancedText = text
          .replaceAll('•', '. ')
          .replaceAll('\n\n', '. ')
          .replaceAll('\n', '. ')
          .replaceAll(':', ', ')
          .replaceAll('**', '')
          .replaceAll('⚠️', 'Warning: ')
          .replaceAll('🚨', 'Alert: ')
          .replaceAll('💡', '')
          .replaceAll('📞', '')
          .replaceAll('🩺', '')
          .replaceAll('🚑', '')
          .replaceAll('💊', '')
          .replaceAll('🏥', '')
          .replaceAll('👋', '')
          .replaceAll('🔥', '');

      print('🎤 Speaking: "${enhancedText.substring(0, enhancedText.length > 50 ? 50 : enhancedText.length)}..."');

      final result = await _flutterTts.speak(enhancedText);
      print('📊 Speak result: $result');
    } catch (e) {
      print('❌ TTS speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      print('🛑 Stopping TTS...');
      await _flutterTts.stop();
      _isSpeaking = false;
      print('✅ TTS stopped');
    } catch (e) {
      print('❌ TTS stop error: $e');
    }
  }

  Future<List<String>> getAvailableVoices() async {
    try {
      final dynamic voices = await _flutterTts.getVoices;
      if (voices != null && voices is List) {
        return voices
            .map((v) => '${v['name']} (${v['locale']})')
            .cast<String>()
            .toList();
      }
    } catch (e) {
      print('❌ Error getting voices: $e');
    }
    return [];
  }

  bool get isSpeaking => _isSpeaking;

  void dispose() {
    _flutterTts.stop();
  }
}