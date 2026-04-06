import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

class VehicleInfo {
  final String? make;
  final String? model;
  final String? year;
  final String? licensePlate;
  final String? vin;

  VehicleInfo({
    this.make,
    this.model,
    this.year,
    this.licensePlate,
    this.vin,
  });

  Map<String, dynamic> toJson() => {
    'make': make,
    'model': model,
    'year': year,
    'licensePlate': licensePlate,
    'vin': vin,
  };

  factory VehicleInfo.fromJson(Map<String, dynamic> json) => VehicleInfo(
    make: json['make'],
    model: json['model'],
    year: json['year'],
    licensePlate: json['licensePlate'],
    vin: json['vin'],
  );
}

class CrashEvent {
  final String id;
  final DateTime timestamp;
  final double severity; // 0-10 scale
  final String location;
  final bool emergencyContacted;
  final Map<String, dynamic> sensorData;

  CrashEvent({
    required this.id,
    required this.timestamp,
    required this.severity,
    required this.location,
    required this.emergencyContacted,
    required this.sensorData,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'severity': severity,
    'location': location,
    'emergencyContacted': emergencyContacted,
    'sensorData': sensorData,
  };

  factory CrashEvent.fromJson(Map<String, dynamic> json) => CrashEvent(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    severity: (json['severity'] as num).toDouble(),
    location: json['location'],
    emergencyContacted: json['emergencyContacted'],
    sensorData: Map<String, dynamic>.from(json['sensorData']),
  );
}

class VehicleHealthStatus {
  final String category; // engine, battery, tires, brakes, etc.
  final String status; // good, warning, critical
  final String message;
  final DateTime lastChecked;

  VehicleHealthStatus({
    required this.category,
    required this.status,
    required this.message,
    required this.lastChecked,
  });

  Color getStatusColor() {
    switch (status) {
      case 'good':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon() {
    switch (status) {
      case 'good':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'critical':
        return Icons.error;
      default:
        return Icons.info;
    }
  }
}

class VehicleSafetyService {
  static final VehicleSafetyService _instance =
  VehicleSafetyService._internal();
  factory VehicleSafetyService() => _instance;
  VehicleSafetyService._internal();

  static const String _vehicleInfoKey = 'vehicle_info';
  static const String _crashHistoryKey = 'crash_history';
  static const String _settingsKey = 'vehicle_safety_settings';

  VehicleInfo? _vehicleInfo;
  List<CrashEvent> _crashHistory = [];
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _crashDetectionEnabled = false;
  bool _isMonitoring = false;
  double _crashThreshold = 3.5; // G-force threshold

  // Mock Bluetooth connection status
  bool _isBluetoothConnected = false;

  /// Initialize service
  Future<void> initialize() async {
    await _loadVehicleInfo();
    await _loadCrashHistory();
    await _loadSettings();
    debugPrint(' Vehicle Safety Service initialized');
  }

  /// Get vehicle info
  VehicleInfo? getVehicleInfo() => _vehicleInfo;

  /// Save vehicle info
  Future<void> saveVehicleInfo(VehicleInfo info) async {
    _vehicleInfo = info;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vehicleInfoKey, json.encode(info.toJson()));
    debugPrint(' Vehicle info saved');
  }

  /// Start crash detection
  Future<void> startCrashDetection() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _crashDetectionEnabled = true;

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      _checkForCrash(event);
    });

