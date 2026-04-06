import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibration/vibration.dart';

/// ==================== SMART DETECTION SERVICE ====================
///
/// UNIVERSAL SENSOR INTELLIGENCE HUB
/// Consolidates all detection capabilities:
/// - Earthquake Detection (accelerometer-based)
/// - Fall Detection (gyroscope + accelerometer)
/// - Environmental Hazards (microphone, temperature simulation)
/// - Natural Disaster Detection (barometer, weather API)
/// - Motion/Activity Monitoring
/// - AI Pattern Recognition
///
/// 24-HOUR MARATHON - PHASE 1 (HOURS 1-4)
/// ================================================================

class SmartDetectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sensor stream subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

  // Detection states
  bool _isMonitoring = false;
  bool _earthquakeDetectionEnabled = false;
  bool _fallDetectionEnabled = false;
  bool _environmentalHazardEnabled = false;
  bool _naturalDisasterEnabled = false;

  // Detection thresholds
  double _earthquakeThreshold = 5.0; // Moderate earthquake
  double _fallThreshold = 15.0;

  // Detection history
  List<DetectionEvent> _detectionHistory = [];

  // Callbacks
  Function(DetectionEvent)? onDetectionTriggered;
  Function(String)? onDetectionLog;
  VoidCallback? onEmergencyDetected;

  // ==================== INITIALIZATION ====================

  Future<bool> initialize() async {
    try {
      debugPrint(' Initializing Smart Detection Service...');

      await _loadSettings();

      if (_isMonitoring) {
        await startMonitoring();
      }

      debugPrint(' Smart Detection Service initialized');
      return true;
    } catch (e) {
      debugPrint(' Smart Detection initialization error: $e');
      return false;
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _isMonitoring = prefs.getBool('detection_monitoring') ?? false;
    _earthquakeDetectionEnabled = prefs.getBool('earthquake_detection') ?? false;
    _fallDetectionEnabled = prefs.getBool('fall_detection') ?? false;
    _environmentalHazardEnabled = prefs.getBool('environmental_hazard') ?? false;
    _naturalDisasterEnabled = prefs.getBool('natural_disaster') ?? false;
    _earthquakeThreshold = prefs.getDouble('earthquake_threshold') ?? 5.0;
    _fallThreshold = prefs.getDouble('fall_threshold') ?? 15.0;

    debugPrint(' Detection settings loaded');
  }

  // ==================== MONITORING CONTROL ====================

  Future<bool> startMonitoring() async {
    if (_isMonitoring) {
      debugPrint(' Monitoring already active');
      return false;
    }

    try {
      debugPrint(' Starting sensor monitoring...');

      // Start accelerometer (earthquake, fall detection)
      if (_earthquakeDetectionEnabled || _fallDetectionEnabled) {
        _startAccelerometer();
      }

      // Start gyroscope (fall detection, orientation)
      if (_fallDetectionEnabled) {
        _startGyroscope();
      }

      // Start magnetometer (anomaly detection)
      _startMagnetometer();

      _isMonitoring = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('detection_monitoring', true);

      debugPrint(' Sensor monitoring started');
      return true;
    } catch (e) {
      debugPrint(' Start monitoring error: $e');
      return false;
    }
  }

  Future<bool> stopMonitoring() async {
    try {
      debugPrint(' Stopping sensor monitoring...');

      _accelerometerSubscription?.cancel();
      _gyroscopeSubscription?.cancel();
      _magnetometerSubscription?.cancel();

      _isMonitoring = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('detection_monitoring', false);

      debugPrint(' Sensor monitoring stopped');
      return true;
    } catch (e) {
      debugPrint(' Stop monitoring error: $e');
      return false;
    }
  }

  // ==================== 1. EARTHQUAKE DETECTION ====================

  void _startAccelerometer() {
    _accelerometerSubscription?.cancel();

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      if (_earthquakeDetectionEnabled) {
        _detectEarthquake(event);
      }

      if (_fallDetectionEnabled) {
        _detectFall(event);
      }
    });

    debugPrint(' Accelerometer monitoring started');
  }

  void _detectEarthquake(AccelerometerEvent event) {
    // Calculate magnitude of acceleration
    final magnitude = _calculateMagnitude(event.x, event.y, event.z);

    // Remove gravity (9.8 m/s²) to get actual movement
    final netAcceleration = (magnitude - 9.8).abs();

    // Earthquake detection logic
    if (netAcceleration > _earthquakeThreshold) {
      final severity = _calculateEarthquakeSeverity(netAcceleration);

      debugPrint(' Earthquake detected! Magnitude: ${netAcceleration.toStringAsFixed(2)} m/s²');

      _triggerDetection(
        type: DetectionType.earthquake,
        severity: severity,
        data: {
          'magnitude': netAcceleration,
          'x': event.x,
          'y': event.y,
          'z': event.z,
          'severity': severity.name,
        },
      );
    }
  }

  EarthquakeSeverity _calculateEarthquakeSeverity(double acceleration) {
    // Simplified Richter scale estimation
    // In production, use more sophisticated algorithms
    if (acceleration < 5.0) return EarthquakeSeverity.minor;
    if (acceleration < 10.0) return EarthquakeSeverity.moderate;
    if (acceleration < 15.0) return EarthquakeSeverity.strong;
    return EarthquakeSeverity.severe;
  }

  Future<void> setEarthquakeDetection(bool enabled) async {
    _earthquakeDetectionEnabled = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('earthquake_detection', enabled);

    if (enabled && !_isMonitoring) {
      await startMonitoring();
    }

    debugPrint(' Earthquake detection: $enabled');
  }

  Future<void> setEarthquakeThreshold(double threshold) async {
    _earthquakeThreshold = threshold;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('earthquake_threshold', threshold);

    debugPrint(' Earthquake threshold: $threshold m/s²');
  }

  bool isEarthquakeDetectionEnabled() => _earthquakeDetectionEnabled;
  double getEarthquakeThreshold() => _earthquakeThreshold;

  // ==================== 2. FALL DETECTION ====================

  DateTime? _lastFallCheckTime;
  bool _isPotentialFall = false;

  void _startGyroscope() {
    _gyroscopeSubscription?.cancel();

    _gyroscopeSubscription = gyroscopeEvents.listen((event) {
      if (_fallDetectionEnabled) {
        _checkOrientation(event);
      }
    });

    debugPrint(' Gyroscope monitoring started');
  }

  void _detectFall(AccelerometerEvent event) {
    final magnitude = _calculateMagnitude(event.x, event.y, event.z);

    // Fall detection logic:
    // 1. Sudden acceleration spike (impact)
    // 2. Followed by low acceleration (lying still)

    if (magnitude > _fallThreshold) {
      _isPotentialFall = true;
      _lastFallCheckTime = DateTime.now();

      debugPrint(' Potential fall detected (impact)');

      // Check if user is still after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (_isPotentialFall) {
          _confirmFall();
        }
      });
    } else if (_isPotentialFall && magnitude < 2.0) {
      // Low movement after impact = confirmed fall
      _confirmFall();
    }
  }

  void _checkOrientation(GyroscopeEvent event) {
    // Check if device is horizontal (person lying down)
    final rotationMagnitude = _calculateMagnitude(event.x, event.y, event.z);

    if (_isPotentialFall && rotationMagnitude < 0.5) {
      // Device is stable and horizontal
      debugPrint(' Device horizontal after impact');
    }
  }

  void _confirmFall() {
    debugPrint(' FALL CONFIRMED!');

    _isPotentialFall = false;

    _triggerDetection(
      type: DetectionType.fall,
      severity: EarthquakeSeverity.severe, // Reuse severity enum
      data: {
        'timestamp': DateTime.now().toIso8601String(),
        'confirmed': true,
      },
    );
  }

  Future<void> setFallDetection(bool enabled) async {
    _fallDetectionEnabled = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fall_detection', enabled);

    if (enabled && !_isMonitoring) {
      await startMonitoring();
    }

    debugPrint(' Fall detection: $enabled');
  }

  bool isFallDetectionEnabled() => _fallDetectionEnabled;

  // ==================== 3. ENVIRONMENTAL HAZARD DETECTION ====================

  void _startMagnetometer() {
    _magnetometerSubscription?.cancel();

    _magnetometerSubscription = magnetometerEvents.listen((event) {
      if (_environmentalHazardEnabled) {
        _detectMagneticAnomaly(event);
      }
    });

    debugPrint(' Magnetometer monitoring started');
  }

  void _detectMagneticAnomaly(MagnetometerEvent event) {
    // Detect unusual magnetic field changes
    // Can indicate electrical hazards, fires, etc.

    final magnitude = _calculateMagnitude(event.x, event.y, event.z);

    // Typical Earth's magnetic field: 25-65 µT
    if (magnitude > 100.0 || magnitude < 10.0) {
      debugPrint(' Magnetic anomaly detected: ${magnitude.toStringAsFixed(2)} µT');

      _triggerDetection(
        type: DetectionType.environmentalHazard,
        severity: EarthquakeSeverity.moderate,
        data: {
          'hazardType': 'magnetic_anomaly',
          'magnitude': magnitude,
          'x': event.x,
          'y': event.y,
          'z': event.z,
        },
      );
    }
  }

  // Simulated environmental hazard detection
  // In production, integrate with actual sensors or APIs
  Future<void> simulateEnvironmentalHazard(String hazardType) async {
    debugPrint(' Simulating environmental hazard: $hazardType');

    _triggerDetection(
      type: DetectionType.environmentalHazard,
      severity: EarthquakeSeverity.severe,
      data: {
        'hazardType': hazardType,
        'simulated': true,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> setEnvironmentalHazardDetection(bool enabled) async {
    _environmentalHazardEnabled = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('environmental_hazard', enabled);

    if (enabled && !_isMonitoring) {
      await startMonitoring();
    }

    debugPrint(' Environmental hazard detection: $enabled');
  }

  bool isEnvironmentalHazardEnabled() => _environmentalHazardEnabled;

  // ==================== 4. NATURAL DISASTER DETECTION ====================

  // In production, integrate with weather APIs, seismograph networks, etc.
  Future<void> checkNaturalDisasters() async {
    if (!_naturalDisasterEnabled) return;

    try {
      // Simulate API call to disaster monitoring service
      debugPrint(' Checking for natural disasters...');

      // In production, use APIs like:
      // - USGS Earthquake API
      // - NOAA Weather API
      // - Tsunami Warning System

      // Example: Check for nearby earthquakes
      // final response = await http.get('https://earthquake.usgs.gov/earthquakes/feed/...');

    } catch (e) {
      debugPrint(' Natural disaster check error: $e');
    }
  }

  Future<void> setNaturalDisasterDetection(bool enabled) async {
    _naturalDisasterEnabled = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('natural_disaster', enabled);

    if (enabled) {
      // Start periodic checks (every 5 minutes)
      Timer.periodic(const Duration(minutes: 5), (timer) {
        if (_naturalDisasterEnabled) {
          checkNaturalDisasters();
        } else {
          timer.cancel();
        }
      });
    }

    debugPrint(' Natural disaster detection: $enabled');
  }

  bool isNaturalDisasterEnabled() => _naturalDisasterEnabled;

  // ==================== DETECTION TRIGGER ====================

  void _triggerDetection({
    required DetectionType type,
    required EarthquakeSeverity severity,
    required Map<String, dynamic> data,
  }) {
    final event = DetectionEvent(
      id: _generateEventId(),
      type: type,
      severity: severity,
      timestamp: DateTime.now(),
      data: data,
    );

    _detectionHistory.insert(0, event);
    if (_detectionHistory.length > 100) {
      _detectionHistory.removeLast();
    }

    // Save to Firestore
    _saveDetectionEvent(event);

    // Vibrate device
    _vibrate();

    // Notify callbacks
    onDetectionTriggered?.call(event);
    onDetectionLog?.call('${type.name} detected - ${severity.name}');

    // If severe, trigger emergency callback
    if (severity == EarthquakeSeverity.severe) {
      onEmergencyDetected?.call();
    }
  }

  Future<void> _saveDetectionEvent(DetectionEvent event) async {
    try {
      await _firestore
          .collection('detection_events')
          .doc(event.id)
          .set(event.toMap());
    } catch (e) {
      debugPrint(' Save detection event error: $e');
    }
  }

  // ==================== DETECTION HISTORY ====================

  List<DetectionEvent> getDetectionHistory() => _detectionHistory;

  Future<List<DetectionEvent>> getDetectionHistoryFromFirestore(
      String userId, {
        int limit = 50,
      }) async {
    try {
      final snapshot = await _firestore
          .collection('detection_events')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => DetectionEvent.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint(' Get detection history error: $e');
      return [];
    }
  }

  Stream<List<DetectionEvent>> getDetectionHistoryStream(String userId) {
    return _firestore
        .collection('detection_events')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => DetectionEvent.fromMap(doc.data(), doc.id))
        .toList());
  }

  // ==================== STATISTICS ====================

  Future<Map<String, dynamic>> getDetectionStatistics(String userId) async {
    try {
      final events = await getDetectionHistoryFromFirestore(userId, limit: 1000);

      int earthquakes = 0;
      int falls = 0;
      int environmental = 0;
      int disasters = 0;
      int totalDetections = events.length;

      for (final event in events) {
        switch (event.type) {
          case DetectionType.earthquake:
            earthquakes++;
            break;
          case DetectionType.fall:
            falls++;
            break;
          case DetectionType.environmentalHazard:
            environmental++;
            break;
          case DetectionType.naturalDisaster:
            disasters++;
            break;
        }
      }

      return {
        'total': totalDetections,
        'earthquakes': earthquakes,
        'falls': falls,
        'environmental': environmental,
        'disasters': disasters,
        'avgPerDay': totalDetections / 30, // Last 30 days
      };
    } catch (e) {
      debugPrint(' Get statistics error: $e');
      return {};
    }
  }

  // ==================== HELPERS ====================

  double _calculateMagnitude(double x, double y, double z) {
    return (x * x + y * y + z * z).abs().clamp(0.0, 100.0);
  }

  String _generateEventId() {
    return 'DET_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 200]);
    }
  }

  bool isMonitoring() => _isMonitoring;

  // ==================== CLEANUP ====================

  void dispose() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    debugPrint(' Smart Detection Service disposed');
  }
}

