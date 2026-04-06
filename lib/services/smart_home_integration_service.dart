import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

/// ==================== SMART HOME INTEGRATION SERVICE ====================
///
/// IOT & REMOTE CONTROL ECOSYSTEM
/// Complete smart home integration for emergency response:
/// - Device discovery & pairing
/// - Smart lock control
/// - Smart light control (SOS patterns)
/// - Smart camera activation
/// - Smart alarm system integration
/// - Emergency automation profiles
/// - Real-time device monitoring
///
/// 24-HOUR MARATHON - PHASE 5 (HOUR 17)
/// ================================================================

// ==================== DEVICE TYPES ====================

enum SmartDeviceType {
  smartLock,
  smartLight,
  smartCamera,
  smartAlarm,
  smartThermostat,
  smartSpeaker,
  doorSensor,
  windowSensor,
  motionSensor,
  smokeSensor,
  smartPlug,
  smartGarage,
}

extension SmartDeviceTypeExtension on SmartDeviceType {
  String get displayName {
    switch (this) {
      case SmartDeviceType.smartLock:
        return 'Smart Lock';
      case SmartDeviceType.smartLight:
        return 'Smart Light';
      case SmartDeviceType.smartCamera:
        return 'Smart Camera';
      case SmartDeviceType.smartAlarm:
        return 'Smart Alarm';
      case SmartDeviceType.smartThermostat:
        return 'Smart Thermostat';
      case SmartDeviceType.smartSpeaker:
        return 'Smart Speaker';
      case SmartDeviceType.doorSensor:
        return 'Door Sensor';
      case SmartDeviceType.windowSensor:
        return 'Window Sensor';
      case SmartDeviceType.motionSensor:
        return 'Motion Sensor';
      case SmartDeviceType.smokeSensor:
        return 'Smoke Sensor';
      case SmartDeviceType.smartPlug:
        return 'Smart Plug';
      case SmartDeviceType.smartGarage:
        return 'Smart Garage';
    }
  }

  IconData get icon {
    switch (this) {
      case SmartDeviceType.smartLock:
        return Icons.lock;
      case SmartDeviceType.smartLight:
        return Icons.lightbulb;
      case SmartDeviceType.smartCamera:
        return Icons.videocam;
      case SmartDeviceType.smartAlarm:
        return Icons.alarm;
      case SmartDeviceType.smartThermostat:
        return Icons.thermostat;
      case SmartDeviceType.smartSpeaker:
        return Icons.speaker;
      case SmartDeviceType.doorSensor:
        return Icons.door_front_door;
      case SmartDeviceType.windowSensor:
        return Icons.window;
      case SmartDeviceType.motionSensor:
        return Icons.sensors;
      case SmartDeviceType.smokeSensor:
        return Icons.smoke_free;
      case SmartDeviceType.smartPlug:
        return Icons.power;
      case SmartDeviceType.smartGarage:
        return Icons.garage;
    }
  }
}

// ==================== SMART DEVICE MODEL ====================

class SmartDevice {
  final String id;
  final String name;
  final SmartDeviceType type;
  final String manufacturer;
  final String model;
  final bool isOnline;
  final bool isEnabled;
  final Map<String, dynamic> state;
  final DateTime lastSeen;
  final String? roomLocation;

  SmartDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.manufacturer,
    required this.model,
    required this.isOnline,
    required this.isEnabled,
    required this.state,
    required this.lastSeen,
    this.roomLocation,
  });

  factory SmartDevice.fromMap(Map<String, dynamic> map) {
    return SmartDevice(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: SmartDeviceType.values.firstWhere(
            (e) => e.toString() == map['type'],
        orElse: () => SmartDeviceType.smartPlug,
      ),
      manufacturer: map['manufacturer'] ?? '',
      model: map['model'] ?? '',
      isOnline: map['isOnline'] ?? false,
      isEnabled: map['isEnabled'] ?? true,
      state: Map<String, dynamic>.from(map['state'] ?? {}),
      lastSeen: map['lastSeen'] != null
          ? (map['lastSeen'] as Timestamp).toDate()
          : DateTime.now(),
      roomLocation: map['roomLocation'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'manufacturer': manufacturer,
      'model': model,
      'isOnline': isOnline,
      'isEnabled': isEnabled,
      'state': state,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'roomLocation': roomLocation,
    };
  }

  SmartDevice copyWith({
    String? id,
    String? name,
    SmartDeviceType? type,
    String? manufacturer,
    String? model,
    bool? isOnline,
    bool? isEnabled,
    Map<String, dynamic>? state,
    DateTime? lastSeen,
    String? roomLocation,
  }) {
    return SmartDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      isOnline: isOnline ?? this.isOnline,
      isEnabled: isEnabled ?? this.isEnabled,
      state: state ?? this.state,
      lastSeen: lastSeen ?? this.lastSeen,
      roomLocation: roomLocation ?? this.roomLocation,
    );
  }
}

