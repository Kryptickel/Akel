import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emergency_contact.dart';

class ContactsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// Get contacts collection reference for a user
  CollectionReference _getContactsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('contacts');
  }

// Stream of contacts for a user
  Stream<List<EmergencyContact>> getContactsStream(String userId) {
    return _getContactsCollection(userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return EmergencyContact.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

// Get all contacts once
  Future<List<EmergencyContact>> getContacts(String userId) async {
    try {
      final snapshot = await _getContactsCollection(userId).get();

      return snapshot.docs.map((doc) {
        return EmergencyContact.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get contacts: $e');
    }
  }

// Add new contact
  Future<String> addContact({
    required String userId,
    required String name,
    required String phone,
    required String relationship,
    int priority = 1,
  }) async {
    try {
      final contact = EmergencyContact(
        id: '',
        name: name,
        phone: phone,
        relationship: relationship,
        priority: priority,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final docRef = await _getContactsCollection(userId).add(contact.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add contact: $e');
    }
  }

// Update contact
  Future<void> updateContact({
    required String userId,
    required String contactId,
    String? name,
    String? phone,
    String? relationship,
    int? priority,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (relationship != null) updates['relationship'] = relationship;
      if (priority != null) updates['priority'] = priority;
      if (isActive != null) updates['isActive'] = isActive;

      if (updates.isNotEmpty) {
        await _getContactsCollection(userId).doc(contactId).update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update contact: $e');
    }
  }

// Delete contact
  Future<void> deleteContact({
    required String userId,
    required String contactId,
  }) async {
    try {
      await _getContactsCollection(userId).doc(contactId).delete();
    } catch (e) {
      throw Exception('Failed to delete contact: $e');
    }
  }

// Get active contacts only (for panic button)
  Future<List<EmergencyContact>> getActiveContacts(String userId) async {
    try {
      final snapshot = await _getContactsCollection(userId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        return EmergencyContact.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get active contacts: $e');
    }
  }
}