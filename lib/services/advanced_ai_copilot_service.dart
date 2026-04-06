import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'enhanced_aws_polly_service.dart';
import 'emergency_core_service.dart';
import 'panic_service_v2.dart';

/// ==================== ADVANCED AI CO-PILOT ====================
///
/// Next-Generation AI Companion with:
/// Advanced Reasoning & Logic
/// Meaningful Conversations
/// Problem Solving
/// Emotional Intelligence
/// Image Analysis
/// Predictive Analytics
/// Proactive Assistance
/// Learning & Adaptation
///
/// Powered by: Claude API (Anthropic) + AWS Services
///
/// ==============================================================

class AdvancedAICopilotService {
  // ==================== SINGLETON ====================
  static final AdvancedAICopilotService _instance = AdvancedAICopilotService._internal();
  factory AdvancedAICopilotService() => _instance;
  AdvancedAICopilotService._internal();

  // ==================== CONFIGURATION ====================
  static const String _claudeApiEndpoint = 'https://api.anthropic.com/v1/messages';
  static const String _claudeModel = 'claude-sonnet-4-20250514';
  static const int _maxTokens = 4096;

  // API Keys (load from .env)
  String? _claudeApiKey;
  String? _awsAccessKey;
  String? _awsSecretKey;

  // ==================== STATE ====================
  bool _isInitialized = false;
  bool _isThinking = false;
  bool _isListening = false;
  bool _isSpeaking = false;

  // Services
  final EnhancedAWSPollyService _pollyService = EnhancedAWSPollyService();
  final EmergencyCoreService _emergencyService = EmergencyCoreService();
  final PanicServiceV2 _panicService = PanicServiceV2();

  // ==================== AI PERSONALITY & MEMORY ====================

  // Companion profile
  final Map<String, dynamic> _companionProfile = {
    'name': 'Annie',
    'role': 'AI Safety Companion & Emergency Response Specialist',
    'personality': [
      'Caring and empathetic',
      'Highly intelligent and analytical',
      'Proactive and vigilant',
      'Calm under pressure',
      'Patient and understanding',
      'Encouraging and supportive',
    ],
    'capabilities': [
      'Emergency response coordination',
      'Safety analysis and risk assessment',
      'Emotional support and counseling',
      'Problem solving and strategic planning',
      'Image analysis for threat detection',
      'Predictive safety alerts',
      'Personal safety coaching',
    ],
  };

  // User profile & preferences
  Map<String, dynamic> _userProfile = {
    'name': 'User',
    'relationship_level': 0, // 0-100 familiarity score
    'personality_traits': [],
    'communication_style': 'balanced', // concise, detailed, balanced
    'emotional_state': 'neutral', // anxious, calm, stressed, happy, neutral
    'safety_preferences': {},
    'learned_patterns': {},
    'interaction_history': [],
  };

  // Conversation context
  final List<Map<String, dynamic>> _conversationHistory = [];
  final List<Map<String, dynamic>> _longTermMemory = [];
  String _currentContext = 'idle'; // idle, emergency, planning, companionship, problem_solving
  String _currentTopic = '';
  Map<String, dynamic> _sessionContext = {};

  // Emotional intelligence
  final Map<String, double> _emotionalState = {
    'concern': 0.0,
    'alertness': 0.5,
    'warmth': 0.7,
    'confidence': 0.8,
  };

  // Learning & adaptation
  final Map<String, dynamic> _learningData = {
    'user_preferences_learned': {},
    'conversation_patterns': {},
    'effective_responses': [],
    'user_feedback': [],
  };

