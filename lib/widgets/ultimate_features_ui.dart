import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/ultimate_ai_features_service.dart';
import 'package:camera/camera.dart';

/// ==================== VOICE CLONING SETUP SCREEN ====================

class VoiceCloningSetupScreen extends StatefulWidget {
  const VoiceCloningSetupScreen({super.key});

  @override
  State<VoiceCloningSetupScreen> createState() =>
      _VoiceCloningSetupScreenState();
}

class _VoiceCloningSetupScreenState extends State<VoiceCloningSetupScreen> {
  final UltimateAIFeaturesService _service = UltimateAIFeaturesService();
  int _currentStep = 0;
  bool _isRecording = false;
  int _recordingCountdown = 0;
  Timer? _countdownTimer;

  final List<String> _recordingPrompts = [
    "Hello, I'm recording my voice for AI cloning. This is sample one.",
    "The quick brown fox jumps over the lazy dog. This demonstrates various sounds.",
    "I love using AI companions. They help me stay safe and connected.",
    "Technology is amazing. I'm excited to have my own voice cloned.",
    "Thank you for helping me create my personalized AI voice experience.",
  ];

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1E3A),
        title: const Row(
          children: [
            Icon(Icons.mic, color: Color(0xFF00BFA5)),
            SizedBox(width: 12),
            Text('Voice Cloning Setup'),
          ],
        ),
      ),
      body: Column(
        children: [
// Progress indicator
          _buildProgressIndicator(),

// Content
          Expanded(
            child: _buildStepContent(),
          ),

// Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E3A),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF00BFA5).withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: List.generate(5, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(left: index > 0 ? 8 : 0),
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? const Color(0xFF00BFA5)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
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
        children: [
          const SizedBox(height: 20),

// Step indicator
          Text(
            'Sample ${_currentStep + 1} of ${_recordingPrompts.length}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 40),

// Recording visualization
          _buildRecordingVisualization(),

          const SizedBox(height: 40),

// Prompt text
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1E3A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF00BFA5).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Read this text clearly:',
                  style: TextStyle(
                    color: Color(0xFF00BFA5),
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
          ),

          const Spacer(),

// Record button
          _buildRecordButton(),

          const SizedBox(height: 20),

// Instructions
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
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            (_isRecording ? const Color(0xFFFF4081) : const Color(0xFF00BFA5))
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
                : const Color(0xFF00BFA5),
            boxShadow: [
              BoxShadow(
                color: (_isRecording
                    ? const Color(0xFFFF4081)
                    : const Color(0xFF00BFA5))
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
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _isRecording ? null : _startRecording,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: _isRecording
                ? [
              const Color(0xFFFF4081),
              const Color(0xFFF50057),
            ]
                : [
              const Color(0xFF00BFA5),
              const Color(0xFF00E5FF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: (_isRecording
                  ? const Color(0xFFFF4081)
                  : const Color(0xFF00BFA5))
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

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _recordingCountdown = 3;
    });

// Countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
        setState(() => _currentStep++);
      }
    } catch (e) {
      setState(() => _isRecording = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recording failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00BFA5),
                  const Color(0xFF00E5FF),
                ],
              ),
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
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E3A),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00BFA5).withOpacity(0.3),
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
                  side: const BorderSide(color: Color(0xFF00BFA5)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentStep >= _recordingPrompts.length
                  ? null
                  : _isRecording
                  ? null
                  : () {
                setState(() => _currentStep++);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
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
}

/// ==================== LANGUAGE SELECTOR ====================

class LanguageSelectorDialog extends StatefulWidget {
  const LanguageSelectorDialog({super.key});

  @override
  State<LanguageSelectorDialog> createState() => _LanguageSelectorDialogState();
}

class _LanguageSelectorDialogState extends State<LanguageSelectorDialog> {
  final UltimateAIFeaturesService _service = UltimateAIFeaturesService();
  final TextEditingController _searchController = TextEditingController();
  List<Language> _languages = [];
  List<Language> _filteredLanguages = [];
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _languages = _service.getSupportedLanguages();
    _filteredLanguages = _languages;
    _selectedLanguage = _service.targetLanguage;
  }

  void _filterLanguages(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLanguages = _languages;
      } else {
        _filteredLanguages = _languages
            .where((lang) =>
        lang.name.toLowerCase().contains(query.toLowerCase()) ||
            lang.code.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A0E27),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
// Header
            Row(
              children: [
                const Icon(Icons.language, color: Color(0xFF00BFA5)),
                const SizedBox(width: 12),
                const Text(
                  'Select Language',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

// Search bar
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search languages...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00BFA5)),
                filled: true,
                fillColor: const Color(0xFF1A1E3A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterLanguages,
            ),

            const SizedBox(height: 16),

// Language list
            Expanded(
              child: ListView.builder(
                itemCount: _filteredLanguages.length,
                itemBuilder: (context, index) {
                  final language = _filteredLanguages[index];
                  final isSelected = language.code == _selectedLanguage;

                  return ListTile(
                    leading: Text(
                      language.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      language.name,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF00BFA5) : Colors.white,
                        fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      language.code,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Color(0xFF00BFA5))
                        : null,
                    onTap: () async {
                      await _service.setTargetLanguage(language.code);
                      Navigator.pop(context, language);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ==================== AR AVATAR VIEWER ====================

class ARAvatarViewer extends StatefulWidget {
  const ARAvatarViewer({super.key});

  @override
  State<ARAvatarViewer> createState() => _ARAvatarViewerState();
}

class _ARAvatarViewerState extends State<ARAvatarViewer> {
  final UltimateAIFeaturesService _service = UltimateAIFeaturesService();
  CameraController? _cameraController;
  bool _isARActive = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
      );

      await _cameraController!.initialize();
      setState(() {});

    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
// Camera preview
          if (_cameraController != null && _cameraController!.value.isInitialized)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            ),

// AR overlay
          if (_isARActive) _buildAROverlay(),

// Controls
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildAROverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
// 3D Avatar placeholder (would be actual 3D model)
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00BFA5).withOpacity(0.8),
                  const Color(0xFF00E5FF).withOpacity(0.8),
                ],
              ),
            ),
            child: const Icon(
              Icons.psychology,
              size: 100,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

// Speech bubble
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Hi! I'm Annie in AR! 👋",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return SafeArea(
      child: Column(
        children: [
// Top bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _isARActive
                        ? const Color(0xFF00BFA5)
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isARActive ? 'AR Active' : 'AR Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

// Bottom controls
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  Icons.cameraswitch,
                  'Switch',
                      () {},
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _isARActive = !_isARActive);
                    HapticFeedback.mediumImpact();
                  },
                  child: Container(
                    width: 80,
                    height: 80,
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
                          color: const Color(0xFF00BFA5).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isARActive ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                _buildControlButton(
                  Icons.settings,
                  'Settings',
                      () => _showARSettings(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showARSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1E3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final skins = _service.getAvailableAvatarSkins();

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Avatar Skins',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...skins.map((skin) {
                return ListTile(
                  leading: Text(skin.emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    skin.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    skin.description,
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                  onTap: () async {
                    await _service.setAvatarSkin(skin.id);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}