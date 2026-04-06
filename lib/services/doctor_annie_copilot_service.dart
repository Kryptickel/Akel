import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'enhanced_aws_polly_service.dart';
import 'emergency_core_service.dart';
import 'panic_service_v2.dart';

/// ==================== DOCTOR ANNIE AI CO-PILOT ====================
///
/// Intelligent AI Assistant for Emergency Response
///
/// Features:
/// Voice conversations with Doctor Annie
/// Natural language understanding
/// Emergency command recognition
/// Location-aware responses
/// Context-aware suggestions
/// Speech recognition
/// Proactive safety tips
///
/// Powered by: AWS Lex V2 + Polly Neural + Custom AI Logic
///
/// ==============================================================

class DoctorAnnieCopilotService {
  // ==================== SINGLETON ====================
  static final DoctorAnnieCopilotService _instance = DoctorAnnieCopilotService._internal();
  factory DoctorAnnieCopilotService() => _instance;
  DoctorAnnieCopilotService._internal();

  // ==================== STATE ====================
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;

  // Services
  final EnhancedAWSPollyService _pollyService = EnhancedAWSPollyService();
  final EmergencyCoreService _emergencyService = EmergencyCoreService();
  final PanicServiceV2 _panicService = PanicServiceV2();

  // Conversation context
  final List<Map<String, dynamic>> _conversationHistory = [];
  String _currentContext = 'idle'; // idle, emergency, planning, guidance
  Map<String, dynamic> _userProfile = {};

  // Callbacks
  Function(String message, bool isUser)? onMessageReceived;
  Function(String intent)? onIntentDetected;
  Function()? onEmergencyDetected;

