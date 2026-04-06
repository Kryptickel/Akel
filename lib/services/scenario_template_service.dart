import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum ScenarioType {
  homeInvasion,
  carAccident,
  medical,
  stalking,
  assault,
  fire,
  naturalDisaster,
  lostChild,
  domesticViolence,
  custom,
}

class ScenarioAction {
  final bool startLocationTracking;
  final bool startAudioRecording;
  final bool startVideoRecording;
  final bool sendBroadcast;
  final bool callEmergencyServices;
  final bool activateSiren;
  final bool shareLocationLive;

  ScenarioAction({
    this.startLocationTracking = false,
    this.startAudioRecording = false,
    this.startVideoRecording = false,
    this.sendBroadcast = false,
    this.callEmergencyServices = false,
    this.activateSiren = false,
    this.shareLocationLive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'startLocationTracking': startLocationTracking,
      'startAudioRecording': startAudioRecording,
      'startVideoRecording': startVideoRecording,
      'sendBroadcast': sendBroadcast,
      'callEmergencyServices': callEmergencyServices,
      'activateSiren': activateSiren,
      'shareLocationLive': shareLocationLive,
    };
  }

  factory ScenarioAction.fromMap(Map<String, dynamic> map) {
    return ScenarioAction(
      startLocationTracking: map['startLocationTracking'] ?? false,
      startAudioRecording: map['startAudioRecording'] ?? false,
      startVideoRecording: map['startVideoRecording'] ?? false,
      sendBroadcast: map['sendBroadcast'] ?? false,
      callEmergencyServices: map['callEmergencyServices'] ?? false,
      activateSiren: map['activateSiren'] ?? false,
      shareLocationLive: map['shareLocationLive'] ?? false,
    );
  }
}

class ScenarioTemplate {
  final String id;
  final String userId;
  final String name;
  final ScenarioType type;
  final String message;
  final List<String> contactGroups;
  final ScenarioAction actions;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime? lastUsed;
  final int usageCount;

  ScenarioTemplate({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.message,
    required this.contactGroups,
    required this.actions,
    this.isFavorite = false,
    required this.createdAt,
    this.lastUsed,
    this.usageCount = 0,
  });

  factory ScenarioTemplate.fromMap(Map<String, dynamic> map, String id) {
    return ScenarioTemplate(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      type: _typeFromString(map['type'] ?? 'custom'),
      message: map['message'] ?? '',
      contactGroups: List<String>.from(map['contactGroups'] ?? []),
      actions: ScenarioAction.fromMap(map['actions'] ?? {}),
      isFavorite: map['isFavorite'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUsed: (map['lastUsed'] as Timestamp?)?.toDate(),
      usageCount: map['usageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': _typeToString(type),
      'message': message,
      'contactGroups': contactGroups,
      'actions': actions.toMap(),
      'isFavorite': isFavorite,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUsed': lastUsed != null ? Timestamp.fromDate(lastUsed!) : null,
      'usageCount': usageCount,
    };
  }

  static ScenarioType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'homeinvasion':
        return ScenarioType.homeInvasion;
      case 'caraccident':
        return ScenarioType.carAccident;
      case 'medical':
        return ScenarioType.medical;
      case 'stalking':
        return ScenarioType.stalking;
      case 'assault':
        return ScenarioType.assault;
      case 'fire':
        return ScenarioType.fire;
      case 'naturaldisaster':
        return ScenarioType.naturalDisaster;
      case 'lostchild':
        return ScenarioType.lostChild;
      case 'domesticviolence':
        return ScenarioType.domesticViolence;
      default:
        return ScenarioType.custom;
    }
  }

  static String _typeToString(ScenarioType type) {
    switch (type) {
      case ScenarioType.homeInvasion:
        return 'homeInvasion';
      case ScenarioType.carAccident:
        return 'carAccident';
      case ScenarioType.medical:
        return 'medical';
      case ScenarioType.stalking:
        return 'stalking';
      case ScenarioType.assault:
        return 'assault';
      case ScenarioType.fire:
        return 'fire';
      case ScenarioType.naturalDisaster:
        return 'naturalDisaster';
      case ScenarioType.lostChild:
        return 'lostChild';
      case ScenarioType.domesticViolence:
        return 'domesticViolence';
      case ScenarioType.custom:
        return 'custom';
    }
  }
}

class ScenarioTemplateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create default templates
  Future<void> createDefaultTemplates(String userId) async {
    final defaultTemplates = [
      ScenarioTemplate(
        id: '',
        userId: userId,
        name: 'Home Invasion',
        type: ScenarioType.homeInvasion,
        message: ' EMERGENCY: Someone has broken into my home! I need immediate help!',
        contactGroups: ['family', 'emergency'],
        actions: ScenarioAction(
          startLocationTracking: true,
          startAudioRecording: true,
          callEmergencyServices: true,
          activateSiren: true,
        ),
        createdAt: DateTime.now(),
      ),
      ScenarioTemplate(
        id: '',
        userId: userId,
        name: 'Car Accident',
        type: ScenarioType.carAccident,
        message: ' CAR ACCIDENT: I\'ve been in a car accident and need help!',
        contactGroups: ['family', 'emergency'],
        actions: ScenarioAction(
          startLocationTracking: true,
          shareLocationLive: true,
          callEmergencyServices: true,
        ),
        createdAt: DateTime.now(),
      ),
      ScenarioTemplate(
        id: '',
        userId: userId,
        name: 'Medical Emergency',
        type: ScenarioType.medical,
        message: ' MEDICAL EMERGENCY: I need immediate medical assistance!',
        contactGroups: ['family', 'emergency'],
        actions: ScenarioAction(
          startLocationTracking: true,
          shareLocationLive: true,
          callEmergencyServices: true,
        ),
        createdAt: DateTime.now(),
      ),
      ScenarioTemplate(
        id: '',
        userId: userId,
        name: 'Being Followed',
        type: ScenarioType.stalking,
        message: ' HELP: I\'m being followed. Please track my location and stand by.',
        contactGroups: ['family', 'friends'],
        actions: ScenarioAction(
          startLocationTracking: true,
          shareLocationLive: true,
          startVideoRecording: true,
        ),
        createdAt: DateTime.now(),
      ),
      ScenarioTemplate(
        id: '',
        userId: userId,
        name: 'Physical Assault',
        type: ScenarioType.assault,
        message: ' ASSAULT: I\'m being attacked! Call police immediately!',
        contactGroups: ['emergency'],
        actions: ScenarioAction(
          startLocationTracking: true,
          startAudioRecording: true,
          startVideoRecording: true,
          callEmergencyServices: true,
          activateSiren: true,
        ),
        createdAt: DateTime.now(),
      ),
      ScenarioTemplate(
        id: '',
        userId: userId,
        name: 'Fire Emergency',
        type: ScenarioType.fire,
        message: ' FIRE: There\'s a fire! I need fire department assistance!',
        contactGroups: ['family', 'emergency'],
        actions: ScenarioAction(
          startLocationTracking: true,
          callEmergencyServices: true,
          sendBroadcast: true,
        ),
        createdAt: DateTime.now(),
      ),
    ];

    for (final template in defaultTemplates) {
      await _firestore.collection('scenario_templates').add(template.toMap());
    }

    debugPrint(' Default scenario templates created');
  }

  // Create custom template
  Future<ScenarioTemplate?> createTemplate({
    required String userId,
    required String name,
    required ScenarioType type,
    required String message,
    required List<String> contactGroups,
    required ScenarioAction actions,
  }) async {
    try {
      final template = ScenarioTemplate(
        id: '',
        userId: userId,
        name: name,
        type: type,
        message: message,
        contactGroups: contactGroups,
        actions: actions,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('scenario_templates').add(template.toMap());

      debugPrint(' Scenario template created: $name');

      return ScenarioTemplate(
        id: docRef.id,
        userId: userId,
        name: name,
        type: type,
        message: message,
        contactGroups: contactGroups,
        actions: actions,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint(' Create template error: $e');
      return null;
    }
  }

  // Get all templates for user
  Future<List<ScenarioTemplate>> getTemplates(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('scenario_templates')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return ScenarioTemplate.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint(' Get templates error: $e');
      return [];
    }
  }

  // Get favorite templates
  Future<List<ScenarioTemplate>> getFavoriteTemplates(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('scenario_templates')
          .where('userId', isEqualTo: userId)
          .where('isFavorite', isEqualTo: true)
          .orderBy('usageCount', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return ScenarioTemplate.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint(' Get favorite templates error: $e');
      return [];
    }
  }

  // Update template
  Future<bool> updateTemplate({
    required String templateId,
    String? name,
    String? message,
    List<String>? contactGroups,
    ScenarioAction? actions,
    bool? isFavorite,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (name != null) updates['name'] = name;
      if (message != null) updates['message'] = message;
      if (contactGroups != null) updates['contactGroups'] = contactGroups;
      if (actions != null) updates['actions'] = actions.toMap();
      if (isFavorite != null) updates['isFavorite'] = isFavorite;

      await _firestore.collection('scenario_templates').doc(templateId).update(updates);

      debugPrint(' Template updated: $templateId');
      return true;
    } catch (e) {
      debugPrint(' Update template error: $e');
      return false;
    }
  }

  // Record template usage
  Future<void> recordUsage(String templateId) async {
    try {
      await _firestore.collection('scenario_templates').doc(templateId).update({
        'lastUsed': FieldValue.serverTimestamp(),
        'usageCount': FieldValue.increment(1),
      });

      debugPrint(' Template usage recorded: $templateId');
    } catch (e) {
      debugPrint(' Record usage error: $e');
    }
  }

  // Delete template
  Future<bool> deleteTemplate(String templateId) async {
    try {
      await _firestore.collection('scenario_templates').doc(templateId).delete();

      debugPrint(' Template deleted: $templateId');
      return true;
    } catch (e) {
      debugPrint(' Delete template error: $e');
      return false;
    }
  }

  // Duplicate template
  Future<ScenarioTemplate?> duplicateTemplate(String templateId) async {
    try {
      final doc = await _firestore.collection('scenario_templates').doc(templateId).get();

      if (!doc.exists) return null;

      final original = ScenarioTemplate.fromMap(doc.data()!, doc.id);

      final duplicate = ScenarioTemplate(
        id: '',
        userId: original.userId,
        name: '${original.name} (Copy)',
        type: original.type,
        message: original.message,
        contactGroups: original.contactGroups,
        actions: original.actions,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('scenario_templates').add(duplicate.toMap());

      debugPrint(' Template duplicated: ${original.name}');

      return ScenarioTemplate(
        id: docRef.id,
        userId: duplicate.userId,
        name: duplicate.name,
        type: duplicate.type,
        message: duplicate.message,
        contactGroups: duplicate.contactGroups,
        actions: duplicate.actions,
        createdAt: duplicate.createdAt,
      );
    } catch (e) {
      debugPrint(' Duplicate template error: $e');
      return null;
    }
  }

  // Get template statistics
  Future<Map<String, dynamic>> getTemplateStatistics(String userId) async {
    try {
      final templates = await getTemplates(userId);

      final totalTemplates = templates.length;
      final favoriteTemplates = templates.where((t) => t.isFavorite).length;
      final totalUsage = templates.fold<int>(0, (sum, t) => sum + t.usageCount);

      final mostUsed = templates.isNotEmpty
          ? templates.reduce((a, b) => a.usageCount > b.usageCount ? a : b)
          : null;

      return {
        'totalTemplates': totalTemplates,
        'favoriteTemplates': favoriteTemplates,
        'totalUsage': totalUsage,
        'mostUsedTemplate': mostUsed?.name ?? 'None',
        'mostUsedCount': mostUsed?.usageCount ?? 0,
      };
    } catch (e) {
      debugPrint(' Get template statistics error: $e');
      return {};
    }
  }

  // Get type icon
  static String getTypeIcon(ScenarioType type) {
    switch (type) {
      case ScenarioType.homeInvasion:
        return ' ';
      case ScenarioType.carAccident:
        return ' ';
      case ScenarioType.medical:
        return ' ';
      case ScenarioType.stalking:
        return ' ';
      case ScenarioType.assault:
        return ' ';
      case ScenarioType.fire:
        return ' ';
      case ScenarioType.naturalDisaster:
        return ' ';
      case ScenarioType.lostChild:
        return ' ';
      case ScenarioType.domesticViolence:
        return ' ';
      case ScenarioType.custom:
        return ' ';
    }
  }

  // Get type label
  static String getTypeLabel(ScenarioType type) {
    switch (type) {
      case ScenarioType.homeInvasion:
        return 'Home Invasion';
      case ScenarioType.carAccident:
        return 'Car Accident';
      case ScenarioType.medical:
        return 'Medical Emergency';
      case ScenarioType.stalking:
        return 'Being Followed';
      case ScenarioType.assault:
        return 'Physical Assault';
      case ScenarioType.fire:
        return 'Fire Emergency';
      case ScenarioType.naturalDisaster:
        return 'Natural Disaster';
      case ScenarioType.lostChild:
        return 'Lost Child';
      case ScenarioType.domesticViolence:
        return 'Domestic Violence';
      case ScenarioType.custom:
        return 'Custom';
    }
  }

  // Get type color
  static String getTypeColor(ScenarioType type) {
    switch (type) {
      case ScenarioType.homeInvasion:
        return '#F44336'; // Red
      case ScenarioType.carAccident:
        return '#FF9800'; // Orange
      case ScenarioType.medical:
        return '#E91E63'; // Pink
      case ScenarioType.stalking:
        return '#9C27B0'; // Purple
      case ScenarioType.assault:
        return '#D32F2F'; // Dark Red
      case ScenarioType.fire:
        return '#FF5722'; // Deep Orange
      case ScenarioType.naturalDisaster:
        return '#795548'; // Brown
      case ScenarioType.lostChild:
        return '#2196F3'; // Blue
      case ScenarioType.domesticViolence:
        return '#673AB7'; // Deep Purple
      case ScenarioType.custom:
        return '#607D8B'; // Blue Grey
    }
  }
}