import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

enum WatchType {
  appleWatch,
  wearOS,
  samsungGalaxy,
  unknown,
}

class ConnectedWatch {
  final String id;
  final String name;
  final WatchType type;
  final String model;
  final int batteryLevel;
  final bool isConnected;
  final DateTime lastSync;

  ConnectedWatch({
    required this.id,
    required this.name,
    required this.type,
    required this.model,
    required this.batteryLevel,
    required this.isConnected,
    required this.lastSync,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'model': model,
    'batteryLevel': batteryLevel,
    'isConnected': isConnected,
    'lastSync': lastSync.toIso8601String(),
  };

  factory ConnectedWatch.fromJson(Map<String, dynamic> json) =>
      ConnectedWatch(
        id: json['id'],
        name: json['name'],
        type: WatchType.values[json['type']],
        model: json['model'],
        batteryLevel: json['batteryLevel'],
        isConnected: json['isConnected'],
        lastSync: DateTime.parse(json['lastSync']),
      );
}

class FallEvent {
  final String id;
  final DateTime timestamp;
  final double impactForce;
  final bool emergencyContacted;
  final String? location;

  FallEvent({
    required this.id,
    required this.timestamp,
    required this.impactForce,
    required this.emergencyContacted,
    this.location,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'impactForce': impactForce,
    'emergencyContacted': emergencyContacted,
    'location': location,
  };

  factory FallEvent.fromJson(Map<String, dynamic> json) => FallEvent(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    impactForce: json['impactForce'],
    emergencyContacted: json['emergencyContacted'],
    location: json['location'],
  );
}

class SmartwatchService {
  static final SmartwatchService _instance = SmartwatchService._internal();
  factory SmartwatchService() => _instance;
  SmartwatchService._internal();

  static const String _watchesKey = 'connected_watches';
  static const String _fallEventsKey = 'fall_events';
  static const String _settingsKey = 'smartwatch_settings';

  List<ConnectedWatch> _connectedWatches = [];
  List<FallEvent> _fallEvents = [];

  // Settings
  bool _panicButtonEnabled = true;
  bool _fallDetectionEnabled = true;
  double _fallSensitivity = 0.7; // 0-1 scale
  bool _hapticFeedbackEnabled = true;
  bool _silentModeSupport = true;
  int _heartRateThreshold = 120;

  Timer? _syncTimer;

  /// Initialize service
  Future<void> initialize() async {
    await _loadSettings();
    await _loadWatches();
    await _loadFallEvents();
    _startPeriodicSync();
    debugPrint(' Smartwatch Service initialized');
  }

  /// Get connected watches
  List<ConnectedWatch> getConnectedWatches() => _connectedWatches;

  /// Get primary watch
  ConnectedWatch? getPrimaryWatch() {
    if (_connectedWatches.isEmpty) return null;
    return _connectedWatches.firstWhere(
          (w) => w.isConnected,
      orElse: () => _connectedWatches.first,
    );
  }

  /// Connect watch (mock)
  Future<void> connectWatch(WatchType type) async {
    String name;
    String model;

    switch (type) {
      case WatchType.appleWatch:
        name = 'Apple Watch';
        model = 'Series 9';
        break;
      case WatchType.wearOS:
        name = 'Wear OS Watch';
        model = 'Pixel Watch 2';
        break;
      case WatchType.samsungGalaxy:
        name = 'Galaxy Watch';
        model = 'Galaxy Watch 6';
        break;
      case WatchType.unknown:
        name = 'Unknown Watch';
        model = 'Unknown';
        break;
    }

    final watch = ConnectedWatch(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: type,
      model: model,
      batteryLevel: 85,
      isConnected: true,
      lastSync: DateTime.now(),
    );

    _connectedWatches.add(watch);
    await _saveWatches();

    debugPrint(' Watch connected: $name');
  }

  /// Disconnect watch
  Future<void> disconnectWatch(String watchId) async {
    _connectedWatches.removeWhere((w) => w.id == watchId);
    await _saveWatches();
    debugPrint(' Watch disconnected');
  }

  /// Trigger panic from watch
  Future<void> triggerWristPanic() async {
    if (!_panicButtonEnabled) {
      debugPrint(' Wrist panic disabled');
      return;
    }

    debugPrint(' WRIST PANIC ACTIVATED!');
    // In real app, would trigger panic button service

    if (_hapticFeedbackEnabled) {
      debugPrint(' Haptic feedback sent to watch');
    }
  }

  /// Detect fall
  Future<void> detectFall(double impactForce) async {
    if (!_fallDetectionEnabled) return;

    if (impactForce > _fallSensitivity * 10) {
      debugPrint(' FALL DETECTED! Impact: ${impactForce.toStringAsFixed(2)}G');

      final fallEvent = FallEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        impactForce: impactForce,
        emergencyContacted: true,
        location: 'GPS Location',
      );

      _fallEvents.add(fallEvent);
      await _saveFallEvents();

      // Send haptic alert to watch
      if (_hapticFeedbackEnabled) {
        debugPrint(' Fall alert sent to watch');
      }
    }
  }

  /// Get fall events
  List<FallEvent> getFallEvents() => _fallEvents;

  /// Clear fall history
  Future<void> clearFallHistory() async {
    _fallEvents.clear();
    await _saveFallEvents();
    debugPrint(' Fall history cleared');
  }

