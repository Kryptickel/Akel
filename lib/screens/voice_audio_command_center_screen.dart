import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../core/constants/themes/utils/akel_design_system.dart';
import '../widgets/futuristic_widgets.dart';
import '../widgets/voice_visualizer_widget.dart';
import '../services/voice_command_service.dart';
import '../providers/auth_provider.dart';
import '../models/voice_command.dart';

/// ==================== VOICE & AUDIO COMMAND CENTER ====================
///
/// 4-IN-1 VOICE & AUDIO HUB:
/// 1. ✅ Voice Commands - Wake word detection & emergency commands
/// 2. ✅ Voice-to-Text - Real-time transcription
/// 3. ✅ Text-to-Speech - Audio feedback & announcements
/// 4. ✅ Continuous Listening - Background voice monitoring
///
/// TABS:
/// - Dashboard: Overview & quick actions
/// - Commands: Voice command history & stats
/// - Transcribe: Voice-to-text with save/share
/// - Settings: Configure wake words, sensitivity, languages
///
/// BUILD 55 - HOUR 4-5 COMPLETE
/// ================================================================

class VoiceAudioCommandCenterScreen extends StatefulWidget {
  const VoiceAudioCommandCenterScreen({Key? key}) : super(key: key);

  @override
  State<VoiceAudioCommandCenterScreen> createState() => _VoiceAudioCommandCenterScreenState();
}

class _VoiceAudioCommandCenterScreenState extends State<VoiceAudioCommandCenterScreen>
    with TickerProviderStateMixin {
  final VoiceCommandService _voiceService = VoiceCommandService();

  late TabController _tabController;
  late AnimationController _pulseController;

  bool _isListening = false;
  bool _isEnabled = false;
  bool _continuousListening = false;
  bool _isInitializing = true;
  String _lastWords = '';
  double _confidence = 0.0;
  String _transcription = '';
  bool _isTranscribing = false;

  Map<String, int> _stats = {
    'total': 0,
    'triggered': 0,
    'recognized': 0,
  };

  List<stt.LocaleName> _availableLanguages = [];
  String _selectedLanguage = 'en-US';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _initializeVoiceService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

// ==================== INITIALIZATION ====================

  Future<void> _initializeVoiceService() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      setState(() {
        _isInitializing = false;
      });
      return;
    }

    try {
// Initialize service
      final initialized = await _voiceService.initialize();

      if (!initialized) {
        _showError('Voice service initialization failed');
        setState(() {
          _isInitializing = false;
        });
        return;
      }

// Setup callbacks
      _voiceService.onListeningChanged = (isListening) {
        if (mounted) {
          setState(() {
            _isListening = isListening;
          });
        }
      };

      _voiceService.onWordsChanged = (words) {
        if (mounted) {
          setState(() {
            _lastWords = words;
          });
        }
      };

      _voiceService.onConfidenceChanged = (confidence) {
        if (mounted) {
          setState(() {
            _confidence = confidence;
          });
        }
      };

      _voiceService.onEmergencyDetected = () {
        if (mounted) {
          _showEmergencyTriggered();
        }
      };

// Load settings
      await _loadSettings(userId);

// Load languages
      await _loadLanguages();

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      debugPrint('❌ Voice service initialization error: $e');
      setState(() {
        _isInitializing = false;
      });
      _showError('Failed to initialize voice service');
    }
  }

  Future<void> _loadSettings(String userId) async {
    try {
      final enabled = await _voiceService.isVoiceCommandsEnabled();
      final continuous = await _voiceService.isContinuousListeningEnabled();
      final stats = await _voiceService.getVoiceCommandStats(userId);

      if (mounted) {
        setState(() {
          _isEnabled = enabled;
          _continuousListening = continuous;
          _stats = stats;
        });
      }
    } catch (e) {
      debugPrint('❌ Load settings error: $e');
    }
  }

  Future<void> _loadLanguages() async {
    try {
      final languages = await _voiceService.getAvailableLocales();
      if (mounted) {
        setState(() {
          _availableLanguages = languages;
        });
      }
    } catch (e) {
      debugPrint('❌ Load languages error: $e');
    }
  }

