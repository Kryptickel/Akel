import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

import '../services/aws_lex_service.dart';
import '../services/enhanced_aws_polly_service.dart';
import '../services/medical_intelligence_service.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../models/ai_message.dart';
import '../models/doctor_annie_appearance.dart';
import '../widgets/glossy_3d_widgets.dart';
import '../widgets/doctor_annie_avatar_widget.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import 'hospital_finder_screen.dart';
import 'voice_settings_screen.dart';
import 'voice_center_screen.dart';

/// ==================== DOCTOR ANNIE SCREEN ====================
///
/// UNIFIED AI HEALTH ASSISTANT
///
/// Features:
/// - 3D Animated Avatar (customizable appearance)
/// - 50+ Voice Options (AWS Polly + Google TTS)
/// - Voice Center Integration (40+ voices)
/// - AI Chat (AWS Lex + Medical Intelligence)
/// - Symptom Checking & Emergency Detection
/// - Hospital Finder Integration
/// - Complete Voice Control
///
/// BUILD 55 - Voice Center Complete Integration
/// =============================================================

class DoctorAnnieScreen extends StatefulWidget {
  const DoctorAnnieScreen({super.key});

  @override
  State<DoctorAnnieScreen> createState() => _DoctorAnnieScreenState();
}

class _DoctorAnnieScreenState extends State<DoctorAnnieScreen> with TickerProviderStateMixin {
  // Services
  final AWSLexService _lexService = AWSLexService();
  final EnhancedAWSPollyService _pollyService = EnhancedAWSPollyService();
  final MedicalIntelligenceService _medicalService = MedicalIntelligenceService();

  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State
  final List<AIMessage> _messages = [];
  final Set<String> _selectedSymptoms = {};
  bool _isLoading = false;
  bool _isVoiceEnabled = true;
  String _currentSymptoms = '';

  // Avatar
  late AnimationController _avatarController;
  late AnimationController _floatController;
  DoctorAnnieAppearance _annieAppearance = const DoctorAnnieAppearance(
    hairStyle: HairStyle.braided,
    hairColor: Color(0xFF2C1810),
    skinTone: Color(0xFFC68642),
    ethnicity: EthnicityType.indian,
    hasStethoscope: true,
    clothing: ClothingType.labCoat,
    glossyIntensity: 0.8,
    enableReflections: true,
    enableShadows: true,
  );

  // Common symptoms for quick selection
  static const List<String> _commonSymptoms = [
    'Fever',
    'Headache',
    'Chest pain',
    'Shortness of breath',
    'Nausea',
    'Dizziness',
    'Back pain',
    'Fatigue',
    'Cough',
    'Sore throat',
    'Stomach pain',
    'Rash',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
    _loadAnnieAppearance();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _avatarController.dispose();
    _floatController.dispose();
    _pollyService.stop();
    super.dispose();
  }

  void _initializeAnimations() {
    _avatarController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> _initializeServices() async {
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid ?? 'anonymous';

    _lexService.initSession(userId);
    await _medicalService.initialize();

    if (!_pollyService.isInitialized) {
      await _pollyService.initialize();
    }
  }

  Future<void> _loadAnnieAppearance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appearanceJson = prefs.getString('doctor_annie_appearance');

      if (appearanceJson != null && mounted) {
        setState(() {
          _annieAppearance = DoctorAnnieAppearance.fromJson(
            jsonDecode(appearanceJson),
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading Annie appearance: $e');
    }
  }

  Future<void> _saveAnnieAppearance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'doctor_annie_appearance',
        jsonEncode(_annieAppearance.toJson()),
      );
    } catch (e) {
      debugPrint('Error saving Annie appearance: $e');
    }
  }

  void _addWelcomeMessage() {
    final currentVoice = _pollyService.currentProvider == TTSProvider.awsPolly
        ? _pollyService.currentVoice.displayName
        : 'Google TTS';

    final welcomeMessage = AIMessage.ai(
      " Hello! I'm **Doctor Annie**, your AI health assistant.\n\n"
          "I can help you with:\n"
          "• Symptom checking & analysis\n"
          "• First aid guidance\n"
          "• Medication information\n"
          "• Finding nearby hospitals\n"
          "• Health questions & advice\n\n"
          "**Voice:** I'm currently using $currentVoice voice. "
          "You can change my voice in Voice Settings or Voice Center (40+ voices available)!\n\n"
          " **Important:** I'm an AI assistant and cannot replace professional medical advice. "
          "For emergencies, use the panic button or call 911.\n\n"
          "How can I help you today?",
    );

    setState(() {
      _messages.add(welcomeMessage);
    });

    if (_isVoiceEnabled) {
      _speak(
        "Hello! I'm Doctor Annie, your AI health assistant. "
            "I'm currently using $currentVoice voice. "
            "How can I help you today?",
      );
    }
  }

