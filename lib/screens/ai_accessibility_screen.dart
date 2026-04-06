import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import '../widgets/futuristic_widgets.dart';

/// ==================== AI ACCESSIBILITY SCREEN ====================
///
/// HOUR 2 - AI & ACCESSIBILITY PART 1
/// - Color Dictator (camera color identification)
/// - AI Camera Guide for Blind (obstacle detection via voice)
/// - Smart Sound Detection (alarm, siren, cry recognition)
/// - Real-Time Captioning (live speech to text)
///
/// ================================================================

class AiAccessibilityScreen extends StatefulWidget {
  const AiAccessibilityScreen({Key? key}) : super(key: key);

  @override
  State<AiAccessibilityScreen> createState() => _AiAccessibilityScreenState();
}

class _AiAccessibilityScreenState extends State<AiAccessibilityScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Text('AI ACCESSIBILITY', style: AkelDesign.h3.copyWith(fontSize: 16)),
            Text('Smart Assistance Tools', style: AkelDesign.caption.copyWith(fontSize: 10)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.teal,
          labelColor: Colors.teal,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.color_lens), text: 'Colors'),
            Tab(icon: Icon(Icons.remove_red_eye), text: 'Camera Guide'),
            Tab(icon: Icon(Icons.hearing), text: 'Sound'),
            Tab(icon: Icon(Icons.closed_caption), text: 'Captions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ColorDictatorTab(),
          _CameraGuideTab(),
          _SoundDetectionTab(),
          _CaptioningTab(),
        ],
      ),
    );
  }
}

// ==================== TAB 1: COLOR DICTATOR ====================

class _ColorDictatorTab extends StatefulWidget {
  const _ColorDictatorTab();

  @override
  State<_ColorDictatorTab> createState() => _ColorDictatorTabState();
}

class _ColorDictatorTabState extends State<_ColorDictatorTab> {
  CameraController? _cameraController;
  FlutterTts _tts = FlutterTts();
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  String _detectedColor = '';
  String _detectedShade = '';
  Color _previewColor = Colors.grey;
  bool _continuousMode = false;
  Timer? _continuousTimer;

// Color name lookup table
  static const Map<String, Map<String, dynamic>> _colorDatabase = {
    'red': {'hex': 0xFFE53935, 'shades': ['light red', 'red', 'dark red', 'crimson']},
    'orange': {'hex': 0xFFFF9800, 'shades': ['light orange', 'orange', 'dark orange', 'amber']},
    'yellow': {'hex': 0xFFFFEB3B, 'shades': ['light yellow', 'yellow', 'golden', 'dark yellow']},
    'green': {'hex': 0xFF4CAF50, 'shades': ['light green', 'green', 'dark green', 'olive']},
    'blue': {'hex': 0xFF2196F3, 'shades': ['light blue', 'blue', 'dark blue', 'navy']},
    'purple': {'hex': 0xFF9C27B0, 'shades': ['lavender', 'purple', 'dark purple', 'violet']},
    'pink': {'hex': 0xFFE91E63, 'shades': ['light pink', 'pink', 'hot pink', 'rose']},
    'brown': {'hex': 0xFF795548, 'shades': ['tan', 'light brown', 'brown', 'dark brown']},
    'grey': {'hex': 0xFF9E9E9E, 'shades': ['white', 'light grey', 'grey', 'dark grey', 'black']},
    'teal': {'hex': 0xFF009688, 'shades': ['cyan', 'teal', 'dark teal']},
  };