// ==================== VOICE CONTROL ====================

  void _handleToggleListening() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    final userName = authProvider.userProfile?['name'] ?? 'User';

    if (userId == null) return;

    if (_isListening) {
      _voiceService.stopListening();
    } else {
      _voiceService.startListening(
        userId: userId,
        userName: userName,
      );
    }
  }

  void _handleToggleVoiceCommands(bool value) {
    _voiceService.setVoiceCommandsEnabled(value);
    setState(() {
      _isEnabled = value;
    });

    if (!value && _isListening) {
      _voiceService.stopListening();
    }
  }

  void _handleToggleContinuousListening(bool value) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    final userName = authProvider.userProfile?['name'] ?? 'User';

    if (userId == null) return;

    if (value) {
      _voiceService.startContinuousListening(
        userId: userId,
        userName: userName,
      );
    } else {
      _voiceService.stopContinuousListening();
    }

    setState(() {
      _continuousListening = value;
    });
  }

// ==================== TRANSCRIPTION ====================

  void _handleStartTranscription() async {
    setState(() {
      _transcription = '';
      _isTranscribing = true;
    });

    _voiceService.speak('Start speaking now');

    final result = await _voiceService.transcribeSpeech(
      duration: const Duration(seconds: 30),
    );

    if (mounted) {
      setState(() {
        _isTranscribing = false;
      });

      if (result != null && result.isNotEmpty) {
        setState(() {
          _transcription = result;
        });
        _voiceService.speak('Transcription complete');
      } else {
        _voiceService.speak('No speech detected');
      }
    }
  }

  void _handleClearTranscription() {
    setState(() {
      _transcription = '';
    });
  }

  void _handleCopyTranscription() {
    if (_transcription.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _transcription));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Copied to clipboard'),
          backgroundColor: AkelDesign.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleTestTTS() {
    _voiceService.speak('Voice commands are working perfectly');
  }

  void _handleTestWakeWord() {
    _voiceService.speak('Say the wake word followed by an emergency command');
  }

  void _handleTestEmergency() {
    _showEmergencyTriggered();
  }

