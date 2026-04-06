import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart'; // NEW - Text-to-Speech
import 'dart:async'; // NEW - For transcription
import '../models/voice_command.dart';
import 'panic_service.dart';
import 'vibration_service.dart';

/// ==================== ENHANCED VOICE COMMAND SERVICE ====================
/// YOUR ORIGINAL + HOUR 3-5 ENHANCEMENTS
///
/// ORIGINAL FEATURES:
/// - Wake word detection
/// - Emergency command recognition
/// - Firebase logging
/// - Voice command history
///
/// NEW HOUR 3-5 FEATURES:
/// 1. Text-to-Speech feedback
/// 2. Voice transcription
/// 3. Continuous listening mode
/// 4. Smart sound detection (coming in visual hub)
/// 5. Real-time captioning (coming in visual hub)
///
/// BUILD 55 - ENHANCED
/// ================================================================

class VoiceCommandService {
  // ==================== EXISTING SERVICES ====================
  final SpeechToText _speech = SpeechToText();
  final PanicService _panicService = PanicService();
  final VibrationService _vibrationService = VibrationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // NEW: Text-to-Speech
  late FlutterTts _tts;

  // ==================== STATE ====================
  bool _isListening = false;
  bool _isInitialized = false;
  bool _ttsInitialized = false;
  String _lastWords = '';
  double _lastConfidence = 0.0;

// NEW: Callbacks for UI updates
  VoidCallback? onEmergencyCommand; // This fixes the Panic Manger error
  VoidCallback? onEmergencyDetected; // This fixes the Audio Screen error

  Function(String)? onWordsChanged;
  Function(double)? onConfidenceChanged;
  Function(bool)? onListeningChanged;

  // ==================== EXISTING WAKE WORDS & COMMANDS ====================
  static const List<String> defaultWakeWords = [
    'hey akel',
    'akel',
    'okay akel',
  ];

  static const List<String> defaultEmergencyCommands = [
    'emergency',
    'help',
    'help me',
    'call for help',
    'i need help',
    'panic',
    'danger',
    'save me',
    '911',
    'police',
  ];

  // ==================== GETTERS ====================
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get lastWords => _lastWords;
  double get confidence => _lastConfidence;

  // ==================== INITIALIZATION ====================

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      debugPrint(' Initializing Enhanced Voice Command Service...');

      // Initialize Speech-to-Text
      _isInitialized = await _speech.initialize(
        onStatus: (status) => _handleStatus(status),
        onError: (error) => _handleError(error),
      );

      // NEW: Initialize Text-to-Speech
      if (_isInitialized) {
        await _initializeTTS();
      }

      if (_isInitialized && _ttsInitialized) {
        debugPrint(' Enhanced Voice Command Service initialized');
        await speak('Voice commands ready'); // NEW: Audio confirmation
      } else {
        debugPrint(' Failed to initialize voice service');
      }

