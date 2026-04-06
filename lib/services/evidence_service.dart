import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

enum EvidenceType { audio, video, photo }
enum RecordingStatus { idle, recording, processing, completed, error }

class Evidence {
  final String id;
  final String userId;
  final String panicEventId;
  final EvidenceType type;
  final String localPath;
  final String? remotePath;
  final DateTime timestamp;
  final int durationSeconds;
  final int fileSizeBytes;
  final bool isUploaded;
  final String? errorMessage;

  Evidence({
    required this.id,
    required this.userId,
    required this.panicEventId,
    required this.type,
    required this.localPath,
    this.remotePath,
    required this.timestamp,
    required this.durationSeconds,
    required this.fileSizeBytes,
    this.isUploaded = false,
    this.errorMessage,
  });

  factory Evidence.fromMap(Map<String, dynamic> map, String id) {
    return Evidence(
      id: id,
      userId: map['userId'] ?? '',
      panicEventId: map['panicEventId'] ?? '',
      type: _typeFromString(map['type'] ?? 'audio'),
      localPath: map['localPath'] ?? '',
      remotePath: map['remotePath'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationSeconds: map['durationSeconds'] ?? 0,
      fileSizeBytes: map['fileSizeBytes'] ?? 0,
      isUploaded: map['isUploaded'] ?? false,
      errorMessage: map['errorMessage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'panicEventId': panicEventId,
      'type': _typeToString(type),
      'localPath': localPath,
      'remotePath': remotePath,
      'timestamp': FieldValue.serverTimestamp(),
      'durationSeconds': durationSeconds,
      'fileSizeBytes': fileSizeBytes,
      'isUploaded': isUploaded,
      'errorMessage': errorMessage,
    };
  }

  static EvidenceType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'audio':
        return EvidenceType.audio;
      case 'video':
        return EvidenceType.video;
      case 'photo':
        return EvidenceType.photo;
      default:
        return EvidenceType.audio;
    }
  }

  static String _typeToString(EvidenceType type) {
    switch (type) {
      case EvidenceType.audio:
        return 'audio';
      case EvidenceType.video:
        return 'video';
      case EvidenceType.photo:
        return 'photo';
    }
  }
}

class EvidenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AudioRecorder _audioRecorder = AudioRecorder();

  CameraController? _cameraController;
  RecordingStatus _status = RecordingStatus.idle;
  DateTime? _recordingStartTime;
  String? _currentRecordingPath;
  String? _currentPanicEventId;

  RecordingStatus get status => _status;
  bool get isRecording => _status == RecordingStatus.recording;

  // Initialize camera
  Future<bool> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint(' No cameras available');
        return false;
      }

      // Use back camera for evidence
      final camera = cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      debugPrint(' Camera initialized');
      return true;
    } catch (e) {
      debugPrint(' Camera initialization error: $e');
      return false;
    }
  }

  // Start audio recording
  Future<String?> startAudioRecording(String userId, String panicEventId) async {
    try {
      if (_status == RecordingStatus.recording) {
        debugPrint(' Already recording');
        return null;
      }

      _status = RecordingStatus.recording;
      _currentPanicEventId = panicEventId;
      _recordingStartTime = DateTime.now();

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/audio_$timestamp.m4a';

      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        debugPrint(' No audio recording permission');
        _status = RecordingStatus.error;
        return null;
      }

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      debugPrint(' Audio recording started: $_currentRecordingPath');
      return _currentRecordingPath;
    } catch (e) {
      debugPrint(' Start audio recording error: $e');
      _status = RecordingStatus.error;
      return null;
    }
  }

  // Stop audio recording
  Future<Evidence?> stopAudioRecording(String userId) async {
    try {
      if (_status != RecordingStatus.recording) {
        debugPrint(' Not currently recording');
        return null;
      }

      _status = RecordingStatus.processing;

      final path = await _audioRecorder.stop();
      if (path == null || _currentRecordingPath == null) {
        debugPrint(' Recording path is null');
        _status = RecordingStatus.error;
        return null;
      }

      final duration = DateTime.now().difference(_recordingStartTime!).inSeconds;
      final file = File(_currentRecordingPath!);
      final fileSize = await file.length();

      final evidence = Evidence(
        id: '',
        userId: userId,
        panicEventId: _currentPanicEventId!,
        type: EvidenceType.audio,
        localPath: _currentRecordingPath!,
        timestamp: _recordingStartTime!,
        durationSeconds: duration,
        fileSizeBytes: fileSize,
      );

      // Save to Firestore
      final docRef = await _firestore.collection('evidence').add(evidence.toMap());

      debugPrint(' Audio recording stopped: $duration seconds, ${_formatBytes(fileSize)}');

      _status = RecordingStatus.completed;
      _currentRecordingPath = null;
      _currentPanicEventId = null;
      _recordingStartTime = null;

      return Evidence(
        id: docRef.id,
        userId: userId,
        panicEventId: evidence.panicEventId,
        type: evidence.type,
        localPath: evidence.localPath,
        timestamp: evidence.timestamp,
        durationSeconds: duration,
        fileSizeBytes: fileSize,
      );
    } catch (e) {
      debugPrint(' Stop audio recording error: $e');
      _status = RecordingStatus.error;
      return null;
    }
  }

  // Start video recording
  Future<String?> startVideoRecording(String userId, String panicEventId) async {
    try {
      if (_status == RecordingStatus.recording) {
        debugPrint(' Already recording');
        return null;
      }

      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        final initialized = await initializeCamera();
        if (!initialized) return null;
      }

      _status = RecordingStatus.recording;
      _currentPanicEventId = panicEventId;
      _recordingStartTime = DateTime.now();

      await _cameraController!.startVideoRecording();

      debugPrint(' Video recording started');
      return 'recording';
    } catch (e) {
      debugPrint(' Start video recording error: $e');
      _status = RecordingStatus.error;
      return null;
    }
  }

  // Stop video recording
  Future<Evidence?> stopVideoRecording(String userId) async {
    try {
      if (_status != RecordingStatus.recording) {
        debugPrint(' Not currently recording');
        return null;
      }

      if (_cameraController == null) {
        debugPrint(' Camera controller is null');
        return null;
      }

      _status = RecordingStatus.processing;

      final videoFile = await _cameraController!.stopVideoRecording();
      final duration = DateTime.now().difference(_recordingStartTime!).inSeconds;
      final file = File(videoFile.path);
      final fileSize = await file.length();

      final evidence = Evidence(
        id: '',
        userId: userId,
        panicEventId: _currentPanicEventId!,
        type: EvidenceType.video,
        localPath: videoFile.path,
        timestamp: _recordingStartTime!,
        durationSeconds: duration,
        fileSizeBytes: fileSize,
      );

      // Save to Firestore
      final docRef = await _firestore.collection('evidence').add(evidence.toMap());

      debugPrint(' Video recording stopped: $duration seconds, ${_formatBytes(fileSize)}');

      _status = RecordingStatus.completed;
      _currentRecordingPath = null;
      _currentPanicEventId = null;
      _recordingStartTime = null;

      return Evidence(
        id: docRef.id,
        userId: userId,
        panicEventId: evidence.panicEventId,
        type: evidence.type,
        localPath: evidence.localPath,
        timestamp: evidence.timestamp,
        durationSeconds: duration,
        fileSizeBytes: fileSize,
      );
    } catch (e) {
      debugPrint(' Stop video recording error: $e');
      _status = RecordingStatus.error;
      return null;
    }
  }

  // Upload evidence to Firebase Storage
  Future<bool> uploadEvidence(String evidenceId) async {
    try {
      final doc = await _firestore.collection('evidence').doc(evidenceId).get();
      if (!doc.exists) return false;

      final evidence = Evidence.fromMap(doc.data()!, doc.id);
      final file = File(evidence.localPath);

      if (!await file.exists()) {
        debugPrint(' Evidence file not found: ${evidence.localPath}');
        return false;
      }

      final extension = evidence.type == EvidenceType.audio ? 'm4a' : 'mp4';
      final remotePath = 'evidence/${evidence.userId}/${evidence.id}.$extension';

      final uploadTask = _storage.ref(remotePath).putFile(file);

      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint(' Upload progress: ${progress.toStringAsFixed(1)}%');
      });

      await uploadTask;

      await _firestore.collection('evidence').doc(evidenceId).update({
        'remotePath': remotePath,
        'isUploaded': true,
      });

      debugPrint(' Evidence uploaded: $remotePath');
      return true;
    } catch (e) {
      debugPrint(' Upload evidence error: $e');
      return false;
    }
  }

  // Get all evidence for user
  Future<List<Evidence>> getEvidence(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('evidence')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Evidence.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint(' Get evidence error: $e');
      return [];
    }
  }

  // Get evidence for specific panic event
  Future<List<Evidence>> getEvidenceForEvent(String panicEventId) async {
    try {
      final snapshot = await _firestore
          .collection('evidence')
          .where('panicEventId', isEqualTo: panicEventId)
          .get();

      return snapshot.docs.map((doc) {
        return Evidence.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint(' Get evidence for event error: $e');
      return [];
    }
  }

  // Delete evidence
  Future<bool> deleteEvidence(String evidenceId) async {
    try {
      final doc = await _firestore.collection('evidence').doc(evidenceId).get();
      if (!doc.exists) return false;

      final evidence = Evidence.fromMap(doc.data()!, doc.id);

      // Delete local file
      final file = File(evidence.localPath);
      if (await file.exists()) {
        await file.delete();
      }

      // Delete remote file if uploaded
      if (evidence.isUploaded && evidence.remotePath != null) {
        await _storage.ref(evidence.remotePath).delete();
      }

      // Delete Firestore document
      await _firestore.collection('evidence').doc(evidenceId).delete();

      debugPrint(' Evidence deleted: $evidenceId');
      return true;
    } catch (e) {
      debugPrint(' Delete evidence error: $e');
      return false;
    }
  }

  // Get evidence statistics
  Future<Map<String, dynamic>> getEvidenceStatistics(String userId) async {
    try {
      final evidence = await getEvidence(userId);

      final totalEvidence = evidence.length;
      final audioEvidence = evidence.where((e) => e.type == EvidenceType.audio).length;
      final videoEvidence = evidence.where((e) => e.type == EvidenceType.video).length;
      final photoEvidence = evidence.where((e) => e.type == EvidenceType.photo).length;
      final uploadedEvidence = evidence.where((e) => e.isUploaded).length;

      final totalDuration = evidence.fold<int>(0, (sum, e) => sum + e.durationSeconds);
      final totalSize = evidence.fold<int>(0, (sum, e) => sum + e.fileSizeBytes);

      return {
        'totalEvidence': totalEvidence,
        'audioEvidence': audioEvidence,
        'videoEvidence': videoEvidence,
        'photoEvidence': photoEvidence,
        'uploadedEvidence': uploadedEvidence,
        'totalDuration': totalDuration,
        'totalSize': totalSize,
      };
    } catch (e) {
      debugPrint(' Get evidence statistics error: $e');
      return {};
    }
  }

  // Format bytes for display
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Format duration for display
  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  // Format file size
  String formatFileSize(int bytes) {
    return _formatBytes(bytes);
  }

  // Get type icon
  static String getTypeIcon(EvidenceType type) {
    switch (type) {
      case EvidenceType.audio:
        return ' ';
      case EvidenceType.video:
        return ' ';
      case EvidenceType.photo:
        return ' ';
    }
  }

  // Get type color
  static String getTypeColor(EvidenceType type) {
    switch (type) {
      case EvidenceType.audio:
        return '#9C27B0'; // Purple
      case EvidenceType.video:
        return '#F44336'; // Red
      case EvidenceType.photo:
        return '#2196F3'; // Blue
    }
  }

  // Get type label
  static String getTypeLabel(EvidenceType type) {
    switch (type) {
      case EvidenceType.audio:
        return 'Audio';
      case EvidenceType.video:
        return 'Video';
      case EvidenceType.photo:
        return 'Photo';
    }
  }

  // Dispose
  void dispose() {
    _audioRecorder.dispose();
    _cameraController?.dispose();
  }
}