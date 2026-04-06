import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

class FamilyMember {
  final String id;
  final String name;
  final String relationship; // parent, child, spouse, sibling, grandparent, etc.
  final String? photoUrl;
  final String? phoneNumber;
  final String? email;
  final DateTime? birthday;
  final LocationInfo? lastKnownLocation;
  final HealthStatus? healthStatus;
  final bool isPrimaryContact;
  final DateTime addedDate;

  FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    this.photoUrl,
    this.phoneNumber,
    this.email,
    this.birthday,
    this.lastKnownLocation,
    this.healthStatus,
    this.isPrimaryContact = false,
    required this.addedDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'relationship': relationship,
    'photoUrl': photoUrl,
    'phoneNumber': phoneNumber,
    'email': email,
    'birthday': birthday?.toIso8601String(),
    'lastKnownLocation': lastKnownLocation?.toJson(),
    'healthStatus': healthStatus?.toJson(),
    'isPrimaryContact': isPrimaryContact,
    'addedDate': addedDate.toIso8601String(),
  };

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: json['id'],
    name: json['name'],
    relationship: json['relationship'],
    photoUrl: json['photoUrl'],
    phoneNumber: json['phoneNumber'],
    email: json['email'],
    birthday:
    json['birthday'] != null ? DateTime.parse(json['birthday']) : null,
    lastKnownLocation: json['lastKnownLocation'] != null
        ? LocationInfo.fromJson(json['lastKnownLocation'])
        : null,
    healthStatus: json['healthStatus'] != null
        ? HealthStatus.fromJson(json['healthStatus'])
        : null,
    isPrimaryContact: json['isPrimaryContact'] ?? false,
    addedDate: DateTime.parse(json['addedDate']),
  );

  int get age {
    if (birthday == null) return 0;
    final now = DateTime.now();
    int age = now.year - birthday!.year;
    if (now.month < birthday!.month ||
        (now.month == birthday!.month && now.day < birthday!.day)) {
      age--;
    }
    return age;
  }
}

class LocationInfo {
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;
  final double? batteryLevel;

  LocationInfo({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
    this.batteryLevel,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'timestamp': timestamp.toIso8601String(),
    'batteryLevel': batteryLevel,
  };

  factory LocationInfo.fromJson(Map<String, dynamic> json) => LocationInfo(
    latitude: json['latitude'],
    longitude: json['longitude'],
    address: json['address'],
    timestamp: DateTime.parse(json['timestamp']),
    batteryLevel: json['batteryLevel'],
  );
}

class HealthStatus {
  final int? heartRate;
  final int? steps;
  final double? bodyTemperature;
  final String status; // good, warning, critical
  final DateTime lastUpdated;