  /// Sync with watch (mock)
  Future<void> syncWithWatch() async {
    if (_connectedWatches.isEmpty) return;

    debugPrint(' Syncing with watch...');

    // Mock sync - update battery and connection status
    for (int i = 0; i < _connectedWatches.length; i++) {
      final watch = _connectedWatches[i];
      _connectedWatches[i] = ConnectedWatch(
        id: watch.id,
        name: watch.name,
        type: watch.type,
        model: watch.model,
        batteryLevel: (watch.batteryLevel - 1).clamp(0, 100),
        isConnected: true,
        lastSync: DateTime.now(),
      );
    }

    await _saveWatches();
    debugPrint(' Sync complete');
  }

  /// Send notification to watch
  Future<void> sendNotificationToWatch(String title, String message) async {
    if (_connectedWatches.isEmpty) return;

    debugPrint(' Notification sent to watch: $title');

    if (_hapticFeedbackEnabled) {
      debugPrint(' Haptic pattern: ${_getHapticPattern(title)}');
    }
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'connectedWatches': _connectedWatches.length,
      'activeWatches':
      _connectedWatches.where((w) => w.isConnected).length,
      'totalFalls': _fallEvents.length,
      'recentFalls': _fallEvents
          .where((f) => DateTime.now().difference(f.timestamp).inDays < 7)
          .length,
      'averageBattery': _connectedWatches.isNotEmpty
          ? _connectedWatches.fold<int>(0, (sum, w) => sum + w.batteryLevel) /
          _connectedWatches.length
          : 0,
    };
  }

  /// Settings
  bool isPanicButtonEnabled() => _panicButtonEnabled;
  bool isFallDetectionEnabled() => _fallDetectionEnabled;
  double getFallSensitivity() => _fallSensitivity;
  bool isHapticFeedbackEnabled() => _hapticFeedbackEnabled;
  bool isSilentModeSupported() => _silentModeSupport;
  int getHeartRateThreshold() => _heartRateThreshold;

  Future<void> updateSettings({
    bool? panicButton,
    bool? fallDetection,
    double? fallSensitivity,
    bool? hapticFeedback,
    bool? silentMode,
    int? heartRateThreshold,
  }) async {
    if (panicButton != null) _panicButtonEnabled = panicButton;
    if (fallDetection != null) _fallDetectionEnabled = fallDetection;
    if (fallSensitivity != null) _fallSensitivity = fallSensitivity;
    if (hapticFeedback != null) _hapticFeedbackEnabled = hapticFeedback;
    if (silentMode != null) _silentModeSupport = silentMode;
    if (heartRateThreshold != null) _heartRateThreshold = heartRateThreshold;
    await _saveSettings();
  }

  /// Get watch icon
  IconData getWatchIcon(WatchType type) {
    switch (type) {
      case WatchType.appleWatch:
        return Icons.watch;
      case WatchType.wearOS:
        return Icons.watch_outlined;
      case WatchType.samsungGalaxy:
        return Icons.watch;
      default:
        return Icons.watch_off;
    }
  }

  /// Get watch color
  Color getWatchColor(WatchType type) {
    switch (type) {
      case WatchType.appleWatch:
        return Colors.white;
      case WatchType.wearOS:
        return Colors.blue;
      case WatchType.samsungGalaxy:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Private methods
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      syncWithWatch();
    });
  }

  String _getHapticPattern(String title) {
    if (title.contains('Emergency') || title.contains('Alert')) {
      return 'Strong-Strong-Strong';
    } else if (title.contains('Reminder')) {
      return 'Light-Light';
    }
    return 'Medium';
  }

  /// Storage methods
  Future<void> _loadWatches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final watchesJson = prefs.getStringList(_watchesKey);
      if (watchesJson != null) {
        _connectedWatches = watchesJson
            .map((str) => ConnectedWatch.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load watches error: $e');
    }
  }

  Future<void> _saveWatches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final watchesJson =
      _connectedWatches.map((w) => json.encode(w.toJson())).toList();
      await prefs.setStringList(_watchesKey, watchesJson);
    } catch (e) {
      debugPrint(' Save watches error: $e');
    }
  }

  Future<void> _loadFallEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getStringList(_fallEventsKey);
      if (eventsJson != null) {
        _fallEvents = eventsJson
            .map((str) => FallEvent.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load fall events error: $e');
    }
  }

  Future<void> _saveFallEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson =
      _fallEvents.map((e) => json.encode(e.toJson())).toList();
      await prefs.setStringList(_fallEventsKey, eventsJson);
    } catch (e) {
      debugPrint(' Save fall events error: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson != null) {
        final settings = json.decode(settingsJson);
        _panicButtonEnabled = settings['panicButtonEnabled'] ?? true;
        _fallDetectionEnabled = settings['fallDetectionEnabled'] ?? true;
        _fallSensitivity = settings['fallSensitivity'] ?? 0.7;
        _hapticFeedbackEnabled = settings['hapticFeedbackEnabled'] ?? true;
        _silentModeSupport = settings['silentModeSupport'] ?? true;
        _heartRateThreshold = settings['heartRateThreshold'] ?? 120;
      }
    } catch (e) {
      debugPrint(' Load settings error: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = {
        'panicButtonEnabled': _panicButtonEnabled,
        'fallDetectionEnabled': _fallDetectionEnabled,
        'fallSensitivity': _fallSensitivity,
        'hapticFeedbackEnabled': _hapticFeedbackEnabled,
        'silentModeSupport': _silentModeSupport,
        'heartRateThreshold': _heartRateThreshold,
      };
      await prefs.setString(_settingsKey, json.encode(settings));
    } catch (e) {
      debugPrint(' Save settings error: $e');
    }
  }

  /// Dispose
  void dispose() {
    _syncTimer?.cancel();
  }
}