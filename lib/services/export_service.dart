import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';

class ExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Export contacts to CSV format
  Future<String> exportContactsToCSV(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .get();

      List<List<dynamic>> rows = [
        ['Name', 'Phone', 'Email', 'Group', 'Created At']
      ];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        rows.add([
          data['name'] ?? '',
          data['phone'] ?? '',
          data['email'] ?? '',
          data['group'] ?? '',
          data['createdAt'] ?? '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      return csv;
    } catch (e) {
      throw Exception('Failed to export contacts: $e');
    }
  }

  // Export panic history to JSON format
  Future<String> exportPanicHistoryToJSON(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('panic_events')
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> events = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        events.add({
          'id': doc.id,
          'timestamp': data['timestamp'],
          'location': data['location'],
          'contacts_notified': data['contacts_notified'],
          'message': data['message'],
          'success': data['success'],
        });
      }

      Map<String, dynamic> exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'user_id': userId,
        'total_events': events.length,
        'events': events,
      };

      String json = const JsonEncoder.withIndent(' ').convert(exportData);
      return json;
    } catch (e) {
      throw Exception('Failed to export panic history: $e');
    }
  }

  // Export user profile to JSON
  Future<String> exportUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        throw Exception('User profile not found');
      }

      final data = doc.data()!;

      Map<String, dynamic> profile = {
        'export_date': DateTime.now().toIso8601String(),
        'user_id': userId,
        'profile': {
          'name': data['name'],
          'phone': data['phone'],
          'email': data['email'],
          'created_at': data['createdAt'],
        },
      };

      String json = const JsonEncoder.withIndent(' ').convert(profile);
      return json;
    } catch (e) {
      throw Exception('Failed to export profile: $e');
    }
  }

  // Export everything (full backup)
  Future<String> exportFullBackup(String userId) async {
    try {
      // Get user profile
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};

      // Get contacts
      final contactsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .get();

      List<Map<String, dynamic>> contacts = contactsSnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();

      // Get panic events
      final eventsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('panic_events')
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> events = eventsSnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();

      // Create full backup
      Map<String, dynamic> backup = {
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'user_id': userId,
        'profile': userData,
        'contacts': contacts,
        'panic_events': events,
        'statistics': {
          'total_contacts': contacts.length,
          'total_panic_events': events.length,
        },
      };

      String json = const JsonEncoder.withIndent(' ').convert(backup);
      return json;
    } catch (e) {
      throw Exception('Failed to create full backup: $e');
    }
  }

  // Get file names with timestamps
  String getContactsFileName() {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    return 'akel_contacts_$timestamp.csv';
  }

  String getPanicHistoryFileName() {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    return 'akel_panic_history_$timestamp.json';
  }

  String getProfileFileName() {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    return 'akel_profile_$timestamp.json';
  }

  String getFullBackupFileName() {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    return 'akel_full_backup_$timestamp.json';
  }
}