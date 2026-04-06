import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum AgeMode {
  standard,
  kid,
  senior,
}

class SchoolZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String arrivalTime;
  final String departureTime;
  final List<String> weekdays;

  SchoolZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.arrivalTime,
    required this.departureTime,
    required this.weekdays,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'radiusMeters': radiusMeters,
    'arrivalTime': arrivalTime,
    'departureTime': departureTime,
    'weekdays': weekdays,
  };

  factory SchoolZone.fromJson(Map<String, dynamic> json) => SchoolZone(
    id: json['id'],
    name: json['name'],
    latitude: json['latitude'],
    longitude: json['longitude'],
    radiusMeters: json['radiusMeters'],
    arrivalTime: json['arrivalTime'],
    departureTime: json['departureTime'],
    weekdays: List<String>.from(json['weekdays']),
  );
}

class ParentalControl {
  final bool requireApprovalForContacts;
  final bool restrictedMode;
  final List<String> allowedContacts;
  final bool disableEmergencyDataWipe;
  final bool locationAlwaysOn;
  final int maxPanicButtonUsesPerDay;

  ParentalControl({
    this.requireApprovalForContacts = true,
    this.restrictedMode = false,
    this.allowedContacts = const [],
    this.disableEmergencyDataWipe = true,
    this.locationAlwaysOn = true,
    this.maxPanicButtonUsesPerDay = 10,
  });

  Map<String, dynamic> toJson() => {
    'requireApprovalForContacts': requireApprovalForContacts,
    'restrictedMode': restrictedMode,
    'allowedContacts': allowedContacts,
    'disableEmergencyDataWipe': disableEmergencyDataWipe,
    'locationAlwaysOn': locationAlwaysOn,
    'maxPanicButtonUsesPerDay': maxPanicButtonUsesPerDay,
  };

  factory ParentalControl.fromJson(Map<String, dynamic> json) =>
      ParentalControl(
        requireApprovalForContacts:
        json['requireApprovalForContacts'] ?? true,
        restrictedMode: json['restrictedMode'] ?? false,
        allowedContacts: List<String>.from(json['allowedContacts'] ?? []),
        disableEmergencyDataWipe: json['disableEmergencyDataWipe'] ?? true,
        locationAlwaysOn: json['locationAlwaysOn'] ?? true,
        maxPanicButtonUsesPerDay: json['maxPanicButtonUsesPerDay'] ?? 10,
      );
}

class KidModeSettings {
  final bool gamificationEnabled;
  final int safetyPoints;
  final List<String> earnedBadges;
  final bool parentalApprovalRequired;
  final bool simplifiedUI;

  KidModeSettings({
    this.gamificationEnabled = true,
    this.safetyPoints = 0,
    this.earnedBadges = const [],
    this.parentalApprovalRequired = true,
    this.simplifiedUI = true,
  });

  Map<String, dynamic> toJson() => {
    'gamificationEnabled': gamificationEnabled,
    'safetyPoints': safetyPoints,
    'earnedBadges': earnedBadges,
    'parentalApprovalRequired': parentalApprovalRequired,
    'simplifiedUI': simplifiedUI,
  };

  factory KidModeSettings.fromJson(Map<String, dynamic> json) =>
      KidModeSettings(
        gamificationEnabled: json['gamificationEnabled'] ?? true,
        safetyPoints: json['safetyPoints'] ?? 0,
        earnedBadges: List<String>.from(json['earnedBadges'] ?? []),
        parentalApprovalRequired: json['parentalApprovalRequired'] ?? true,
        simplifiedUI: json['simplifiedUI'] ?? true,
      );
}

class SeniorModeSettings {
  final double textSize;
  final bool voiceControlEnabled;
  final bool medicationReminders;
  final List<String> medicationSchedule;
  final bool fallDetectionSensitive;
  final bool largeButtonsEnabled;

  SeniorModeSettings({
    this.textSize = 1.5,
    this.voiceControlEnabled = true,
    this.medicationReminders = true,
    this.medicationSchedule = const [],
    this.fallDetectionSensitive = true,
    this.largeButtonsEnabled = true,
  });

  Map<String, dynamic> toJson() => {
    'textSize': textSize,
    'voiceControlEnabled': voiceControlEnabled,
    'medicationReminders': medicationReminders,
    'medicationSchedule': medicationSchedule,
    'fallDetectionSensitive': fallDetectionSensitive,
    'largeButtonsEnabled': largeButtonsEnabled,
  };

