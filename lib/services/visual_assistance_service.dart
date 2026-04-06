import 'dart:io';
import 'dart:ui' show Rect;
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// ==================== VISUAL ASSISTANCE SERVICE ====================
///
/// 5-IN-1 VISUAL ASSISTANCE:
/// 1. Object Recognition - Detect and identify objects
/// 2. Scene Description - Describe entire scenes
/// 3. Text Recognition (OCR) - Extract text from images
/// 4. Color Identification - Identify colors in images
/// 5. Navigation Assistance - Visual navigation help
///
/// BUILD 55 - HOUR 6
/// ================================================================

class VisualAssistanceService {
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _tts = FlutterTts();

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  // ML Kit processors
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImageLabeler _imageLabeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.5),
  );

  bool _isInitialized = false;
  bool _isProcessing = false;

  // ==================== INITIALIZATION ====================

  Future<bool> initialize() async {
    try {
      debugPrint(' Initializing Visual Assistance Service...');

      // Initialize TTS
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);

      // Get available cameras
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint(' No cameras available');
        return false;
      }

      debugPrint(' Found ${_cameras!.length} camera(s)');

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint(' Visual service initialization error: $e');
      return false;
    }
  }

  // ==================== CAMERA MANAGEMENT ====================

  Future<CameraController?> startCamera({bool useFrontCamera = false}) async {
    if (_cameras == null || _cameras!.isEmpty) {
      debugPrint(' No cameras available');
      return null;
    }

    try {
      // Select camera
      final camera = useFrontCamera
          ? _cameras!.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      )
          : _cameras!.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      // Dispose existing controller
      await _cameraController?.dispose();

      // Create new controller
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      debugPrint(' Camera started');
      return _cameraController;
    } catch (e) {
      debugPrint(' Camera start error: $e');
      return null;
    }
  }

  Future<void> stopCamera() async {
    await _cameraController?.dispose();
    _cameraController = null;
    debugPrint(' Camera stopped');
  }

  Future<XFile?> takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint(' Camera not initialized');
      return null;
    }

    try {
      final image = await _cameraController!.takePicture();
      debugPrint(' Picture taken: ${image.path}');
      return image;
    } catch (e) {
      debugPrint(' Take picture error: $e');
      return null;
    }
  }

  Future<XFile?> pickImageFromGallery() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        debugPrint(' Image picked: ${image.path}');
      }
      return image;
    } catch (e) {
      debugPrint(' Pick image error: $e');
      return null;
    }
  }

  // ==================== 1. OBJECT RECOGNITION ====================

  Future<List<DetectedObject>> recognizeObjects(String imagePath) async {
    if (_isProcessing) {
      debugPrint(' Already processing...');
      return [];
    }

    _isProcessing = true;

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final labels = await _imageLabeler.processImage(inputImage);

      final objects = labels.map((label) {
        return DetectedObject(
          label: label.label,
          confidence: label.confidence,
          description: _getObjectDescription(label.label),
        );
      }).toList();

      debugPrint(' Detected ${objects.length} objects');

      _isProcessing = false;
      return objects;
    } catch (e) {
      debugPrint(' Object recognition error: $e');
      _isProcessing = false;
      return [];
    }
  }

  String _getObjectDescription(String label) {
    // Enhanced descriptions for common objects
    final descriptions = {
      'Person': 'A person detected in the image',
      'Face': 'A human face detected',
      'Dog': 'A dog or canine animal',
      'Cat': 'A cat or feline animal',
      'Car': 'A vehicle or automobile',
      'Phone': 'A mobile phone or smartphone',
      'Book': 'A book or reading material',
      'Food': 'Food or edible items',
      'Chair': 'A chair or seating furniture',
      'Table': 'A table or flat surface',
    };

    return descriptions[label] ?? 'A $label detected in the image';
  }

  // ==================== 2. SCENE DESCRIPTION ====================

  Future<SceneDescription> describeScene(String imagePath) async {
    if (_isProcessing) {
      debugPrint(' Already processing...');
      return SceneDescription(
        mainDescription: 'Processing...',
        objects: [],
        colors: [],
        confidence: 0.0,
      );
    }

    _isProcessing = true;

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final labels = await _imageLabeler.processImage(inputImage);

      // Build scene description
      final objects = labels.map((l) => l.label).toList();
      final mainObject = labels.isNotEmpty ? labels.first.label : 'unknown';
      final confidence = labels.isNotEmpty ? labels.first.confidence : 0.0;

      String description;
      if (objects.isEmpty) {
        description = 'Unable to identify specific objects in the scene';
      } else if (objects.length == 1) {
        description = 'The image shows $mainObject';
      } else if (objects.length == 2) {
        description = 'The image shows ${objects[0]} and ${objects[1]}';
      } else {
        description = 'The image shows ${objects[0]}, ${objects[1]}, and ${objects.length - 2} other objects';
      }

      final scene = SceneDescription(
        mainDescription: description,
        objects: objects.take(10).toList(),
        colors: await _extractDominantColors(imagePath),
        confidence: confidence,
      );

      debugPrint(' Scene described: $description');

      _isProcessing = false;
      return scene;
    } catch (e) {
      debugPrint(' Scene description error: $e');
      _isProcessing = false;
      return SceneDescription(
        mainDescription: 'Error analyzing scene',
        objects: [],
        colors: [],
        confidence: 0.0,
      );
    }
  }

  // ==================== 3. TEXT RECOGNITION (OCR) ====================

  Future<RecognizedText> recognizeText(String imagePath) async {
    if (_isProcessing) {
      debugPrint(' Already processing...');
      return RecognizedText(
        fullText: '',
        blocks: [],
        language: 'en',
      );
    }

    _isProcessing = true;

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final blocks = recognizedText.blocks.map((block) {
        return TextBlock(
          text: block.text,
          confidence: 0.9, // ML Kit doesn't provide confidence for text
          boundingBox: block.boundingBox,
        );
      }).toList();

      final result = RecognizedText(
        fullText: recognizedText.text,
        blocks: blocks,
        language: 'en',
      );

      debugPrint(' Text recognized: ${recognizedText.text.length} characters');

      _isProcessing = false;
      return result;
    } catch (e) {
      debugPrint(' Text recognition error: $e');
      _isProcessing = false;
      return RecognizedText(
        fullText: '',
        blocks: [],
        language: 'en',
      );
    }
  }

  // ==================== 4. COLOR IDENTIFICATION ====================

  Future<List<IdentifiedColor>> identifyColors(String imagePath) async {
    if (_isProcessing) {
      debugPrint(' Already processing...');
      return [];
    }

    _isProcessing = true;

    try {
      final colors = await _extractDominantColors(imagePath);

      debugPrint(' Identified ${colors.length} colors');

      _isProcessing = false;
      return colors;
    } catch (e) {
      debugPrint(' Color identification error: $e');
      _isProcessing = false;
      return [];
    }
  }

  Future<List<IdentifiedColor>> _extractDominantColors(String imagePath) async {
    // Simplified color extraction (in production, use image processing library)
    // This is a placeholder - would need image processing package
    return [
      IdentifiedColor(name: 'Red', hex: '#FF0000', percentage: 30.0),
      IdentifiedColor(name: 'Blue', hex: '#0000FF', percentage: 25.0),
      IdentifiedColor(name: 'Green', hex: '#00FF00', percentage: 20.0),
      IdentifiedColor(name: 'Yellow', hex: '#FFFF00', percentage: 15.0),
      IdentifiedColor(name: 'White', hex: '#FFFFFF', percentage: 10.0),
    ];
  }

  // ==================== 5. NAVIGATION ASSISTANCE ====================

  Future<NavigationGuidance> getNavigationGuidance(String imagePath) async {
    if (_isProcessing) {
      debugPrint(' Already processing...');
      return NavigationGuidance(
        direction: 'Processing...',
        obstacles: [],
        pathClear: false,
      );
    }

    _isProcessing = true;

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final labels = await _imageLabeler.processImage(inputImage);

      // Analyze for navigation
      final obstacles = <String>[];
      bool pathClear = true;

      for (final label in labels) {
        final lowerLabel = label.label.toLowerCase();
        if (lowerLabel.contains('person') ||
            lowerLabel.contains('car') ||
            lowerLabel.contains('bicycle') ||
            lowerLabel.contains('animal') ||
            lowerLabel.contains('furniture') ||
            lowerLabel.contains('wall') ||
            lowerLabel.contains('door')) {
          obstacles.add(label.label);
          pathClear = false;
        }
      }

      String direction;
      if (pathClear) {
        direction = 'Path ahead is clear';
      } else if (obstacles.length == 1) {
        direction = '${obstacles[0]} detected ahead';
      } else {
        direction = 'Multiple obstacles detected: ${obstacles.join(", ")}';
      }

      final guidance = NavigationGuidance(
        direction: direction,
        obstacles: obstacles,
        pathClear: pathClear,
      );

      debugPrint(' Navigation guidance: $direction');

      _isProcessing = false;
      return guidance;
    } catch (e) {
      debugPrint(' Navigation guidance error: $e');
      _isProcessing = false;
      return NavigationGuidance(
        direction: 'Unable to analyze path',
        obstacles: [],
        pathClear: false,
      );
    }
  }

  // ==================== TEXT-TO-SPEECH ====================

  Future<void> speak(String text) async {
    try {
      await _tts.speak(text);
      debugPrint(' Speaking: $text');
    } catch (e) {
      debugPrint(' TTS error: $e');
    }
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  // ==================== CLEANUP ====================

  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    _imageLabeler.close();
    debugPrint(' Visual service disposed');
  }
}

// ==================== MODELS ====================

class DetectedObject {
  final String label;
  final double confidence;
  final String description;

  DetectedObject({
    required this.label,
    required this.confidence,
    required this.description,
  });
}

class SceneDescription {
  final String mainDescription;
  final List<String> objects;
  final List<IdentifiedColor> colors;
  final double confidence;

  SceneDescription({
    required this.mainDescription,
    required this.objects,
    required this.colors,
    required this.confidence,
  });
}

class RecognizedText {
  final String fullText;
  final List<TextBlock> blocks;
  final String language;

  RecognizedText({
    required this.fullText,
    required this.blocks,
    required this.language,
  });
}

class TextBlock {
  final String text;
  final double confidence;
  final Rect boundingBox;

  TextBlock({
    required this.text,
    required this.confidence,
    required this.boundingBox,
  });
}

class IdentifiedColor {
  final String name;
  final String hex;
  final double percentage;

  IdentifiedColor({
    required this.name,
    required this.hex,
    required this.percentage,
  });
}

class NavigationGuidance {
  final String direction;
  final List<String> obstacles;
  final bool pathClear;

  NavigationGuidance({
    required this.direction,
    required this.obstacles,
    required this.pathClear,
  });
}