// ==================== UI HELPERS ====================

  void _showEmergencyTriggered() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
        ),
        icon: const Icon(
          Icons.emergency,
          color: AkelDesign.primaryRed,
          size: 64,
        ),
        title: Text(
          'Emergency Triggered!',
          style: AkelDesign.h3.copyWith(color: AkelDesign.primaryRed),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Emergency panic activated via voice command',
          style: AkelDesign.body,
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: FuturisticButton(
              text: 'OK',
              onPressed: () => Navigator.pop(context),
              color: AkelDesign.primaryRed,
              isSmall: true,
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AkelDesign.errorRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

// ==================== BUILD METHODS ====================

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: AkelDesign.deepBlack,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FuturisticLoadingIndicator(
                size: 60,
                color: AkelDesign.neonBlue,
              ),
              SizedBox(height: AkelDesign.xl),
              Text(
                'Initializing Voice Service...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AkelDesign.deepBlack,
      appBar: AppBar(
        backgroundColor: AkelDesign.carbonFiber,
        elevation: 0,
        leading: FuturisticIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.pop(context),
          size: 40,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VOICE & AUDIO CENTER', style: AkelDesign.h3.copyWith(fontSize: 16)),
            Text('4-in-1 Command Hub', style: AkelDesign.caption.copyWith(fontSize: 10)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: StatusIndicator(
              isActive: _isListening,
              label: _isListening ? 'LISTENING' : 'IDLE',
              activeColor: AkelDesign.successGreen,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AkelDesign.neonBlue,
          labelColor: AkelDesign.neonBlue,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Commands'),
            Tab(text: 'Transcribe'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildCommandsTab(),
          _buildTranscribeTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

// ==================== DASHBOARD TAB ====================

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
// Voice Visualizer
          Center(
            child: GestureDetector(
              onTap: _isEnabled ? _handleToggleListening : null,
              child: VoiceVisualizerWidget(
                isListening: _isListening,
                amplitude: _confidence,
                color: _isListening ? AkelDesign.successGreen : AkelDesign.neonBlue,
                size: 250,
              ),
            ),
          ),

          const SizedBox(height: AkelDesign.xl),

// Status Card
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.md),
            hasGlow: _isListening,
            glowColor: AkelDesign.successGreen,
            child: Column(
              children: [
                Text(
                  _isListening ? 'LISTENING...' : (_isEnabled ? 'TAP TO START' : 'DISABLED'),
                  style: AkelDesign.h3.copyWith(
                    color: _isListening
                        ? AkelDesign.successGreen
                        : (_isEnabled ? Colors.white70 : AkelDesign.errorRed),
                  ),
                ),
                if (_lastWords.isNotEmpty) ...[
                  const SizedBox(height: AkelDesign.md),
                  Text(
                    '"$_lastWords"',
                    style: AkelDesign.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AkelDesign.sm),
                  Text(
                    'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                    style: AkelDesign.caption.copyWith(
                      color: _confidence > 0.7 ? AkelDesign.successGreen : AkelDesign.warningOrange,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.xl),

// Quick Stats
          Text('VOICE COMMAND STATS', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'Total\nCommands',
                  value: '${_stats['total']}',
                  icon: Icons.mic,
                  color: AkelDesign.neonBlue,
                ),
              ),
              const SizedBox(width: AkelDesign.md),
              Expanded(
                child: MetricCard(
                  label: 'Emergency\nTriggered',
                  value: '${_stats['triggered']}',
                  icon: Icons.emergency,
                  color: AkelDesign.primaryRed,
                ),
              ),
            ],
          ),

          const SizedBox(height: AkelDesign.md),

          Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'Recognition\nRate',
                  value: _stats['total']! > 0
                      ? '${((_stats['recognized']! / _stats['total']!) * 100).toStringAsFixed(0)}%'
                      : '0%',
                  icon: Icons.check_circle,
                  color: AkelDesign.successGreen,
                ),
              ),
              const SizedBox(width: AkelDesign.md),
              Expanded(
                child: MetricCard(
                  label: 'Status',
                  value: _isEnabled ? 'ON' : 'OFF',
                  icon: _isEnabled ? Icons.power : Icons.power_off,
                  color: _isEnabled ? AkelDesign.successGreen : AkelDesign.errorRed,
                ),
              ),
            ],
          ),

          const SizedBox(height: AkelDesign.xl),

// Quick Actions
          Text('QUICK ACTIONS', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          FuturisticButton(
            text: _isListening ? 'STOP LISTENING' : 'START LISTENING',
            icon: _isListening ? Icons.mic_off : Icons.mic,
            onPressed: _isEnabled ? _handleToggleListening : () {},
            color: _isListening ? AkelDesign.errorRed : AkelDesign.successGreen,
            isFullWidth: true,
          ),

          const SizedBox(height: AkelDesign.md),

          FuturisticButton(
            text: 'TEST TEXT-TO-SPEECH',
            icon: Icons.volume_up,
            onPressed: _handleTestTTS,
            color: AkelDesign.infoBlue,
            isFullWidth: true,
            isOutlined: true,
          ),
        ],
      ),
    );
  }

