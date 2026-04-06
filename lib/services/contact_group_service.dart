import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/contact_group.dart';

class ContactGroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<Map<String, String>> templates = [
    {'name': 'Family', 'icon': ' ', 'color': 'red'},
    {'name': 'Work', 'icon': ' ', 'color': 'blue'},
    {'name': 'Friends', 'icon': ' ', 'color': 'green'},
    {'name': 'Medical', 'icon': ' ', 'color': 'purple'},
    {'name': 'Neighbors', 'icon': ' ', 'color': 'orange'},
    {'name': 'Authorities', 'icon': ' ', 'color': 'indigo'},
  ];

  // ==================== EXISTING METHODS ====================

  Future<String> createGroup({
    required String userId,
    required String name,
    required String icon,
    required String color,
    List<String>? contactIds,
  }) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contact_groups')
          .add({
        'name': name,
        'icon': icon,
        'color': color,
        'contactIds': contactIds ?? [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint(' Group created: $name (${docRef.id})');
      return docRef.id;
    } catch (e) {
      debugPrint(' Error creating group: $e');
      rethrow;
    }
  }

  Stream<List<ContactGroup>> getGroups(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('contact_groups')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ContactGroup.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<ContactGroup?> getGroup(String userId, String groupId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contact_groups')
          .doc(groupId)
          .get();

      if (doc.exists && doc.data() != null) {
        return ContactGroup.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint(' Error getting group: $e');
      return null;
    }
  }

  Future<void> updateGroup({
    required String userId,
    required String groupId,
    String? name,
    String? icon,
    String? color,
    List<String>? contactIds,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (icon != null) updates['icon'] = icon;
      if (color != null) updates['color'] = color;
      if (contactIds != null) updates['contactIds'] = contactIds;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contact_groups')
          .doc(groupId)
          .update(updates);

      debugPrint(' Group updated: $groupId');
    } catch (e) {
      debugPrint(' Error updating group: $e');
      rethrow;
    }
  }

  Future<void> deleteGroup(String userId, String groupId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contact_groups')
          .doc(groupId)
          .delete();

      debugPrint(' Group deleted: $groupId');
    } catch (e) {
      debugPrint(' Error deleting group: $e');
      rethrow;
    }
  }

  Future<void> addContactToGroup({
    required String userId,
    required String groupId,
    required String contactId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contact_groups')
          .doc(groupId)
          .update({
        'contactIds': FieldValue.arrayUnion([contactId]),
      });

      debugPrint(' Contact added to group');
    } catch (e) {
      debugPrint(' Error adding contact to group: $e');
      rethrow;
    }
  }

  Future<void> removeContactFromGroup({
    required String userId,
    required String groupId,
    required String contactId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contact_groups')
          .doc(groupId)
          .update({
        'contactIds': FieldValue.arrayRemove([contactId]),
      });

      debugPrint(' Contact removed from group');
    } catch (e) {
      debugPrint(' Error removing contact from group: $e');
      rethrow;
    }
  }

  Future<List<ContactGroup>> getGroupsForContact(
      String userId,
      String contactId,
      ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contact_groups')
          .where('contactIds', arrayContains: contactId)
          .get();

      return snapshot.docs.map((doc) {
        return ContactGroup.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint(' Error getting groups for contact: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getContactsInGroup(
      String userId,
      String groupId,
      ) async {
    try {
      final group = await getGroup(userId, groupId);
      if (group == null || group.contactIds.isEmpty) {
        return [];
      }

      final contactsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .get();

      return contactsSnapshot.docs
          .where((doc) => group.contactIds.contains(doc.id))
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint(' Error getting contacts in group: $e');
      return [];
    }
  }

  // ==================== NEW PRIORITY SYSTEM ====================

  /// Get priority label
  static String getPriorityLabel(int priority) {
    switch (priority) {
      case 1:
        return 'High';
      case 2:
        return 'Medium';
      case 3:
        return 'Low';
      default:
        return 'Medium';
    }
  }

  /// Get priority color (hex string)
  static String getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return '#F44336'; // Red
      case 2:
        return '#FF9800'; // Orange
      case 3:
        return '#4CAF50'; // Green
      default:
        return '#FF9800';
    }
  }

  /// Get priority icon
  static String getPriorityIcon(int priority) {
    switch (priority) {
      case 1:
        return ' '; // High
      case 2:
        return ' '; // Medium
      case 3:
        return ' '; // Low
      default:
        return ' ';
    }
  }

  /// Update contact priority
  Future<bool> updateContactPriority(
      String userId,
      String contactId,
      int priority,
      ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .doc(contactId)
          .update({'priority': priority});

      debugPrint(' Contact priority updated: $contactId -> $priority');
      return true;
    } catch (e) {
      debugPrint(' Update contact priority error: $e');
      return false;
    }
  }

  /// Bulk update priorities
  Future<bool> bulkUpdatePriorities(
      String userId,
      List<String> contactIds,
      int priority,
      ) async {
    try {
      final batch = _firestore.batch();

      for (final contactId in contactIds) {
        final ref = _firestore
            .collection('users')
            .doc(userId)
            .collection('contacts')
            .doc(contactId);
        batch.update(ref, {'priority': priority});
      }

      await batch.commit();
      debugPrint(' Bulk priority update: ${contactIds.length} contacts');
      return true;
    } catch (e) {
      debugPrint(' Bulk update priorities error: $e');
      return false;
    }
  }

  /// Bulk assign to group
  Future<bool> bulkAssignToGroup(
      String userId,
      String groupId,
      List<String> contactIds,
      ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contact_groups')
          .doc(groupId)
          .update({
        'contactIds': FieldValue.arrayUnion(contactIds),
      });

      debugPrint(' Bulk assign to group: ${contactIds.length} contacts');
      return true;
    } catch (e) {
      debugPrint(' Bulk assign to group error: $e');
      return false;
    }
  }

  /// Bulk remove from group
  Future<bool> bulkRemoveFromGroup(
      String userId,
      String groupId,
      List<String> contactIds,
      ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contact_groups')
          .doc(groupId)
          .update({
        'contactIds': FieldValue.arrayRemove(contactIds),
      });

      debugPrint(' Bulk remove from group: ${contactIds.length} contacts');
      return true;
    } catch (e) {
      debugPrint(' Bulk remove from group error: $e');
      return false;
    }
  }

  // ==================== STATISTICS & ANALYTICS ====================

  /// Get group statistics
  Future<Map<String, dynamic>> getGroupStatistics(String userId) async {
    try {
      // Get all contacts
      final contactsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .get();

      final contacts = contactsSnapshot.docs.map((doc) => doc.data()).toList();

      // Get all groups
      final groupsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contact_groups')
          .get();

      final groups = groupsSnapshot.docs;

      // Count contacts per group
      final Map<String, int> groupCounts = {};
      for (final group in groups) {
        final groupData = group.data();
        final contactIds = List<String>.from(groupData['contactIds'] ?? []);
        groupCounts[groupData['name']] = contactIds.length;
      }

      // Count by priority
      final priorityCounts = <int, int>{};
      for (final contact in contacts) {
        final priority = contact['priority'] ?? 2;
        priorityCounts[priority] = (priorityCounts[priority] ?? 0) + 1;
      }

      return {
        'totalContacts': contacts.length,
        'totalGroups': groups.length,
        'groupCounts': groupCounts,
        'priorityCounts': priorityCounts,
        'highPriority': priorityCounts[1] ?? 0,
        'mediumPriority': priorityCounts[2] ?? 0,
        'lowPriority': priorityCounts[3] ?? 0,
      };
    } catch (e) {
      debugPrint(' Get group statistics error: $e');
      return {
        'totalContacts': 0,
        'totalGroups': 0,
        'groupCounts': {},
        'priorityCounts': {},
        'highPriority': 0,
        'mediumPriority': 0,
        'lowPriority': 0,
      };
    }
  }

  // ==================== EXPORT FUNCTIONALITY ====================

  /// Export contacts as CSV
  String exportContactsAsCSV(List<Map<String, dynamic>> contacts) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Name,Phone,Email,Priority,Relationship,Groups');

    // Data
    for (final contact in contacts) {
      final name = _escapeCsv(contact['name'] ?? '');
      final phone = _escapeCsv(contact['phone'] ?? '');
      final email = _escapeCsv(contact['email'] ?? '');
      final priority = getPriorityLabel(contact['priority'] ?? 2);
      final relationship = _escapeCsv(contact['relationship'] ?? '');
      final groups = 'N/A'; // Groups will be in separate collection

      buffer.writeln('$name,$phone,$email,$priority,$relationship,$groups');
    }

    return buffer.toString();
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // ==================== SORTING & FILTERING ====================

  /// Get contacts sorted by priority
  Future<List<Map<String, dynamic>>> getContactsSortedByPriority(
      String userId,
      ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .get();

      final contacts = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort by priority (1 = high, 2 = medium, 3 = low)
      contacts.sort((a, b) {
        final aPriority = a['priority'] ?? 2;
        final bPriority = b['priority'] ?? 2;
        return aPriority.compareTo(bPriority);
      });

      return contacts;
    } catch (e) {
      debugPrint(' Get contacts sorted error: $e');
      return [];
    }
  }

  /// Get contacts by priority level
  Future<List<Map<String, dynamic>>> getContactsByPriority(
      String userId,
      int priority,
      ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .get();

      final contacts = snapshot.docs
          .where((doc) => (doc.data()['priority'] ?? 2) == priority)
          .map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      return contacts;
    } catch (e) {
      debugPrint(' Get contacts by priority error: $e');
      return [];
    }
  }

  /// Get all contacts with groups information
  Future<List<Map<String, dynamic>>> getContactsWithGroups(
      String userId,
      ) async {
    try {
      final contactsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .get();

      final groupsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contact_groups')
          .get();

      final contacts = contactsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Add group names to each contact
      for (final contact in contacts) {
        final contactId = contact['id'];
        final groupNames = <String>[];

        for (final groupDoc in groupsSnapshot.docs) {
          final groupData = groupDoc.data();
          final contactIds = List<String>.from(groupData['contactIds'] ?? []);

          if (contactIds.contains(contactId)) {
            groupNames.add(groupData['name'] as String);
          }
        }

        contact['groupNames'] = groupNames;
      }

      return contacts;
    } catch (e) {
      debugPrint(' Get contacts with groups error: $e');
      return [];
    }
  }
}