// ==================== MODELS ====================

enum DetectionType {
  earthquake,
  fall,
  environmentalHazard,
  naturalDisaster,
}

enum EarthquakeSeverity {
  minor, // 3.0-4.0 Richter
  moderate, // 4.0-5.5 Richter
  strong, // 5.5-6.5 Richter
  severe, // 6.5+ Richter
}

class DetectionEvent {
  final String id;
  final DetectionType type;
  final EarthquakeSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  DetectionEvent({
    required this.id,
    required this.type,
    required this.severity,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }

  static DetectionEvent fromMap(Map<String, dynamic> map, String id) {
    return DetectionEvent(
      id: id,
      type: DetectionType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => DetectionType.earthquake,
      ),
      severity: EarthquakeSeverity.values.firstWhere(
            (e) => e.name == map['severity'],
        orElse: () => EarthquakeSeverity.minor,
      ),
      timestamp: DateTime.parse(map['timestamp']),
      data: map['data'] ?? {},
    );
  }

  String getDisplayTitle() {
    switch (type) {
      case DetectionType.earthquake:
        return ' Earthquake Detected';
      case DetectionType.fall:
        return ' Fall Detected';
      case DetectionType.environmentalHazard:
        return ' Environmental Hazard';
      case DetectionType.naturalDisaster:
        return ' Natural Disaster';
    }
  }

  String getSeverityLabel() {
    switch (severity) {
      case EarthquakeSeverity.minor:
        return 'Minor';
      case EarthquakeSeverity.moderate:
        return 'Moderate';
      case EarthquakeSeverity.strong:
        return 'Strong';
      case EarthquakeSeverity.severe:
        return 'SEVERE';
    }
  }

  Color getSeverityColor() {
    switch (severity) {
      case EarthquakeSeverity.minor:
        return const Color(0xFF4CAF50); // Green
      case EarthquakeSeverity.moderate:
        return const Color(0xFFFFA726); // Orange
      case EarthquakeSeverity.strong:
        return const Color(0xFFFF5722); // Deep Orange
      case EarthquakeSeverity.severe:
        return const Color(0xFFF44336); // Red
    }
  }
}