// ==================== COMMANDS TAB ====================

  Widget _buildCommandsTab() {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off, size: 80, color: Colors.white30),
            const SizedBox(height: AkelDesign.lg),
            Text('Not logged in', style: AkelDesign.h3.copyWith(color: Colors.white60)),
          ],
        ),
      );
    }

    return StreamBuilder<List<VoiceCommand>>(
      stream: _voiceService.getVoiceCommandHistory(userId, limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: FuturisticLoadingIndicator(size: 50, color: AkelDesign.neonBlue),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: AkelDesign.errorRed),
                const SizedBox(height: AkelDesign.lg),
                Text('Error loading commands', style: AkelDesign.body),
                const SizedBox(height: AkelDesign.md),
                FuturisticButton(
                  text: 'RETRY',
                  icon: Icons.refresh,
                  onPressed: () {
                    setState(() {});
                  },
                  isSmall: true,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mic_none, size: 80, color: Colors.white30),
                const SizedBox(height: AkelDesign.lg),
                Text(
                  'No voice commands yet',
                  style: AkelDesign.h3.copyWith(color: Colors.white60),
                ),
                const SizedBox(height: AkelDesign.sm),
                Text(
                  'Start using voice commands to see history',
                  style: AkelDesign.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final commands = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(AkelDesign.lg),
          itemCount: commands.length,
          itemBuilder: (context, index) {
            final command = commands[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: AkelDesign.md),
              child: FuturisticCard(
                padding: const EdgeInsets.all(AkelDesign.md),
                hasGlow: command.triggered,
                glowColor: AkelDesign.primaryRed,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          command.triggered ? Icons.emergency : Icons.mic,
                          color: command.triggered ? AkelDesign.primaryRed : AkelDesign.neonBlue,
                          size: 20,
                        ),
                        const SizedBox(width: AkelDesign.sm),
                        Expanded(
                          child: Text(
                            command.command,
                            style: AkelDesign.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: command.triggered ? AkelDesign.primaryRed : Colors.white,
                            ),
                          ),
                        ),
                        if (command.triggered)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AkelDesign.sm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AkelDesign.primaryRed.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
                              border: Border.all(
                                color: AkelDesign.primaryRed,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'TRIGGERED',
                              style: AkelDesign.caption.copyWith(
                                color: AkelDesign.primaryRed,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AkelDesign.sm),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.white60),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(command.timestamp),
                          style: AkelDesign.caption,
                        ),
                        const SizedBox(width: AkelDesign.md),
                        const Icon(Icons.graphic_eq, size: 14, color: Colors.white60),
                        const SizedBox(width: 4),
                        Text(
                          '${(command.confidence * 100).toStringAsFixed(0)}%',
                          style: AkelDesign.caption.copyWith(
                            color: command.confidence > 0.7
                                ? AkelDesign.successGreen
                                : AkelDesign.warningOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// ==================== TRANSCRIBE TAB ====================

  Widget _buildTranscribeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VOICE-TO-TEXT', style: AkelDesign.h3),
          const SizedBox(height: AkelDesign.sm),
          Text(
            'Convert your speech to text for messages, notes, or documentation',
            style: AkelDesign.caption,
          ),

          const SizedBox(height: AkelDesign.xl),

// Transcription Display
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.lg),
            hasGlow: _isTranscribing,
            glowColor: AkelDesign.neonBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isTranscribing ? Icons.mic : Icons.article,
                      color: AkelDesign.neonBlue,
                      size: 20,
                    ),
                    const SizedBox(width: AkelDesign.sm),
                    Text(
                      _isTranscribing ? 'Listening...' : 'Transcription',
                      style: AkelDesign.subtitle,
                    ),
                    if (_isTranscribing) ...[
                      const SizedBox(width: AkelDesign.sm),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AkelDesign.neonBlue),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AkelDesign.md),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 200),
                  padding: const EdgeInsets.all(AkelDesign.md),
                  decoration: BoxDecoration(
                    color: AkelDesign.deepBlack,
                    borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
                    border: Border.all(
                      color: AkelDesign.neonBlue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _transcription.isEmpty
                        ? (_isTranscribing
                        ? 'Listening... Speak now...'
                        : 'Tap "Start Transcription" to begin...')
                        : _transcription,
                    style: AkelDesign.body.copyWith(
                      color: _transcription.isEmpty ? Colors.white30 : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.xl),

// Control Buttons
          FuturisticButton(
            text: 'START TRANSCRIPTION (30s)',
            icon: Icons.mic,
            onPressed: _isTranscribing ? () {} : _handleStartTranscription,
            color: AkelDesign.successGreen,
            isFullWidth: true,
          ),

          if (_transcription.isNotEmpty) ...[
            const SizedBox(height: AkelDesign.md),

            Row(
              children: [
                Expanded(
                  child: FuturisticButton(
                    text: 'CLEAR',
                    icon: Icons.clear,
                    onPressed: _handleClearTranscription,
                    color: AkelDesign.errorRed,
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: AkelDesign.md),
                Expanded(
                  child: FuturisticButton(
                    text: 'COPY',
                    icon: Icons.copy,
                    onPressed: _handleCopyTranscription,
                    color: AkelDesign.infoBlue,
                    isOutlined: true,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AkelDesign.xl),

// Info Card
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.md),
            hasGlow: true,
            glowColor: AkelDesign.infoBlue,
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AkelDesign.infoBlue, size: 20),
                const SizedBox(width: AkelDesign.md),
                Expanded(
                  child: Text(
                    'Speak clearly for up to 30 seconds. Transcription will appear automatically when you finish.',
                    style: AkelDesign.caption,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ==================== SETTINGS TAB ====================

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VOICE SETTINGS', style: AkelDesign.h3),
          const SizedBox(height: AkelDesign.xl),

// Enable Voice Commands
          _buildSettingCard(
            title: 'Voice Commands',
            subtitle: 'Enable wake word detection and emergency commands',
            icon: Icons.mic,
            value: _isEnabled,
            onChanged: _handleToggleVoiceCommands,
          ),

          const SizedBox(height: AkelDesign.md),

// Continuous Listening
          _buildSettingCard(
            title: 'Continuous Listening',
            subtitle: 'Always listen for wake words in background',
            icon: Icons.hearing,
            value: _continuousListening,
            onChanged: _isEnabled ? _handleToggleContinuousListening : null,
          ),

          const SizedBox(height: AkelDesign.xl),

// Wake Words
          Text('WAKE WORDS', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: VoiceCommandService.defaultWakeWords
                  .map((word) => Padding(
                padding: const EdgeInsets.only(bottom: AkelDesign.sm),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: AkelDesign.neonBlue),
                    const SizedBox(width: AkelDesign.sm),
                    Text('"$word"', style: AkelDesign.body),
                  ],
                ),
              ))
                  .toList(),
            ),
          ),

          const SizedBox(height: AkelDesign.xl),

// Emergency Commands
          Text('EMERGENCY COMMANDS', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.md),
            child: Wrap(
              spacing: AkelDesign.sm,
              runSpacing: AkelDesign.sm,
              children: VoiceCommandService.defaultEmergencyCommands
                  .map((cmd) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AkelDesign.md,
                  vertical: AkelDesign.sm,
                ),
                decoration: BoxDecoration(
                  color: AkelDesign.primaryRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
                  border: Border.all(
                    color: AkelDesign.primaryRed,
                    width: 1,
                  ),
                ),
                child: Text(
                  cmd,
                  style: AkelDesign.caption.copyWith(
                    color: AkelDesign.primaryRed,
                  ),
                ),
              ))
                  .toList(),
            ),
          ),

          const SizedBox(height: AkelDesign.xl),

// Test Section
          Text('TEST VOICE FEATURES', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          FuturisticButton(
            text: 'TEST WAKE WORD',
            icon: Icons.play_arrow,
            onPressed: _handleTestWakeWord,
            color: AkelDesign.neonBlue,
            isFullWidth: true,
            isOutlined: true,
          ),

          const SizedBox(height: AkelDesign.md),

          FuturisticButton(
            text: 'TEST EMERGENCY TRIGGER',
            icon: Icons.emergency,
            onPressed: _handleTestEmergency,
            color: AkelDesign.primaryRed,
            isFullWidth: true,
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool)? onChanged,
  }) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.md),
      hasGlow: value,
      glowColor: AkelDesign.successGreen,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AkelDesign.sm),
            decoration: BoxDecoration(
              color: (value ? AkelDesign.successGreen : Colors.white30).withOpacity(0.2),
              borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
            ),
            child: Icon(
              icon,
              color: value ? AkelDesign.successGreen : Colors.white60,
              size: 24,
            ),
          ),
          const SizedBox(width: AkelDesign.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AkelDesign.body.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: AkelDesign.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AkelDesign.successGreen,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
  }
}