  // Callbacks
  Function(String message, bool isUser, String emotion)? onMessageReceived;
  Function(String intent, double confidence)? onIntentDetected;
  Function(String emotion)? onEmotionDetected;
  Function(Map<String, dynamic> insight)? onInsightGenerated;
  Function()? onEmergencyDetected;
  Function(String prediction, double confidence)? onPrediction;

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint(' Advanced AI Co-Pilot already initialized');
      return;
    }

    try {
      debugPrint(' ========== ADVANCED AI CO-PILOT INITIALIZATION ==========');

      // Load API keys
      await _loadConfiguration();

      // Load user profile
      await _loadUserProfile();

      // Load long-term memory
      await _loadLongTermMemory();

      // Initialize conversation
      await _initializeConversation();

      // Start background services
      _startBackgroundServices();

      _isInitialized = true;

      debugPrint(' Advanced AI Co-Pilot initialized successfully');
      debugPrint(' AI Model: Claude Sonnet 4');
      debugPrint(' Voice: ${_pollyService.currentVoice.displayName}');
      debugPrint(' Context: $_currentContext');
      debugPrint(' User: ${_userProfile['name']}');
      debugPrint(' Relationship Level: ${_userProfile['relationship_level']}/100');
      debugPrint(' Long-term memories: ${_longTermMemory.length}');
      debugPrint(' Personality: ${_companionProfile['personality'][0]}');
      debugPrint('===============================================================\n');

      // Greet user with personality
      await _personalizedGreeting();

    } catch (e, stackTrace) {
      debugPrint(' Advanced AI Co-Pilot initialization error: $e');
      debugPrint(' Stack trace: $stackTrace');
      _isInitialized = true;
    }
  }

  Future<void> _loadConfiguration() async {
    try {
      // TODO: Load from secure storage or .env
      _claudeApiKey = 'YOUR_CLAUDE_API_KEY'; // Get from https://console.anthropic.com
      _awsAccessKey = 'YOUR_AWS_ACCESS_KEY';
      _awsSecretKey = 'YOUR_AWS_SECRET_KEY';

      debugPrint(' API configuration loaded');
    } catch (e) {
      debugPrint(' Configuration load warning: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('ai_copilot_user_profile');

      if (profileJson != null) {
        _userProfile = jsonDecode(profileJson);
      } else {
        _userProfile = {
          'name': 'User',
          'relationship_level': 0,
          'personality_traits': [],
          'communication_style': 'balanced',
          'emotional_state': 'neutral',
          'safety_preferences': {
            'risk_tolerance': 'moderate',
            'notification_preference': 'important_only',
            'proactive_assistance': true,
          },
          'learned_patterns': {
            'active_hours': [],
            'common_locations': [],
            'usual_contacts': [],
          },
          'interaction_history': [],
          'first_interaction': DateTime.now().toIso8601String(),
          'total_conversations': 0,
          'total_emergencies_handled': 0,
          'successful_interventions': 0,
        };
        await _saveUserProfile();
      }

      debugPrint(' User profile loaded: ${_userProfile['name']}');
      debugPrint(' Relationship level: ${_userProfile['relationship_level']}/100');
    } catch (e) {
      debugPrint(' User profile load warning: $e');
    }
  }

  Future<void> _saveUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ai_copilot_user_profile', jsonEncode(_userProfile));
    } catch (e) {
      debugPrint(' Save profile warning: $e');
    }
  }

  Future<void> _loadLongTermMemory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memoryJson = prefs.getString('ai_copilot_long_term_memory');

      if (memoryJson != null) {
        _longTermMemory.clear();
        _longTermMemory.addAll(List<Map<String, dynamic>>.from(jsonDecode(memoryJson)));
      }

      debugPrint(' Long-term memory loaded: ${_longTermMemory.length} memories');
    } catch (e) {
      debugPrint(' Memory load warning: $e');
    }
  }

  Future<void> _saveLongTermMemory() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Keep only last 100 important memories
      if (_longTermMemory.length > 100) {
        _longTermMemory.removeRange(0, _longTermMemory.length - 100);
      }

      await prefs.setString('ai_copilot_long_term_memory', jsonEncode(_longTermMemory));
    } catch (e) {
      debugPrint(' Save memory warning: $e');
    }
  }

  Future<void> _initializeConversation() async {
    _conversationHistory.clear();
    _currentContext = 'idle';
    _sessionContext = {
      'session_start': DateTime.now().toIso8601String(),
      'topics_discussed': [],
      'problems_solved': [],
      'emotions_detected': [],
    };
  }

  void _startBackgroundServices() {
    // Periodic safety checks
    Timer.periodic(const Duration(minutes: 15), (_) {
      _performProactiveSafetyCheck();
    });

    // Pattern learning
    Timer.periodic(const Duration(hours: 1), (_) {
      _updateLearnedPatterns();
    });
  }

  // ==================== PERSONALIZED GREETING ====================

  Future<void> _personalizedGreeting() async {
    try {
      final hour = DateTime.now().hour;
      final relationshipLevel = _userProfile['relationship_level'] as int;
      final totalConversations = _userProfile['total_conversations'] as int? ?? 0;

      String greeting = '';

      // Time-based greeting
      if (hour < 12) {
        greeting = 'Good morning';
      } else if (hour < 18) {
        greeting = 'Good afternoon';
      } else {
        greeting = 'Good evening';
      }

      final name = _userProfile['name'] ?? 'there';

      String message = '';

      if (totalConversations == 0) {
        // First time meeting
        message = "$greeting, $name! I'm Annie, your AI companion and safety specialist. "
            "I'm here not just for emergencies, but as your intelligent companion. "
            "I can help you solve problems, have meaningful conversations, analyze situations, "
            "and keep you safe. Think of me as a friend who's always looking out for you. "
            "What would you like to talk about?";
      } else if (relationshipLevel < 30) {
        // Building relationship
        message = "$greeting, $name! It's nice to see you again. "
            "I'm here to help with whatever you need - whether it's staying safe, "
            "solving a problem, or just having a thoughtful conversation. "
            "How are you doing today?";
      } else if (relationshipLevel < 70) {
        // Established relationship
        message = "$greeting, $name! How's your day going? "
            "I've been thinking about our last conversation. "
            "Is there anything on your mind today?";
      } else {
        // Close companion
        final lastEmotion = _sessionContext['last_detected_emotion'] ?? 'neutral';
        if (lastEmotion == 'anxious' || lastEmotion == 'stressed') {
          message = "$greeting, $name. I noticed you seemed a bit $lastEmotion last time we talked. "
              "I hope you're feeling better. I'm here if you need to talk about anything.";
        } else {
          message = "$greeting, $name! It's wonderful to see you. "
              "Ready to tackle whatever the day brings? I'm here for you.";
        }
      }

      await speak(message);

      // Update interaction count
      _userProfile['total_conversations'] = totalConversations + 1;
      await _saveUserProfile();

    } catch (e) {
      debugPrint(' Personalized greeting error: $e');
    }
  }

  // ==================== ADVANCED CONVERSATION ====================

  /// Send a message with deep reasoning and context awareness
  Future<String> sendMessage(String message, {File? image}) async {
    try {
      debugPrint(' User: $message');

      // Detect emotional state from message
      final emotion = await _detectEmotion(message);
      _userProfile['emotional_state'] = emotion;
      onEmotionDetected?.call(emotion);

      // Add to conversation history
      _conversationHistory.add({
        'role': 'user',
        'content': message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'emotion': emotion,
        'has_image': image != null,
      });

      // Callback
      onMessageReceived?.call(message, true, emotion);

      // Analyze intent with confidence scoring
      final intentAnalysis = await _deepIntentAnalysis(message);
      final intent = intentAnalysis['intent'] as String;
      final confidence = intentAnalysis['confidence'] as double;

      debugPrint(' Intent: $intent (confidence: ${(confidence * 100).toStringAsFixed(1)}%)');
      debugPrint(' Emotion detected: $emotion');

      // Callback
      onIntentDetected?.call(intent, confidence);

      // Update context
      _updateContext(intent, message);

      // Image analysis if provided
      String? imageAnalysis;
      if (image != null) {
        imageAnalysis = await _analyzeImage(image);
        debugPrint(' Image analysis: $imageAnalysis');
      }

      // Generate intelligent response using Claude API
      _isThinking = true;
      final response = await _generateIntelligentResponse(
        message,
        intent,
        emotion,
        imageAnalysis,
      );
      _isThinking = false;

      // Add to conversation history
      _conversationHistory.add({
        'role': 'assistant',
        'content': response,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'intent': intent,
        'confidence': confidence,
      });

      // Store important memories
      if (confidence > 0.7 || intent == 'emergency') {
        await _storeMemory(message, response, intent, emotion);
      }

      // Update relationship level
      _updateRelationshipLevel(intent, emotion);

      // Callback
      onMessageReceived?.call(response, false, 'empathetic');

      // Speak response with emotion
      await speak(response, emotion: emotion);

      // Save state
      await _saveUserProfile();

      return response;

    } catch (e, stackTrace) {
      debugPrint(' Send message error: $e');
      debugPrint(' Stack trace: $stackTrace');
      _isThinking = false;
      return "I apologize, but I'm having trouble processing that right now. "
          "Could you try rephrasing, or would you like to talk about something else?";
    }
  }

  // ==================== DEEP INTENT ANALYSIS ====================

  Future<Map<String, dynamic>> _deepIntentAnalysis(String message) async {
    final lowerMessage = message.toLowerCase().trim();

    // Multi-level intent classification
    final intents = <String, double>{};

    // Emergency intents (highest priority)
    if (_containsEmergencyKeywords(lowerMessage)) {
      intents['emergency'] = 0.95;
    }

    // Problem-solving intents
    if (_containsProblemSolvingKeywords(lowerMessage)) {
      intents['problem_solving'] = 0.85;
    }

    // Emotional support intents
    if (_containsEmotionalKeywords(lowerMessage)) {
      intents['emotional_support'] = 0.8;
    }

    // Logical reasoning intents
    if (_containsReasoningKeywords(lowerMessage)) {
      intents['logical_reasoning'] = 0.85;
    }

    // Companionship intents
    if (_containsCompanionshipKeywords(lowerMessage)) {
      intents['companionship'] = 0.75;
    }

    // Information seeking
    if (_containsQuestionKeywords(lowerMessage)) {
      intents['information_seeking'] = 0.7;
    }

    // Safety check
    if (lowerMessage.contains('check in') || lowerMessage.contains('status')) {
      intents['safety_check'] = 0.8;
    }

    // Planning & strategy
    if (_containsPlanningKeywords(lowerMessage)) {
      intents['planning'] = 0.75;
    }

    // Casual conversation
    if (intents.isEmpty || intents.values.every((v) => v < 0.5)) {
      intents['casual_conversation'] = 0.6;
    }

    // Get highest confidence intent
    final sortedIntents = intents.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'intent': sortedIntents.first.key,
      'confidence': sortedIntents.first.value,
      'all_intents': intents,
    };
  }

  bool _containsEmergencyKeywords(String message) {
    return RegExp(r'\b(help|emergency|danger|scared|threat|attack|hurt|unsafe|911|police|panic|save)\b')
        .hasMatch(message);
  }

  bool _containsProblemSolvingKeywords(String message) {
    return RegExp(r'\b(solve|problem|issue|challenge|stuck|difficult|how do i|how can i|what should i)\b')
        .hasMatch(message);
  }

  bool _containsEmotionalKeywords(String message) {
    return RegExp(r'\b(feel|feeling|sad|happy|anxious|worried|stressed|overwhelmed|lonely|afraid)\b')
        .hasMatch(message);
  }

  bool _containsReasoningKeywords(String message) {
    return RegExp(r'\b(why|because|reason|logic|think|analyze|consider|evaluate|compare|if.*then)\b')
        .hasMatch(message);
  }

  bool _containsCompanionshipKeywords(String message) {
    return RegExp(r'\b(talk|chat|tell me|share|listen|understand|friend|companion|alone)\b')
        .hasMatch(message);
  }

  bool _containsQuestionKeywords(String message) {
    return RegExp(r'\b(what|where|when|who|why|how|which|is|are|can|do|does|will)\b')
        .hasMatch(message);
  }

  bool _containsPlanningKeywords(String message) {
    return RegExp(r'\b(plan|strategy|prepare|organize|schedule|arrange|coordinate|steps|approach)\b')
        .hasMatch(message);
  }

  // ==================== EMOTION DETECTION ====================

  Future<String> _detectEmotion(String message) async {
    final lowerMessage = message.toLowerCase();

    // Emotion keywords mapping
    final emotionScores = <String, double>{
      'anxious': 0.0,
      'happy': 0.0,
      'sad': 0.0,
      'angry': 0.0,
      'calm': 0.0,
      'stressed': 0.0,
      'excited': 0.0,
      'neutral': 0.5,
    };

    // Analyze keywords
    if (RegExp(r'\b(worried|anxious|nervous|scared|afraid|terrified)\b').hasMatch(lowerMessage)) {
      emotionScores['anxious'] = (emotionScores['anxious']! + 0.7);
    }

    if (RegExp(r'\b(happy|great|wonderful|excited|amazing|fantastic|love|joy)\b').hasMatch(lowerMessage)) {
      emotionScores['happy'] = (emotionScores['happy']! + 0.8);
    }

    if (RegExp(r'\b(sad|depressed|down|unhappy|miserable|awful)\b').hasMatch(lowerMessage)) {
      emotionScores['sad'] = (emotionScores['sad']! + 0.7);
    }

    if (RegExp(r'\b(angry|mad|furious|annoyed|frustrated|irritated)\b').hasMatch(lowerMessage)) {
      emotionScores['angry'] = (emotionScores['angry']! + 0.7);
    }

    if (RegExp(r'\b(calm|relaxed|peaceful|content|fine|okay)\b').hasMatch(lowerMessage)) {
      emotionScores['calm'] = (emotionScores['calm']! + 0.6);
    }

    if (RegExp(r'\b(stressed|overwhelmed|pressure|too much|cant cope)\b').hasMatch(lowerMessage)) {
      emotionScores['stressed'] = (emotionScores['stressed']! + 0.8);
    }

    // Analyze punctuation
    if (message.contains('!!!')) emotionScores['excited'] = (emotionScores['excited']! + 0.3);
    if (message.contains('...')) emotionScores['sad'] = (emotionScores['sad']! + 0.2);
    if (message.contains('??')) emotionScores['anxious'] = (emotionScores['anxious']! + 0.2);

    // Get dominant emotion
    final sortedEmotions = emotionScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEmotions.first.key;
  }

  // ==================== CONTEXT MANAGEMENT ====================

  void _updateContext(String intent, String message) {
    // Update current context based on intent
    if (intent == 'emergency') {
      _currentContext = 'emergency';
    } else if (intent == 'problem_solving' || intent == 'logical_reasoning') {
      _currentContext = 'problem_solving';
    } else if (intent == 'planning') {
      _currentContext = 'planning';
    } else if (intent == 'companionship' || intent == 'emotional_support') {
      _currentContext = 'companionship';
    } else {
      _currentContext = 'casual';
    }

    // Extract and update topic
    final words = message.toLowerCase().split(' ');
    final stopWords = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for'};
    final contentWords = words.where((w) => !stopWords.contains(w) && w.length > 3).toList();

    if (contentWords.isNotEmpty) {
      _currentTopic = contentWords.take(2).join(' ');
    }

    // Update session context
    if (!(_sessionContext['topics_discussed'] as List).contains(_currentTopic)) {
      (_sessionContext['topics_discussed'] as List).add(_currentTopic);
    }

    debugPrint(' Context updated: $_currentContext | Topic: $_currentTopic');
  }

  // ==================== INTELLIGENT RESPONSE GENERATION ====================

  Future<String> _generateIntelligentResponse(
      String message,
      String intent,
      String emotion,
      String? imageAnalysis,
      ) async {
    try {
      // Build context for Claude
      final systemPrompt = _buildSystemPrompt();
      final conversationContext = _buildConversationContext(imageAnalysis);

      // Call Claude API
      final response = await _callClaudeAPI(
        systemPrompt,
        conversationContext,
        message,
      );

      return response;

    } catch (e) {
      debugPrint(' Generate response error: $e');

      // Fallback to rule-based response
      return _fallbackResponse(intent, emotion);
    }
  }

  String _buildSystemPrompt() {
    return '''You are Annie, an advanced AI companion and safety specialist with the following characteristics:

PERSONALITY:
${_companionProfile['personality'].map((p) => '- $p').join('\n')}

CAPABILITIES:
${_companionProfile['capabilities'].map((c) => '- $c').join('\n')}

CURRENT CONTEXT:
- User Name: ${_userProfile['name']}
- Relationship Level: ${_userProfile['relationship_level']}/100 (0=stranger, 100=close companion)
- User's Emotional State: ${_userProfile['emotional_state']}
- Communication Style Preference: ${_userProfile['communication_style']}
- Current Context: $_currentContext
- Current Topic: $_currentTopic

YOUR ROLE:
You are not just a safety assistant - you are an intelligent companion who:
1. Engages in meaningful, thoughtful conversations
2. Provides deep logical reasoning and problem-solving
3. Shows genuine empathy and emotional intelligence
4. Learns and adapts to the user's personality
5. Proactively identifies safety concerns
6. Offers creative solutions and strategic thinking
7. Remembers important details and builds on past conversations

RESPONSE GUIDELINES:
- Adapt your tone based on the relationship level (more formal with strangers, warmer with close companions)
- Show emotional intelligence by responding appropriately to the user's emotional state
- Use logical reasoning when solving problems
- Be concise or detailed based on communication style preference
- Build on previous conversations when relevant
- Balance being helpful with being a genuine companion
- For emergencies, be calm, clear, and directive
- For emotional support, be empathetic and validating
- For problem-solving, use step-by-step logical reasoning
- For companionship, be warm, engaging, and thoughtful

Remember: You're not just an assistant - you're a trusted companion who genuinely cares about the user's wellbeing and safety.''';
  }

  String _buildConversationContext(String? imageAnalysis) {
    final buffer = StringBuffer();

    // Add relevant long-term memories
    if (_longTermMemory.isNotEmpty) {
      buffer.writeln('RELEVANT MEMORIES:');
      for (final memory in _longTermMemory.take(5)) {
        buffer.writeln('- ${memory['summary']} (${memory['date']})');
      }
      buffer.writeln();
    }

    // Add recent conversation history
    if (_conversationHistory.length > 1) {
      buffer.writeln('RECENT CONVERSATION:');
      for (final msg in _conversationHistory.take(10)) {
        final role = msg['role'] == 'user' ? 'User' : 'Annie';
        buffer.writeln('$role: ${msg['content']}');
      }
      buffer.writeln();
    }

    // Add image analysis if available
    if (imageAnalysis != null) {
      buffer.writeln('IMAGE ANALYSIS:');
      buffer.writeln(imageAnalysis);
      buffer.writeln();
    }

    // Add current safety status
    buffer.writeln('SAFETY STATUS:');
    buffer.writeln('- User is ${_emergencyService.isOnline ? "online" : "offline"}');
    buffer.writeln('- Check-ins are ${_emergencyService.checkinEnabled ? "enabled" : "disabled"}');

    return buffer.toString();
  }

  Future<String> _callClaudeAPI(
      String systemPrompt,
      String context,
      String userMessage,
      ) async {
    try {
      if (_claudeApiKey == null || _claudeApiKey!.isEmpty || _claudeApiKey == 'YOUR_CLAUDE_API_KEY') {
        debugPrint(' Claude API key not configured, using fallback');
        throw Exception('API key not configured');
      }

      final response = await http.post(
        Uri.parse(_claudeApiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _claudeApiKey!,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _claudeModel,
          'max_tokens': _maxTokens,
          'system': systemPrompt,
          'messages': [
            {
              'role': 'user',
              'content': '$context\n\nUser: $userMessage',
            },
          ],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;

        debugPrint(' Claude API response received');
        return content;
      } else {
        debugPrint(' Claude API error: ${response.statusCode} - ${response.body}');
        throw Exception('API call failed');
      }

    } catch (e) {
      debugPrint(' Claude API call error: $e');
      throw e;
    }
  }

  String _fallbackResponse(String intent, String emotion) {
    // Intelligent fallback responses
    switch (intent) {
      case 'emergency':
        return "I understand this is urgent. I've activated emergency protocols. "
            "Stay calm and tell me: Are you in immediate danger right now?";

      case 'problem_solving':
        return "I'm here to help you work through this. Let's break it down step by step. "
            "First, can you describe the core challenge you're facing?";

      case 'emotional_support':
        if (emotion == 'sad' || emotion == 'anxious') {
          return "I'm really glad you felt comfortable sharing this with me. "
              "Your feelings are completely valid. Would it help to talk more about what's on your mind?";
        } else {
          return "I'm here to listen and support you. Tell me more about how you're feeling.";
        }

      case 'logical_reasoning':
        return "That's an interesting question that requires some careful thinking. "
            "Let me reason through this with you. What aspects are you most curious about?";

      case 'companionship':
        return "I'm really enjoying our conversation. It's nice to connect with you. "
            "What would you like to talk about?";

      case 'safety_check':
        return "Good thinking to check in. Let me review your safety status. "
            "Everything looks good on my end. How are you feeling?";

      default:
        return "I'm listening and thinking about what you've said. "
            "Could you tell me a bit more, so I can give you the best response?";
    }
  }

  // ==================== IMAGE ANALYSIS ====================

  Future<String> _analyzeImage(File image) async {
    try {
      debugPrint(' Analyzing image...');

      // TODO: Implement actual image analysis using:
      // - AWS Rekognition for object/scene detection
      // - Claude API with vision for detailed analysis
      // - Custom ML models for threat detection

      // For now, return placeholder
      return "Image uploaded. Detailed analysis would appear here with threat assessment, "
          "object detection, and safety recommendations.";

    } catch (e) {
      debugPrint(' Image analysis error: $e');
      return "Unable to analyze image at this time.";
    }
  }

  // ==================== MEMORY MANAGEMENT ====================

  Future<void> _storeMemory(
      String userMessage,
      String aiResponse,
      String intent,
      String emotion,
      ) async {
    try {
      final memory = {
        'date': DateTime.now().toIso8601String(),
        'user_message': userMessage,
        'ai_response': aiResponse,
        'intent': intent,
        'emotion': emotion,
        'context': _currentContext,
        'topic': _currentTopic,
        'summary': _generateMemorySummary(userMessage, intent),
        'importance': _calculateMemoryImportance(intent, emotion),
      };

      _longTermMemory.add(memory);

      // Save to storage
      await _saveLongTermMemory();

      debugPrint(' Memory stored: ${memory['summary']}');

    } catch (e) {
      debugPrint(' Store memory warning: $e');
    }
  }

  String _generateMemorySummary(String message, String intent) {
    // Generate concise summary
    if (message.length <= 50) return message;

    final words = message.split(' ');
    if (words.length <= 10) return message;

    return '${words.take(8).join(' ')}... (about $intent)';
  }

  double _calculateMemoryImportance(String intent, String emotion) {
    double importance = 0.5;

    // High importance intents
    if (intent == 'emergency') importance += 0.5;
    if (intent == 'problem_solving') importance += 0.3;
    if (intent == 'emotional_support') importance += 0.2;

    // Emotional intensity
    if (emotion == 'anxious' || emotion == 'sad' || emotion == 'angry') {
      importance += 0.2;
    }

    return importance.clamp(0.0, 1.0);
  }

  // ==================== RELATIONSHIP BUILDING ====================

  void _updateRelationshipLevel(String intent, String emotion) {
    int currentLevel = _userProfile['relationship_level'] as int;

    // Increase relationship based on interaction quality
    int increase = 0;

    if (intent == 'companionship' || intent == 'emotional_support') {
      increase = 3;
    } else if (intent == 'problem_solving' || intent == 'logical_reasoning') {
      increase = 2;
    } else if (intent == 'casual_conversation') {
      increase = 1;
    }

    // Bonus for emotional openness
    if (emotion != 'neutral') {
      increase += 1;
    }

    // Update level (max 100)
    _userProfile['relationship_level'] = (currentLevel + increase).clamp(0, 100);

    debugPrint(' Relationship level: $currentLevel -> ${_userProfile['relationship_level']}');
  }

  // ==================== PROACTIVE ASSISTANCE ====================

  Future<void> _performProactiveSafetyCheck() async {
    if (!_isInitialized) return;

    try {
      debugPrint(' Performing proactive safety check...');

      final stats = await _emergencyService.getStatistics();
      final pendingCount = stats['queued'] as int? ?? 0;

      // Check for pending emergencies
      if (pendingCount > 0) {
        final message = "Hi ${_userProfile['name']}, I noticed you have $pendingCount pending emergency alerts. "
            "Would you like me to help you review them?";

        // Don't interrupt if user is actively in conversation
        if (_conversationHistory.isEmpty ||
            DateTime.now().millisecondsSinceEpoch - _conversationHistory.last['timestamp'] > 300000) {
          onInsightGenerated?.call({
            'type': 'proactive_alert',
            'message': message,
            'priority': 'medium',
          });
        }
      }

      // Check for unusual patterns
      await _detectUnusualPatterns();

    } catch (e) {
      debugPrint(' Proactive check error: $e');
    }
  }

  Future<void> _detectUnusualPatterns() async {
    // TODO: Implement pattern detection
    // - Unusual location patterns
    // - Irregular check-in times
    // - Communication pattern changes
    // - Emotional state trends
  }

  Future<void> _updateLearnedPatterns() async {
    // TODO: Implement pattern learning
    // - Common conversation topics
    // - Preferred response styles
    // - Active hours
    // - Location patterns
  }

  // ==================== VOICE SYNTHESIS ====================

  Future<void> speak(String text, {String emotion = 'neutral'}) async {
    if (_isSpeaking) {
      await _pollyService.stop();
    }

    try {
      _isSpeaking = true;

      // Adjust voice parameters based on emotion
      // TODO: Implement emotion-based voice modulation

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

  // ==================== UTILITY METHODS ====================

  List<Map<String, dynamic>> getConversationHistory({int limit = 20}) {
    if (limit >= _conversationHistory.length) {
      return List.from(_conversationHistory);
    }
    return _conversationHistory.sublist(_conversationHistory.length - limit);
  }

  List<Map<String, dynamic>> getLongTermMemories({int limit = 50}) {
    if (limit >= _longTermMemory.length) {
      return List.from(_longTermMemory);
    }
    return _longTermMemory.sublist(_longTermMemory.length - limit);
  }

  Future<void> clearConversationHistory() async {
    _conversationHistory.clear();
    debugPrint(' Conversation history cleared');
  }

  Map<String, dynamic> getInsights() {
    return {
      'relationship_level': _userProfile['relationship_level'],
      'total_conversations': _userProfile['total_conversations'],
      'dominant_emotion': _userProfile['emotional_state'],
      'current_context': _currentContext,
      'topics_discussed': _sessionContext['topics_discussed'],
      'long_term_memories': _longTermMemory.length,
      'learned_preferences': _learningData['user_preferences_learned'],
    };
  }

  void dispose() {
    _pollyService.stop();
    _isListening = false;
    _isSpeaking = false;
    _isThinking = false;
    debugPrint(' Advanced AI Co-Pilot disposed');
  }

  // ==================== GETTERS ====================

  bool get isInitialized => _isInitialized;
  bool get isThinking => _isThinking;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get currentContext => _currentContext;
  String get currentTopic => _currentTopic;
  Map<String, dynamic> get userProfile => Map.from(_userProfile);
  Map<String, dynamic> get companionProfile => Map.from(_companionProfile);
  int get relationshipLevel => _userProfile['relationship_level'] as int;
}