import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../services/advanced_ai_copilot_service.dart';

/// ==================== AI CO-PILOT CHAT INTERFACE ====================
///
/// Beautiful, animated chat UI with:
/// Voice input with waveform animation
/// Thinking indicator with pulsing dots
/// Image sharing capability
/// Message bubbles with emotion indicators
/// Smooth animations and transitions
/// Relationship level display
/// Context awareness indicators
///
/// ==============================================================

class AICopilotChatInterface extends StatefulWidget {
  const AICopilotChatInterface({super.key});

  @override
  State<AICopilotChatInterface> createState() => _AICopilotChatInterfaceState();
}

class _AICopilotChatInterfaceState extends State<AICopilotChatInterface>
    with TickerProviderStateMixin {
  // Services
  final AdvancedAICopilotService _copilot = AdvancedAICopilotService();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final ImagePicker _imagePicker = ImagePicker();

  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State
  final List<ChatMessage> _messages = [];
  bool _isListening = false;
  bool _isThinking = false;
  bool _isSpeaking = false;
  String _currentEmotion = 'neutral';
  String _currentContext = 'idle';
  int _relationshipLevel = 0;

  // Animations
  late AnimationController _thinkingController;
  late AnimationController _voiceWaveController;
  late AnimationController _messageEntryController;
  late Animation<double> _messageEntryAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCopilot();
    _initializeSpeechRecognition();
  }

  void _initializeAnimations() {
    // Thinking animation
    _thinkingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Voice wave animation
    _voiceWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Message entry animation
    _messageEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _messageEntryAnimation = CurvedAnimation(
      parent: _messageEntryController,
      curve: Curves.easeOutBack,
    );
  }

  Future<void> _initializeCopilot() async {
    try {
      if (!_copilot.isInitialized) {
        await _copilot.initialize();
      }

      // Setup callbacks
      _copilot.onMessageReceived = (message, isUser, emotion) {
        if (!isUser) {
          setState(() {
            _currentEmotion = emotion;
            _isThinking = false;
          });
        }
      };

      _copilot.onIntentDetected = (intent, confidence) {
        debugPrint(' Intent: $intent (${(confidence * 100).toStringAsFixed(1)}%)');
      };

      _copilot.onEmotionDetected = (emotion) {
        setState(() => _currentEmotion = emotion);
      };

      // Load conversation history
      _loadConversationHistory();

      // Get relationship level
      final insights = _copilot.getInsights();
      setState(() {
        _relationshipLevel = insights['relationship_level'] as int;
        _currentContext = insights['current_context'] as String;
      });

    } catch (e) {
      debugPrint(' Initialize copilot error: $e');
    }
  }

  Future<void> _initializeSpeechRecognition() async {
    try {
      await _speechToText.initialize(
        onStatus: (status) {
          debugPrint(' Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          debugPrint(' Speech error: $error');
          setState(() => _isListening = false);
        },
      );
    } catch (e) {
      debugPrint(' Speech recognition init warning: $e');
    }
  }

  void _loadConversationHistory() {
    final history = _copilot.getConversationHistory(limit: 20);
    for (final entry in history) {
      _messages.add(ChatMessage(
        text: entry['content'] as String,
        isUser: entry['role'] == 'user',
        emotion: entry['emotion'] as String? ?? 'neutral',
        timestamp: DateTime.fromMillisecondsSinceEpoch(entry['timestamp'] as int),
      ));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _thinkingController.dispose();
    _voiceWaveController.dispose();
    _messageEntryController.dispose();
    super.dispose();
  }

  // ==================== MESSAGE SENDING ====================

  Future<void> _sendMessage({File? image}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && image == null) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        emotion: 'neutral',
        timestamp: DateTime.now(),
        image: image,
      ));
      _messageController.clear();
      _isThinking = true;
    });

    _messageEntryController.forward(from: 0);
    _scrollToBottom();

    // Send to AI
    try {
      final response = await _copilot.sendMessage(text, image: image);

      // Add AI response
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          emotion: _currentEmotion,
          timestamp: DateTime.now(),
        ));
        _isThinking = false;
      });

      _messageEntryController.forward(from: 0);
      _scrollToBottom();

      // Update relationship level
      final insights = _copilot.getInsights();
      setState(() {
        _relationshipLevel = insights['relationship_level'] as int;
      });

    } catch (e) {
      debugPrint(' Send message error: $e');
      setState(() => _isThinking = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==================== VOICE INPUT ====================

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    try {
      if (!_speechToText.isAvailable) {
        throw Exception('Speech recognition not available');
      }

      setState(() => _isListening = true);

      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _messageController.text = result.recognizedWords;
          });
        },
        listenMode: stt.ListenMode.confirmation,
      );

    } catch (e) {
      debugPrint(' Start listening error: $e');
      setState(() => _isListening = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voice input failed: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  // ==================== IMAGE PICKER ====================

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        await _sendMessage(image: File(pickedFile.path));
      }
    } catch (e) {
      debugPrint(' Pick image error: $e');
    }
  }

  // ==================== UI HELPERS ====================

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

  Color _getEmotionColor(String emotion) {
    switch (emotion) {
      case 'happy':
      case 'excited':
        return const Color(0xFF4CAF50);
      case 'sad':
        return const Color(0xFF2196F3);
      case 'anxious':
      case 'stressed':
        return const Color(0xFFFF9800);
      case 'angry':
        return const Color(0xFFF44336);
      case 'calm':
        return const Color(0xFF00BFA5);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion) {
      case 'happy':
      case 'excited':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'anxious':
      case 'stressed':
        return Icons.sentiment_neutral;
      case 'angry':
        return Icons.sentiment_very_dissatisfied;
      case 'calm':
        return Icons.spa;
      default:
        return Icons.sentiment_neutral;
    }
  }

  // ==================== BUILD UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildRelationshipBar(),
            Expanded(child: _buildMessageList()),
            if (_isThinking) _buildThinkingIndicator(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // ==================== HEADER ====================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00BFA5),
            const Color(0xFF00E5FF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BFA5).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // AI Avatar
          _buildAIAvatar(),

          const SizedBox(width: 16),

          // AI Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Doctor Annie',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: _copilot.isInitialized ? Colors.greenAccent : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _copilot.isInitialized ? 'Active' : 'Initializing...',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _currentContext,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showInfoDialog,
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAvatar() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white,
            const Color(0xFF00BFA5).withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.psychology,
        color: Color(0xFF0A0E27),
        size: 28,
      ),
    );
  }

  // ==================== RELATIONSHIP BAR ====================

  Widget _buildRelationshipBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E3A),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF00BFA5).withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.favorite,
                    color: Color(0xFFFF4081),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Relationship',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                '$_relationshipLevel/100',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _relationshipLevel / 100,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                _relationshipLevel < 30
                    ? Colors.orange
                    : _relationshipLevel < 70
                    ? const Color(0xFF00BFA5)
                    : const Color(0xFFFF4081),
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MESSAGE LIST ====================

  Widget _buildMessageList() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0E27),
            const Color(0xFF1A1E3A).withOpacity(0.5),
          ],
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return FadeTransition(
            opacity: _messageEntryAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(message.isUser ? 1 : -1, 0),
                end: Offset.zero,
              ).animate(_messageEntryAnimation),
              child: _buildMessageBubble(message),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
        message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            // AI Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00BFA5),
                    const Color(0xFF00E5FF),
                  ],
                ),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message content
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Message bubble
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: message.isUser
                        ? LinearGradient(
                      colors: [
                        const Color(0xFF00BFA5),
                        const Color(0xFF00E5FF),
                      ],
                    )
                        : null,
                    color: message.isUser ? null : const Color(0xFF1A1E3A),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: message.isUser
                            ? const Color(0xFF00BFA5).withOpacity(0.3)
                            : Colors.black26,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image if present
                      if (message.image != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            message.image!,
                            width: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (message.text.isNotEmpty) const SizedBox(height: 8),
                      ],

                      // Text
                      if (message.text.isNotEmpty)
                        Text(
                          message.text,
                          style: TextStyle(
                            color: message.isUser
                                ? Colors.white
                                : Colors.white.withOpacity(0.95),
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Metadata
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Emotion indicator for AI messages
                    if (!message.isUser && message.emotion != 'neutral') ...[
                      Icon(
                        _getEmotionIcon(message.emotion),
                        size: 14,
                        color: _getEmotionColor(message.emotion),
                      ),
                      const SizedBox(width: 4),
                    ],

                    // Timestamp
                    Text(
                      _formatTimestamp(message.timestamp),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (message.isUser) ...[
            const SizedBox(width: 8),
            // User Avatar
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1A1E3A),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  // ==================== THINKING INDICATOR ====================

  Widget _buildThinkingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00BFA5),
                  const Color(0xFF00E5FF),
                ],
              ),
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          _buildThinkingDots(),
        ],
      ),
    );
  }

  Widget _buildThinkingDots() {
    return Row(
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _thinkingController,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (_thinkingController.value + delay) % 1.0;
            final scale = 0.5 + (0.5 * (1 - (value - 0.5).abs() * 2));

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00BFA5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00BFA5).withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // ==================== INPUT AREA ====================

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E3A),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00BFA5).withOpacity(0.3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Voice waveform when listening
          if (_isListening) _buildVoiceWaveform(),

          // Input row
          Row(
            children: [
              // Image picker
              IconButton(
                icon: const Icon(Icons.image, color: Color(0xFF00BFA5)),
                onPressed: () => _showImageSourceDialog(),
              ),

              // Text input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0E27),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: _isListening
                          ? const Color(0xFFFF4081)
                          : const Color(0xFF00BFA5).withOpacity(0.3),
                      width: _isListening ? 2 : 1,
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: _isListening
                          ? 'Listening...'
                          : 'Message Annie...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Voice button
              GestureDetector(
                onTap: _toggleListening,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _isListening
                        ? LinearGradient(
                      colors: [
                        const Color(0xFFFF4081),
                        const Color(0xFFF50057),
                      ],
                    )
                        : LinearGradient(
                      colors: [
                        const Color(0xFF00BFA5),
                        const Color(0xFF00E5FF),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening
                            ? const Color(0xFFFF4081)
                            : const Color(0xFF00BFA5))
                            .withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              GestureDetector(
                onTap: () => _sendMessage(),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00BFA5),
                        const Color(0xFF00E5FF),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00BFA5).withOpacity(0.4),
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
        ],
      ),
    );
  }

  // ==================== VOICE WAVEFORM ====================

  Widget _buildVoiceWaveform() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(20, (index) {
          return AnimatedBuilder(
            animation: _voiceWaveController,
            builder: (context, child) {
              final delay = index * 0.05;
              final value = (_voiceWaveController.value + delay) % 1.0;
              final height = 4.0 + (20.0 * (1 - (value - 0.5).abs() * 2));

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 3,
                  height: height,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4081),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4081).withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  // ==================== DIALOGS ====================

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1E3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose Image Source',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Color(0xFF00BFA5)),
                  title: const Text('Camera', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Color(0xFF00BFA5)),
                  title: const Text('Gallery', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInfoDialog() {
    final insights = _copilot.getInsights();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1E3A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.psychology, color: Color(0xFF00BFA5)),
              SizedBox(width: 12),
              Text(
                'Annie\'s Insights',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInsightRow('Relationship', '${insights['relationship_level']}/100'),
                _buildInsightRow('Conversations', '${insights['total_conversations']}'),
                _buildInsightRow('Current Mood', insights['dominant_emotion']),
                _buildInsightRow('Context', insights['current_context']),
                _buildInsightRow('Memories', '${insights['long_term_memories']}'),
                const SizedBox(height: 16),
                const Text(
                  'Topics Discussed:',
                  style: TextStyle(
                    color: Color(0xFF00BFA5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (insights['topics_discussed'] as List)
                      .map((topic) => Chip(
                    label: Text(
                      topic,
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: const Color(0xFF00BFA5).withOpacity(0.2),
                  ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF00BFA5)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInsightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== CHAT MESSAGE MODEL ====================

class ChatMessage {
  final String text;
  final bool isUser;
  final String emotion;
  final DateTime timestamp;
  final File? image;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.emotion,
    required this.timestamp,
    this.image,
  });
}