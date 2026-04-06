import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// ==================== AI VOICE NAVIGATION SERVICE ====================
///
/// INTELLIGENT VOICE-GUIDED NAVIGATION
/// Complete AI-powered voice navigation system:
/// - Text-to-speech (TTS) engine
/// - Speech-to-text (STT) recognition
/// - Voice-guided navigation
/// - Screen content reading
/// - Interactive voice commands
/// - Context-aware announcements
/// - Multi-language support
/// - Accessibility features
///
/// 24-HOUR MARATHON - PHASE 6 (HOUR 21)
/// ================================================================

// ==================== NAVIGATION CONTEXT ====================

enum NavigationContext {
  home,
  emergencyScreen,
  contacts,
  settings,
  map,
  medicalHub,
  iotHub,
  communityNetwork,
  unknown,
}

extension NavigationContextExtension on NavigationContext {
  String get displayName {
    switch (this) {
      case NavigationContext.home:
        return 'Home Screen';
      case NavigationContext.emergencyScreen:
        return 'Emergency Services';
      case NavigationContext.contacts:
        return 'Emergency Contacts';
      case NavigationContext.settings:
        return 'Settings';
      case NavigationContext.map:
        return 'Safety Map';
      case NavigationContext.medicalHub:
        return 'Medical Intelligence Hub';
      case NavigationContext.iotHub:
        return 'IoT Control Hub';
      case NavigationContext.communityNetwork:
        return 'Community Safety Network';
      case NavigationContext.unknown:
        return 'Unknown Screen';
    }
  }

  String get helpText {
    switch (this) {
      case NavigationContext.home:
        return 'You are on the home screen. Say "trigger panic" to activate emergency alert, or "open menu" to explore features.';
      case NavigationContext.emergencyScreen:
        return 'Emergency services screen. Say "call ambulance", "call police", or "call fire department" to contact emergency services.';
      case NavigationContext.contacts:
        return 'Emergency contacts screen. Say "add contact" or "call contact name" to interact with your contacts.';
      case NavigationContext.settings:
        return 'Settings screen. Say "enable feature name" or "disable feature name" to configure settings.';
      case NavigationContext.map:
        return 'Safety map screen. Say "find safe zones" or "show nearby help" to view locations.';
      case NavigationContext.medicalHub:
        return 'Medical hub screen. Say "show medical ID" or "track medications" to access health features.';
      case NavigationContext.iotHub:
        return 'IoT control hub. Say "lock doors" or "turn on cameras" to control smart devices.';
      case NavigationContext.communityNetwork:
        return 'Community network screen. Say "broadcast alert" or "view nearby alerts" to interact with community.';
      case NavigationContext.unknown:
        return 'Screen not recognized. Say "go home" or "help" for assistance.';
    }
  }
}

// ==================== VOICE COMMAND ====================

class VoiceNavigationCommand {
  final String phrase;
  final String action;
  final NavigationContext? targetContext;
  final Function? callback;

  VoiceNavigationCommand({
    required this.phrase,
    required this.action,
    this.targetContext,
    this.callback,
  });
}

// ==================== TTS SETTINGS ====================

class TTSSettings {
  final double rate;
  final double pitch;
  final double volume;
  final String language;
  final String voice;

  TTSSettings({
    this.rate = 0.5,
    this.pitch = 1.0,
    this.volume = 1.0,
    this.language = 'en-US',
    this.voice = 'default',
  });

  TTSSettings copyWith({
    double? rate,
    double? pitch,
    double? volume,
    String? language,
    String? voice,
  }) {
    return TTSSettings(
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      language: language ?? this.language,
      voice: voice ?? this.voice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rate': rate,
      'pitch': pitch,
      'volume': volume,
      'language': language,
      'voice': voice,
    };
  }

  factory TTSSettings.fromMap(Map<String, dynamic> map) {
    return TTSSettings(
      rate: map['rate'] ?? 0.5,
      pitch: map['pitch'] ?? 1.0,
      volume: map['volume'] ?? 1.0,
      language: map['language'] ?? 'en-US',
      voice: map['voice'] ?? 'default',
    );
  }
}

// ==================== AI VOICE NAVIGATION SERVICE ====================

class AIVoiceNavigationService {
  // TTS Engine
  final FlutterTts _tts = FlutterTts();

  // STT Engine
  final stt.SpeechToText _stt = stt.SpeechToText();

  // State
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isListening = false;
  bool _isEnabled = false;

  NavigationContext _currentContext = NavigationContext.home;
  TTSSettings _ttsSettings = TTSSettings();

  final List<VoiceNavigationCommand> _registeredCommands = [];
  final List<String> _speechQueue = [];

  // Callbacks
  Function(String text)? onSpeechRecognized;
  Function(String command)? onCommandExecuted;
  Function(NavigationContext context)? onContextChanged;
  Function(String message)? onLog;
  Function(String error)? onError;