    await _saveSettings();
    debugPrint(' Crash detection started');
  }

  /// Stop crash detection
  Future<void> stopCrashDetection() async {
    _isMonitoring = false;
    _crashDetectionEnabled = false;
    await _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    await _saveSettings();
    debugPrint(' Crash detection stopped');
  }

  /// Check for crash based on accelerometer data
  void _checkForCrash(AccelerometerEvent event) {
    // Calculate total acceleration magnitude
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    // Remove gravity (9.8 m/s²) and convert to G-force
    final gForce = (magnitude - 9.8) / 9.8;

    // If exceeds threshold, potential crash detected
    if (gForce.abs() > _crashThreshold) {
      _handleCrashDetected(gForce, event);
    }
  }

  /// Handle detected crash
  void _handleCrashDetected(double gForce, AccelerometerEvent event) async {
    debugPrint(' CRASH DETECTED! G-Force: ${gForce.toStringAsFixed(2)}');

    final crashEvent = CrashEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      severity: (gForce.abs() * 2).clamp(0, 10), // Scale to 0-10
      location: 'GPS Location', // Would use actual GPS
      emergencyContacted: true,
      sensorData: {
        'x': event.x,
        'y': event.y,
        'z': event.z,
        'gForce': gForce,
      },
    );

    _crashHistory.add(crashEvent);
    await _saveCrashHistory();

    // Trigger emergency alert
    // In real implementation, this would activate panic button
    debugPrint(' Emergency contacts notified');
  }

  /// Get crash history
  List<CrashEvent> getCrashHistory() => _crashHistory;

  /// Clear crash history
  Future<void> clearCrashHistory() async {
    _crashHistory.clear();
    await _saveCrashHistory();
    debugPrint(' Crash history cleared');
  }

  /// Get Bluetooth connection status
  bool isBluetoothConnected() => _isBluetoothConnected;

  /// Toggle Bluetooth connection (mock)
  Future<void> toggleBluetoothConnection() async {
    _isBluetoothConnected = !_isBluetoothConnected;
    debugPrint(_isBluetoothConnected
        ? ' Bluetooth connected to vehicle'
        : ' Bluetooth disconnected');
  }

  /// Get vehicle health status (mock data)
  List<VehicleHealthStatus> getVehicleHealth() {
    final random = Random();
    final statuses = ['good', 'good', 'good', 'warning', 'critical'];

    return [
      VehicleHealthStatus(
        category: 'Engine',
        status: statuses[random.nextInt(statuses.length)],
        message: 'Engine running normally',
        lastChecked: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      VehicleHealthStatus(
        category: 'Battery',
        status: 'good',
        message: 'Battery voltage: 12.6V',
        lastChecked: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      VehicleHealthStatus(
        category: 'Tires',
        status: 'warning',
        message: 'Front right tire pressure low',
        lastChecked: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      VehicleHealthStatus(
        category: 'Brakes',
        status: 'good',
        message: 'Brake pads: 65% remaining',
        lastChecked: DateTime.now().subtract(const Duration(days: 1)),
      ),
      VehicleHealthStatus(
        category: 'Oil',
        status: 'warning',
        message: 'Oil change due in 500 miles',
        lastChecked: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];
  }

  /// Request roadside assistance
  Future<void> requestRoadsideAssistance(String issueType) async {
    debugPrint(' Roadside assistance requested: $issueType');
    // In real implementation, this would contact a service provider
    await Future.delayed(const Duration(seconds: 1));
    debugPrint(' Assistance request sent');
  }

  /// Get crash detection status
  bool isCrashDetectionEnabled() => _crashDetectionEnabled;

  bool isMonitoring() => _isMonitoring;

  /// Get crash threshold
  double getCrashThreshold() => _crashThreshold;

  /// Set crash threshold
  Future<void> setCrashThreshold(double threshold) async {
    _crashThreshold = threshold;
    await _saveSettings();
    debugPrint(' Crash threshold set to: $threshold G');
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalCrashes': _crashHistory.length,
      'lastCrash': _crashHistory.isNotEmpty
          ? _crashHistory.last.timestamp
          : null,
      'averageSeverity': _crashHistory.isNotEmpty
          ? _crashHistory.fold<double>(
          0, (sum, crash) => sum + crash.severity) /
          _crashHistory.length
          : 0.0,
      'emergenciesContacted': _crashHistory
          .where((crash) => crash.emergencyContacted)
          .length,
    };
  }

  /// Load vehicle info
  Future<void> _loadVehicleInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final infoJson = prefs.getString(_vehicleInfoKey);
      if (infoJson != null) {
        _vehicleInfo = VehicleInfo.fromJson(json.decode(infoJson));
      }
    } catch (e) {
      debugPrint(' Load vehicle info error: $e');
    }
  }

  /// Load crash history
  Future<void> _loadCrashHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_crashHistoryKey);
      if (historyJson != null) {
        _crashHistory = historyJson
            .map((str) => CrashEvent.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load crash history error: $e');
    }
  }

  /// Save crash history
  Future<void> _saveCrashHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson =
      _crashHistory.map((crash) => json.encode(crash.toJson())).toList();
      await prefs.setStringList(_crashHistoryKey, historyJson);
    } catch (e) {
      debugPrint(' Save crash history error: $e');
    }
  }

  /// Load settings
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson != null) {
        final settings = json.decode(settingsJson);
        _crashDetectionEnabled = settings['crashDetectionEnabled'] ?? false;
        _crashThreshold = settings['crashThreshold'] ?? 3.5;
      }
    } catch (e) {
      debugPrint(' Load settings error: $e');
    }
  }

  /// Save settings
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = {
        'crashDetectionEnabled': _crashDetectionEnabled,
        'crashThreshold': _crashThreshold,
      };
      await prefs.setString(_settingsKey, json.encode(settings));
    } catch (e) {
      debugPrint(' Save settings error: $e');
    }
  }

  /// Dispose
  void dispose() {
    _accelerometerSubscription?.cancel();
  }
}