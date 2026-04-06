import 'package:flutter/foundation.dart';
import './panic_service.dart';
import './voice_command_service.dart';
import './gesture_control_service.dart';
import './evidence_collection_service.dart';
import './vibration_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ==================== UNIFIED PANIC MANAGER ====================
///
/// CENTRAL PANIC SYSTEM COORDINATOR
/// Integrates all panic triggers across the app:
/// - Manual panic button
/// - Voice commands
/// - Gesture controls
/// - Emergency shortcuts
/// - Automatic triggers
///
/// BUILD 55 - HOUR 11
/// ================================================================

class UnifiedPanicManager {
  final PanicService _panicService = PanicService();
  final VoiceCommandService _voiceService = VoiceCommandService();
  final GestureControlService _gestureService = GestureControlService();
  final EvidenceCollectionService _evidenceService = EvidenceCollectionService();
  final VibrationService _vibrationService = VibrationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Callbacks
  VoidCallback? onPanicTriggered;
  Function(String)? onPanicLog;
  Function(PanicTriggerSource)? onTriggerSourceDetected;

  bool _isInitialized = false;
  PanicState _currentState = PanicState.inactive;
  List<PanicEvent> _panicHistory = [];

  // ==================== INITIALIZATION ====================

  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint(' Unified Panic Manager already initialized');
      return true;
    }

    try {
      debugPrint(' Initializing Unified Panic Manager...');

      // Initialize all services
      await _panicService.initialize();
      await _voiceService.initialize();
      await _gestureService.initialize();
      await _evidenceService.initialize();

      // Setup cross-service callbacks
      _setupCallbacks();

      _isInitialized = true;
      debugPrint(' Unified Panic Manager initialized');
      return true;
    } catch (e) {
      debugPrint(' Unified Panic Manager initialization error: $e');
      return false;
    }
  }

  void _setupCallbacks() {
    // Voice command panic
    _voiceService.onEmergencyCommand = () {
      _handlePanicTrigger(
        source: PanicTriggerSource.voiceCommand,
        data: {'command': 'voice_emergency'},
      );
    };

    // Gesture panic (shake)
    _gestureService.onShakeDetected = () {
      _handlePanicTrigger(
        source: PanicTriggerSource.shakeGesture,
        data: {'gesture': 'shake'},
      );
    };

    // Gesture panic (pattern)
    _gestureService.onPatternMatched = () {
      _handlePanicTrigger(
        source: PanicTriggerSource.tapPattern,
        data: {'gesture': 'tap_pattern'},
      );
    };

    debugPrint(' Cross-service callbacks configured');
  }

  // ==================== PANIC TRIGGER METHODS ====================

  Future<bool> triggerPanic({
    required String userId,
    required String userName,
    required PanicTriggerSource source,
    Map<String, dynamic>? additionalData,
    bool autoStartEvidence = true,
  }) async {
    if (!_isInitialized) {
      debugPrint(' Panic Manager not initialized');
      return false;
    }

    try {
      debugPrint(' PANIC TRIGGERED - Source: ${source.name}');

      // Update state
      _currentState = PanicState.active;

      // Trigger vibration
      await _vibrationService.emergency();

      // Trigger main panic service
      await _panicService.triggerPanic(userId, userName);

      // Auto-start evidence collection if enabled
      if (autoStartEvidence) {
        await _startEvidenceCollection(userId);
      }

      // Create panic event
      final event = PanicEvent(
        id: _generateEventId(),
        userId: userId,
        userName: userName,
        source: source,
        timestamp: DateTime.now(),
        data: additionalData ?? {},
        evidenceStarted: autoStartEvidence,
      );

      // Save event
      await _savePanicEvent(event);
      _panicHistory.insert(0, event);

      // Notify callbacks
      onPanicTriggered?.call();
      onTriggerSourceDetected?.call(source);
      onPanicLog?.call('Panic triggered via ${source.name}');

      debugPrint(' Panic system activated');
      return true;
    } catch (e) {
      debugPrint(' Panic trigger error: $e');
      return false;
    }
  }

  void _handlePanicTrigger({
    required PanicTriggerSource source,
    Map<String, dynamic>? data,
  }) {
    // This will be called by integrated services
    // In production, you'd get userId from auth
    debugPrint(' Panic trigger detected: ${source.name}');
    onTriggerSourceDetected?.call(source);
  }

  Future<void> _startEvidenceCollection(String userId) async {
    try {
      // Start audio recording
      final audioStarted = await _evidenceService.startAudioRecording(
        userId: userId,
        description: 'Emergency panic - auto recorded',
      );

      if (audioStarted) {
        debugPrint(' Emergency audio recording started');
      }

      // Optionally start video
      // await _evidenceService.startVideoRecording(userId: userId);
    } catch (e) {
      debugPrint(' Evidence collection start error: $e');
    }
  }

  // ==================== PANIC CANCELLATION ====================

  Future<bool> cancelPanic({
    required String userId,
    String? reason,
  }) async {
    try {
      debugPrint(' Cancelling panic...');

      _currentState = PanicState.cancelled;

      // Stop evidence collection
      if (_evidenceService.isRecordingAudio()) {
        await _evidenceService.stopAudioRecording(
          userId: userId,
          description: 'Panic cancelled - $reason',
        );
      }

      if (_evidenceService.isRecordingVideo()) {
        await _evidenceService.stopVideoRecording(
          userId: userId,
          description: 'Panic cancelled - $reason',
        );
      }

      // Log cancellation
      onPanicLog?.call('Panic cancelled: ${reason ?? "user action"}');

      debugPrint(' Panic cancelled');
      return true;
    } catch (e) {
      debugPrint(' Panic cancellation error: $e');
      return false;
    }
  }

  // ==================== PANIC RESOLUTION ====================

  Future<bool> resolvePanic({
    required String userId,
    String? resolution,
  }) async {
    try {
      debugPrint('✓ Resolving panic...');

      _currentState = PanicState.resolved;

      // Stop evidence collection
      if (_evidenceService.isRecordingAudio()) {
        await _evidenceService.stopAudioRecording(
          userId: userId,
          description: 'Panic resolved - $resolution',
        );
      }

      // Log resolution
      onPanicLog?.call('Panic resolved: ${resolution ?? "safe"}');

      debugPrint(' Panic resolved');
      return true;
    } catch (e) {
      debugPrint(' Panic resolution error: $e');
      return false;
    }
  }

  // ==================== DATA MANAGEMENT ====================

  Future<void> _savePanicEvent(PanicEvent event) async {
    try {
      await _firestore
          .collection('panic_events')
          .doc(event.id)
          .set(event.toMap());
    } catch (e) {
      debugPrint(' Save panic event error: $e');
    }
  }

  Future<List<PanicEvent>> getPanicHistory(String userId, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('panic_events')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PanicEvent.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint(' Get panic history error: $e');
      return [];
    }
  }

  Stream<List<PanicEvent>> getPanicHistoryStream(String userId) {
    return _firestore
        .collection('panic_events')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PanicEvent.fromMap(doc.data(), doc.id))
        .toList());
  }

  // ==================== STATISTICS ====================

  Future<Map<String, dynamic>> getPanicStatistics(String userId) async {
    try {
      final events = await getPanicHistory(userId, limit: 1000);

      int total = events.length;
      int manualTriggers = 0;
      int voiceTriggers = 0;
      int gestureTriggers = 0;
      int autoTriggers = 0;
      int cancelled = 0;
      int resolved = 0;

      for (final event in events) {
        switch (event.source) {
          case PanicTriggerSource.manualButton:
            manualTriggers++;
            break;
          case PanicTriggerSource.voiceCommand:
            voiceTriggers++;
            break;
          case PanicTriggerSource.shakeGesture:
          case PanicTriggerSource.tapPattern:
            gestureTriggers++;
            break;
          case PanicTriggerSource.automatic:
            autoTriggers++;
            break;
          default:
            break;
        }
      }

      return {
        'total': total,
        'manualTriggers': manualTriggers,
        'voiceTriggers': voiceTriggers,
        'gestureTriggers': gestureTriggers,
        'autoTriggers': autoTriggers,
        'cancelled': cancelled,
        'resolved': resolved,
        'averageResponseTime': _calculateAverageResponseTime(events),
      };
    } catch (e) {
      debugPrint(' Get statistics error: $e');
      return {};
    }
  }

  double _calculateAverageResponseTime(List<PanicEvent> events) {
    // Simplified - in production, calculate actual response times
    return 0.0;
  }

  // ==================== HELPERS ====================

  String _generateEventId() {
    return 'PANIC_${DateTime.now().millisecondsSinceEpoch}';
  }

  PanicState getCurrentState() => _currentState;
  List<PanicEvent> getCachedHistory() => _panicHistory;

  // ==================== CLEANUP ====================

  void dispose() {
    _voiceService.dispose();
    _gestureService.dispose();
    _evidenceService.dispose();
    debugPrint(' Unified Panic Manager disposed');
  }
}

// ==================== MODELS ====================

enum PanicState {
  inactive,
  active,
  cancelled,
  resolved,
}

enum PanicTriggerSource {
  manualButton,
  voiceCommand,
  shakeGesture,
  tapPattern,
  screenGesture,
  automatic,
  widget,
  wearable,
  fallDetection,
  safeWord,
}

class PanicEvent {
  final String id;
  final String userId;
  final String userName;
  final PanicTriggerSource source;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final bool evidenceStarted;

  PanicEvent({
    required this.id,
    required this.userId,
    required this.userName,
    required this.source,
    required this.timestamp,
    required this.data,
    this.evidenceStarted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'source': source.name,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'evidenceStarted': evidenceStarted,
    };
  }

  static PanicEvent fromMap(Map<String, dynamic> map, String id) {
    return PanicEvent(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      source: PanicTriggerSource.values.firstWhere(
            (e) => e.name == map['source'],
        orElse: () => PanicTriggerSource.manualButton,
      ),
      timestamp: DateTime.parse(map['timestamp']),
      data: map['data'] ?? {},
      evidenceStarted: map['evidenceStarted'] ?? false,
    );
  }
}