  Future<void> _speak(String text) async {
    if (_isVoiceEnabled && text.trim().isNotEmpty) {
      final cleanText = _cleanTextForSpeech(text);
      try {
        await _pollyService.speak(cleanText);
      } catch (e) {
        debugPrint('Speech error: $e');
      }
    }
  }

  String _cleanTextForSpeech(String text) {
    String clean = text
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'__'), '')
        .replaceAll(RegExp(r'•'), '')
        .replaceAll(RegExp(r' | | | | | | '), '')
        .replaceAll(RegExp(r'\n\n+'), '. ')
        .replaceAll('\n', '. ');
    return clean.trim();
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showErrorDialog('Please sign in to use Doctor Annie');
      return;
    }

    _currentSymptoms = text;

    String fullMessage = text;
    if (_selectedSymptoms.isNotEmpty) {
      fullMessage = 'Symptoms: ${_selectedSymptoms.join(", ")}\n\n$text';
    }

    final userMessage = AIMessage.user(fullMessage);

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    final symptomsToSend = _selectedSymptoms.toList();

    _scrollToBottom();
    await _pollyService.stop();

    try {
      // Get responses from both AWS Lex and Medical Intelligence
      final lexMessage = await _lexService.sendMessage(text);
      final medicalResponse = await _medicalService.askDoctorAnnie(
        userId: userId,
        question: text,
        symptoms: symptomsToSend.isNotEmpty ? symptomsToSend : null,
      );

      // Combine and prioritize responses
      final combinedContent = _combineResponses(
        lexMessage.content,
        medicalResponse,
      );

      final aiMessage = AIMessage.ai(combinedContent);

      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
        _selectedSymptoms.clear();
      });

      _scrollToBottom();

      // Check for emergency
      if (_isEmergency(medicalResponse)) {
        _showEmergencyDialog();
      }

      // Speak response
      if (_isVoiceEnabled && !aiMessage.isError) {
        await _speak(aiMessage.content);
      }
    } catch (e) {
      setState(() {
        _messages.add(AIMessage.error('Error: ${e.toString()}'));
        _isLoading = false;
      });
      debugPrint('Message error: $e');
    }
  }

  String _combineResponses(String lexResponse, String medicalResponse) {
    // Prioritize emergency responses
    if (_isEmergency(medicalResponse)) {
      return medicalResponse;
    }

    // Use medical response if significantly longer/more detailed
    if (medicalResponse.length > lexResponse.length * 1.5) {
      return medicalResponse;
    }

    // Use Lex response for conversational queries
    return lexResponse;
  }

  bool _isEmergency(String response) {
    final emergencyKeywords = [
      'URGENT',
      '911',
      'emergency',
      'immediately',
      'call an ambulance',
      'life-threatening',
      'seek immediate',
    ];

    final lowerResponse = response.toLowerCase();
    return emergencyKeywords.any((keyword) =>
        lowerResponse.contains(keyword.toLowerCase())
    );
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AkelDesign.primaryRed.withOpacity(0.5), width: 2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AkelDesign.primaryRed.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning,
                color: AkelDesign.primaryRed,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Emergency Detected!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doctor Annie has detected potential emergency symptoms.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              ' Please seek immediate medical attention.',
              style: TextStyle(
                color: AkelDesign.warningOrange,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I understand'),
          ),
          const SizedBox(width: 8),
          Glossy3DButton(
            text: 'Call 911',
            icon: Icons.phone,
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual 911 call
            },
            color: AkelDesign.errorRed,
            width: 120,
            height: 45,
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        title: const Row(
          children: [
            Icon(Icons.error, color: AkelDesign.errorRed),
            SizedBox(width: 12),
            Text('Error', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAvatarCustomization() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildAvatarCustomizationSheet(),
    );
  }

  Widget _buildAvatarCustomizationSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AkelDesign.carbonFiber,
            AkelDesign.deepBlack,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.face, color: Color(0xFF00BFA5), size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Customize Doctor Annie',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Preview
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00BFA5).withOpacity(0.2),
                  const Color(0xFF00E5FF).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00BFA5).withOpacity(0.3),
              ),
            ),
            child: Center(
              child: DoctorAnnieAvatarWidget(
                appearance: _annieAppearance,
                size: 120,
                enableAnimations: true,
                showHolographicBackground: true,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Preset options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildPresetOption(
                  'Female Doctor (Indian)',
                  'Professional, empathetic',
                  Icons.face,
                  const DoctorAnnieAppearance(
                    hairStyle: HairStyle.braided,
                    hairColor: Color(0xFF2C1810),
                    skinTone: Color(0xFFC68642),
                    ethnicity: EthnicityType.indian,
                    hasStethoscope: true,
                    clothing: ClothingType.labCoat,
                    glossyIntensity: 0.8,
                    enableReflections: true,
                    enableShadows: true,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPresetOption(
                  'Male Doctor (Caucasian)',
                  'Calm, professional',
                  Icons.face_2,
                  const DoctorAnnieAppearance(
                    hairStyle: HairStyle.straight,
                    hairColor: Color(0xFF4A3728),
                    skinTone: Color(0xFFE0AC69),
                    ethnicity: EthnicityType.caucasian,
                    hasStethoscope: true,
                    clothing: ClothingType.labCoat,
                    glossyIntensity: 0.7,
                    enableReflections: true,
                    enableShadows: true,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPresetOption(
                  'Neutral Doctor (Asian)',
                  'Modern, approachable',
                  Icons.face_3,
                  const DoctorAnnieAppearance(
                    hairStyle: HairStyle.bun,
                    hairColor: Color(0xFF1A1A1A),
                    skinTone: Color(0xFFD4A574),
                    ethnicity: EthnicityType.asian,
                    hasStethoscope: true,
                    clothing: ClothingType.scrubs,
                    glossyIntensity: 0.8,
                    enableReflections: true,
                    enableShadows: true,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPresetOption(
                  'African Doctor',
                  'Warm, experienced',
                  Icons.face_4,
                  const DoctorAnnieAppearance(
                    hairStyle: HairStyle.curly,
                    hairColor: Color(0xFF1A1A1A),
                    skinTone: Color(0xFF8D5524),
                    ethnicity: EthnicityType.african,
                    hasStethoscope: true,
                    clothing: ClothingType.labCoat,
                    glossyIntensity: 0.9,
                    enableReflections: true,
                    enableShadows: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetOption(
      String title,
      String subtitle,
      IconData icon,
      DoctorAnnieAppearance appearance,
      ) {
    final isSelected = _annieAppearance.hairStyle == appearance.hairStyle &&
        _annieAppearance.ethnicity == appearance.ethnicity;

    return InkWell(
      onTap: () {
        setState(() {
          _annieAppearance = appearance;
        });
        _saveAnnieAppearance();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [
              const Color(0xFF00BFA5).withOpacity(0.3),
              const Color(0xFF00E5FF).withOpacity(0.1),
            ],
          )
              : null,
          color: isSelected ? null : AkelDesign.carbonFiber.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00BFA5)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF00BFA5), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF00BFA5),
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Clear Chat?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will delete all messages in this conversation.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Glossy3DButton(
            text: 'Clear',
            icon: Icons.delete,
            onPressed: () {
              setState(() {
                _messages.clear();
                _currentSymptoms = '';
                _selectedSymptoms.clear();
              });
              _addWelcomeMessage();
              Navigator.pop(context);
            },
            color: AkelDesign.errorRed,
            width: 100,
            height: 40,
          ),
        ],
      ),
    );
  }

  void _navigateToHospitalFinder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HospitalFinderScreen(
          searchQuery: _currentSymptoms,
          fromDoctorAnnie: true,
        ),
      ),
    );
  }

  void _navigateToVoiceSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VoiceSettingsScreen()),
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _navigateToVoiceCenter() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VoiceCenterScreen()),
    );
    if (mounted) {
      setState(() {});
    }
  }

  bool _shouldShowHospitalButton(AIMessage message) {
    final content = message.content.toLowerCase();
    final medicalKeywords = [
      'hospital',
      'emergency',
      'urgent care',
      'doctor',
      'seek medical',
      'call 911',
      'see a doctor',
      'medical attention',
      'serious',
      'severe',
    ];

    return medicalKeywords.any((keyword) => content.contains(keyword));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentVoice = _pollyService.currentProvider == TTSProvider.awsPolly
        ? _pollyService.currentVoice.displayName
        : 'Google TTS';

    return Scaffold(
      backgroundColor: AkelDesign.deepBlack,
      appBar: AppBar(
        backgroundColor: AkelDesign.carbonFiber,
        elevation: 0,
        title: Row(
          children: [
            // Animated 3D Avatar
            AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    math.sin(_floatController.value * 2 * math.pi) * 3,
                  ),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: DoctorAnnieAvatarWidget(
                      appearance: _annieAppearance,
                      size: 40,
                      enableAnimations: true,
                      showHolographicBackground: false,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    ' Doctor Annie',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'AI Health • $currentVoice',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (_pollyService.isSpeaking)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF00BFA5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Voice Center button (highlighted)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BFA5), Color(0xFF00E5FF)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00BFA5).withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.settings_voice, size: 18),
            ),
            onPressed: _navigateToVoiceCenter,
            tooltip: 'Voice Center (40+ voices)',
          ),

          // Voice settings
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF00BFA5)),
            onPressed: _navigateToVoiceSettings,
            tooltip: 'Voice Settings',
          ),

          // Avatar customization
          IconButton(
            icon: const Icon(Icons.face, color: Colors.white70),
            onPressed: _showAvatarCustomization,
            tooltip: 'Customize Avatar',
          ),

          // Hospital finder
          IconButton(
            icon: const Icon(Icons.local_hospital, color: Colors.blue),
            tooltip: 'Find Hospitals',
            onPressed: _navigateToHospitalFinder,
          ),

          // Voice toggle
          IconButton(
            icon: Icon(
              _isVoiceEnabled ? Icons.volume_up : Icons.volume_off,
              color: _isVoiceEnabled
                  ? const Color(0xFF00BFA5)
                  : Colors.white70,
            ),
            tooltip: _isVoiceEnabled ? 'Disable Voice' : 'Enable Voice',
            onPressed: () {
              setState(() {
                _isVoiceEnabled = !_isVoiceEnabled;
              });
              if (!_isVoiceEnabled) {
                _pollyService.stop();
              } else {
                _speak(
                  'Voice enabled. I am Doctor Annie using $currentVoice voice.',
                );
              }
            },
          ),

          // Clear chat
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            tooltip: 'Clear Chat',
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Warning banner
          LiquidGlassCard(
            borderRadius: 0,
            padding: const EdgeInsets.all(12),
            gradientColors: const [
              Colors.orange,
              Colors.deepOrange,
              Colors.amber,
            ],
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI assistant using $currentVoice. For informational purposes only.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Symptom selector
          if (_commonSymptoms.isNotEmpty)
            FrostedGlassCard(
              borderRadius: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.medical_services,
                        color: Color(0xFF00BFA5),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Quick Symptom Selection',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _commonSymptoms.map((symptom) {
                      final isSelected = _selectedSymptoms.contains(symptom);
                      return GestureDetector(
                        onTap: () => _toggleSymptom(symptom),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF00BFA5).withOpacity(0.3)
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF00BFA5)
                                  : Colors.white24,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: const Color(0xFF00BFA5)
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                                : null,
                          ),
                          child: Text(
                            symptom,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? Center(
              child: RealisticGlassCard(
                enable3D: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DoctorAnnieAvatarWidget(
                      appearance: _annieAppearance,
                      size: 100,
                      enableAnimations: true,
                      showHolographicBackground: true,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Start a conversation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Using $currentVoice voice',
                      style: const TextStyle(
                        color: Color(0xFF00BFA5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Column(
                  children: [
                    _buildMessageBubble(message),
                    if (message.sender == MessageSender.ai &&
                        _shouldShowHospitalButton(message))
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 8,
                          bottom: 8,
                          right: 60,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Glossy3DButton(
                            text: 'Find Nearby Hospitals',
                            icon: Icons.local_hospital,
                            onPressed: _navigateToHospitalFinder,
                            color: Colors.blue,
                            width: 220,
                            height: 45,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            NeumorphicCard(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF00BFA5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Doctor Annie is thinking...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Input area
          RealisticGlassCard(
            borderRadius: 0,
            enable3D: false,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Ask Doctor Annie anything...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Glossy3DButton(
                  text: '',
                  icon: Icons.send,
                  onPressed: _isLoading ? () {} : _sendMessage,
                  color: _isLoading
                      ? Colors.grey
                      : const Color(0xFF00BFA5),
                  width: 56,
                  height: 56,
                  elevation: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AIMessage message) {
    final isUser = message.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            SizedBox(
              width: 36,
              height: 36,
              child: DoctorAnnieAvatarWidget(
                appearance: _annieAppearance,
                size: 36,
                enableAnimations: false,
                showHolographicBackground: false,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: isUser
                ? NeumorphicCard(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF00BFA5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(message.timestamp),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            )
                : RealisticGlassCard(
              enable3D: false,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: message.isError
                          ? Colors.red
                          : Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(message.timestamp),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5).withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00BFA5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00BFA5).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF00BFA5),
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}