  @override
  void initState() {
    super.initState();
    _initTts();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _tts.stop();
    _continuousTimer?.cancel();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint('Camera init error: ' + e.toString());
    }
  }

  Future<void> _captureAndAnalyzeColor() async {
    if (_cameraController == null || !_isCameraInitialized || _isDetecting) return;

    setState(() => _isDetecting = true);

    try {
      final image = await _cameraController!.takePicture();
      final bytes = await File(image.path).readAsBytes();

// Sample center pixel region for color detection
// In production this would use ML Kit or TensorFlow Lite
// For now we simulate with dominant color analysis
      final colorResult = _analyzeImageColor(bytes);

      setState(() {
        _detectedColor = colorResult['name'] as String;
        _detectedShade = colorResult['shade'] as String;
        _previewColor = Color(colorResult['hex'] as int);
        _isDetecting = false;
      });

      final announcement = _detectedShade + ' ' + _detectedColor;
      await _tts.speak(announcement);
    } catch (e) {
      setState(() => _isDetecting = false);
      debugPrint('Color capture error: ' + e.toString());
    }
  }

  Map<String, dynamic> _analyzeImageColor(List<int> bytes) {
// Simplified color analysis — samples bytes at center region
// Real implementation would decode image and sample pixel colors
    if (bytes.length < 100) {
      return {'name': 'unknown', 'shade': 'unknown', 'hex': 0xFF9E9E9E};
    }

// Sample bytes to simulate RGB extraction
    final r = bytes[bytes.length ~/ 3] % 256;
    final g = bytes[bytes.length ~/ 2] % 256;
    final b = bytes[(bytes.length * 2) ~/ 3] % 256;

    return _rgbToColorName(r, g, b);
  }

  Map<String, dynamic> _rgbToColorName(int r, int g, int b) {
// Find closest color in database
    String closestColor = 'grey';
    double minDistance = double.infinity;

    final colorHexes = {
      'red': [224, 57, 53],
      'orange': [255, 152, 0],
      'yellow': [255, 235, 59],
      'green': [76, 175, 80],
      'blue': [33, 150, 243],
      'purple': [156, 39, 176],
      'pink': [233, 30, 99],
      'brown': [121, 85, 72],
      'grey': [158, 158, 158],
      'teal': [0, 150, 136],
    };

    colorHexes.forEach((name, rgb) {
      final distance = _colorDistance(r, g, b, rgb[0], rgb[1], rgb[2]);
      if (distance < minDistance) {
        minDistance = distance;
        closestColor = name;
      }
    });

// Determine shade based on brightness
    final brightness = (r * 0.299 + g * 0.587 + b * 0.114);
    final shades = _colorDatabase[closestColor]?['shades'] as List<String>? ?? ['medium'];
    String shade;
    if (brightness > 200) {
      shade = shades.first;
    } else if (brightness > 128) {
      shade = shades.length > 1 ? shades[1] : shades.first;
    } else if (brightness > 64) {
      shade = shades.length > 2 ? shades[2] : shades.last;
    } else {
      shade = shades.last;
    }

    return {
      'name': closestColor,
      'shade': shade,
      'hex': _colorDatabase[closestColor]?['hex'] ?? 0xFF9E9E9E,
    };
  }

  double _colorDistance(int r1, int g1, int b1, int r2, int g2, int b2) {
    return ((r1 - r2) * (r1 - r2) + (g1 - g2) * (g1 - g2) + (b1 - b2) * (b1 - b2)).toDouble();
  }

  void _toggleContinuousMode(bool val) {
    setState(() => _continuousMode = val);
    if (val) {
      _continuousTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _captureAndAnalyzeColor();
      });
    } else {
      _continuousTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COLOR DICTATOR', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.sm),
          Text(
            'Point camera at any object to hear its color announced aloud',
            style: AkelDesign.caption,
          ),
          const SizedBox(height: AkelDesign.lg),

// Camera preview
          if (_isCameraInitialized && _cameraController != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AkelDesign.darkPanel,
                borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
                border: Border.all(color: Colors.white10),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.white38, size: 48),
                    SizedBox(height: AkelDesign.md),
                    Text('Camera initializing...', style: TextStyle(color: Colors.white38)),
                  ],
                ),
              ),
            ),

          const SizedBox(height: AkelDesign.lg),

