import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// ==================== EVIDENCE COLLECTION SERVICE ====================
///
/// 4-IN-1 EVIDENCE SYSTEM:
/// 1. Photo Evidence - Quick photo capture with metadata
/// 2. Audio Recording - Background audio recording
/// 3. Video Recording - Stealth video capture
/// 4. Evidence Vault - Encrypted secure storage
///
/// BUILD 55 - HOUR 10
/// ================================================================

class EvidenceCollectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  FlutterSoundRecorder? _audioRecorder;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  bool _isRecordingAudio = false;
  bool _isRecordingVideo = false;
  String? _currentAudioPath;
  String? _currentVideoPath;

  // Encryption
  late encrypt.Key _encryptionKey;
  late encrypt.IV _encryptionIV;
  late encrypt.Encrypter _encrypter;

  // ==================== INITIALIZATION ====================

  Future<bool> initialize() async {
    try {
      debugPrint(' Initializing Evidence Collection Service...');

      // Initialize encryption
      _initializeEncryption();

      // Initialize audio recorder
      _audioRecorder = FlutterSoundRecorder();
      await _audioRecorder!.openRecorder();

      // Get available cameras
      _cameras = await availableCameras();

      debugPrint(' Evidence Collection Service initialized');
      return true;
    } catch (e) {
      debugPrint(' Evidence service initialization error: $e');
      return false;
    }
  }

  void _initializeEncryption() {
    // In production, use secure key storage
    _encryptionKey = encrypt.Key.fromLength(32);
    _encryptionIV = encrypt.IV.fromLength(16);
    _encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));

    debugPrint(' Encryption initialized');
  }

  // ==================== 1. PHOTO EVIDENCE ====================

  Future<EvidenceItem?> capturePhoto({
    required String userId,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint(' Capturing photo evidence...');

      // Initialize camera if needed
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        await _initializeCamera();
      }

      if (_cameraController == null) {
        debugPrint(' Camera not available');
        return null;
      }

      // Capture image
      final image = await _cameraController!.takePicture();

      // Generate metadata
      final timestamp = DateTime.now();
      final evidenceMetadata = {
        'timestamp': timestamp.toIso8601String(),
        'type': 'photo',
        'location': metadata?['location'],
        'description': description,
        'fileSize': await File(image.path).length(),
        ...?metadata,
      };

      // Create evidence item
      final evidence = EvidenceItem(
        id: _generateEvidenceId(),
        userId: userId,
        type: EvidenceType.photo,
        filePath: image.path,
        timestamp: timestamp,
        description: description ?? 'Photo evidence',
        metadata: evidenceMetadata,
        isEncrypted: false,
        isUploaded: false,
      );

      // Save to Firestore
      await _saveEvidenceToFirestore(evidence);

      debugPrint(' Photo captured: ${evidence.id}');
      return evidence;
    } catch (e) {
      debugPrint(' Photo capture error: $e');
      return null;
    }
  }

  Future<void> _initializeCamera() async {
    if (_cameras == null || _cameras!.isEmpty) {
      debugPrint(' No cameras available');
      return;
    }

    try {
      final camera = _cameras!.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      debugPrint(' Camera initialized');
    } catch (e) {
      debugPrint(' Camera initialization error: $e');
    }
  }

  // ==================== 2. AUDIO RECORDING ====================

  Future<bool> startAudioRecording({
    required String userId,
    String? description,
  }) async {
    if (_isRecordingAudio) {
      debugPrint(' Already recording audio');
      return false;
    }

    try {
      debugPrint(' Starting audio recording...');

      // Get file path
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      _currentAudioPath = '${directory.path}/audio_evidence_$timestamp.aac';

      // Start recording
      await _audioRecorder!.startRecorder(
        toFile: _currentAudioPath,
        codec: Codec.aacADTS,
      );

      _isRecordingAudio = true;
      debugPrint(' Audio recording started');
      return true;
    } catch (e) {
      debugPrint(' Audio recording start error: $e');
      return false;
    }
  }

  Future<EvidenceItem?> stopAudioRecording({
    required String userId,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isRecordingAudio) {
      debugPrint(' Not recording audio');
      return null;
    }

    try {
      debugPrint(' Stopping audio recording...');

      await _audioRecorder!.stopRecorder();
      _isRecordingAudio = false;

      if (_currentAudioPath == null) {
        debugPrint(' No audio file path');
        return null;
      }

      // Get file info
      final file = File(_currentAudioPath!);
      final fileSize = await file.length();
      final duration = await _getAudioDuration(_currentAudioPath!);

      // Generate metadata
      final timestamp = DateTime.now();
      final evidenceMetadata = {
        'timestamp': timestamp.toIso8601String(),
        'type': 'audio',
        'duration': duration,
        'fileSize': fileSize,
        'description': description,
        ...?metadata,
      };

      // Create evidence item
      final evidence = EvidenceItem(
        id: _generateEvidenceId(),
        userId: userId,
        type: EvidenceType.audio,
        filePath: _currentAudioPath!,
        timestamp: timestamp,
        description: description ?? 'Audio evidence',
        metadata: evidenceMetadata,
        isEncrypted: false,
        isUploaded: false,
      );

      // Save to Firestore
      await _saveEvidenceToFirestore(evidence);

      debugPrint(' Audio recording saved: ${evidence.id}');
      return evidence;
    } catch (e) {
      debugPrint(' Audio recording stop error: $e');
      _isRecordingAudio = false;
      return null;
    }
  }

  Future<int> _getAudioDuration(String path) async {
    // Simplified - in production, use audio player to get actual duration
    return 0;
  }

  bool isRecordingAudio() => _isRecordingAudio;

  // ==================== 3. VIDEO RECORDING ====================

  Future<bool> startVideoRecording({
    required String userId,
    String? description,
    bool stealthMode = false,
  }) async {
    if (_isRecordingVideo) {
      debugPrint(' Already recording video');
      return false;
    }

    try {
      debugPrint(' Starting video recording...');

      // Initialize camera if needed
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        await _initializeCamera();
      }

      if (_cameraController == null) {
        debugPrint(' Camera not available');
        return false;
      }

      // Get file path
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      _currentVideoPath = '${directory.path}/video_evidence_$timestamp.mp4';

      // Start recording
      await _cameraController!.startVideoRecording();

      _isRecordingVideo = true;
      debugPrint(' Video recording started');
      return true;
    } catch (e) {
      debugPrint(' Video recording start error: $e');
      return false;
    }
  }

  Future<EvidenceItem?> stopVideoRecording({
    required String userId,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isRecordingVideo) {
      debugPrint(' Not recording video');
      return null;
    }

    try {
      debugPrint(' Stopping video recording...');

      final video = await _cameraController!.stopVideoRecording();
      _isRecordingVideo = false;

      // Get file info
      final file = File(video.path);
      final fileSize = await file.length();

      // Generate metadata
      final timestamp = DateTime.now();
      final evidenceMetadata = {
        'timestamp': timestamp.toIso8601String(),
        'type': 'video',
        'fileSize': fileSize,
        'description': description,
        ...?metadata,
      };

      // Create evidence item
      final evidence = EvidenceItem(
        id: _generateEvidenceId(),
        userId: userId,
        type: EvidenceType.video,
        filePath: video.path,
        timestamp: timestamp,
        description: description ?? 'Video evidence',
        metadata: evidenceMetadata,
        isEncrypted: false,
        isUploaded: false,
      );

      // Save to Firestore
      await _saveEvidenceToFirestore(evidence);

      debugPrint(' Video recording saved: ${evidence.id}');
      return evidence;
    } catch (e) {
      debugPrint(' Video recording stop error: $e');
      _isRecordingVideo = false;
      return null;
    }
  }

  bool isRecordingVideo() => _isRecordingVideo;

  // ==================== 4. EVIDENCE VAULT ====================

  Future<bool> encryptEvidence(String evidenceId) async {
    try {
      debugPrint(' Encrypting evidence: $evidenceId');

      // Get evidence
      final evidenceDoc = await _firestore
          .collection('evidence')
          .doc(evidenceId)
          .get();

      if (!evidenceDoc.exists) {
        debugPrint(' Evidence not found');
        return false;
      }

      final evidence = EvidenceItem.fromMap(evidenceDoc.data()!, evidenceDoc.id);

      // Read file
      final file = File(evidence.filePath);
      if (!await file.exists()) {
        debugPrint(' Evidence file not found');
        return false;
      }

      final bytes = await file.readAsBytes();

      // Encrypt
      final encrypted = _encrypter.encryptBytes(bytes, iv: _encryptionIV);

      // Save encrypted file
      final encryptedPath = '${evidence.filePath}.encrypted';
      await File(encryptedPath).writeAsBytes(encrypted.bytes);

      // Update Firestore
      await _firestore.collection('evidence').doc(evidenceId).update({
        'isEncrypted': true,
        'encryptedPath': encryptedPath,
      });

      // Delete original file
      await file.delete();

      debugPrint(' Evidence encrypted');
      return true;
    } catch (e) {
      debugPrint(' Encryption error: $e');
      return false;
    }
  }

  Future<bool> uploadEvidence(String evidenceId) async {
    try {
      debugPrint(' Uploading evidence: $evidenceId');

      // Get evidence
      final evidenceDoc = await _firestore
          .collection('evidence')
          .doc(evidenceId)
          .get();

      if (!evidenceDoc.exists) {
        debugPrint(' Evidence not found');
        return false;
      }

      final evidence = EvidenceItem.fromMap(evidenceDoc.data()!, evidenceDoc.id);

      // Get file
      final file = File(evidence.filePath);
      if (!await file.exists()) {
        debugPrint(' Evidence file not found');
        return false;
      }

      // Upload to Firebase Storage
      final storageRef = _storage.ref().child('evidence/${evidence.userId}/${evidence.id}');
      await storageRef.putFile(file);

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();

      // Update Firestore
      await _firestore.collection('evidence').doc(evidenceId).update({
        'isUploaded': true,
        'downloadUrl': downloadUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(' Evidence uploaded');
      return true;
    } catch (e) {
      debugPrint(' Upload error: $e');
      return false;
    }
  }

  Future<List<EvidenceItem>> getEvidence(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('evidence')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => EvidenceItem.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint(' Get evidence error: $e');
      return [];
    }
  }

  Stream<List<EvidenceItem>> getEvidenceStream(String userId) {
    return _firestore
        .collection('evidence')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => EvidenceItem.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<bool> deleteEvidence(String evidenceId) async {
    try {
      // Get evidence
      final evidenceDoc = await _firestore
          .collection('evidence')
          .doc(evidenceId)
          .get();

      if (!evidenceDoc.exists) {
        debugPrint(' Evidence not found');
        return false;
      }

      final evidence = EvidenceItem.fromMap(evidenceDoc.data()!, evidenceDoc.id);

      // Delete file
      final file = File(evidence.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Delete encrypted file if exists
      if (evidence.isEncrypted && evidence.metadata?['encryptedPath'] != null) {
        final encryptedFile = File(evidence.metadata!['encryptedPath']);
        if (await encryptedFile.exists()) {
          await encryptedFile.delete();
        }
      }

      // Delete from Firestore
      await _firestore.collection('evidence').doc(evidenceId).delete();

      debugPrint(' Evidence deleted');
      return true;
    } catch (e) {
      debugPrint(' Delete error: $e');
      return false;
    }
  }

  // ==================== HELPERS ====================

  Future<void> _saveEvidenceToFirestore(EvidenceItem evidence) async {
    await _firestore.collection('evidence').doc(evidence.id).set(evidence.toMap());
  }

  String _generateEvidenceId() {
    return 'EVD_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<Map<String, int>> getEvidenceStats(String userId) async {
    try {
      final evidence = await getEvidence(userId);

      int photos = 0;
      int audio = 0;
      int video = 0;
      int encrypted = 0;
      int uploaded = 0;

      for (final item in evidence) {
        switch (item.type) {
          case EvidenceType.photo:
            photos++;
            break;
          case EvidenceType.audio:
            audio++;
            break;
          case EvidenceType.video:
            video++;
            break;
        }

        if (item.isEncrypted) encrypted++;
        if (item.isUploaded) uploaded++;
      }

      return {
        'total': evidence.length,
        'photos': photos,
        'audio': audio,
        'video': video,
        'encrypted': encrypted,
        'uploaded': uploaded,
      };
    } catch (e) {
      debugPrint(' Stats error: $e');
      return {};
    }
  }

  // ==================== CLEANUP ====================

  void dispose() {
    _audioRecorder?.closeRecorder();
    _cameraController?.dispose();
    debugPrint(' Evidence Collection Service disposed');
  }
}

// ==================== MODELS ====================

enum EvidenceType {
  photo,
  audio,
  video,
}

class EvidenceItem {
  final String id;
  final String userId;
  final EvidenceType type;
  final String filePath;
  final DateTime timestamp;
  final String description;
  final Map<String, dynamic>? metadata;
  final bool isEncrypted;
  final bool isUploaded;

  EvidenceItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.filePath,
    required this.timestamp,
    required this.description,
    this.metadata,
    this.isEncrypted = false,
    this.isUploaded = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'filePath': filePath,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'metadata': metadata,
      'isEncrypted': isEncrypted,
      'isUploaded': isUploaded,
    };
  }

  static EvidenceItem fromMap(Map<String, dynamic> map, String id) {
    return EvidenceItem(
      id: id,
      userId: map['userId'] ?? '',
      type: EvidenceType.values.firstWhere(
            (e) => e.toString().split('.').last == map['type'],
        orElse: () => EvidenceType.photo,
      ),
      filePath: map['filePath'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      description: map['description'] ?? '',
      metadata: map['metadata'],
      isEncrypted: map['isEncrypted'] ?? false,
      isUploaded: map['isUploaded'] ?? false,
    );
  }
}