  factory SeniorModeSettings.fromJson(Map<String, dynamic> json) =>
      SeniorModeSettings(
        textSize: json['textSize'] ?? 1.5,
        voiceControlEnabled: json['voiceControlEnabled'] ?? true,
        medicationReminders: json['medicationReminders'] ?? true,
        medicationSchedule:
        List<String>.from(json['medicationSchedule'] ?? []),
        fallDetectionSensitive: json['fallDetectionSensitive'] ?? true,
        largeButtonsEnabled: json['largeButtonsEnabled'] ?? true,
      );
}

class AgeModeService {
  static final AgeModeService _instance = AgeModeService._internal();
  factory AgeModeService() => _instance;
  AgeModeService._internal();

  static const String _ageModeKey = 'age_mode';
  static const String _schoolZonesKey = 'school_zones';
  static const String _parentalControlKey = 'parental_control';
  static const String _kidSettingsKey = 'kid_mode_settings';
  static const String _seniorSettingsKey = 'senior_mode_settings';
  static const String _userAgeKey = 'user_age';

  AgeMode _currentMode = AgeMode.standard;
  List<SchoolZone> _schoolZones = [];
  ParentalControl _parentalControl = ParentalControl();
  KidModeSettings _kidSettings = KidModeSettings();
  SeniorModeSettings _seniorSettings = SeniorModeSettings();
  int _userAge = 25;

  /// Initialize service
  Future<void> initialize() async {
    await _loadSettings();
    debugPrint(' Age Mode Service initialized: $_currentMode');
  }

  /// Get current mode
  AgeMode getCurrentMode() => _currentMode;

  /// Set age mode
  Future<void> setAgeMode(AgeMode mode) async {
    _currentMode = mode;
    await _saveSettings();
    debugPrint(' Age mode changed to: $mode');
  }

  /// Auto-detect mode based on age
  Future<void> autoDetectMode() async {
    if (_userAge < 13) {
      await setAgeMode(AgeMode.kid);
    } else if (_userAge >= 65) {
      await setAgeMode(AgeMode.senior);
    } else {
      await setAgeMode(AgeMode.standard);
    }
  }

  /// Get/Set user age
  int getUserAge() => _userAge;

  Future<void> setUserAge(int age) async {
    _userAge = age;
    await _saveSettings();
    await autoDetectMode();
  }

  /// School Zones
  List<SchoolZone> getSchoolZones() => _schoolZones;

  Future<void> addSchoolZone(SchoolZone zone) async {
    _schoolZones.add(zone);
    await _saveSchoolZones();
    debugPrint(' School zone added: ${zone.name}');
  }

  Future<void> removeSchoolZone(String zoneId) async {
    _schoolZones.removeWhere((z) => z.id == zoneId);
    await _saveSchoolZones();
    debugPrint(' School zone removed');
  }

  /// Parental Controls
  ParentalControl getParentalControl() => _parentalControl;

  Future<void> updateParentalControl(ParentalControl control) async {
    _parentalControl = control;
    await _saveParentalControl();
    debugPrint(' Parental controls updated');
  }

  /// Kid Mode Settings
  KidModeSettings getKidSettings() => _kidSettings;

  Future<void> updateKidSettings(KidModeSettings settings) async {
    _kidSettings = settings;
    await _saveKidSettings();
    debugPrint(' Kid mode settings updated');
  }

  Future<void> addSafetyPoints(int points) async {
    _kidSettings = KidModeSettings(
      gamificationEnabled: _kidSettings.gamificationEnabled,
      safetyPoints: _kidSettings.safetyPoints + points,
      earnedBadges: _kidSettings.earnedBadges,
      parentalApprovalRequired: _kidSettings.parentalApprovalRequired,
      simplifiedUI: _kidSettings.simplifiedUI,
    );
    await _saveKidSettings();
    debugPrint(' +$points safety points! Total: ${_kidSettings.safetyPoints}');
  }

  Future<void> earnBadge(String badgeName) async {
    if (!_kidSettings.earnedBadges.contains(badgeName)) {
      final updatedBadges = List<String>.from(_kidSettings.earnedBadges)
        ..add(badgeName);
      _kidSettings = KidModeSettings(
        gamificationEnabled: _kidSettings.gamificationEnabled,
        safetyPoints: _kidSettings.safetyPoints,
        earnedBadges: updatedBadges,
        parentalApprovalRequired: _kidSettings.parentalApprovalRequired,
        simplifiedUI: _kidSettings.simplifiedUI,
      );
      await _saveKidSettings();
      debugPrint(' Badge earned: $badgeName');
    }
  }

  /// Senior Mode Settings
  SeniorModeSettings getSeniorSettings() => _seniorSettings;

  Future<void> updateSeniorSettings(SeniorModeSettings settings) async {
    _seniorSettings = settings;
    await _saveSeniorSettings();
    debugPrint(' Senior mode settings updated');
  }

