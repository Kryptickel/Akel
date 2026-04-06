import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import '../widgets/futuristic_widgets.dart';
import '../widgets/camera_preview_widget.dart';
import '../services/visual_assistance_service.dart';

/// ==================== VISUAL ASSISTANCE HUB SCREEN ====================
///
/// 5-IN-1 VISUAL ASSISTANCE CENTER:
/// 1. Object Recognition
/// 2. Scene Description
/// 3. Text Recognition (OCR)
/// 4. Color Identification
/// 5. Navigation Assistance
///
/// BUILD 55 - HOUR 7
/// ================================================================

class VisualAssistanceHubScreen extends StatefulWidget {
  const VisualAssistanceHubScreen({Key? key}) : super(key: key);

  @override
  State<VisualAssistanceHubScreen> createState() => _VisualAssistanceHubScreenState();
}

class _VisualAssistanceHubScreenState extends State<VisualAssistanceHubScreen>
    with TickerProviderStateMixin {
  final VisualAssistanceService _visualService = VisualAssistanceService();

  late TabController _tabController;
  CameraController? _cameraController;

  bool _isInitializing = true;
  bool _isProcessing = false;
  bool _useFrontCamera = false;
  String? _currentImagePath;

  // Results
  List<DetectedObject> _detectedObjects = [];
  SceneDescription? _sceneDescription;
  RecognizedText? _recognizedText;
  List<IdentifiedColor> _colors = [];
  NavigationGuidance? _navigationGuidance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cameraController?.dispose();
    _visualService.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    setState(() => _isInitializing = true);

    try {
      final initialized = await _visualService.initialize();

      if (!initialized) {
        _showError('Failed to initialize visual service');
        setState(() => _isInitializing = false);
        return;
      }

      // Start camera
      await _startCamera();

      setState(() => _isInitializing = false);
    } catch (e) {
      debugPrint(' Initialization error: $e');
      setState(() => _isInitializing = false);
      _showError('Initialization failed: $e');
    }
  }

  Future<void> _startCamera() async {
    final controller = await _visualService.startCamera(
      useFrontCamera: _useFrontCamera,
    );

    if (controller != null && mounted) {
      setState(() {
        _cameraController = controller;
      });
    }
  }

  Future<void> _switchCamera() async {
    setState(() {
      _useFrontCamera = !_useFrontCamera;
    });
    await _startCamera();
  }

  Future<void> _captureAndProcess() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final image = await _visualService.takePicture();

      if (image == null) {
        _showError('Failed to capture image');
        setState(() => _isProcessing = false);
        return;
      }

      setState(() {
        _currentImagePath = image.path;
      });

      await _processImage(image.path);

      setState(() => _isProcessing = false);
    } catch (e) {
      debugPrint(' Capture error: $e');
      setState(() => _isProcessing = false);
      _showError('Capture failed: $e');
    }
  }

  Future<void> _pickAndProcess() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final image = await _visualService.pickImageFromGallery();

      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }

      setState(() {
        _currentImagePath = image.path;
      });

      await _processImage(image.path);

      setState(() => _isProcessing = false);
    } catch (e) {
      debugPrint(' Pick error: $e');
      setState(() => _isProcessing = false);
      _showError('Image selection failed: $e');
    }
  }

  Future<void> _processImage(String imagePath) async {
    final currentTab = _tabController.index;

    switch (currentTab) {
      case 0: // Object Recognition
        await _processObjectRecognition(imagePath);
        break;
      case 1: // Scene Description
        await _processSceneDescription(imagePath);
        break;
      case 2: // Text Recognition
        await _processTextRecognition(imagePath);
        break;
      case 3: // Color Identification
        await _processColorIdentification(imagePath);
        break;
      case 4: // Navigation
        await _processNavigation(imagePath);
        break;
    }
  }

  Future<void> _processObjectRecognition(String imagePath) async {
    final objects = await _visualService.recognizeObjects(imagePath);

    if (mounted) {
      setState(() {
        _detectedObjects = objects;
      });

      if (objects.isNotEmpty) {
        final summary = objects.length == 1
            ? 'Detected ${objects.first.label}'
            : 'Detected ${objects.length} objects';

        await _visualService.speak(summary);
      } else {
        await _visualService.speak('No objects detected');
      }
    }
  }

  Future<void> _processSceneDescription(String imagePath) async {
    final scene = await _visualService.describeScene(imagePath);

    if (mounted) {
      setState(() {
        _sceneDescription = scene;
      });

      await _visualService.speak(scene.mainDescription);
    }
  }

  Future<void> _processTextRecognition(String imagePath) async {
    final text = await _visualService.recognizeText(imagePath);

    if (mounted) {
      setState(() {
        _recognizedText = text;
      });

      if (text.fullText.isNotEmpty) {
        await _visualService.speak('Text recognized: ${text.fullText.substring(0, text.fullText.length > 100 ? 100 : text.fullText.length)}');
      } else {
        await _visualService.speak('No text detected');
      }
    }
  }

  Future<void> _processColorIdentification(String imagePath) async {
    final colors = await _visualService.identifyColors(imagePath);

    if (mounted) {
      setState(() {
        _colors = colors;
      });

      if (colors.isNotEmpty) {
        final summary = 'Primary colors: ${colors.take(3).map((c) => c.name).join(", ")}';
        await _visualService.speak(summary);
      }
    }
  }

  Future<void> _processNavigation(String imagePath) async {
    final guidance = await _visualService.getNavigationGuidance(imagePath);

    if (mounted) {
      setState(() {
        _navigationGuidance = guidance;
      });

      await _visualService.speak(guidance.direction);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AkelDesign.errorRed,
      ),
    );
  }

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
                'Initializing Visual Assistance...',
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
            Text(
              'VISUAL ASSISTANCE HUB',
              style: AkelDesign.h3.copyWith(fontSize: 16),
            ),
            Text(
              '5-in-1 AI Vision Center',
              style: AkelDesign.caption.copyWith(fontSize: 10),
            ),
          ],
        ),
        actions: [
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AkelDesign.neonBlue,
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AkelDesign.neonBlue,
          labelColor: AkelDesign.neonBlue,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Objects'),
            Tab(text: 'Scene'),
            Tab(text: 'Text (OCR)'),
            Tab(text: 'Colors'),
            Tab(text: 'Navigation'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildObjectRecognitionTab(),
          _buildSceneDescriptionTab(),
          _buildTextRecognitionTab(),
          _buildColorIdentificationTab(),
          _buildNavigationTab(),
        ],
      ),
    );
  }

  // ==================== TAB 1: OBJECT RECOGNITION ====================

  Widget _buildObjectRecognitionTab() {
    return Column(
      children: [
        // Camera Preview
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(AkelDesign.md),
            child: CameraPreviewWidget(
              controller: _cameraController,
              onCapture: _captureAndProcess,
              onSwitchCamera: _switchCamera,
              onPickImage: _pickAndProcess,
              overlayText: _isProcessing ? 'Analyzing...' : 'Tap to identify objects',
            ),
          ),
        ),

        // Results
        Expanded(
          flex: 3,
          child: _buildObjectResults(),
        ),
      ],
    );
  }

  Widget _buildObjectResults() {
    if (_detectedObjects.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search,
        title: 'No Objects Detected',
        subtitle: 'Capture an image to identify objects',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AkelDesign.md),
      itemCount: _detectedObjects.length,
      itemBuilder: (context, index) {
        final obj = _detectedObjects[index];
        return _buildObjectCard(obj);
      },
    );
  }

  Widget _buildObjectCard(DetectedObject obj) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.md),
      hasGlow: true,
      glowColor: AkelDesign.neonBlue,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AkelDesign.neonBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
            ),
            child: const Icon(
              Icons.category,
              color: AkelDesign.neonBlue,
              size: 32,
            ),
          ),
          const SizedBox(width: AkelDesign.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  obj.label,
                  style: AkelDesign.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  obj.description,
                  style: AkelDesign.caption,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.analytics,
                      size: 16,
                      color: AkelDesign.successGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Confidence: ${(obj.confidence * 100).toStringAsFixed(1)}%',
                      style: AkelDesign.caption.copyWith(
                        color: AkelDesign.successGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CONTINUE IN NEXT MESSAGE ====================
  // ==================== TAB 2: SCENE DESCRIPTION ====================

  Widget _buildSceneDescriptionTab() {
    return Column(
      children: [
        // Camera Preview
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(AkelDesign.md),
            child: CameraPreviewWidget(
              controller: _cameraController,
              onCapture: _captureAndProcess,
              onSwitchCamera: _switchCamera,
              onPickImage: _pickAndProcess,
              overlayText: _isProcessing ? 'Describing scene...' : 'Tap to describe scene',
            ),
          ),
        ),

        // Results
        Expanded(
          flex: 3,
          child: _buildSceneResults(),
        ),
      ],
    );
  }

  Widget _buildSceneResults() {
    if (_sceneDescription == null) {
      return _buildEmptyState(
        icon: Icons.landscape,
        title: 'No Scene Analysis',
        subtitle: 'Capture an image to describe the scene',
      );
    }

    final scene = _sceneDescription!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Description
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.lg),
            hasGlow: true,
            glowColor: AkelDesign.neonBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.description,
                      color: AkelDesign.neonBlue,
                      size: 28,
                    ),
                    const SizedBox(width: AkelDesign.md),
                    Expanded(
                      child: Text(
                        'Scene Description',
                        style: AkelDesign.subtitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AkelDesign.md),
                Text(
                  scene.mainDescription,
                  style: AkelDesign.body.copyWith(fontSize: 16),
                ),
                const SizedBox(height: AkelDesign.md),
                Row(
                  children: [
                    const Icon(
                      Icons.analytics,
                      size: 16,
                      color: AkelDesign.successGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Confidence: ${(scene.confidence * 100).toStringAsFixed(1)}%',
                      style: AkelDesign.caption.copyWith(
                        color: AkelDesign.successGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.lg),

          // Detected Objects
          if (scene.objects.isNotEmpty) ...[
            Text('DETECTED OBJECTS', style: AkelDesign.subtitle),
            const SizedBox(height: AkelDesign.md),
            Wrap(
              spacing: AkelDesign.sm,
              runSpacing: AkelDesign.sm,
              children: scene.objects.map((obj) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AkelDesign.md,
                    vertical: AkelDesign.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AkelDesign.neonBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
                    border: Border.all(
                      color: AkelDesign.neonBlue.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    obj,
                    style: AkelDesign.caption.copyWith(
                      color: AkelDesign.neonBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: AkelDesign.lg),

          // Dominant Colors
          if (scene.colors.isNotEmpty) ...[
            Text('DOMINANT COLORS', style: AkelDesign.subtitle),
            const SizedBox(height: AkelDesign.md),
            ...scene.colors.take(5).map((color) {
              return _buildColorItem(color);
            }),
          ],

          const SizedBox(height: AkelDesign.lg),

          // Speak Button
          FuturisticButton(
            text: 'SPEAK DESCRIPTION',
            icon: Icons.volume_up,
            onPressed: () {
              _visualService.speak(scene.mainDescription);
            },
            color: AkelDesign.infoBlue,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  // ==================== TAB 3: TEXT RECOGNITION (OCR) ====================

  Widget _buildTextRecognitionTab() {
    return Column(
      children: [
        // Camera Preview
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(AkelDesign.md),
            child: CameraPreviewWidget(
              controller: _cameraController,
              onCapture: _captureAndProcess,
              onSwitchCamera: _switchCamera,
              onPickImage: _pickAndProcess,
              overlayText: _isProcessing ? 'Extracting text...' : 'Tap to recognize text',
            ),
          ),
        ),

        // Results
        Expanded(
          flex: 3,
          child: _buildTextResults(),
        ),
      ],
    );
  }

  Widget _buildTextResults() {
    if (_recognizedText == null || _recognizedText!.fullText.isEmpty) {
      return _buildEmptyState(
        icon: Icons.text_fields,
        title: 'No Text Detected',
        subtitle: 'Capture an image containing text',
      );
    }

    final text = _recognizedText!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full Text Display
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.lg),
            hasGlow: true,
            glowColor: AkelDesign.neonBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.article,
                      color: AkelDesign.neonBlue,
                      size: 28,
                    ),
                    const SizedBox(width: AkelDesign.md),
                    Expanded(
                      child: Text(
                        'Recognized Text',
                        style: AkelDesign.subtitle,
                      ),
                    ),
                    Text(
                      '${text.fullText.length} chars',
                      style: AkelDesign.caption,
                    ),
                  ],
                ),
                const SizedBox(height: AkelDesign.md),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 150),
                  padding: const EdgeInsets.all(AkelDesign.md),
                  decoration: BoxDecoration(
                    color: AkelDesign.deepBlack,
                    borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
                    border: Border.all(
                      color: AkelDesign.neonBlue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: SelectableText(
                    text.fullText,
                    style: AkelDesign.body.copyWith(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.lg),

          // Text Blocks
          if (text.blocks.isNotEmpty) ...[
            Text(
              'TEXT BLOCKS (${text.blocks.length})',
              style: AkelDesign.subtitle,
            ),
            const SizedBox(height: AkelDesign.md),
            ...text.blocks.map((block) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AkelDesign.sm),
                child: FuturisticCard(
                  padding: const EdgeInsets.all(AkelDesign.md),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.text_snippet,
                        color: AkelDesign.neonBlue,
                        size: 20,
                      ),
                      const SizedBox(width: AkelDesign.md),
                      Expanded(
                        child: Text(
                          block.text,
                          style: AkelDesign.body,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: AkelDesign.lg),

          // Actions
          Row(
            children: [
              Expanded(
                child: FuturisticButton(
                  text: 'COPY TEXT',
                  icon: Icons.copy,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text.fullText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(' Text copied to clipboard'),
                        backgroundColor: AkelDesign.successGreen,
                      ),
                    );
                  },
                  color: AkelDesign.successGreen,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: AkelDesign.md),
              Expanded(
                child: FuturisticButton(
                  text: 'SPEAK TEXT',
                  icon: Icons.volume_up,
                  onPressed: () {
                    _visualService.speak(text.fullText);
                  },
                  color: AkelDesign.infoBlue,
                  isOutlined: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== TAB 4: COLOR IDENTIFICATION ====================

  Widget _buildColorIdentificationTab() {
    return Column(
      children: [
        // Camera Preview
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(AkelDesign.md),
            child: CameraPreviewWidget(
              controller: _cameraController,
              onCapture: _captureAndProcess,
              onSwitchCamera: _switchCamera,
              onPickImage: _pickAndProcess,
              overlayText: _isProcessing ? 'Analyzing colors...' : 'Tap to identify colors',
            ),
          ),
        ),

        // Results
        Expanded(
          flex: 3,
          child: _buildColorResults(),
        ),
      ],
    );
  }

  Widget _buildColorResults() {
    if (_colors.isEmpty) {
      return _buildEmptyState(
        icon: Icons.palette,
        title: 'No Colors Detected',
        subtitle: 'Capture an image to identify colors',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AkelDesign.md),
      itemCount: _colors.length,
      itemBuilder: (context, index) {
        final color = _colors[index];
        return _buildColorCard(color);
      },
    );
  }

  Widget _buildColorCard(IdentifiedColor color) {
    final colorValue = _hexToColor(color.hex);

    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.md),
      hasGlow: true,
      glowColor: colorValue,
      child: Row(
        children: [
          // Color Swatch
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorValue,
              borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorValue.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: AkelDesign.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  color.name,
                  style: AkelDesign.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  color.hex,
                  style: AkelDesign.caption.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: color.percentage / 100,
                        backgroundColor: Colors.white10,
                        color: colorValue,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(width: AkelDesign.sm),
                    Text(
                      '${color.percentage.toStringAsFixed(1)}%',
                      style: AkelDesign.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white70),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: color.hex));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(' ${color.hex} copied'),
                  backgroundColor: AkelDesign.successGreen,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorItem(IdentifiedColor color) {
    final colorValue = _hexToColor(color.hex);

    return Padding(
      padding: const EdgeInsets.only(bottom: AkelDesign.sm),
      child: FuturisticCard(
        padding: const EdgeInsets.all(AkelDesign.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorValue,
                borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: AkelDesign.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    color.name,
                    style: AkelDesign.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    color.hex,
                    style: AkelDesign.caption.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
            Text(
              '${color.percentage.toStringAsFixed(0)}%',
              style: AkelDesign.caption,
            ),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  // ==================== TAB 5: NAVIGATION ASSISTANCE ====================

  Widget _buildNavigationTab() {
    return Column(
      children: [
        // Camera Preview
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(AkelDesign.md),
            child: CameraPreviewWidget(
              controller: _cameraController,
              onCapture: _captureAndProcess,
              onSwitchCamera: _switchCamera,
              onPickImage: _pickAndProcess,
              overlayText: _isProcessing
                  ? 'Analyzing path...'
                  : 'Tap to check navigation',
            ),
          ),
        ),

        // Results
        Expanded(
          flex: 3,
          child: _buildNavigationResults(),
        ),
      ],
    );
  }

  Widget _buildNavigationResults() {
    if (_navigationGuidance == null) {
      return _buildEmptyState(
        icon: Icons.explore,
        title: 'No Navigation Data',
        subtitle: 'Capture an image to analyze path',
      );
    }

    final guidance = _navigationGuidance!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Path Status
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.xl),
            hasGlow: true,
            glowColor: guidance.pathClear
                ? AkelDesign.successGreen
                : AkelDesign.warningOrange,
            child: Column(
              children: [
                Icon(
                  guidance.pathClear
                      ? Icons.check_circle
                      : Icons.warning,
                  color: guidance.pathClear
                      ? AkelDesign.successGreen
                      : AkelDesign.warningOrange,
                  size: 64,
                ),
                const SizedBox(height: AkelDesign.lg),
                Text(
                  guidance.pathClear ? 'PATH CLEAR' : 'OBSTACLES DETECTED',
                  style: AkelDesign.h3.copyWith(
                    color: guidance.pathClear
                        ? AkelDesign.successGreen
                        : AkelDesign.warningOrange,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AkelDesign.md),
                Text(
                  guidance.direction,
                  style: AkelDesign.body.copyWith(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.lg),

          // Obstacles
          if (guidance.obstacles.isNotEmpty) ...[
            Text(
              'DETECTED OBSTACLES (${guidance.obstacles.length})',
              style: AkelDesign.subtitle,
            ),
            const SizedBox(height: AkelDesign.md),
            ...guidance.obstacles.map((obstacle) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AkelDesign.sm),
                child: FuturisticCard(
                  padding: const EdgeInsets.all(AkelDesign.md),
                  hasGlow: true,
                  glowColor: AkelDesign.warningOrange,
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AkelDesign.warningOrange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
                        ),
                        child: const Icon(
                          Icons.warning,
                          color: AkelDesign.warningOrange,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AkelDesign.md),
                      Expanded(
                        child: Text(
                          obstacle,
                          style: AkelDesign.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: AkelDesign.lg),

          // Actions
          FuturisticButton(
            text: 'SPEAK GUIDANCE',
            icon: Icons.volume_up,
            onPressed: () {
              _visualService.speak(guidance.direction);
            },
            color: AkelDesign.infoBlue,
            isFullWidth: true,
          ),

          const SizedBox(height: AkelDesign.md),

          // Info Card
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.md),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AkelDesign.infoBlue,
                  size: 20,
                ),
                const SizedBox(width: AkelDesign.md),
                Expanded(
                  child: Text(
                    'Navigation assistance uses AI to detect obstacles and provide path guidance',
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

  // ==================== HELPER WIDGETS ====================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.white24,
          ),
          const SizedBox(height: AkelDesign.lg),
          Text(
            title,
            style: AkelDesign.h3.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: AkelDesign.sm),
          Text(
            subtitle,
            style: AkelDesign.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