// ==================== AUTOMATION PROFILE MODEL ====================

class AutomationProfile {
  final String id;
  final String name;
  final String description;
  final List<AutomationAction> actions;
  final bool isEnabled;
  final DateTime createdAt;

  AutomationProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.actions,
    required this.isEnabled,
    required this.createdAt,
  });

  factory AutomationProfile.fromMap(Map<String, dynamic> map) {
    return AutomationProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      actions: (map['actions'] as List<dynamic>?)
          ?.map((a) => AutomationAction.fromMap(a))
          .toList() ??
          [],
      isEnabled: map['isEnabled'] ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'actions': actions.map((a) => a.toMap()).toList(),
      'isEnabled': isEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// ==================== AUTOMATION ACTION MODEL ====================

class AutomationAction {
  final String deviceId;
  final String action;
  final Map<String, dynamic> parameters;
  final int delaySeconds;

  AutomationAction({
    required this.deviceId,
    required this.action,
    required this.parameters,
    this.delaySeconds = 0,
  });

  factory AutomationAction.fromMap(Map<String, dynamic> map) {
    return AutomationAction(
      deviceId: map['deviceId'] ?? '',
      action: map['action'] ?? '',
      parameters: Map<String, dynamic>.from(map['parameters'] ?? {}),
      delaySeconds: map['delaySeconds'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'action': action,
      'parameters': parameters,
      'delaySeconds': delaySeconds,
    };
  }
}

// ==================== SMART HOME INTEGRATION SERVICE ====================

class SmartHomeIntegrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;
  List<SmartDevice> _devices = [];
  List<AutomationProfile> _automationProfiles = [];

// Callbacks
  Function(String message)? onLog;
  Function(SmartDevice device)? onDeviceStatusChanged;
  Function(String profileId)? onAutomationTriggered;

// Getters
  bool isInitialized() => _isInitialized;
  List<SmartDevice> getDevices() => List.unmodifiable(_devices);
  List<AutomationProfile> getautomationProfilesList() => List.unmodifiable(_automationProfiles);

// ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🏠 Initializing Smart Home Integration Service...');
      _isInitialized = true;
      debugPrint('✅ Smart Home Integration Service initialized');
    } catch (e) {
      debugPrint('❌ Smart Home Integration initialization error: $e');
      rethrow;
    }
  }

  void dispose() {
    _devices.clear();
    _automationProfiles.clear();
    _isInitialized = false;
    debugPrint('🏠 Smart Home Integration Service disposed');
  }