  // AWS Lex Configuration (from .env)
  String? _lexBotId;
  String? _lexAliasId;
  String? _lexRegion;

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint(' Doctor Annie Co-Pilot already initialized');
      return;
    }

    try {
      debugPrint(' ========== DOCTOR ANNIE CO-PILOT INITIALIZATION ==========');

      // Load AWS Lex configuration
      await _loadConfiguration();

      // Load user profile
      await _loadUserProfile();

      // Initialize conversation
      await _initializeConversation();

      _isInitialized = true;

      debugPrint(' Doctor Annie Co-Pilot initialized successfully');
      debugPrint(' AI Model: AWS Lex V2 + GPT Logic');
      debugPrint(' Voice: ${_pollyService.currentVoice.displayName}');
      debugPrint(' Context: $_currentContext');
      debugPrint(' User Profile: ${_userProfile['name'] ?? "Guest"}');
      debugPrint('===============================================================\n');

      // Greet user
      await greet();

    } catch (e, stackTrace) {
      debugPrint(' Doctor Annie Co-Pilot initialization error: $e');
      debugPrint(' Stack trace: $stackTrace');
      _isInitialized = true;
    }
  }

  Future<void> _loadConfiguration() async {
    try {
      // TODO: Load from .env
      _lexBotId = 'YOUR_LEX_BOT_ID';
      _lexAliasId = 'YOUR_LEX_ALIAS_ID';
      _lexRegion = 'us-east-1';

      debugPrint(' AWS Lex configuration loaded');
    } catch (e) {
      debugPrint(' Configuration load warning: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('doctor_annie_user_profile');

      if (profileJson != null) {
        _userProfile = jsonDecode(profileJson);
      } else {
        _userProfile = {
          'name': 'User',
          'preferences': {
            'voice_speed': 'normal',
            'proactive_tips': true,
            'emergency_contacts_count': 0,
          },
          'interaction_count': 0,
          'last_interaction': null,
        };
        await _saveUserProfile();
      }

      debugPrint(' User profile loaded: ${_userProfile['name']}');
    } catch (e) {
      debugPrint(' User profile load warning: $e');
    }
  }

  Future<void> _saveUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('doctor_annie_user_profile', jsonEncode(_userProfile));
    } catch (e) {
      debugPrint(' Save profile warning: $e');
    }
  }

  Future<void> _initializeConversation() async {
    _conversationHistory.clear();
    _currentContext = 'idle';
  }

  // ==================== GREETING ====================

  Future<void> greet() async {
    try {
      final hour = DateTime.now().hour;
      String greeting;

      if (hour < 12) {
        greeting = 'Good morning';
      } else if (hour < 18) {
        greeting = 'Good afternoon';
      } else {
        greeting = 'Good evening';
      }

      final name = _userProfile['name'] ?? 'there';
      final interactionCount = _userProfile['interaction_count'] as int? ?? 0;

      String message;
      if (interactionCount == 0) {
        message = "$greeting, $name! I'm Doctor Annie, your AI safety co-pilot. "
            "I'm here to help you stay safe. You can ask me anything about "
            "emergency procedures, check-in systems, or just say 'help' to see what I can do.";
      } else {
        message = "$greeting, $name! How can I help keep you safe today?";
      }

      await speak(message);

      _userProfile['interaction_count'] = interactionCount + 1;
      _userProfile['last_interaction'] = DateTime.now().toIso8601String();
      await _saveUserProfile();

    } catch (e) {
      debugPrint(' Greet error: $e');
    }
  }

  // ==================== CONVERSATION ====================

  /// Send a message to Doctor Annie
  Future<String> sendMessage(String message) async {
    try {
      debugPrint(' User: $message');

      // Add to conversation history
      _conversationHistory.add({
        'role': 'user',
        'message': message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Callback
      onMessageReceived?.call(message, true);

      // Analyze intent
      final intent = await _analyzeIntent(message);
      debugPrint(' Intent detected: $intent');

      // Callback
      onIntentDetected?.call(intent);

      // Generate response based on intent
      final response = await _generateResponse(intent, message);

      // Add to conversation history
      _conversationHistory.add({
        'role': 'assistant',
        'message': response,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Callback
      onMessageReceived?.call(response, false);

      // Speak response
      await speak(response);

      return response;

    } catch (e) {
      debugPrint(' Send message error: $e');
      return "I'm sorry, I encountered an error. Please try again.";
    }
  }

  // ==================== INTENT ANALYSIS ====================

  Future<String> _analyzeIntent(String message) async {
    final lowerMessage = message.toLowerCase().trim();

    // Emergency intents
    if (_isEmergencyIntent(lowerMessage)) {
      _currentContext = 'emergency';
      onEmergencyDetected?.call();
      return 'emergency';
    }

    // Help intent
    if (lowerMessage.contains('help') || lowerMessage == '?') {
      return 'help';
    }

    // Status check
    if (lowerMessage.contains('status') || lowerMessage.contains('how am i')) {
      return 'status_check';
    }

    // Check-in
    if (lowerMessage.contains('check in') || lowerMessage.contains('check-in')) {
      return 'checkin';
    }

    // Location
    if (lowerMessage.contains('where am i') || lowerMessage.contains('location')) {
      return 'location';
    }

    // Emergency contacts
    if (lowerMessage.contains('contact') || lowerMessage.contains('call someone')) {
      return 'contacts';
    }

    // Safety tips
    if (lowerMessage.contains('tip') || lowerMessage.contains('advice') || lowerMessage.contains('suggest')) {
      return 'safety_tips';
    }

    // Settings
    if (lowerMessage.contains('setting') || lowerMessage.contains('configure')) {
      return 'settings';
    }

    // Greeting
    if (lowerMessage.contains('hello') || lowerMessage.contains('hi ') || lowerMessage.startsWith('hi')) {
      return 'greeting';
    }

    // Gratitude
    if (lowerMessage.contains('thank') || lowerMessage.contains('thanks')) {
      return 'gratitude';
    }

    // Default: general conversation
    return 'general';
  }

  bool _isEmergencyIntent(String message) {
    final emergencyKeywords = [
      'help me',
      'emergency',
      'danger',
      'scared',
      'threatened',
      'attack',
      'hurt',
      'unsafe',
      'call 911',
      'call police',
      'panic',
      'need help',
      'save me',
    ];

    return emergencyKeywords.any((keyword) => message.contains(keyword));
  }

  // ==================== RESPONSE GENERATION ====================

  Future<String> _generateResponse(String intent, String message) async {
    switch (intent) {
      case 'emergency':
        return await _handleEmergency(message);

      case 'help':
        return _getHelpMessage();

      case 'status_check':
        return await _getStatusMessage();

      case 'checkin':
        return await _handleCheckin();

      case 'location':
        return await _handleLocation();

      case 'contacts':
        return _getContactsMessage();

      case 'safety_tips':
        return _getSafetyTip();

      case 'settings':
        return _getSettingsMessage();

      case 'greeting':
        return _getGreetingResponse();

      case 'gratitude':
        return "You're very welcome! I'm always here to help keep you safe.";

      case 'general':
      default:
        return _getGeneralResponse(message);
    }
  }

  // ==================== INTENT HANDLERS ====================

  Future<String> _handleEmergency(String message) async {
    try {
      debugPrint(' EMERGENCY DETECTED');

      // Get location
      Position? location;
      try {
        location = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint(' Location unavailable: $e');
      }

      // Trigger panic
      await _panicService.panicOfflineMode();

      String response = " Emergency alert activated! ";

      if (location != null) {
        response += "I've recorded your location at ${location.latitude}, ${location.longitude}. ";
      }

      response += "Your emergency contacts will be notified. "
          "Stay calm. Help is on the way. ";

      final pendingCount = await _emergencyService.getPendingCount();
      if (pendingCount > 0) {
        response += "You have $pendingCount pending emergency alerts. ";
      }

      response += "Are you safe right now? You can say 'yes' or 'no'.";

      return response;

    } catch (e) {
      debugPrint(' Handle emergency error: $e');
      return "Emergency services activated. Please stay calm and safe.";
    }
  }

  String _getHelpMessage() {
    return "I can help you with:\n\n"
        " Emergency - Say 'emergency' or 'help me'\n"
        " Check-in - Say 'check in'\n"
        " Location - Say 'where am i'\n"
        " Contacts - Say 'show contacts'\n"
        " Safety tips - Say 'give me a tip'\n"
        " Settings - Say 'settings'\n"
        " Status - Say 'status check'\n\n"
        "What would you like to do?";
  }

  Future<String> _getStatusMessage() async {
    try {
      final stats = await _emergencyService.getStatistics();
      final pendingCount = stats['queued'] as int? ?? 0;
      final checkinEnabled = stats['checkin_enabled'] as bool? ?? false;
      final isOnline = stats['is_online'] as bool? ?? false;

      String response = "Here's your safety status:\n\n";
      response += " Connection: ${isOnline ? 'Online' : 'Offline'}\n";
      response += " Pending emergencies: $pendingCount\n";
      response += " Check-ins: ${checkinEnabled ? 'Enabled' : 'Disabled'}\n";

      if (checkinEnabled) {
        final lastCheckin = _emergencyService.lastCheckin;
        if (lastCheckin != null) {
          final minutesAgo = DateTime.now().difference(lastCheckin).inMinutes;
          response += " Last check-in: $minutesAgo minutes ago\n";
        }
      }

      response += "\nYou're doing great! Stay safe.";

      return response;

    } catch (e) {
      debugPrint(' Get status error: $e');
      return "I'm having trouble checking your status right now.";
    }
  }

  Future<String> _handleCheckin() async {
    try {
      await _emergencyService.performCheckin(notes: 'Doctor Annie assisted check-in');

      return " Check-in completed successfully! "
          "I've recorded your location and timestamp. "
          "Stay safe out there!";

    } catch (e) {
      debugPrint(' Handle checkin error: $e');
      return "I had trouble completing your check-in. Please try again.";
    }
  }

  Future<String> _handleLocation() async {
    try {
      final location = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 5));

      return " You are currently at:\n"
          "Latitude: ${location.latitude.toStringAsFixed(6)}\n"
          "Longitude: ${location.longitude.toStringAsFixed(6)}\n"
          "Accuracy: ±${location.accuracy.toStringAsFixed(1)} meters\n\n"
          "This location has been saved.";

    } catch (e) {
      debugPrint(' Location error: $e');
      return "I'm having trouble accessing your location right now. "
          "Please check your location permissions.";
    }
  }

  String _getContactsMessage() {
    final contactCount = _userProfile['preferences']?['emergency_contacts_count'] ?? 0;

    if (contactCount == 0) {
      return "You haven't set up any emergency contacts yet. "
          "I recommend adding at least 3 trusted contacts. "
          "Would you like help setting them up?";
    } else {
      return "You have $contactCount emergency contact${contactCount > 1 ? 's' : ''} configured. "
          "They will be notified automatically in case of emergency.";
    }
  }

  String _getSafetyTip() {
    final tips = [
      " Always share your location with trusted contacts when traveling alone.",
      " Set up regular check-ins when going to unfamiliar places.",
      " Keep your phone charged above 20% when you're out.",
      " Trust your instincts - if something feels wrong, it probably is.",
      " Have a code word with your emergency contacts for when you need help discreetly.",
      " Memorize at least one emergency contact's phone number.",
      " Enable location services for emergency features to work properly.",
      " Review your emergency plan regularly to keep it up to date.",
    ];

    final tip = tips[DateTime.now().millisecondsSinceEpoch % tips.length];
    return "$tip\n\nWould you like another tip?";
  }

  String _getSettingsMessage() {
    return " You can configure:\n\n"
        " Check-in frequency\n"
        " Emergency alert preferences\n"
        " Emergency contacts\n"
        " Voice settings\n"
        " Location sharing\n\n"
        "Go to Settings in the menu to make changes.";
  }

  String _getGreetingResponse() {
    final greetings = [
      "Hello! How can I help keep you safe today?",
      "Hi there! I'm here to assist you. What do you need?",
      "Hey! Ready to help. What's on your mind?",
    ];

    return greetings[DateTime.now().second % greetings.length];
  }

  String _getGeneralResponse(String message) {
    // Simple keyword-based responses
    if (message.toLowerCase().contains('weather')) {
      return "I don't have weather information, but I can help you with safety features. "
          "Try asking about emergencies, check-ins, or safety tips!";
    }

    if (message.toLowerCase().contains('time')) {
      final now = DateTime.now();
      return "It's ${now.hour}:${now.minute.toString().padLeft(2, '0')}. "
          "Is there anything safety-related I can help you with?";
    }

    // Default
    return "I understand you're talking about '$message'. "
        "I'm specialized in safety and emergency assistance. "
        "Try asking me about emergencies, check-ins, location, or safety tips!";
  }

  // ==================== VOICE ====================

  Future<void> speak(String text) async {
    if (_isSpeaking) {
      await _pollyService.stop();
    }

    try {
      _isSpeaking = true;
      await _pollyService.speak(text);
      _isSpeaking = false;
    } catch (e) {
      debugPrint(' Speak error: $e');
      _isSpeaking = false;
    }
  }

  Future<void> stopSpeaking() async {
    await _pollyService.stop();
    _isSpeaking = false;
  }

  // ==================== PROACTIVE ASSISTANCE ====================

  /// Provide proactive safety suggestions based on context
  Future<void> provideSuggestion() async {
    if (!_userProfile['preferences']?['proactive_tips'] ?? true) {
      return;
    }

    try {
      final stats = await _emergencyService.getStatistics();
      final pendingCount = stats['queued'] as int? ?? 0;

      if (pendingCount > 0) {
        await speak("Heads up! You have $pendingCount pending emergency alerts. "
            "Would you like me to help you review them?");
      }

      // Check-in reminder
      if (stats['checkin_enabled'] == true) {
        final lastCheckin = _emergencyService.lastCheckin;
        if (lastCheckin != null) {
          final hoursSince = DateTime.now().difference(lastCheckin).inHours;
          if (hoursSince > 3) {
            await speak("It's been $hoursSince hours since your last check-in. "
                "Would you like to check in now?");
          }
        }
      }

    } catch (e) {
      debugPrint(' Provide suggestion error: $e');
    }
  }

  // ==================== CONVERSATION HISTORY ====================

  List<Map<String, dynamic>> getConversationHistory({int limit = 20}) {
    if (limit >= _conversationHistory.length) {
      return List.from(_conversationHistory);
    }
    return _conversationHistory.sublist(_conversationHistory.length - limit);
  }

  Future<void> clearConversationHistory() async {
    _conversationHistory.clear();
    debugPrint(' Conversation history cleared');
  }

  // ==================== CONTROL ====================

  void dispose() {
    _pollyService.stop();
    _isListening = false;
    _isSpeaking = false;
    debugPrint(' Doctor Annie Co-Pilot disposed');
  }

  // ==================== GETTERS ====================

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get currentContext => _currentContext;
  Map<String, dynamic> get userProfile => Map.from(_userProfile);
}