  /// Check if in school zone
  bool isInSchoolZone(double latitude, double longitude) {
    // In real app, would calculate distance
    return _schoolZones.isNotEmpty;
  }

  /// Get UI theme based on mode
  ThemeData getThemeForMode() {
    switch (_currentMode) {
      case AgeMode.kid:
        return ThemeData.dark().copyWith(
          primaryColor: Colors.blue,
          colorScheme: const ColorScheme.dark(
            primary: Colors.blue,
            secondary: Colors.orange,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(fontSize: 18),
            bodyMedium: TextStyle(fontSize: 16),
          ),
        );
      case AgeMode.senior:
        return ThemeData.dark().copyWith(
          primaryColor: const Color(0xFF00BFA5),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00BFA5),
            secondary: Colors.orange,
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(fontSize: 20 * _seniorSettings.textSize),
            bodyMedium: TextStyle(fontSize: 18 * _seniorSettings.textSize),
          ),
        );
      case AgeMode.standard:
      default:
        return ThemeData.dark().copyWith(
          primaryColor: const Color(0xFF00BFA5),
        );
    }
  }

  /// Get available badges for kids
  List<Map<String, dynamic>> getAvailableBadges() {
    return [
      {
        'id': 'first_checkin',
        'name': 'First Check-In',
        'description': 'Complete your first safety check-in',
        'icon': Icons.check_circle,
        'earned': _kidSettings.earnedBadges.contains('first_checkin'),
      },
      {
        'id': 'safety_streak_7',
        'name': '7-Day Streak',
        'description': 'Check in every day for 7 days',
        'icon': Icons.local_fire_department,
        'earned': _kidSettings.earnedBadges.contains('safety_streak_7'),
      },
      {
        'id': 'location_sharer',
        'name': 'Location Sharer',
        'description': 'Share your location with family',
        'icon': Icons.location_on,
        'earned': _kidSettings.earnedBadges.contains('location_sharer'),
      },
      {
        'id': 'emergency_ready',
        'name': 'Emergency Ready',
        'description': 'Add 3 emergency contacts',
        'icon': Icons.contacts,
        'earned': _kidSettings.earnedBadges.contains('emergency_ready'),
      },
      {
        'id': 'safety_expert',
        'name': 'Safety Expert',
        'description': 'Complete all safety tutorials',
        'icon': Icons.school,
        'earned': _kidSettings.earnedBadges.contains('safety_expert'),
      },
    ];
  }

  /// Storage methods
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load age mode
      final modeIndex = prefs.getInt(_ageModeKey) ?? 0;
      _currentMode = AgeMode.values[modeIndex];

      // Load user age
      _userAge = prefs.getInt(_userAgeKey) ?? 25;

      // Load school zones
      final zonesJson = prefs.getStringList(_schoolZonesKey);
      if (zonesJson != null) {
        _schoolZones = zonesJson
            .map((str) => SchoolZone.fromJson(json.decode(str)))
            .toList();
      }

      // Load parental control
      final controlJson = prefs.getString(_parentalControlKey);
      if (controlJson != null) {
        _parentalControl = ParentalControl.fromJson(json.decode(controlJson));
      }

      // Load kid settings
      final kidJson = prefs.getString(_kidSettingsKey);
      if (kidJson != null) {
        _kidSettings = KidModeSettings.fromJson(json.decode(kidJson));
      }

      // Load senior settings
      final seniorJson = prefs.getString(_seniorSettingsKey);
      if (seniorJson != null) {
        _seniorSettings = SeniorModeSettings.fromJson(json.decode(seniorJson));
      }
    } catch (e) {
      debugPrint(' Load age mode settings error: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_ageModeKey, _currentMode.index);
      await prefs.setInt(_userAgeKey, _userAge);
    } catch (e) {
      debugPrint(' Save age mode error: $e');
    }
  }

  Future<void> _saveSchoolZones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final zonesJson = _schoolZones.map((z) => json.encode(z.toJson())).toList();
      await prefs.setStringList(_schoolZonesKey, zonesJson);
    } catch (e) {
      debugPrint(' Save school zones error: $e');
    }
  }

  Future<void> _saveParentalControl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _parentalControlKey, json.encode(_parentalControl.toJson()));
    } catch (e) {
      debugPrint(' Save parental control error: $e');
    }
  }

  Future<void> _saveKidSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kidSettingsKey, json.encode(_kidSettings.toJson()));
    } catch (e) {
      debugPrint(' Save kid settings error: $e');
    }
  }

  Future<void> _saveSeniorSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _seniorSettingsKey, json.encode(_seniorSettings.toJson()));
    } catch (e) {
      debugPrint(' Save senior settings error: $e');
    }
  }
}