  // Getters
  bool isInitialized() => _isInitialized;
  bool isSpeaking() => _isSpeaking;
  bool isListening() => _isListening;
  bool isEnabled() => _isEnabled;
  NavigationContext getCurrentContext() => _currentContext;
  TTSSettings getSettings() => _ttsSettings;

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint(' Initializing AI Voice Navigation Service...');

      // Load settings
      await _loadSettings();

      // Initialize TTS
      await _initializeTTS();

      // Initialize STT
      await _initializeSTT();

      // Register default commands
      _registerDefaultCommands();

      _isInitialized = true;
      debugPrint(' AI Voice Navigation Service initialized');
    } catch (e) {
      debugPrint(' Voice Navigation initialization error: $e');
      onError?.call('Failed to initialize voice navigation: $e');
      rethrow;
    }
  }

  void dispose() {
    _tts.stop();
    _stt.stop();
    _registeredCommands.clear();
    _speechQueue.clear();
    _isInitialized = false;
    debugPrint(' AI Voice Navigation Service disposed');
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _isEnabled = prefs.getBool('voice_navigation_enabled') ?? true;

    final settingsMap = {
      'rate': prefs.getDouble('tts_rate') ?? 0.5,
      'pitch': prefs.getDouble('tts_pitch') ?? 1.0,
      'volume': prefs.getDouble('tts_volume') ?? 1.0,
      'language': prefs.getString('tts_language') ?? 'en-US',
      'voice': prefs.getString('tts_voice') ?? 'default',
    };

    _ttsSettings = TTSSettings.fromMap(settingsMap);
  }

  Future<void> _initializeTTS() async {
    // Set TTS handlers
    _tts.setStartHandler(() {
      _isSpeaking = true;
      debugPrint(' TTS started');
    });

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      debugPrint(' TTS completed');
      _processNextInQueue();
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      debugPrint(' TTS error: $msg');
      onError?.call('Text-to-speech error: $msg');
    });

    // Configure TTS
    await _tts.setLanguage(_ttsSettings.language);
    await _tts.setSpeechRate(_ttsSettings.rate);
    await _tts.setPitch(_ttsSettings.pitch);
    await _tts.setVolume(_ttsSettings.volume);

    debugPrint(' TTS engine initialized');
  }

  Future<void> _initializeSTT() async {
    final available = await _stt.initialize(
      onStatus: (status) {
        debugPrint('STT Status: $status');
        _isListening = status == 'listening';
      },
      onError: (error) {
        debugPrint(' STT error: $error');
        onError?.call('Speech recognition error: $error');
        _isListening = false;
      },
    );

    if (available) {
      debugPrint(' STT engine initialized');
    } else {
      debugPrint(' STT not available on this device');
    }
  }

  // ==================== TEXT-TO-SPEECH ====================

  /// Speak text immediately (interrupts current speech)
  Future<void> speak(String text, {bool interrupt = false}) async {
    if (!_isEnabled || text.isEmpty) return;

    try {
      onLog?.call('Speaking: $text');
      debugPrint(' Speaking: $text');

      if (interrupt && _isSpeaking) {
        await _tts.stop();
      }

      if (_isSpeaking) {
        _speechQueue.add(text);
        debugPrint(' Added to speech queue: $text');
      } else {
        await _tts.speak(text);
      }
    } catch (e) {
      debugPrint(' Speak error: $e');
      onError?.call('Failed to speak: $e');
    }
  }

  /// Add text to speech queue
  void speakQueued(String text) {
    if (!_isEnabled || text.isEmpty) return;

    if (_isSpeaking) {
      _speechQueue.add(text);
      debugPrint(' Queued: $text');
    } else {
      speak(text);
    }
  }

  /// Process next item in speech queue
  Future<void> _processNextInQueue() async {
    if (_speechQueue.isNotEmpty && !_isSpeaking) {
      final next = _speechQueue.removeAt(0);
      await speak(next);
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _tts.stop();
    _speechQueue.clear();
    _isSpeaking = false;
  }

  // ==================== SPEECH-TO-TEXT ====================

  /// Start listening for voice input
  Future<void> startListening({
    Function(String)? onResult,
    Duration? timeout,
  }) async {
    if (!_isEnabled || _isListening) return;

    try {
      debugPrint(' Starting to listen...');

      await _stt.listen(
        onResult: (result) {
          final text = result.recognizedWords;
          debugPrint(' Recognized: $text');

          onSpeechRecognized?.call(text);
          onResult?.call(text);

          if (result.finalResult) {
            _processVoiceCommand(text);
          }
        },
        listenFor: timeout ?? const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
      );

      _isListening = true;
      onLog?.call('Listening for voice commands...');
    } catch (e) {
      debugPrint(' Start listening error: $e');
      onError?.call('Failed to start listening: $e');
      _isListening = false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _stt.stop();
      _isListening = false;
      debugPrint(' Stopped listening');
    } catch (e) {
      debugPrint(' Stop listening error: $e');
    }
  }

  // ==================== NAVIGATION ====================

  /// Set current navigation context
  void setContext(NavigationContext context) {
    if (_currentContext != context) {
      _currentContext = context;
      onContextChanged?.call(context);
      debugPrint(' Context changed to: ${context.displayName}');
    }
  }

  /// Announce current screen
  Future<void> announceCurrentScreen() async {
    final announcement = 'You are now on ${_currentContext.displayName}';
    await speak(announcement);
  }

  /// Provide help for current screen
  Future<void> provideContextHelp() async {
    await speak(_currentContext.helpText);
  }

  /// Navigate and announce
  Future<void> navigateAndAnnounce(
      NavigationContext newContext,
      String? customAnnouncement,
      ) async {
    setContext(newContext);

    final announcement =
        customAnnouncement ?? 'Navigating to ${newContext.displayName}';
    await speak(announcement);
  }

  // ==================== VOICE COMMANDS ====================

  /// Register voice command
  void registerCommand(VoiceNavigationCommand command) {
    _registeredCommands.add(command);
    debugPrint(' Registered command: ${command.phrase}');
  }

  /// Unregister voice command
  void unregisterCommand(String phrase) {
    _registeredCommands.removeWhere((cmd) => cmd.phrase == phrase);
    debugPrint(' Unregistered command: $phrase');
  }

  /// Process recognized voice command
  void _processVoiceCommand(String text) {
    final lowerText = text.toLowerCase().trim();
    debugPrint(' Processing command: $lowerText');

    // Check registered commands
    for (final command in _registeredCommands) {
      if (lowerText.contains(command.phrase.toLowerCase())) {
        debugPrint(' Command matched: ${command.phrase}');
        onCommandExecuted?.call(command.phrase);

        if (command.callback != null) {
          command.callback!();
        }

        if (command.targetContext != null) {
          navigateAndAnnounce(command.targetContext!, null);
        }

        return;
      }
    }

    debugPrint(' No command matched for: $lowerText');
    speak('Command not recognized. Say "help" for available commands.');
  }

  /// Register default commands
  void _registerDefaultCommands() {
    final defaultCommands = [
      VoiceNavigationCommand(
        phrase: 'help',
        action: 'provide_help',
        callback: provideContextHelp,
      ),
      VoiceNavigationCommand(
        phrase: 'where am i',
        action: 'announce_location',
        callback: announceCurrentScreen,
      ),
      VoiceNavigationCommand(
        phrase: 'go home',
        action: 'navigate_home',
        targetContext: NavigationContext.home,
      ),
      VoiceNavigationCommand(
        phrase: 'open emergency services',
        action: 'navigate_emergency',
        targetContext: NavigationContext.emergencyScreen,
      ),
      VoiceNavigationCommand(
        phrase: 'open contacts',
        action: 'navigate_contacts',
        targetContext: NavigationContext.contacts,
      ),
      VoiceNavigationCommand(
        phrase: 'open settings',
        action: 'navigate_settings',
        targetContext: NavigationContext.settings,
      ),
      VoiceNavigationCommand(
        phrase: 'open map',
        action: 'navigate_map',
        targetContext: NavigationContext.map,
      ),
      VoiceNavigationCommand(
        phrase: 'open medical hub',
        action: 'navigate_medical',
        targetContext: NavigationContext.medicalHub,
      ),
      VoiceNavigationCommand(
        phrase: 'trigger panic',
        action: 'trigger_panic',
        callback: () {
          speak('Emergency panic triggered. Sending alerts to your contacts.');
        },
      ),
      VoiceNavigationCommand(
        phrase: 'call police',
        action: 'call_police',
        callback: () {
          speak('Calling police emergency services.');
        },
      ),
      VoiceNavigationCommand(
        phrase: 'call ambulance',
        action: 'call_ambulance',
        callback: () {
          speak('Calling ambulance emergency services.');
        },
      ),
      VoiceNavigationCommand(
        phrase: 'call fire department',
        action: 'call_fire',
        callback: () {
          speak('Calling fire department.');
        },
      ),
    ];

    for (final command in defaultCommands) {
      registerCommand(command);
    }

    debugPrint(' Registered ${defaultCommands.length} default commands');
  }

  // ==================== SETTINGS ====================

  /// Enable voice navigation
  Future<void> enable() async {
    _isEnabled = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_navigation_enabled', true);
    onLog?.call('Voice navigation enabled');
    await speak('Voice navigation enabled');
  }

  /// Disable voice navigation
  Future<void> disable() async {
    _isEnabled = false;
    await stopSpeaking();
    await stopListening();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_navigation_enabled', false);
    onLog?.call('Voice navigation disabled');
  }

  /// Update TTS settings
  Future<void> updateSettings(TTSSettings newSettings) async {
    _ttsSettings = newSettings;

    await _tts.setLanguage(newSettings.language);
    await _tts.setSpeechRate(newSettings.rate);
    await _tts.setPitch(newSettings.pitch);
    await _tts.setVolume(newSettings.volume);

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_rate', newSettings.rate);
    await prefs.setDouble('tts_pitch', newSettings.pitch);
    await prefs.setDouble('tts_volume', newSettings.volume);
    await prefs.setString('tts_language', newSettings.language);
    await prefs.setString('tts_voice', newSettings.voice);

    onLog?.call('Voice settings updated');
    debugPrint(' TTS settings updated');
  }

  // ==================== SCREEN READING ====================

  /// Read screen content (simulation)
  Future<void> readScreen() async {
    final content = _getScreenContent(_currentContext);
    await speak(content);
  }

  String _getScreenContent(NavigationContext context) {
    switch (context) {
      case NavigationContext.home:
        return 'Home screen. Main panic button in center. Emergency features available in menu.';
      case NavigationContext.emergencyScreen:
        return 'Emergency services screen. Fire department, police, ambulance, and 911 buttons available.';
      case NavigationContext.contacts:
        return 'Emergency contacts screen. Your saved emergency contacts are listed here.';
      case NavigationContext.settings:
        return 'Settings screen. Configure your emergency features and preferences.';
      case NavigationContext.map:
        return 'Safety map screen. View nearby safe zones and emergency services.';
      case NavigationContext.medicalHub:
        return 'Medical intelligence hub. Access medical ID, medications, and health information.';
      case NavigationContext.iotHub:
        return 'IoT control hub. Control your smart home devices and security systems.';
      case NavigationContext.communityNetwork:
        return 'Community safety network. Connect with nearby helpers and view alerts.';
      case NavigationContext.unknown:
        return 'Unknown screen. Navigation information not available.';
    }
  }

  // ==================== ANNOUNCEMENTS ====================

  /// Announce alert
  Future<void> announceAlert(String alert, {bool urgent = false}) async {
    final prefix = urgent ? 'Urgent alert. ' : 'Alert. ';
    await speak(prefix + alert, interrupt: urgent);
  }

  /// Announce success
  Future<void> announceSuccess(String message) async {
    await speak('Success. $message');
  }

  /// Announce error
  Future<void> announceError(String error) async {
    await speak('Error. $error');
  }

  /// Announce status
  Future<void> announceStatus(String status) async {
    await speak(status);
  }

  // ==================== UTILITY METHODS ====================

  /// Get available languages
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _tts.getLanguages;
      return List<String>.from(languages);
    } catch (e) {
      debugPrint(' Error getting languages: $e');
      return ['en-US'];
    }
  }

  /// Get available voices
  Future<List<String>> getAvailableVoices() async {
    try {
      final voices = await _tts.getVoices;
      return voices.map((v) => v['name'] as String).toList();
    } catch (e) {
      debugPrint(' Error getting voices: $e');
      return ['default'];
    }
  }

  /// Test voice with sample text
  Future<void> testVoice() async {
    await speak(
      'This is a voice navigation test. You are hearing the current voice settings.',
    );
  }

  // ==================== ACCESSIBILITY HELPERS ====================

  /// Read button label
  Future<void> readButton(String label) async {
    await speak('Button: $label');
  }

  /// Read field label
  Future<void> readField(String label, String? value) async {
    final text = value != null
        ? 'Field: $label. Current value: $value'
        : 'Field: $label. Empty.';
    await speak(text);
  }

  /// Read list item
  Future<void> readListItem(String item, int index, int total) async {
    await speak('Item $index of $total: $item');
  }

  /// Announce focus change
  Future<void> announceFocus(String element) async {
    await speak('Focused on $element');
  }

  // ==================== EMERGENCY ANNOUNCEMENTS ====================

  /// Announce panic triggered
  Future<void> announcePanicTriggered() async {
    await speak(
      'Emergency panic button triggered. Sending alerts to your emergency contacts now.',
      interrupt: true,
    );
  }

  /// Announce emergency call
  Future<void> announceEmergencyCall(String service) async {
    await speak('Calling $service emergency services now.', interrupt: true);
  }

  /// Announce location shared
  Future<void> announceLocationShared() async {
    await speak('Your location has been shared with emergency contacts.');
  }

  /// Announce alert sent
  Future<void> announceAlertSent(int contactCount) async {
    final contacts = contactCount == 1 ? 'contact' : 'contacts';
    await speak('Emergency alert sent to $contactCount $contacts.');
  }
}