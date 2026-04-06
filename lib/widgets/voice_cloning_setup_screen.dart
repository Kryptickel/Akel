import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/ultimate_ai_features_service.dart';
import '../core/constants/themes/utils/akel_design_system.dart';

/// ==================== VOICE CLONING SETUP SCREEN ====================
///
/// Complete wizard for voice cloning setup:
/// - Records 5 voice samples (5-10 seconds each)
/// - Shows progress and waveform animation
/// - Trains voice model using ElevenLabs
/// - Beautiful UI with animations
///
/// ==============================================================

class VoiceCloningSetupScreen extends StatefulWidget {
  const VoiceCloningSetupScreen({super.key});

  @override
  State<VoiceCloningSetupScreen> createState() =>
      _VoiceCloningSetupScreenState();
}

class _VoiceCloningSetupScreenState extends State<VoiceCloningSetupScreen>
    with TickerProviderStateMixin {
  final UltimateAIFeaturesService _service = UltimateAIFeaturesService();

  int _currentStep = 0;
  bool _isRecording = false;
  int _recordingCountdown = 0;
  Timer? _countdownTimer;

  late AnimationController _pulseController;
  late AnimationController _waveController;

  final List<String> _recordingPrompts = [
    "Hello, I'm recording my voice for AI cloning. This is sample one.",
    "The quick brown fox jumps over the lazy dog. This demonstrates various sounds.",
    "I love using AI companions. They help me stay safe and connected.",
    "Technology is amazing. I'm excited to have my own voice cloned.",
    "Thank you for helping me create my personalized AI voice experience.",
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AkelDesign.deepBlack,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AkelDesign.carbonFiber,
              AkelDesign.deepBlack,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressIndicator(),
              Expanded(child: _buildStepContent()),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9C27B0).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice Cloning',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Clone your voice for AI',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of ${_recordingPrompts.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Text(
                '${((_currentStep / _recordingPrompts.length) * 100).toInt()}%',
                style: const TextStyle(
                  color: Color(0xFF9C27B0),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _currentStep / _recordingPrompts.length,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF9C27B0)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    if (_currentStep >= _recordingPrompts.length) {
      return _buildCompletionStep();
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildRecordingVisualization(),
          const SizedBox(height: 40),
          _buildPromptCard(),
          const Spacer(),
          _buildRecordButton(),
          const SizedBox(height: 20),
          Text(
            _isRecording
                ? 'Recording... Speak clearly'
                : 'Tap the button and read the text',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingVisualization() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                (_isRecording ? const Color(0xFFFF4081) : const Color(0xFF9C27B0))
                    .withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording
                    ? const Color(0xFFFF4081)
                    : const Color(0xFF9C27B0),
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording
                        ? const Color(0xFFFF4081)
                        : const Color(0xFF9C27B0))
                        .withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: _recordingCountdown > 0
                    ? Text(
                  '$_recordingCountdown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : Icon(
                  _isRecording ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPromptCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AkelDesign.carbonFiber,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF9C27B0).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withOpacity(0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Read this text clearly:',
            style: TextStyle(
              color: Color(0xFF9C27B0),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _recordingPrompts[_currentStep],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _isRecording ? null : _startRecording,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: _isRecording
              ? const LinearGradient(
            colors: [Color(0xFFFF4081), Color(0xFFF50057)],
          )
              : const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
          ),
          boxShadow: [
            BoxShadow(
              color: (_isRecording
                  ? const Color(0xFFFF4081)
                  : const Color(0xFF9C27B0))
                  .withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.stop : Icons.fiber_manual_record,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildCompletionStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Voice Cloning Complete!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your voice has been successfully cloned.\nAnnie can now speak with your voice!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () async {
              await _service.setVoiceCloningEnabled(true);
              if (mounted) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Enable Voice Cloning',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    if (_currentStep >= _recordingPrompts.length) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AkelDesign.carbonFiber,
        border: Border(
          top: BorderSide(
            color: const Color(0xFF9C27B0).withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isRecording
                    ? null
                    : () {
                  setState(() => _currentStep--);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF9C27B0)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isRecording
                  ? null
                  : () {
                setState(() => _currentStep++);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _currentStep >= _recordingPrompts.length - 1 ? 'Finish' : 'Skip',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _recordingCountdown = 3;
    });

    HapticFeedback.mediumImpact();

    // Countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _recordingCountdown--;
      });

      if (_recordingCountdown == 0) {
        timer.cancel();
        _recordActualSample();
      }
    });
  }

  Future<void> _recordActualSample() async {
    try {
      HapticFeedback.mediumImpact();

      // Record for 5 seconds
      final path = await _service.recordVoiceSample(
        sampleNumber: _currentStep + 1,
        duration: const Duration(seconds: 5),
      );

      setState(() => _isRecording = false);

      if (path != null) {
        HapticFeedback.heavyImpact();

        // Move to next step
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() => _currentStep++);
        }
      }
    } catch (e) {
      setState(() => _isRecording = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}