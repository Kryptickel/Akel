import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../services/aws_service.dart';
import '../services/facial_animation_service.dart';
import '../services/google_tts_service.dart';
import '../services/vibration_service.dart';
import '../widgets/doctor_annie_avatar_widget.dart';
import '../widgets/glossy_3d_widgets.dart';
import '../models/doctor_annie_appearance.dart';
import '../models/doctor_annie_personality.dart';
import '../models/doctor_annie_voice_config.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import 'doctor_annie_customizer_screen.dart';

class DoctorAnnieChatScreen extends StatefulWidget {
  const DoctorAnnieChatScreen({super.key});

  @override
  State<DoctorAnnieChatScreen> createState() => _DoctorAnnieChatScreenState();
}

class _DoctorAnnieChatScreenState extends State<DoctorAnnieChatScreen>
    with TickerProviderStateMixin {
  final AWSService _awsService = AWSService();
  final GoogleTTSService _ttsService = GoogleTTSService();
  final FacialAnimationService _facialService = FacialAnimationService();
  final VibrationService _vibrationService = VibrationService();
  final TextEditingController _textController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _backgroundController;
  late AnimationController _avatarBreathController;

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  String? _sessionId;
  String _currentVoiceDisplay = ' American Female'; // ← ADDED

  DoctorAnnieAppearance _appearance = const DoctorAnnieAppearance(
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

  DoctorAnniePersonality _personality = const DoctorAnniePersonality(
    bedsideManner: BedsideManner.warm,
    communicationStyle: CommunicationStyle.conversational,
  );

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _avatarBreathController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _initSpeech();
    _initializeAWSService();
    _initializeGoogleTTS();
    _loadConfiguration();
    _loadCurrentVoice(); // ← ADDED
    _sendWelcomeMessage();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _avatarBreathController.dispose();
    _textController.dispose();
    _audioPlayer.dispose();
    _speech.stop();
    _awsService.dispose();
    _ttsService.dispose();
    _scrollController.dispose();
    _facialService.dispose();
    super.dispose();
  }

  Future<void> _initializeGoogleTTS() async {
    try {
      await _ttsService.initialize();
      debugPrint(' Google TTS ready for Doctor Annie');
    } catch (e) {
      debugPrint(' Google TTS initialization failed: $e');
    }
  }

  // ← ADDED: Load current voice display name
  Future<void> _loadCurrentVoice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVoice = prefs.getString('current_voice_display');
      if (savedVoice != null && mounted) {
        setState(() {
          _currentVoiceDisplay = savedVoice;
        });
      }
    } catch (e) {
      debugPrint('Could not load voice display: $e');
    }
  }

  Future<void> _loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();

    final appearanceJson = prefs.getString('doctor_annie_appearance');
    if (appearanceJson != null && mounted) {
      setState(() {
        _appearance = DoctorAnnieAppearance.fromJson(jsonDecode(appearanceJson));
      });
    }

    final personalityJson = prefs.getString('doctor_annie_personality');
    if (personalityJson != null && mounted) {
      setState(() {
        _personality = DoctorAnniePersonality.fromJson(jsonDecode(personalityJson));
      });
    }
  }

  void _sendWelcomeMessage() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        String greeting = 'Hello! I\'m Doctor Annie, your AI medical assistant. How can I help you today?';

        if (_personality.bedsideManner == BedsideManner.warm) {
          greeting = 'Hello there! I\'m Doctor Annie. I\'m here to help with any medical questions you might have. How are you feeling today?';
        } else if (_personality.bedsideManner == BedsideManner.direct) {
          greeting = 'Hello. I\'m Doctor Annie. What medical questions can I help you with?';
        }

        setState(() {
          _messages.add(ChatMessage(text: greeting, isUser: false));
        });
        _speakMessage(greeting);
      }
    });
  }

  Future<void> _initSpeech() async {
    try {
      await _speech.initialize();
    } catch (e) {
      debugPrint('Error initializing speech: $e');
    }
  }

  Future<void> _initializeAWSService() async {
    try {
      await _awsService.initializeSpeechRecognition();
    } catch (e) {
      debugPrint('Error initializing AWS service: $e');
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    await _vibrationService.light();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    _textController.clear();
    _scrollToBottom();

    try {
      final response = await _awsService.sendTextToBot(
        text,
        sessionId: _sessionId,
      );

      if (response['success'] == true) {
        final botMessage = response['message'] as String;
        _sessionId = response['sessionId'] as String?;

        setState(() {
          _messages.add(ChatMessage(text: botMessage, isUser: false));
          _isLoading = false;
        });

        _scrollToBottom();
        await _speakMessage(botMessage);
      } else {
        final errorMessage = response['error'] as String? ?? 'Unknown error';
        setState(() {
          _messages.add(ChatMessage(
            text: 'I apologize, but I encountered an issue: $errorMessage',
            isUser: false,
          ));
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'I\'m sorry, I\'m having trouble connecting right now. Please try again.',
          isUser: false,
        ));
        _isLoading = false;
      });
      debugPrint('Error sending message: $e');
    }
  }

  Future<void> _speakMessage(String text) async {
    if (text.isEmpty) return;

    try {
      _facialService.startLipSync(text);
      await _ttsService.speak(text);
      await Future.delayed(Duration(milliseconds: text.length * 50));

      if (mounted) {
        _facialService.stopLipSync();
      }
    } catch (e) {
      debugPrint('Error speaking: $e');
      if (mounted) {
        _facialService.stopLipSync();
      }
    }
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      await _vibrationService.light();
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                _textController.text = result.recognizedWords;
              });
            }
          },
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.confirmation,
            cancelOnError: true,
            partialResults: true,
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition not available'),
              backgroundColor: AkelDesign.errorRed,
            ),
          );
        }
      }
    }
  }

  void _stopListening() async {
    await _vibrationService.light();
    _speech.stop();
    setState(() => _isListening = false);
    if (_textController.text.isNotEmpty) {
      _sendMessage(_textController.text);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _navigateToCustomizer() async {
    await _vibrationService.medium();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DoctorAnnieCustomizerScreen()),
    );
    _loadConfiguration();
  }

  // ← ADDED: Complete voice selector with all voices
  void _showVoiceSelector() async {
    final voiceCategories = {
      ' ENGLISH ACCENTS': {
        ' American Female': {'id': 'en-US-Wavenet-F', 'lang': 'en-US'},
        ' American Male': {'id': 'en-US-Wavenet-D', 'lang': 'en-US'},
        ' British Female': {'id': 'en-GB-Wavenet-A', 'lang': 'en-GB'},
        ' British Male': {'id': 'en-GB-Wavenet-B', 'lang': 'en-GB'},
        ' Indian Female': {'id': 'en-IN-Wavenet-A', 'lang': 'en-IN'},
        ' Indian Male': {'id': 'en-IN-Wavenet-B', 'lang': 'en-IN'},
        ' Australian Female': {'id': 'en-AU-Wavenet-A', 'lang': 'en-AU'},
        ' Australian Male': {'id': 'en-AU-Wavenet-B', 'lang': 'en-AU'},
        ' Canadian Female': {'id': 'en-US-Wavenet-C', 'lang': 'en-US'},
        ' Canadian Male': {'id': 'en-US-Wavenet-A', 'lang': 'en-US'},
        ' South African Female': {'id': 'en-GB-Wavenet-C', 'lang': 'en-GB'},
        ' South African Male': {'id': 'en-GB-Wavenet-D', 'lang': 'en-GB'},
      },
      ' ASIAN LANGUAGES': {
        ' Hindi Female': {'id': 'hi-IN-Wavenet-A', 'lang': 'hi-IN'},
        ' Hindi Male': {'id': 'hi-IN-Wavenet-B', 'lang': 'hi-IN'},
        ' Japanese Female': {'id': 'ja-JP-Wavenet-A', 'lang': 'ja-JP'},
        ' Japanese Male': {'id': 'ja-JP-Wavenet-C', 'lang': 'ja-JP'},
        ' Korean Female': {'id': 'ko-KR-Wavenet-A', 'lang': 'ko-KR'},
        ' Korean Male': {'id': 'ko-KR-Wavenet-C', 'lang': 'ko-KR'},
        ' Mandarin Female': {'id': 'cmn-CN-Wavenet-A', 'lang': 'cmn-CN'},
        ' Mandarin Male': {'id': 'cmn-CN-Wavenet-B', 'lang': 'cmn-CN'},
      },
      ' EUROPEAN LANGUAGES': {
        ' Spanish Female': {'id': 'es-ES-Wavenet-A', 'lang': 'es-ES'},
        ' Spanish Male': {'id': 'es-ES-Wavenet-B', 'lang': 'es-ES'},
        ' Mexican Spanish Female': {'id': 'es-US-Wavenet-A', 'lang': 'es-US'},
        ' Mexican Spanish Male': {'id': 'es-US-Wavenet-B', 'lang': 'es-US'},
        ' French Female': {'id': 'fr-FR-Wavenet-A', 'lang': 'fr-FR'},
        ' French Male': {'id': 'fr-FR-Wavenet-B', 'lang': 'fr-FR'},
        ' French Canadian Female': {'id': 'fr-CA-Wavenet-A', 'lang': 'fr-CA'},
        ' French Canadian Male': {'id': 'fr-CA-Wavenet-B', 'lang': 'fr-CA'},
        ' German Female': {'id': 'de-DE-Wavenet-A', 'lang': 'de-DE'},
        ' German Male': {'id': 'de-DE-Wavenet-B', 'lang': 'de-DE'},
        ' Italian Female': {'id': 'it-IT-Wavenet-A', 'lang': 'it-IT'},
        ' Italian Male': {'id': 'it-IT-Wavenet-C', 'lang': 'it-IT'},
        ' Portuguese Female': {'id': 'pt-BR-Wavenet-A', 'lang': 'pt-BR'},
        ' Portuguese Male': {'id': 'pt-BR-Wavenet-B', 'lang': 'pt-BR'},
        ' Russian Female': {'id': 'ru-RU-Wavenet-A', 'lang': 'ru-RU'},
        ' Russian Male': {'id': 'ru-RU-Wavenet-B', 'lang': 'ru-RU'},
      },
      ' OTHER LANGUAGES': {
        ' Arabic Female': {'id': 'ar-XA-Wavenet-A', 'lang': 'ar-XA'},
        ' Arabic Male': {'id': 'ar-XA-Wavenet-B', 'lang': 'ar-XA'},
        ' Turkish Female': {'id': 'tr-TR-Wavenet-A', 'lang': 'tr-TR'},
        ' Turkish Male': {'id': 'tr-TR-Wavenet-B', 'lang': 'tr-TR'},
        ' Indonesian Female': {'id': 'id-ID-Wavenet-A', 'lang': 'id-ID'},
        ' Indonesian Male': {'id': 'id-ID-Wavenet-B', 'lang': 'id-ID'},
        ' Vietnamese Female': {'id': 'vi-VN-Wavenet-A', 'lang': 'vi-VN'},
        ' Vietnamese Male': {'id': 'vi-VN-Wavenet-B', 'lang': 'vi-VN'},
        ' Thai Female': {'id': 'th-TH-Wavenet-A', 'lang': 'th-TH'},
      },
    };

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BFA5), Color(0xFF00E5FF)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.record_voice_over, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Select Voice',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 600,
          child: DefaultTabController(
            length: voiceCategories.length,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  indicatorColor: const Color(0xFF00BFA5),
                  labelColor: const Color(0xFF00BFA5),
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontSize: 13),
                  tabs: voiceCategories.keys.map((category) {
                    return Tab(text: category);
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    children: voiceCategories.entries.map((category) {
                      return SingleChildScrollView(
                        child: Column(
                          children: category.value.entries.map((voice) {
                            final isSelected = _currentVoiceDisplay == voice.key;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                  colors: [Color(0xFF00BFA5), Color(0xFF00E5FF)],
                                )
                                    : null,
                                color: isSelected ? null : AkelDesign.carbonFiber.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF00BFA5)
                                      : Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                title: Text(
                                  voice.key,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.play_circle_outline, color: Colors.white70, size: 20),
                                      onPressed: () async {
                                        await _ttsService.setVoice(
                                          voice.value['id']!,
                                          voice.value['lang']!,
                                        );
                                        await _speakMessage('Hello! This is how I sound.');
                                      },
                                      tooltip: 'Preview',
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_circle, color: Colors.white, size: 22),
                                  ],
                                ),
                                onTap: () async {
                                  setState(() {
                                    _currentVoiceDisplay = voice.key;
                                  });

                                  // Save voice display name
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('current_voice_display', voice.key);

                                  await _ttsService.setVoice(
                                    voice.value['id']!,
                                    voice.value['lang']!,
                                  );

                                  await _speakMessage('Voice changed successfully!');

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle, color: Colors.white),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text('Voice: ${voice.key}')),
                                          ],
                                        ),
                                        backgroundColor: const Color(0xFF00BFA5),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF00BFA5), fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AkelDesign.deepBlack,
      appBar: AppBar(
        backgroundColor: AkelDesign.carbonFiber,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 56,
        leadingWidth: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BFA5), Color(0xFF00E5FF)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00BFA5).withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Dr. Annie',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'AI Assistant',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // ← ADDED: Voice selector button
          IconButton(
            icon: const Icon(Icons.record_voice_over, color: Colors.white, size: 20),
            onPressed: _showVoiceSelector,
            tooltip: 'Change Voice',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 20),
            onPressed: _navigateToCustomizer,
            tooltip: 'Customize',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0 + (_backgroundController.value * 0.2),
                colors: [
                  AkelDesign.carbonFiber,
                  AkelDesign.deepBlack,
                ],
              ),
            ),
            child: child,
          );
        },
        child: Column(
          children: [
            // AVATAR SECTION
            Container(
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF00BFA5).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: AnimatedBuilder(
                  animation: _avatarBreathController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_avatarBreathController.value * 0.05),
                      child: DoctorAnnieAvatarWidget(
                        appearance: _appearance,
                        size: 240,
                        enableAnimations: true,
                        showHolographicBackground: true,
                      ),
                    );
                  },
                ),
              ),
            ),

            // MESSAGES SECTION
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                child: RealisticGlassCard(
                  enable3D: true,
                  margin: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.waving_hand,
                        size: 64,
                        color: Color(0xFF00BFA5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Hi! I\'m Doctor Annie',
                        style: AkelDesign.h2.copyWith(
                          fontSize: 22,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your AI medical assistant\nAsk me anything!',
                        style: AkelDesign.caption.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
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
                  return _buildMessageBubble(message);
                },
              ),
            ),

            // TYPING INDICATOR
            if (_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00BFA5).withValues(alpha: 0.3),
                            const Color(0xFF00BFA5).withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTypingDot(0),
                          const SizedBox(width: 4),
                          _buildTypingDot(1),
                          const SizedBox(width: 4),
                          _buildTypingDot(2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // INPUT SECTION
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AkelDesign.carbonFiber.withValues(alpha: 0.8),
                    AkelDesign.carbonFiber,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _isListening ? _stopListening : _startListening,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isListening
                                  ? [Colors.red, Colors.red.shade700]
                                  : [
                                const Color(0xFF00BFA5),
                                const Color(0xFF00E5FF),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening
                                    ? Colors.red
                                    : const Color(0xFF00BFA5))
                                    .withValues(alpha: 0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AkelDesign.darkPanel.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF00BFA5).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _textController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Ask Doctor Annie...',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: _sendMessage,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _sendMessage(_textController.text),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00BFA5), Color(0xFF00E5FF)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00BFA5)
                                    .withValues(alpha: 0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animValue = (value + delay) % 1.0;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3 + (animValue * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        if (mounted && _isLoading) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: message.isUser
                ? [
              const Color(0xFF00BFA5).withValues(alpha: 0.8),
              const Color(0xFF00E5FF).withValues(alpha: 0.6),
            ]
                : [
              AkelDesign.darkPanel.withValues(alpha: 0.8),
              AkelDesign.darkPanel.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: message.isUser
                ? const Color(0xFF00BFA5).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: message.isUser
                  ? const Color(0xFF00BFA5).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}