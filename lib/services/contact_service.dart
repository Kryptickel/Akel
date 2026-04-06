import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emergency_contact.dart';

class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// Singleton pattern
  static final ContactService _instance = ContactService._internal();
  factory ContactService() => _instance;
  ContactService._internal();

// ==================== GET CONTACTS ====================

  /// Get all emergency contacts for a user
  Future<List<EmergencyContact>> getEmergencyContacts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('emergency_contacts')
          .orderBy('priority')
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => EmergencyContact.fromMap({
        'id': doc.id,
        ...doc.data(),
      }))
          .toList();
    } catch (e) {
      debugPrint('❌ Get contacts error: $e');
      return [];
    }
  }

  /// Get a single contact by ID
  Future<EmergencyContact?> getContact(String userId, String contactId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('emergency_contacts')
          .doc(contactId)
          .get();

      if (doc.exists) {
        return EmergencyContact.fromMap({
          'id': doc.id,
          ...doc.data()!,
        });
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get contact error: $e');
      return null;
    }
  }

// ==================== ADD CONTACT ====================

  /// Add a new emergency contact
  Future<bool> addEmergencyContact(
      String userId,
      EmergencyContact contact,
      ) async {
    try {
      final contactData = contact.toMap();
      contactData['createdAt'] = FieldValue.serverTimestamp();
      contactData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('emergency_contacts')
          .doc(contact.id)
          .set(contactData);

      debugPrint('✅ Contact added: ${contact.name}');
      return true;
    } catch (e) {
      debugPrint('❌ Add contact error: $e');
      return false;
    }
  }

// ==================== UPDATE CONTACT ====================

  /// Update an existing emergency contact
  Future<bool> updateEmergencyContact(
      String userId,
      EmergencyContact contact,
      ) async {
    try {
      final contactData = contact.toMap();
      contactData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('emergency_contacts')
          .doc(contact.id)
          .update(contactData);

      debugPrint('✅ Contact updated: ${contact.name}');
      return true;
    } catch (e) {
      debugPrint('❌ Update contact error: $e');
      return false;
    }
  }

// ==================== DELETE CONTACT ====================

  /// Delete an emergency contact
  Future<bool> deleteEmergencyContact(
      String userId,
      String contactId,
      ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('emergency_contacts')
          .doc(contactId)
          .delete();

      debugPrint('✅ Contact deleted: $contactId');
      return true;
    } catch (e) {
      debugPrint('❌ Delete contact error: $e');
      return false;
    }
  }

// ==================== VERIFY CONTACT ====================

  /// Toggle contact verification status
  Future<bool> toggleVerification(
      String userId,
      String contactId,
      bool isVerified,
      ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('emergency_contacts')
          .doc(contactId)
          .update({
        'isVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Contact verification toggled: $contactId');
      return true;
    } catch (e) {
      debugPrint('❌ Toggle verification error: $e');
      return false;
    }
  }

// ==================== LOG INTERACTION ====================

  /// Log contact interaction (call, SMS, etc.)
  Future<bool> logContactInteraction(
      String userId,
      String contactId,
      String interactionType,
      ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contact_interactions')
          .add({
        'contactId': contactId,
        'type': interactionType, // 'call', 'sms', 'email'
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Interaction logged: $interactionType for $contactId');
      return true;
    } catch (e) {
      debugPrint('❌ Log interaction error: $e');
      return false;
    }
  }

// ==================== GET INTERACTIONS ====================

  /// Get interaction history for a contact
  Future<List<Map<String, dynamic>>> getContactInteractions(
      String userId,
      String contactId, {
        int limit = 50,
      }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contact_interactions')
          .where('contactId', isEqualTo: contactId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Get interactions error: $e');
      return [];
    }
  }

// ==================== STATISTICS ====================

  /// Get contact statistics
  Future<Map<String, int>> getContactStats(String userId) async {
    try {
      final contacts = await getEmergencyContacts(userId);

      final verified = contacts.where((c) => c.isVerified).length;
      final highPriority = contacts.where((c) => c.priority == 1).length;
      final mediumPriority = contacts.where((c) => c.priority == 2).length;
      final lowPriority = contacts.where((c) => c.priority == 3).length;
      final relationships = contacts.map((c) => c.relationship).toSet().length;

      return {
        'total': contacts.length,
        'verified': verified,
        'highPriority': highPriority,
        'mediumPriority': mediumPriority,
        'lowPriority': lowPriority,
        'relationships': relationships,
      };
    } catch (e) {
      debugPrint('❌ Get stats error: $e');
      return {};
    }
  }

// ==================== BULK OPERATIONS ====================

  /// Import multiple contacts
  Future<int> importContacts(
      String userId,
      List<EmergencyContact> contacts,
      ) async {
    int successCount = 0;

    for (final contact in contacts) {
      final success = await addEmergencyContact(userId, contact);
      if (success) successCount++;
    }

    debugPrint('✅ Imported $successCount of ${contacts.length} contacts');
    return successCount;
  }

  /// Delete all contacts for a user
  Future<bool> deleteAllContacts(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('emergency_contacts')
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ All contacts deleted for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Delete all contacts error: $e');
      return false;
    }
  }

// ==================== SEARCH ====================

  /// Search contacts by name or phone
  Future<List<EmergencyContact>> searchContacts(
      String userId,
      String query,
      ) async {
    try {
      final allContacts = await getEmergencyContacts(userId);
      final lowerQuery = query.toLowerCase();

      return allContacts.where((contact) {
        return contact.name.toLowerCase().contains(lowerQuery) ||
            contact.phone.contains(query) ||
            (contact.relationship?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    } catch (e) {
      debugPrint('❌ Search contacts error: $e');
      return [];
    }
  }

// ==================== VALIDATION ====================

  /// Validate contact data
  bool validateContact(EmergencyContact contact) {
    if (contact.name.isEmpty) {
      debugPrint('❌ Contact name is required');
      return false;
    }

    if (contact.phone.isEmpty) {
      debugPrint('❌ Contact phone is required');
      return false;
    }

    if (contact.phone.length < 10) {
      debugPrint('❌ Phone number too short');
      return false;
    }

    return true;
  }
}