import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum RelationshipType {
  family,
  friend,
  colleague,
  neighbor,
  partner,
  doctor,
  lawyer,
  therapist,
  caregiver,
  teacher,
  custom,
}

class RelationshipTag {
  final String id;
  final String userId;
  final String name;
  final RelationshipType type;
  final String color;
  final int priority;
  final DateTime createdAt;

  RelationshipTag({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.color,
    this.priority = 2,
    required this.createdAt,
  });

  factory RelationshipTag.fromMap(Map<String, dynamic> map, String id) {
    return RelationshipTag(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      type: _typeFromString(map['type'] ?? 'custom'),
      color: map['color'] ?? '#607D8B',
      priority: map['priority'] ?? 2,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': _typeToString(type),
      'color': color,
      'priority': priority,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static RelationshipType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'family':
        return RelationshipType.family;
      case 'friend':
        return RelationshipType.friend;
      case 'colleague':
        return RelationshipType.colleague;
      case 'neighbor':
        return RelationshipType.neighbor;
      case 'partner':
        return RelationshipType.partner;
      case 'doctor':
        return RelationshipType.doctor;
      case 'lawyer':
        return RelationshipType.lawyer;
      case 'therapist':
        return RelationshipType.therapist;
      case 'caregiver':
        return RelationshipType.caregiver;
      case 'teacher':
        return RelationshipType.teacher;
      default:
        return RelationshipType.custom;
    }
  }

  static String _typeToString(RelationshipType type) {
    switch (type) {
      case RelationshipType.family:
        return 'family';
      case RelationshipType.friend:
        return 'friend';
      case RelationshipType.colleague:
        return 'colleague';
      case RelationshipType.neighbor:
        return 'neighbor';
      case RelationshipType.partner:
        return 'partner';
      case RelationshipType.doctor:
        return 'doctor';
      case RelationshipType.lawyer:
        return 'lawyer';
      case RelationshipType.therapist:
        return 'therapist';
      case RelationshipType.caregiver:
        return 'caregiver';
      case RelationshipType.teacher:
        return 'teacher';
      case RelationshipType.custom:
        return 'custom';
    }
  }
}