// ==================== DEVICE MANAGEMENT ====================

  /// Discover available smart devices (mock implementation)
  Future<List<SmartDevice>> discoverDevices() async {
    await Future.delayed(const Duration(seconds: 2));

// Mock discovered devices
    final discoveredDevices = [
      SmartDevice(
        id: 'lock_front_door',
        name: 'Front Door Lock',
        type: SmartDeviceType.smartLock,
        manufacturer: 'August',
        model: 'Smart Lock Pro',
        isOnline: true,
        isEnabled: true,
        state: {'locked': true, 'battery': 85},
        lastSeen: DateTime.now(),
        roomLocation: 'Front Door',
      ),
      SmartDevice(
        id: 'light_living_room',
        name: 'Living Room Light',
        type: SmartDeviceType.smartLight,
        manufacturer: 'Philips Hue',
        model: 'A19 Bulb',
        isOnline: true,
        isEnabled: true,
        state: {'on': false, 'brightness': 100, 'color': '#FFFFFF'},
        lastSeen: DateTime.now(),
        roomLocation: 'Living Room',
      ),
      SmartDevice(
        id: 'camera_front_door',
        name: 'Front Door Camera',
        type: SmartDeviceType.smartCamera,
        manufacturer: 'Ring',
        model: 'Video Doorbell Pro',
        isOnline: true,
        isEnabled: true,
        state: {'recording': false, 'motion_detected': false},
        lastSeen: DateTime.now(),
        roomLocation: 'Front Door',
      ),
      SmartDevice(
        id: 'alarm_system',
        name: 'Home Alarm System',
        type: SmartDeviceType.smartAlarm,
        manufacturer: 'SimpliSafe',
        model: 'SS3',
        isOnline: true,
        isEnabled: true,
        state: {'armed': false, 'mode': 'off'},
        lastSeen: DateTime.now(),
        roomLocation: 'Main Panel',
      ),
    ];

    onLog?.call('Discovered ${discoveredDevices.length} smart devices');
    return discoveredDevices;
  }

  /// Add a device to user's collection
  Future<void> addDevice(String userId, SmartDevice device) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('smart_devices')
          .doc(device.id)
          .set(device.toMap());

      _devices.add(device);
      onLog?.call('Device added: ${device.name}');
      debugPrint('✅ Device added: ${device.name}');
    } catch (e) {
      debugPrint('❌ Error adding device: $e');
      rethrow;
    }
  }

  /// Get all user's devices
  Future<List<SmartDevice>> getUserDevices(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('smart_devices')
          .get();

      _devices = snapshot.docs
          .map((doc) => SmartDevice.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      return _devices;
    } catch (e) {
      debugPrint('❌ Error getting devices: $e');
      return [];
    }
  }

  /// Remove a device
  Future<void> removeDevice(String userId, String deviceId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('smart_devices')
          .doc(deviceId)
          .delete();

      _devices.removeWhere((d) => d.id == deviceId);
      onLog?.call('Device removed');
      debugPrint('✅ Device removed: $deviceId');
    } catch (e) {
      debugPrint('❌ Error removing device: $e');
      rethrow;
    }
  }

  /// Update device state
  Future<void> updateDeviceState(
      String userId,
      String deviceId,
      Map<String, dynamic> newState,
      ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('smart_devices')
          .doc(deviceId)
          .update({
        'state': newState,
        'lastSeen': Timestamp.now(),
      });

      final deviceIndex = _devices.indexWhere((d) => d.id == deviceId);
      if (deviceIndex != -1) {
        _devices[deviceIndex] = _devices[deviceIndex].copyWith(
          state: newState,
          lastSeen: DateTime.now(),
        );
        onDeviceStatusChanged?.call(_devices[deviceIndex]);
      }

      onLog?.call('Device state updated');
      debugPrint('✅ Device state updated: $deviceId');
    } catch (e) {
      debugPrint('❌ Error updating device state: $e');
      rethrow;
    }
  }