  HealthStatus({
    this.heartRate,
    this.steps,
    this.bodyTemperature,
    required this.status,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'heartRate': heartRate,
    'steps': steps,
    'bodyTemperature': bodyTemperature,
    'status': status,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory HealthStatus.fromJson(Map<String, dynamic> json) => HealthStatus(
    heartRate: json['heartRate'],
    steps: json['steps'],
    bodyTemperature: json['bodyTemperature'],
    status: json['status'],
    lastUpdated: DateTime.parse(json['lastUpdated']),
  );

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
}

class CheckInRequest {
  final String id;
  final String memberId;
  final DateTime scheduledTime;
  final String message;
  bool isCompleted;
  DateTime? completedAt;

  CheckInRequest({
    required this.id,
    required this.memberId,
    required this.scheduledTime,
    required this.message,
    this.isCompleted = false,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'memberId': memberId,
    'scheduledTime': scheduledTime.toIso8601String(),
    'message': message,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory CheckInRequest.fromJson(Map<String, dynamic> json) =>
      CheckInRequest(
        id: json['id'],
        memberId: json['memberId'],
        scheduledTime: DateTime.parse(json['scheduledTime']),
        message: json['message'],
        isCompleted: json['isCompleted'] ?? false,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'])
            : null,
      );
}

class FamilyActivity {
  final String id;
  final String memberId;
  final String activityType; // check-in, alert, location-update, etc.
  final String description;
  final DateTime timestamp;

  FamilyActivity({
    required this.id,
    required this.memberId,
    required this.activityType,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'memberId': memberId,
    'activityType': activityType,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
  };

  factory FamilyActivity.fromJson(Map<String, dynamic> json) =>
      FamilyActivity(
        id: json['id'],
        memberId: json['memberId'],
        activityType: json['activityType'],
        description: json['description'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class FamilyDashboardService {
  static final FamilyDashboardService _instance =
  FamilyDashboardService._internal();
  factory FamilyDashboardService() => _instance;
  FamilyDashboardService._internal();

  static const String _membersKey = 'family_members';
  static const String _checkInsKey = 'check_in_requests';
  static const String _activitiesKey = 'family_activities';
  static const String _settingsKey = 'family_dashboard_settings';

  List<FamilyMember> _members = [];
  List<CheckInRequest> _checkInRequests = [];
  List<FamilyActivity> _activities = [];

  // Settings
  bool _autoCheckInEnabled = true;
  int _checkInIntervalHours = 12;
  bool _locationSharingEnabled = true;
  bool _healthMonitoringEnabled = true;

  /// Initialize service
  Future<void> initialize() async {
    await _loadMembers();
    await _loadCheckIns();
    await _loadActivities();
    await _loadSettings();
    _startPeriodicUpdates();
    debugPrint(' Family Dashboard Service initialized');
  }

  /// Get all family members
  List<FamilyMember> getAllMembers() => _members;

  /// Get member by ID
  FamilyMember? getMemberById(String id) {
    try {
      return _members.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Add family member
  Future<void> addMember(FamilyMember member) async {
    _members.add(member);
    await _saveMembers();

    // Add activity
    await _addActivity(FamilyActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      memberId: member.id,
      activityType: 'member-added',
      description: '${member.name} added to family',
      timestamp: DateTime.now(),
    ));

    debugPrint(' Family member added: ${member.name}');
  }

  /// Update family member
  Future<void> updateMember(FamilyMember updatedMember) async {
    final index = _members.indexWhere((m) => m.id == updatedMember.id);
    if (index != -1) {
      _members[index] = updatedMember;
      await _saveMembers();
      debugPrint(' Member updated: ${updatedMember.name}');
    }
  }

  /// Remove family member
  Future<void> removeMember(String memberId) async {
    _members.removeWhere((m) => m.id == memberId);
    await _saveMembers();
    debugPrint(' Member removed');
  }

  /// Request check-in from member
  Future<void> requestCheckIn(String memberId, String message) async {
    final member = getMemberById(memberId);
    if (member == null) return;

    final request = CheckInRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      memberId: memberId,
      scheduledTime: DateTime.now(),
      message: message,
    );

    _checkInRequests.add(request);
    await _saveCheckIns();

    await _addActivity(FamilyActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      memberId: memberId,
      activityType: 'check-in-requested',
      description: 'Check-in requested from ${member.name}',
      timestamp: DateTime.now(),
    ));

    debugPrint(' Check-in requested from ${member.name}');
  }

  /// Complete check-in
  Future<void> completeCheckIn(String requestId) async {
    final request = _checkInRequests.firstWhere((r) => r.id == requestId);
    request.isCompleted = true;
    request.completedAt = DateTime.now();
    await _saveCheckIns();

    final member = getMemberById(request.memberId);
    if (member != null) {
      await _addActivity(FamilyActivity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        memberId: request.memberId,
        activityType: 'check-in-completed',
        description: '${member.name} checked in',
        timestamp: DateTime.now(),
      ));
    }

    debugPrint(' Check-in completed');
  }

  /// Get pending check-ins
  List<CheckInRequest> getPendingCheckIns() {
    return _checkInRequests.where((r) => !r.isCompleted).toList();
  }

  /// Get recent activities
  List<FamilyActivity> getRecentActivities({int limit = 20}) {
    final sorted = List<FamilyActivity>.from(_activities)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(limit).toList();
  }

  /// Get activities for member
  List<FamilyActivity> getActivitiesForMember(String memberId) {
    return _activities
        .where((a) => a.memberId == memberId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Update member location (mock)
  Future<void> updateMemberLocation(String memberId) async {
    final member = getMemberById(memberId);
    if (member == null) return;

    // Mock location update
    final updatedMember = FamilyMember(
      id: member.id,
      name: member.name,
      relationship: member.relationship,
      photoUrl: member.photoUrl,
      phoneNumber: member.phoneNumber,
      email: member.email,
      birthday: member.birthday,
      lastKnownLocation: LocationInfo(
        latitude: 37.7749 + (DateTime.now().millisecond / 100000),
        longitude: -122.4194 + (DateTime.now().millisecond / 100000),
        address: '123 Main St, San Francisco, CA',
        timestamp: DateTime.now(),
        batteryLevel: 75.0,
      ),
      healthStatus: member.healthStatus,
      isPrimaryContact: member.isPrimaryContact,
      addedDate: member.addedDate,
    );

    await updateMember(updatedMember);

    await _addActivity(FamilyActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      memberId: memberId,
      activityType: 'location-updated',
      description: '${member.name} location updated',
      timestamp: DateTime.now(),
    ));
  }

  /// Get family statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalMembers': _members.length,
      'activeMembers': _members.where((m) {
        if (m.lastKnownLocation == null) return false;
        final diff = DateTime.now().difference(m.lastKnownLocation!.timestamp);
        return diff.inHours < 24;
      }).length,
      'pendingCheckIns': getPendingCheckIns().length,
      'recentActivities': _activities
          .where((a) =>
      DateTime.now().difference(a.timestamp).inDays < 7)
          .length,
      'children': _members.where((m) => m.relationship == 'child').length,
      'adults': _members.where((m) => m.relationship != 'child').length,
    };
  }

  /// Settings
  bool isAutoCheckInEnabled() => _autoCheckInEnabled;
  int getCheckInInterval() => _checkInIntervalHours;
  bool isLocationSharingEnabled() => _locationSharingEnabled;
  bool isHealthMonitoringEnabled() => _healthMonitoringEnabled;

  Future<void> updateSettings({
    bool? autoCheckIn,
    int? checkInInterval,
    bool? locationSharing,
    bool? healthMonitoring,
  }) async {
    if (autoCheckIn != null) _autoCheckInEnabled = autoCheckIn;
    if (checkInInterval != null) _checkInIntervalHours = checkInInterval;
    if (locationSharing != null) _locationSharingEnabled = locationSharing;
    if (healthMonitoring != null) _healthMonitoringEnabled = healthMonitoring;
    await _saveSettings();
  }

  /// Get relationship icon
  IconData getRelationshipIcon(String relationship) {
    switch (relationship.toLowerCase()) {
      case 'child':
      case 'son':
      case 'daughter':
        return Icons.child_care;
      case 'parent':
      case 'mother':
      case 'father':
        return Icons.face;
      case 'spouse':
      case 'partner':
        return Icons.favorite;
      case 'sibling':
      case 'brother':
      case 'sister':
        return Icons.people;
      case 'grandparent':
      case 'grandmother':
      case 'grandfather':
        return Icons.elderly;
      default:
        return Icons.person;
    }
  }

  /// Get relationship color
  Color getRelationshipColor(String relationship) {
    switch (relationship.toLowerCase()) {
      case 'child':
      case 'son':
      case 'daughter':
        return Colors.blue;
      case 'parent':
      case 'mother':
      case 'father':
        return Colors.green;
      case 'spouse':
      case 'partner':
        return Colors.pink;
      case 'sibling':
      case 'brother':
      case 'sister':
        return Colors.purple;
      case 'grandparent':
      case 'grandmother':
      case 'grandfather':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Private methods
  Future<void> _addActivity(FamilyActivity activity) async {
    _activities.add(activity);
    // Keep only last 100 activities
    if (_activities.length > 100) {
      _activities = _activities.sublist(_activities.length - 100);
    }
    await _saveActivities();
  }

  void _startPeriodicUpdates() {
    // Mock periodic location updates
    Timer.periodic(const Duration(minutes: 5), (timer) {
      for (final member in _members) {
        if (_locationSharingEnabled) {
          // In real app, would get actual location updates
        }
      }
    });
  }

  /// Storage methods
  Future<void> _loadMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final membersJson = prefs.getStringList(_membersKey);
      if (membersJson != null) {
        _members = membersJson
            .map((str) => FamilyMember.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load members error: $e');
    }
  }

  Future<void> _saveMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final membersJson =
      _members.map((m) => json.encode(m.toJson())).toList();
      await prefs.setStringList(_membersKey, membersJson);
    } catch (e) {
      debugPrint(' Save members error: $e');
    }
  }

  Future<void> _loadCheckIns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final checkInsJson = prefs.getStringList(_checkInsKey);
      if (checkInsJson != null) {
        _checkInRequests = checkInsJson
            .map((str) => CheckInRequest.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load check-ins error: $e');
    }
  }

  Future<void> _saveCheckIns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final checkInsJson =
      _checkInRequests.map((c) => json.encode(c.toJson())).toList();
      await prefs.setStringList(_checkInsKey, checkInsJson);
    } catch (e) {
      debugPrint(' Save check-ins error: $e');
    }
  }

  Future<void> _loadActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson = prefs.getStringList(_activitiesKey);
      if (activitiesJson != null) {
        _activities = activitiesJson
            .map((str) => FamilyActivity.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load activities error: $e');
    }
  }

  Future<void> _saveActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson =
      _activities.map((a) => json.encode(a.toJson())).toList();
      await prefs.setStringList(_activitiesKey, activitiesJson);
    } catch (e) {
      debugPrint(' Save activities error: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson != null) {
        final settings = json.decode(settingsJson);
        _autoCheckInEnabled = settings['autoCheckInEnabled'] ?? true;
        _checkInIntervalHours = settings['checkInIntervalHours'] ?? 12;
        _locationSharingEnabled = settings['locationSharingEnabled'] ?? true;
        _healthMonitoringEnabled = settings['healthMonitoringEnabled'] ?? true;
      }
    } catch (e) {
      debugPrint(' Load settings error: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = {
        'autoCheckInEnabled': _autoCheckInEnabled,
        'checkInIntervalHours': _checkInIntervalHours,
        'locationSharingEnabled': _locationSharingEnabled,
        'healthMonitoringEnabled': _healthMonitoringEnabled,
      };
      await prefs.setString(_settingsKey, json.encode(settings));
    } catch (e) {
      debugPrint(' Save settings error: $e');
    }
  }
}