class RelationshipTagService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Default relationship tags
  static final List<Map<String, dynamic>> defaultTags = [
    {
      'name': 'Family',
      'type': 'family',
      'color': '#E91E63',
      'priority': 1,
      'icon': ' ',
    },
    {
      'name': 'Partner',
      'type': 'partner',
      'color': '#F44336',
      'priority': 1,
      'icon': ' ',
    },
    {
      'name': 'Friend',
      'type': 'friend',
      'color': '#2196F3',
      'priority': 2,
      'icon': ' ',
    },
    {
      'name': 'Colleague',
      'type': 'colleague',
      'color': '#FF9800',
      'priority': 2,
      'icon': ' ',
    },
    {
      'name': 'Neighbor',
      'type': 'neighbor',
      'color': '#4CAF50',
      'priority': 3,
      'icon': ' ',
    },
    {
      'name': 'Doctor',
      'type': 'doctor',
      'color': '#9C27B0',
      'priority': 1,
      'icon': ' ',
    },
    {
      'name': 'Lawyer',
      'type': 'lawyer',
      'color': '#795548',
      'priority': 2,
      'icon': ' ',
    },
    {
      'name': 'Therapist',
      'type': 'therapist',
      'color': '#00BCD4',
      'priority': 2,
      'icon': ' ',
    },
    {
      'name': 'Caregiver',
      'type': 'caregiver',
      'color': '#CDDC39',
      'priority': 1,
      'icon': ' ',
    },
    {
      'name': 'Teacher',
      'type': 'teacher',
      'color': '#FF5722',
      'priority': 3,
      'icon': ' ',
    },
  ];

  // Create default tags for user
  Future<void> createDefaultTags(String userId) async {
    try {
      for (final tagData in defaultTags) {
        final tag = RelationshipTag(
          id: '',
          userId: userId,
          name: tagData['name'] as String,
          type: RelationshipTag._typeFromString(tagData['type'] as String),
          color: tagData['color'] as String,
          priority: tagData['priority'] as int,
          createdAt: DateTime.now(),
        );

        await _firestore.collection('relationship_tags').add(tag.toMap());
      }

      debugPrint(' Default relationship tags created');
    } catch (e) {
      debugPrint(' Create default tags error: $e');
    }
  }

  // Create custom tag
  Future<RelationshipTag?> createTag({
    required String userId,
    required String name,
    required String color,
    int priority = 2,
  }) async {
    try {
      final tag = RelationshipTag(
        id: '',
        userId: userId,
        name: name,
        type: RelationshipType.custom,
        color: color,
        priority: priority,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('relationship_tags').add(tag.toMap());

      debugPrint(' Custom tag created: $name');

      return RelationshipTag(
        id: docRef.id,
        userId: userId,
        name: name,
        type: RelationshipType.custom,
        color: color,
        priority: priority,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint(' Create tag error: $e');
      return null;
    }
  }

  // Get all tags for user
  Future<List<RelationshipTag>> getTags(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('relationship_tags')
          .where('userId', isEqualTo: userId)
          .orderBy('priority')
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        return RelationshipTag.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint(' Get tags error: $e');
      return [];
    }
  }

  // Update tag
  Future<bool> updateTag({
    required String tagId,
    String? name,
    String? color,
    int? priority,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (name != null) updates['name'] = name;
      if (color != null) updates['color'] = color;
      if (priority != null) updates['priority'] = priority;

      await _firestore.collection('relationship_tags').doc(tagId).update(updates);

      debugPrint(' Tag updated: $tagId');
      return true;
    } catch (e) {
      debugPrint(' Update tag error: $e');
      return false;
    }
  }

  // Delete tag
  Future<bool> deleteTag(String tagId) async {
    try {
      await _firestore.collection('relationship_tags').doc(tagId).delete();

      debugPrint(' Tag deleted: $tagId');
      return true;
    } catch (e) {
      debugPrint(' Delete tag error: $e');
      return false;
    }
  }

  // Add tag to contact
  Future<bool> addTagToContact({
    required String userId,
    required String contactId,
    required String tagId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .doc(contactId)
          .update({
        'tags': FieldValue.arrayUnion([tagId]),
      });

      debugPrint(' Tag added to contact');
      return true;
    } catch (e) {
      debugPrint(' Add tag to contact error: $e');
      return false;
    }
  }

  // Remove tag from contact
  Future<bool> removeTagFromContact({
    required String userId,
    required String contactId,
    required String tagId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .doc(contactId)
          .update({
        'tags': FieldValue.arrayRemove([tagId]),
      });

      debugPrint(' Tag removed from contact');
      return true;
    } catch (e) {
      debugPrint(' Remove tag from contact error: $e');
      return false;
    }
  }

  // Get contacts by tag
  Future<List<Map<String, dynamic>>> getContactsByTag({
    required String userId,
    required String tagId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .where('tags', arrayContains: tagId)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      debugPrint(' Get contacts by tag error: $e');
      return [];
    }
  }

  // Get tag statistics
  Future<Map<String, dynamic>> getTagStatistics(String userId) async {
    try {
      final tags = await getTags(userId);
      final totalTags = tags.length;

      final Map<String, int> contactsPerTag = {};

      for (final tag in tags) {
        final contacts = await getContactsByTag(userId: userId, tagId: tag.id);
        contactsPerTag[tag.id] = contacts.length;
      }

      final mostUsedTag = contactsPerTag.entries.isNotEmpty
          ? contactsPerTag.entries.reduce((a, b) => a.value > b.value ? a : b)
          : null;

      final mostUsedTagName = mostUsedTag != null
          ? tags.firstWhere((t) => t.id == mostUsedTag.key).name
          : 'None';

      return {
        'totalTags': totalTags,
        'contactsPerTag': contactsPerTag,
        'mostUsedTag': mostUsedTagName,
        'mostUsedCount': mostUsedTag?.value ?? 0,
      };
    } catch (e) {
      debugPrint(' Get tag statistics error: $e');
      return {};
    }
  }

  // Get tag icon
  static String getTagIcon(RelationshipType type) {
    switch (type) {
      case RelationshipType.family:
        return ' ';
      case RelationshipType.friend:
        return ' ';
      case RelationshipType.colleague:
        return ' ';
      case RelationshipType.neighbor:
        return ' ';
      case RelationshipType.partner:
        return ' ';
      case RelationshipType.doctor:
        return ' ';
      case RelationshipType.lawyer:
        return ' ';
      case RelationshipType.therapist:
        return ' ';
      case RelationshipType.caregiver:
        return ' ';
      case RelationshipType.teacher:
        return ' ';
      case RelationshipType.custom:
        return ' ';
    }
  }

  // Get default colors for color picker
  static List<String> getDefaultColors() {
    return [
      '#F44336', // Red
      '#E91E63', // Pink
      '#9C27B0', // Purple
      '#673AB7', // Deep Purple
      '#3F51B5', // Indigo
      '#2196F3', // Blue
      '#03A9F4', // Light Blue
      '#00BCD4', // Cyan
      '#009688', // Teal
      '#4CAF50', // Green
      '#8BC34A', // Light Green
      '#CDDC39', // Lime
      '#FFEB3B', // Yellow
      '#FFC107', // Amber
      '#FF9800', // Orange
      '#FF5722', // Deep Orange
      '#795548', // Brown
      '#9E9E9E', // Grey
      '#607D8B', // Blue Grey
    ];
  }
}