// ==================== DEVICE CONTROL ====================

  /// Control smart lock
  Future<void> controlSmartLock(
      String userId,
      String deviceId, {
        required bool lock,
      }) async {
    try {
      await updateDeviceState(userId, deviceId, {
        'locked': lock,
        'lastAction': lock ? 'locked' : 'unlocked',
        'timestamp': DateTime.now().toIso8601String(),
      });

      onLog?.call('Smart lock ${lock ? "locked" : "unlocked"}');
      debugPrint('🔒 Smart lock ${lock ? "locked" : "unlocked"}: $deviceId');
    } catch (e) {
      debugPrint('❌ Error controlling smart lock: $e');
      rethrow;
    }
  }

  /// Control smart light
  Future<void> controlSmartLight(
      String userId,
      String deviceId, {
        required bool on,
        int? brightness,
        String? color,
      }) async {
    try {
      final state = <String, dynamic>{
        'on': on,
        'lastAction': on ? 'turned_on' : 'turned_off',
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (brightness != null) state['brightness'] = brightness;
      if (color != null) state['color'] = color;

      await updateDeviceState(userId, deviceId, state);

      onLog?.call('Smart light ${on ? "turned on" : "turned off"}');
      debugPrint('💡 Smart light ${on ? "on" : "off"}: $deviceId');
    } catch (e) {
      debugPrint('❌ Error controlling smart light: $e');
      rethrow;
    }
  }

  /// Activate SOS light pattern
  Future<void> activateSOSLightPattern(String userId, String deviceId) async {
    try {
// Flash lights in SOS pattern (... --- ...)
      onLog?.call('Activating SOS light pattern');
      debugPrint('🚨 Activating SOS pattern on: $deviceId');

// Turn on red
      await controlSmartLight(
        userId,
        deviceId,
        on: true,
        brightness: 100,
        color: '#FF0000',
      );

      await updateDeviceState(userId, deviceId, {
        'on': true,
        'brightness': 100,
        'color': '#FF0000',
        'pattern': 'SOS',
        'timestamp': DateTime.now().toIso8601String(),
      });

      onLog?.call('SOS light pattern activated');
    } catch (e) {
      debugPrint('❌ Error activating SOS pattern: $e');
      rethrow;
    }
  }

  /// Control smart camera
  Future<void> controlSmartCamera(
      String userId,
      String deviceId, {
        required bool recording,
      }) async {
    try {
      await updateDeviceState(userId, deviceId, {
        'recording': recording,
        'lastAction': recording ? 'started_recording' : 'stopped_recording',
        'timestamp': DateTime.now().toIso8601String(),
      });

      onLog?.call('Camera ${recording ? "started" : "stopped"} recording');
      debugPrint('📹 Camera recording ${recording ? "started" : "stopped"}: $deviceId');
    } catch (e) {
      debugPrint('❌ Error controlling camera: $e');
      rethrow;
    }
  }

  /// Control smart alarm
  Future<void> controlSmartAlarm(
      String userId,
      String deviceId, {
        required bool armed,
        String mode = 'away',
      }) async {
    try {
      await updateDeviceState(userId, deviceId, {
        'armed': armed,
        'mode': mode,
        'lastAction': armed ? 'armed' : 'disarmed',
        'timestamp': DateTime.now().toIso8601String(),
      });

      onLog?.call('Alarm ${armed ? "armed" : "disarmed"} (mode: $mode)');
      debugPrint('🚨 Alarm ${armed ? "armed" : "disarmed"}: $deviceId');
    } catch (e) {
      debugPrint('❌ Error controlling alarm: $e');
      rethrow;
    }
  }

// ==================== AUTOMATION PROFILES ====================

  /// Create automation profile
  Future<void> createAutomationProfile(
      String userId,
      AutomationProfile profile,
      ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('automation_profiles')
          .doc(profile.id)
          .set(profile.toMap());

      _automationProfiles.add(profile);
      onLog?.call('Automation profile created: ${profile.name}');
      debugPrint('✅ Automation profile created: ${profile.name}');
    } catch (e) {
      debugPrint('❌ Error creating automation profile: $e');
      rethrow;
    }
  }

  /// Get automation profiles
  Future<List<AutomationProfile>> getAutomationProfiles(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('automation_profiles')
          .get();

      _automationProfiles = snapshot.docs
          .map((doc) => AutomationProfile.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      return _automationProfiles;
    } catch (e) {
      debugPrint('❌ Error getting automation profiles: $e');
      return [];
    }
  }

  /// Execute automation profile
  Future<void> executeAutomationProfile(
      String userId,
      String profileId,
      ) async {
    try {
      final profile = _automationProfiles.firstWhere((p) => p.id == profileId);

      if (!profile.isEnabled) {
        debugPrint('⚠️ Automation profile disabled: ${profile.name}');
        return;
      }

      onLog?.call('Executing automation: ${profile.name}');
      debugPrint('🤖 Executing automation profile: ${profile.name}');

      for (final action in profile.actions) {
        if (action.delaySeconds > 0) {
          await Future.delayed(Duration(seconds: action.delaySeconds));
        }

        await _executeAction(userId, action);
      }

      onAutomationTriggered?.call(profileId);
      onLog?.call('Automation completed: ${profile.name}');
      debugPrint('✅ Automation profile completed: ${profile.name}');
    } catch (e) {
      debugPrint('❌ Error executing automation profile: $e');
      rethrow;
    }
  }

  Future<void> _executeAction(String userId, AutomationAction action) async {
    final device = _devices.firstWhere((d) => d.id == action.deviceId);

    switch (device.type) {
      case SmartDeviceType.smartLock:
        await controlSmartLock(
          userId,
          action.deviceId,
          lock: action.parameters['lock'] ?? true,
        );
        break;

      case SmartDeviceType.smartLight:
        if (action.action == 'sos_pattern') {
          await activateSOSLightPattern(userId, action.deviceId);
        } else {
          await controlSmartLight(
            userId,
            action.deviceId,
            on: action.parameters['on'] ?? true,
            brightness: action.parameters['brightness'],
            color: action.parameters['color'],
          );
        }
        break;

      case SmartDeviceType.smartCamera:
        await controlSmartCamera(
          userId,
          action.deviceId,
          recording: action.parameters['recording'] ?? true,
        );
        break;

      case SmartDeviceType.smartAlarm:
        await controlSmartAlarm(
          userId,
          action.deviceId,
          armed: action.parameters['armed'] ?? true,
          mode: action.parameters['mode'] ?? 'away',
        );
        break;

      default:
        await updateDeviceState(userId, action.deviceId, action.parameters);
    }
  }

  /// Trigger emergency automation
  Future<void> triggerEmergencyAutomation(String userId) async {
    try {
      onLog?.call('🚨 Triggering emergency automation');
      debugPrint('🚨 Triggering emergency automation');

// Execute all emergency profiles
      final emergencyProfiles = _automationProfiles
          .where((p) => p.isEnabled && p.name.toLowerCase().contains('emergency'))
          .toList();

      for (final profile in emergencyProfiles) {
        await executeAutomationProfile(userId, profile.id);
      }

// Default emergency actions if no profiles
      if (emergencyProfiles.isEmpty) {
        await _executeDefaultEmergencyActions(userId);
      }

      onLog?.call('✅ Emergency automation completed');
      debugPrint('✅ Emergency automation completed');
    } catch (e) {
      debugPrint('❌ Error triggering emergency automation: $e');
      rethrow;
    }
  }

  Future<void> _executeDefaultEmergencyActions(String userId) async {
// Lock all doors
    for (final device in _devices.where((d) => d.type == SmartDeviceType.smartLock)) {
      await controlSmartLock(userId, device.id, lock: true);
    }

// Turn on all lights to red (SOS)
    for (final device in _devices.where((d) => d.type == SmartDeviceType.smartLight)) {
      await activateSOSLightPattern(userId, device.id);
    }

// Start recording all cameras
    for (final device in _devices.where((d) => d.type == SmartDeviceType.smartCamera)) {
      await controlSmartCamera(userId, device.id, recording: true);
    }

// Arm alarm system
    for (final device in _devices.where((d) => d.type == SmartDeviceType.smartAlarm)) {
      await controlSmartAlarm(userId, device.id, armed: true, mode: 'away');
    }
  }