      return _isInitialized;
    } catch (e) {
      debugPrint(' Voice initialization error: $e');
      return false;
    }
  }

  // NEW: TTS Initialization
  Future<void> _initializeTTS() async {
    try {
      _tts = FlutterTts();

      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // iOS specific
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      }

      _ttsInitialized = true;
      debugPrint(' Text-to-Speech initialized');
    } catch (e) {
      debugPrint(' TTS initialization error: $e');
      _ttsInitialized = false;
    }
  }

  // ==================== EXISTING: START/STOP LISTENING ====================

  Future<void> startListening({
    required String userId,
    required String userName,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        debugPrint(' Cannot start listening - not initialized');
        return;
      }
    }

    if (_isListening) {
      debugPrint(' Already listening');
      return;
    }

    try {
      await _speech.listen(
        onResult: (result) => _onSpeechResult(result, userId, userName),
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
      );

      _isListening = true;
      onListeningChanged?.call(true); // NEW: Callback
      debugPrint(' Started listening for voice commands');
    } catch (e) {
      debugPrint(' Start listening error: $e');
      _isListening = false;
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      onListeningChanged?.call(false); // NEW: Callback
      debugPrint(' Stopped listening');
    } catch (e) {
      debugPrint(' Stop listening error: $e');
    }
  }

  // ==================== EXISTING: SPEECH RESULT HANDLING ====================

  void _onSpeechResult(
      SpeechRecognitionResult result,
      String userId,
      String userName,
      ) {
    final words = result.recognizedWords.toLowerCase().trim();
    _lastWords = words;
    _lastConfidence = result.confidence;

    // NEW: Callbacks for UI updates
    onWordsChanged?.call(words);
    onConfidenceChanged?.call(result.confidence);

    debugPrint(' Recognized: "$words" (confidence: ${(result.confidence * 100).toStringAsFixed(1)}%)');

    // Only process final results
    if (!result.finalResult) return;

    // Check for wake word + command
    if (_containsWakeWord(words)) {
      debugPrint(' Wake word detected!');
      _vibrationService.light();
      speak('Yes?'); // NEW: Audio feedback

      // Check for emergency command
      if (_containsEmergencyCommand(words)) {
        debugPrint(' Emergency command detected!');
        _triggerEmergency(userId, userName, words, result.confidence);
      }
    }

    // Log command
    _logVoiceCommand(userId, words, result.confidence, false);
  }

  // ==================== EXISTING: WAKE WORD & COMMAND DETECTION ====================

  bool _containsWakeWord(String words) {
    for (final wakeWord in defaultWakeWords) {
      if (words.contains(wakeWord)) {
        return true;
      }
    }
    return false;
  }

  bool _containsEmergencyCommand(String words) {
    for (final command in defaultEmergencyCommands) {
      if (words.contains(command)) {
        return true;
      }
    }
    return false;
  }

  // ==================== EXISTING: EMERGENCY TRIGGER ====================

  Future<void> _triggerEmergency(
      String userId,
      String userName,
      String command,
      double confidence,
      ) async {
    try {
      // Heavy vibration feedback
      await _vibrationService.error();

      // NEW: Audio feedback
      await speak('Emergency detected. Activating panic mode.');

      // Log the triggered command
      await _logVoiceCommand(userId, command, confidence, true);

      // NEW: Callback
      onEmergencyCommand?.call();

      // Trigger panic
      await _panicService.triggerPanic(userId, userName);

      debugPrint(' Emergency triggered via voice command');
    } catch (e) {
      debugPrint(' Trigger emergency error: $e');
    }
  }

  // ==================== EXISTING: LOGGING ====================

  Future<void> _logVoiceCommand(
      String userId,
      String command,
      double confidence,
      bool triggered,
      ) async {
    try {
      final voiceCommand = VoiceCommand(
        id: '',
        userId: userId,
        command: command,
        timestamp: DateTime.now(),
        triggered: triggered,
        confidence: confidence,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('voice_commands')
          .add(voiceCommand.toMap());

      debugPrint(' Voice command logged: $command');
    } catch (e) {
      debugPrint(' Log voice command error: $e');
    }
  }

  // ==================== EXISTING: HISTORY & STATS ====================

  Stream<List<VoiceCommand>> getVoiceCommandHistory(String userId, {int limit = 20}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('voice_commands')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => VoiceCommand.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<Map<String, int>> getVoiceCommandStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('voice_commands')
          .get();

      final total = snapshot.docs.length;
      final triggered = snapshot.docs.where((doc) => doc.data()['triggered'] == true).length;

      return {
        'total': total,
        'triggered': triggered,
        'recognized': total - triggered,
      };
    } catch (e) {
      debugPrint(' Get voice command stats error: $e');
      return {
        'total': 0,
        'triggered': 0,
        'recognized': 0,
      };
    }
  }

  // ==================== NEW: TEXT-TO-SPEECH FEATURES ====================

  Future<void> speak(String text, {double? rate, double? pitch}) async {
    if (!_ttsInitialized) {
      debugPrint(' TTS not initialized');
      return;
    }

    try {
      debugPrint(' Speaking: $text');

      if (rate != null) await _tts.setSpeechRate(rate);
      if (pitch != null) await _tts.setPitch(pitch);

      await _tts.speak(text);
    } catch (e) {
      debugPrint(' TTS error: $e');
    }
  }

  Future<void> stopSpeaking() async {
    if (_ttsInitialized) {
      await _tts.stop();
    }
  }

  // ==================== NEW: VOICE TRANSCRIPTION ====================

  Future<String?> transcribeSpeech({
    Duration duration = const Duration(seconds: 10),
  }) async {
    if (!_isInitialized) return null;

    try {
      debugPrint(' Starting transcription...');

      final completer = Completer<String?>();

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            completer.complete(result.recognizedWords);
          }
        },
        listenFor: duration,
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
      );

      final transcription = await completer.future;
      debugPrint(' Transcription complete: $transcription');

      return transcription;
    } catch (e) {
      debugPrint(' Transcription error: $e');
      return null;
    }
  }

  // ==================== NEW: CONTINUOUS LISTENING ====================

  Future<void> startContinuousListening({
    required String userId,
    required String userName,
  }) async {
    try {
      debugPrint(' Starting continuous listening...');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('continuous_listening_enabled', true);

      // Start listening loop
      _continuousListeningLoop(userId, userName);
    } catch (e) {
      debugPrint(' Continuous listening error: $e');
    }
  }

  Future<void> stopContinuousListening() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('continuous_listening_enabled', false);

      await stopListening();
      debugPrint(' Continuous listening stopped');
    } catch (e) {
      debugPrint(' Stop continuous error: $e');
    }
  }

  Future<void> _continuousListeningLoop(String userId, String userName) async {
    final prefs = await SharedPreferences.getInstance();

    while (prefs.getBool('continuous_listening_enabled') ?? false) {
      if (!_isListening) {
        await startListening(userId: userId, userName: userName);
        await Future.delayed(const Duration(seconds: 30));
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<bool> isContinuousListeningEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('continuous_listening_enabled') ?? false;
  }

  // ==================== NEW: STATUS HANDLERS ====================

  void _handleStatus(String status) {
    debugPrint(' Speech status: $status');

    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      onListeningChanged?.call(false);
    }
  }

  void _handleError(error) {
    debugPrint(' Speech error: $error');
    _isListening = false;
    onListeningChanged?.call(false);
  }

  // ==================== EXISTING: SETTINGS ====================

  Future<void> setVoiceCommandsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('voice_commands_enabled', enabled);

      // NEW: Audio feedback
      if (enabled) {
        await speak('Voice commands enabled');
      } else {
        await speak('Voice commands disabled');
      }

      debugPrint('${enabled ? ' ' : ' '} Voice commands ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint(' Set voice commands enabled error: $e');
    }
  }

  Future<bool> isVoiceCommandsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('voice_commands_enabled') ?? false;
    } catch (e) {
      debugPrint(' Is voice commands enabled error: $e');
      return false;
    }
  }

  // ==================== EXISTING: PERMISSIONS ====================

  Future<bool> hasMicrophonePermission() async {
    try {
      return await _speech.hasPermission;
    } catch (e) {
      debugPrint(' Check microphone permission error: $e');
      return false;
    }
  }

  // ==================== EXISTING: LOCALES ====================

  Future<List<LocaleName>> getAvailableLocales() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      return await _speech.locales();
    } catch (e) {
      debugPrint(' Get available locales error: $e');
      return [];
    }
  }

  // ==================== DISPOSE ====================

  Future<void> dispose() async {
    await stopListening();
    await stopSpeaking();
  }
}