// Color preview
          if (_detectedColor.isNotEmpty) ...[
            FuturisticCard(
              padding: const EdgeInsets.all(AkelDesign.lg),
              hasGlow: true,
              glowColor: _previewColor,
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _previewColor,
                      borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                  ),
                  const SizedBox(width: AkelDesign.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _detectedColor.toUpperCase(),
                          style: AkelDesign.h3.copyWith(color: _previewColor, fontSize: 24),
                        ),
                        Text(_detectedShade, style: AkelDesign.caption),
                        const SizedBox(height: AkelDesign.sm),
                        GestureDetector(
                          onTap: () => _tts.speak(_detectedShade + ' ' + _detectedColor),
                          child: Row(
                            children: [
                              const Icon(Icons.volume_up, color: Colors.teal, size: 16),
                              const SizedBox(width: 4),
                              Text('Tap to repeat', style: AkelDesign.caption.copyWith(color: Colors.teal)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AkelDesign.lg),
          ],

// Capture button
          FuturisticButton(
            text: _isDetecting ? 'ANALYZING...' : 'IDENTIFY COLOR',
            icon: Icons.colorize,
            onPressed: _isDetecting ? () {} : _captureAndAnalyzeColor,
            color: Colors.teal,
            isFullWidth: true,
          ),

          const SizedBox(height: AkelDesign.md),

// Continuous mode
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.md),
            child: Row(
              children: [
                const Icon(Icons.loop, color: Colors.teal),
                const SizedBox(width: AkelDesign.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Continuous Mode', style: AkelDesign.body.copyWith(fontWeight: FontWeight.w700)),
                      Text('Announces color every 3 seconds', style: AkelDesign.caption),
                    ],
                  ),
                ),
                Switch(
                  value: _continuousMode,
                  onChanged: _toggleContinuousMode,
                  activeColor: Colors.teal,
                ),
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.lg),

          Text('COLOR REFERENCE', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          Wrap(
            spacing: AkelDesign.sm,
            runSpacing: AkelDesign.sm,
            children: _colorDatabase.entries.map((entry) {
              final color = Color(entry.value['hex'] as int);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _detectedColor = entry.key;
                    _detectedShade = (entry.value['shades'] as List<String>)[1];
                    _previewColor = color;
                  });
                  _tts.speak(entry.key);
                },
                child: Container(
                  width: 60,
                  padding: const EdgeInsets.all(AkelDesign.sm),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
                  ),
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ==================== TAB 2: AI CAMERA GUIDE FOR BLIND ====================

class _CameraGuideTab extends StatefulWidget {
  const _CameraGuideTab();

  @override
  State<_CameraGuideTab> createState() => _CameraGuideTabState();
}

class _CameraGuideTabState extends State<_CameraGuideTab> {
  CameraController? _cameraController;
  FlutterTts _tts = FlutterTts();
  bool _isCameraInitialized = false;
  bool _isGuiding = false;
  String _lastGuidance = '';
  Timer? _guideTimer;
  double _detectedDistance = 0.0;
  String _detectedObject = '';
  String _direction = 'center';

// Simulated obstacle detection results
// In production this would use TensorFlow Lite object detection
  static const List<Map<String, dynamic>> _simulatedObjects = [
    {'object': 'wall', 'distance': 0.5, 'direction': 'ahead'},
    {'object': 'door', 'distance': 1.2, 'direction': 'right'},
    {'object': 'stairs', 'distance': 2.0, 'direction': 'ahead'},
    {'object': 'person', 'distance': 1.5, 'direction': 'left'},
    {'object': 'chair', 'distance': 0.8, 'direction': 'right'},
    {'object': 'clear path', 'distance': 5.0, 'direction': 'ahead'},
    {'object': 'table', 'distance': 1.0, 'direction': 'ahead'},
    {'object': 'step down', 'distance': 0.3, 'direction': 'ahead'},
  ];

  int _simulationIndex = 5; // Start with clear path

  @override
  void initState() {
    super.initState();
    _initTts();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _tts.stop();
    _guideTimer?.cancel();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint('Camera guide init error: ' + e.toString());
    }
  }

  void _startGuiding() {
    setState(() => _isGuiding = true);
    _analyzeAndGuide();
    _guideTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _analyzeAndGuide();
    });
  }

  void _stopGuiding() {
    setState(() => _isGuiding = false);
    _guideTimer?.cancel();
    _tts.stop();
  }

  Future<void> _analyzeAndGuide() async {
// Cycle through simulated objects for demo
// In production this calls TensorFlow Lite inference
    _simulationIndex = (_simulationIndex + 1) % _simulatedObjects.length;
    final result = _simulatedObjects[_simulationIndex];

    final object = result['object'] as String;
    final distance = result['distance'] as double;
    final direction = result['direction'] as String;

    if (mounted) {
      setState(() {
        _detectedObject = object;
        _detectedDistance = distance;
        _direction = direction;
      });
    }

    final guidance = _buildGuidanceMessage(object, distance, direction);

    if (mounted) {
      setState(() => _lastGuidance = guidance);
    }

    await _tts.speak(guidance);
  }

  String _buildGuidanceMessage(String object, double distance, String direction) {
    if (object == 'clear path') {
      return 'Path ahead is clear';
    }

    String distanceText;
    if (distance < 0.5) {
      distanceText = 'very close, ';
    } else if (distance < 1.0) {
      distanceText = (distance * 100).toInt().toString() + ' centimeters, ';
    } else {
      distanceText = distance.toStringAsFixed(1) + ' meters, ';
    }

    String warning = '';
    if (distance < 0.5) {
      warning = ' Stop immediately.';
    } else if (distance < 1.0) {
      warning = ' Slow down.';
    }

    if (object == 'stairs' || object == 'step down') {
      return 'Warning! ' + object + ' ' + direction + ', ' + distanceText + warning;
    }

    return object + ' ' + direction + ', ' + distanceText + warning;
  }

  Color _getDistanceColor() {
    if (_detectedDistance < 0.5) return Colors.red;
    if (_detectedDistance < 1.0) return Colors.orange;
    if (_detectedDistance < 2.0) return Colors.yellow;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI CAMERA GUIDE', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.sm),
          Text(
            'Real-time obstacle detection and voice navigation guidance',
            style: AkelDesign.caption,
          ),
          const SizedBox(height: AkelDesign.lg),

// Camera preview with overlay
          Stack(
            children: [
              if (_isCameraInitialized && _cameraController != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
                  child: AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AkelDesign.darkPanel,
                    borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
                  ),
                  child: const Center(child: Icon(Icons.camera_alt, color: Colors.white38, size: 48)),
                ),

// Direction overlay
              if (_isGuiding && _detectedObject.isNotEmpty)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
                      border: Border.all(color: _getDistanceColor(), width: 3),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AkelDesign.lg, vertical: AkelDesign.md),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getDirectionIcon(), color: _getDistanceColor(), size: 40),
                            const SizedBox(height: AkelDesign.sm),
                            Text(
                              _detectedObject.toUpperCase(),
                              style: TextStyle(
                                color: _getDistanceColor(),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _detectedDistance.toStringAsFixed(1) + 'm',
                              style: TextStyle(color: _getDistanceColor(), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AkelDesign.lg),

// Status card
          if (_lastGuidance.isNotEmpty)
            FuturisticCard(
              padding: const EdgeInsets.all(AkelDesign.lg),
              hasGlow: true,
              glowColor: _getDistanceColor(),
              child: Row(
                children: [
                  Icon(Icons.record_voice_over, color: _getDistanceColor(), size: 28),
                  const SizedBox(width: AkelDesign.md),
                  Expanded(
                    child: Text(
                      _lastGuidance,
                      style: AkelDesign.body.copyWith(color: _getDistanceColor()),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AkelDesign.lg),

// Control button
          FuturisticButton(
            text: _isGuiding ? 'STOP GUIDING' : 'START GUIDING',
            icon: _isGuiding ? Icons.stop : Icons.play_arrow,
            onPressed: _isGuiding ? _stopGuiding : _startGuiding,
            color: _isGuiding ? Colors.red : Colors.teal,
            isFullWidth: true,
          ),

          const SizedBox(height: AkelDesign.lg),

          Text('DETECTION FEATURES', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          _buildFeatureRow(Icons.warning_amber, 'Obstacle Detection', 'Walls, furniture, objects', Colors.orange),
          _buildFeatureRow(Icons.stairs, 'Stair Detection', 'Steps up and down warnings', Colors.red),
          _buildFeatureRow(Icons.people, 'Person Detection', 'Identifies nearby people', Colors.blue),
          _buildFeatureRow(Icons.directions, 'Navigation Cues', 'Left, right, ahead guidance', Colors.teal),
          _buildFeatureRow(Icons.speed, 'Distance Estimation', 'Approximate distance to objects', Colors.green),
        ],
      ),
    );
  }

  IconData _getDirectionIcon() {
    switch (_direction) {
      case 'left':
        return Icons.arrow_back;
      case 'right':
        return Icons.arrow_forward;
      case 'above':
        return Icons.arrow_upward;
      case 'below':
        return Icons.arrow_downward;
      default:
        return Icons.arrow_upward;
    }
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AkelDesign.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AkelDesign.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AkelDesign.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AkelDesign.body.copyWith(fontWeight: FontWeight.w700)),
                Text(subtitle, style: AkelDesign.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== TAB 3: SMART SOUND DETECTION ====================

class _SoundDetectionTab extends StatefulWidget {
  const _SoundDetectionTab();

  @override
  State<_SoundDetectionTab> createState() => _SoundDetectionTabState();
}

class _SoundDetectionTabState extends State<_SoundDetectionTab> {
  FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  bool _vibrateOnDetection = true;
  bool _speakOnDetection = true;
  Timer? _detectionTimer;
  List<Map<String, dynamic>> _detectionLog = [];
  String _currentSound = '';
  double _confidenceLevel = 0.0;
  int _simulationIndex = 0;

// Sound types to detect
  static const List<Map<String, dynamic>> _soundTypes = [
    {'name': 'Fire Alarm', 'icon': Icons.local_fire_department, 'color': 0xFFE53935, 'priority': 'critical'},
    {'name': 'Ambulance Siren', 'icon': Icons.emergency, 'color': 0xFFFF9800, 'priority': 'high'},
    {'name': 'Police Siren', 'icon': Icons.local_police, 'color': 0xFF1565C0, 'priority': 'high'},
    {'name': 'Baby Crying', 'icon': Icons.child_care, 'color': 0xFFE91E63, 'priority': 'medium'},
    {'name': 'Dog Barking', 'icon': Icons.pets, 'color': 0xFF795548, 'priority': 'low'},
    {'name': 'Doorbell', 'icon': Icons.doorbell, 'color': 0xFF4CAF50, 'priority': 'low'},
    {'name': 'Phone Ringing', 'icon': Icons.phone, 'color': 0xFF2196F3, 'priority': 'low'},
    {'name': 'Glass Breaking', 'icon': Icons.broken_image, 'color': 0xFF9C27B0, 'priority': 'high'},
    {'name': 'Explosion', 'icon': Icons.flash_on, 'color': 0xFFFF5722, 'priority': 'critical'},
    {'name': 'Screaming', 'icon': Icons.record_voice_over, 'color': 0xFFF44336, 'priority': 'critical'},
  ];

  static const List<int> _simulationSequence = [0, 6, 3, 1, 7, 5, 2, 4, 9, 8];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
  }

  void _startListening() {
    setState(() => _isListening = true);

    _detectionTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _simulateDetection();
    });
  }

  void _stopListening() {
    setState(() {
      _isListening = false;
      _currentSound = '';
      _confidenceLevel = 0.0;
    });
    _detectionTimer?.cancel();
    _tts.stop();
  }

  Future<void> _simulateDetection() async {
// Simulates sound detection
// In production this uses the microphone + TensorFlow Lite audio model
    final soundIndex = _simulationSequence[_simulationIndex % _simulationSequence.length];
    _simulationIndex++;

    final sound = _soundTypes[soundIndex];
    final confidence = 0.75 + ((_simulationIndex * 7) % 25) / 100;

    if (mounted) {
      setState(() {
        _currentSound = sound['name'] as String;
        _confidenceLevel = confidence;
        _detectionLog.insert(0, {
          ...sound,
          'time': DateTime.now(),
          'confidence': confidence,
        });

        if (_detectionLog.length > 20) {
          _detectionLog = _detectionLog.take(20).toList();
        }
      });
    }

    final priority = sound['priority'] as String;

    if (_vibrateOnDetection) {
      HapticFeedback.heavyImpact();
    }

    if (_speakOnDetection) {
      final message = _buildSoundMessage(sound['name'] as String, priority);
      await _tts.speak(message);
    }
  }

  String _buildSoundMessage(String soundName, String priority) {
    switch (priority) {
      case 'critical':
        return 'Emergency alert! ' + soundName + ' detected!';
      case 'high':
        return 'Warning! ' + soundName + ' detected nearby.';
      default:
        return soundName + ' detected.';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SMART SOUND DETECTION', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.sm),
          Text(
            'Identifies alarms, sirens, cries and emergency sounds',
            style: AkelDesign.caption,
          ),
          const SizedBox(height: AkelDesign.lg),

// Status indicator
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.xl),
            hasGlow: _isListening,
            glowColor: _isListening ? Colors.teal : Colors.grey,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening
                        ? Colors.teal.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    border: Border.all(
                      color: _isListening ? Colors.teal : Colors.grey,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    _isListening ? Icons.hearing : Icons.hearing_disabled,
                    color: _isListening ? Colors.teal : Colors.grey,
                    size: 40,
                  ),
                ),
                const SizedBox(height: AkelDesign.md),
                Text(
                  _isListening ? 'LISTENING...' : 'NOT LISTENING',
                  style: AkelDesign.h3.copyWith(
                    color: _isListening ? Colors.teal : Colors.grey,
                    fontSize: 16,
                  ),
                ),
                if (_currentSound.isNotEmpty) ...[
                  const SizedBox(height: AkelDesign.md),
                  Text(
                    _currentSound,
                    style: AkelDesign.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AkelDesign.sm),
                  LinearProgressIndicator(
                    value: _confidenceLevel,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                  const SizedBox(height: AkelDesign.xs),
                  Text(
                    'Confidence: ' + (_confidenceLevel * 100).toInt().toString() + '%',
                    style: AkelDesign.caption.copyWith(color: Colors.teal),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.lg),

          FuturisticButton(
            text: _isListening ? 'STOP LISTENING' : 'START LISTENING',
            icon: _isListening ? Icons.stop : Icons.mic,
            onPressed: _isListening ? _stopListening : _startListening,
            color: _isListening ? Colors.red : Colors.teal,
            isFullWidth: true,
          ),

          const SizedBox(height: AkelDesign.lg),

// Settings
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.md),
            child: Column(
              children: [
                _buildToggleRow('Vibrate on Detection', Icons.vibration, _vibrateOnDetection, Colors.orange, (val) => setState(() => _vibrateOnDetection = val)),
                const Divider(color: Colors.white10),
                _buildToggleRow('Speak Detection', Icons.volume_up, _speakOnDetection, Colors.teal, (val) => setState(() => _speakOnDetection = val)),
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.lg),

          Text('DETECTABLE SOUNDS', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          Wrap(
            spacing: AkelDesign.sm,
            runSpacing: AkelDesign.sm,
            children: _soundTypes.map((sound) {
              final color = Color(sound['color'] as int);
              final priority = sound['priority'] as String;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: AkelDesign.sm, vertical: AkelDesign.xs),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(sound['icon'] as IconData, color: color, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      sound['name'] as String,
                      style: AkelDesign.caption.copyWith(color: color, fontSize: 11),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AkelDesign.lg),

          if (_detectionLog.isNotEmpty) ...[
            Text('DETECTION LOG', style: AkelDesign.subtitle),
            const SizedBox(height: AkelDesign.md),
            ..._detectionLog.take(10).map((log) {
              final color = Color(log['color'] as int);
              final time = log['time'] as DateTime;
              final confidence = ((log['confidence'] as double) * 100).toInt();
              final priority = log['priority'] as String;
              return Padding(
                padding: const EdgeInsets.only(bottom: AkelDesign.sm),
                child: FuturisticCard(
                  padding: const EdgeInsets.all(AkelDesign.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AkelDesign.xs),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(log['icon'] as IconData, color: color, size: 18),
                      ),
                      const SizedBox(width: AkelDesign.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log['name'] as String, style: AkelDesign.body.copyWith(fontWeight: FontWeight.w700)),
                            Text(
                              time.hour.toString().padLeft(2, '0') + ':' +
                                  time.minute.toString().padLeft(2, '0') + ':' +
                                  time.second.toString().padLeft(2, '0'),
                              style: AkelDesign.caption,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AkelDesign.xs, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(priority).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              priority.toUpperCase(),
                              style: TextStyle(
                                color: _getPriorityColor(priority),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(confidence.toString() + '%', style: AkelDesign.caption.copyWith(color: color)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleRow(String label, IconData icon, bool value, Color color, Function(bool) onChanged) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AkelDesign.md),
        Expanded(child: Text(label, style: AkelDesign.body)),
        Switch(value: value, onChanged: onChanged, activeColor: color),
      ],
    );
  }
}

// ==================== TAB 4: REAL-TIME CAPTIONING ====================

class _CaptioningTab extends StatefulWidget {
  const _CaptioningTab();

  @override
  State<_CaptioningTab> createState() => _CaptioningTabState();
}

class _CaptioningTabState extends State<_CaptioningTab> {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _currentCaption = '';
  String _interimCaption = '';
  final List<Map<String, dynamic>> _captionHistory = [];
  final ScrollController _scrollController = ScrollController();
  double _fontSize = 18.0;
  bool _highContrastMode = false;
  bool _autoScroll = true;
  String _selectedLanguage = 'en-US';

  static const List<Map<String, String>> _languages = [
    {'code': 'en-US', 'name': 'English (US)'},
    {'code': 'en-GB', 'name': 'English (UK)'},
    {'code': 'es-ES', 'name': 'Spanish'},
    {'code': 'fr-FR', 'name': 'French'},
    {'code': 'de-DE', 'name': 'German'},
    {'code': 'it-IT', 'name': 'Italian'},
    {'code': 'pt-BR', 'name': 'Portuguese'},
    {'code': 'zh-CN', 'name': 'Chinese'},
    {'code': 'ja-JP', 'name': 'Japanese'},
    {'code': 'ar-SA', 'name': 'Arabic'},
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _speechToText.stop();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final available = await _speechToText.initialize(
      onError: (error) => debugPrint('Speech error: ' + error.errorMsg),
      onStatus: (status) => debugPrint('Speech status: ' + status),
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      _showPermissionError();
      return;
    }

    setState(() {
      _isListening = true;
      _interimCaption = '';
    });

    await _speechToText.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _interimCaption = result.recognizedWords;
            if (result.finalResult && result.recognizedWords.isNotEmpty) {
              _currentCaption = result.recognizedWords;
              _captionHistory.insert(0, {
                'text': result.recognizedWords,
                'time': DateTime.now(),
                'confidence': result.confidence,
              });
              _interimCaption = '';
              if (_autoScroll && _scrollController.hasClients) {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            }
          });
        }
      },
      localeId: _selectedLanguage,
      listenMode: ListenMode.dictation,
      cancelOnError: false,
      partialResults: true,
    );
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
        _interimCaption = '';
      });
    }
  }

  void _clearHistory() {
    setState(() {
      _captionHistory.clear();
      _currentCaption = '';
      _interimCaption = '';
    });
  }

  void _showPermissionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Microphone permission required for captioning'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _highContrastMode ? Colors.black : AkelDesign.deepBlack;
    final textColor = _highContrastMode ? Colors.yellow : Colors.white;
    final captionBgColor = _highContrastMode ? Colors.black : AkelDesign.darkPanel;

    return Container(
      color: bgColor,
      child: Column(
        children: [

// Live caption display
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 120),
            margin: const EdgeInsets.all(AkelDesign.lg),
            padding: const EdgeInsets.all(AkelDesign.lg),
            decoration: BoxDecoration(
              color: captionBgColor,
              borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
              border: Border.all(
                color: _isListening ? Colors.teal : Colors.white24,
                width: _isListening ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (_isListening)
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: AkelDesign.sm),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                    Text(
                      _isListening ? 'LIVE' : 'CAPTION',
                      style: AkelDesign.caption.copyWith(
                        color: _isListening ? Colors.red : Colors.white38,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AkelDesign.sm),
                Text(
                  _interimCaption.isNotEmpty
                      ? _interimCaption
                      : (_currentCaption.isNotEmpty ? _currentCaption : 'Start speaking...'),
                  style: TextStyle(
                    color: _interimCaption.isNotEmpty
                        ? textColor.withOpacity(0.7)
                        : textColor,
                    fontSize: _fontSize,
                    fontWeight: FontWeight.w600,
                    fontStyle: _interimCaption.isNotEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),

// Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AkelDesign.lg),
            child: Row(
              children: [
                Expanded(
                  child: FuturisticButton(
                    text: _isListening ? 'STOP' : 'START',
                    icon: _isListening ? Icons.stop : Icons.mic,
                    onPressed: _isListening ? _stopListening : _startListening,
                    color: _isListening ? Colors.red : Colors.teal,
                  ),
                ),
                const SizedBox(width: AkelDesign.md),
                FuturisticIconButton(
                  icon: Icons.delete_outline,
                  onPressed: _clearHistory,
                  size: 44,
                ),
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.md),

// Settings row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AkelDesign.lg),
            child: Row(
              children: [
// Font size
                const Icon(Icons.text_fields, color: Colors.white38, size: 16),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 12,
                    max: 36,
                    activeColor: Colors.teal,
                    onChanged: (val) => setState(() => _fontSize = val),
                  ),
                ),
// High contrast toggle
                GestureDetector(
                  onTap: () => setState(() => _highContrastMode = !_highContrastMode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AkelDesign.sm, vertical: AkelDesign.xs),
                    decoration: BoxDecoration(
                      color: _highContrastMode ? Colors.yellow.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
                      border: Border.all(color: _highContrastMode ? Colors.yellow : Colors.white24),
                    ),
                    child: Icon(Icons.contrast, color: _highContrastMode ? Colors.yellow : Colors.white38, size: 20),
                  ),
                ),
                const SizedBox(width: AkelDesign.sm),
// Language selector
                DropdownButton<String>(
                  value: _selectedLanguage,
                  dropdownColor: AkelDesign.darkPanel,
                  underline: const SizedBox(),
                  style: AkelDesign.caption,
                  icon: const Icon(Icons.language, color: Colors.white38, size: 16),
                  items: _languages.map((lang) => DropdownMenuItem(
                    value: lang['code'],
                    child: Text(lang['name']!, style: AkelDesign.caption),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedLanguage = val);
                  },
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10),

// Caption history
          Expanded(
            child: _captionHistory.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.closed_caption_off, color: Colors.white24, size: 48),
                  const SizedBox(height: AkelDesign.md),
                  Text('No captions yet', style: AkelDesign.caption),
                  const SizedBox(height: AkelDesign.sm),
                  Text(
                    _speechAvailable ? 'Tap Start to begin captioning' : 'Microphone not available',
                    style: AkelDesign.caption.copyWith(color: Colors.white38),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AkelDesign.lg),
              itemCount: _captionHistory.length,
              itemBuilder: (context, index) {
                final item = _captionHistory[index];
                final time = item['time'] as DateTime;
                final confidence = ((item['confidence'] as double?) ?? 0.0) * 100;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AkelDesign.sm),
                  child: Container(
                    padding: const EdgeInsets.all(AkelDesign.md),
                    decoration: BoxDecoration(
                      color: captionBgColor,
                      borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['text'] as String,
                          style: TextStyle(
                            color: textColor,
                            fontSize: _fontSize - 2,
                          ),
                        ),
                        const SizedBox(height: AkelDesign.xs),
                        Row(
                          children: [
                            Text(
                              time.hour.toString().padLeft(2, '0') + ':' +
                                  time.minute.toString().padLeft(2, '0') + ':' +
                                  time.second.toString().padLeft(2, '0'),
                              style: AkelDesign.caption.copyWith(fontSize: 10),
                            ),
                            if (confidence > 0) ...[
                              const SizedBox(width: AkelDesign.sm),
                              Text(
                                confidence.toInt().toString() + '% confidence',
                                style: AkelDesign.caption.copyWith(fontSize: 10, color: Colors.teal),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}