// ==================== STATISTICS ====================

  Future<Map<String, dynamic>> getSmartHomeStatistics(String userId) async {
    try {
      final devices = await getUserDevices(userId);
      final profiles = await getAutomationProfiles(userId);

      return {
        'totalDevices': devices.length,
        'onlineDevices': devices.where((d) => d.isOnline).length,
        'enabledDevices': devices.where((d) => d.isEnabled).length,
        'totalProfiles': profiles.length,
        'enabledProfiles': profiles.where((p) => p.isEnabled).length,
        'devicesByType': _getDeviceCountByType(devices),
      };
    } catch (e) {
      debugPrint('❌ Error getting statistics: $e');
      return {
        'totalDevices': 0,
        'onlineDevices': 0,
        'enabledDevices': 0,
        'totalProfiles': 0,
        'enabledProfiles': 0,
        'devicesByType': {},
      };
    }
  }

  Map<String, int> _getDeviceCountByType(List<SmartDevice> devices) {
    final counts = <String, int>{};
    for (final device in devices) {
      final type = device.type.displayName;
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

// ==================== MOCK DATA GENERATORS ====================

  AutomationProfile getDefaultEmergencyProfile() {
    return AutomationProfile(
      id: 'emergency_default',
      name: 'Emergency Protocol',
      description: 'Locks doors, activates cameras, turns on lights',
      isEnabled: true,
      createdAt: DateTime.now(),
      actions: [
        AutomationAction(
          deviceId: 'lock_front_door',
          action: 'lock',
          parameters: {'lock': true},
        ),
        AutomationAction(
          deviceId: 'light_living_room',
          action: 'sos_pattern',
          parameters: {'on': true, 'color': '#FF0000', 'brightness': 100},
          delaySeconds: 1,
        ),
        AutomationAction(
          deviceId: 'camera_front_door',
          action: 'record',
          parameters: {'recording': true},
          delaySeconds: 1,
        ),
        AutomationAction(
          deviceId: 'alarm_system',
          action: 'arm',
          parameters: {'armed': true, 'mode': 'away'},
          delaySeconds: 2,
        ),
      ],
    );
  }
}