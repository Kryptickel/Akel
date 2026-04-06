import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicalIDService {
  static final MedicalIDService _instance = MedicalIDService._internal();
  factory MedicalIDService() => _instance;
  MedicalIDService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Blood types
  static const List<String> bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'
  ];

  /// Save medical ID
  Future<void> saveMedicalID({
    required String userId,
    required Map<String, dynamic> medicalData,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('medical_info')
          .doc('medical_id')
          .set({
        ...medicalData,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Also save locally for quick access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('medical_id_name', medicalData['name'] ?? '');
      await prefs.setInt('medical_id_age', medicalData['age'] ?? 0);
      await prefs.setString('medical_id_bloodType', medicalData['bloodType'] ?? '');
      await prefs.setString('medical_id_allergies', medicalData['allergies'] ?? '');
      await prefs.setString('medical_id_medications', medicalData['medications'] ?? '');
      await prefs.setString('medical_id_conditions', medicalData['conditions'] ?? '');
      await prefs.setString('medical_id_emergencyContact', medicalData['emergencyContact'] ?? '');
      await prefs.setString('medical_id_emergencyPhone', medicalData['emergencyPhone'] ?? '');
      await prefs.setString('medical_id_insuranceProvider', medicalData['insuranceProvider'] ?? '');
      await prefs.setString('medical_id_insuranceNumber', medicalData['insuranceNumber'] ?? '');
      await prefs.setString('medical_id_organDonor', medicalData['organDonor'] ?? 'Not Specified');
      await prefs.setString('medical_id_notes', medicalData['notes'] ?? '');

      debugPrint(' Medical ID saved');
    } catch (e) {
      debugPrint(' Save medical ID error: $e');
      rethrow;
    }
  }

  /// Get medical ID
  Future<Map<String, dynamic>?> getMedicalID(String userId) async {
    try {
      // Try to get from Firestore first
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medical_info')
          .doc('medical_id')
          .get();

      if (doc.exists) {
        return doc.data();
      }

      // Fall back to local storage
      return await _getLocalMedicalID();
    } catch (e) {
      debugPrint(' Get medical ID error: $e');
      // Fall back to local storage on error
      return await _getLocalMedicalID();
    }
  }

  /// Get medical ID from local storage
  Future<Map<String, dynamic>?> _getLocalMedicalID() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final name = prefs.getString('medical_id_name');
      if (name == null || name.isEmpty) {
        return null; // No medical ID saved
      }

      return {
        'name': name,
        'age': prefs.getInt('medical_id_age') ?? 0,
        'bloodType': prefs.getString('medical_id_bloodType') ?? '',
        'allergies': prefs.getString('medical_id_allergies') ?? '',
        'medications': prefs.getString('medical_id_medications') ?? '',
        'conditions': prefs.getString('medical_id_conditions') ?? '',
        'emergencyContact': prefs.getString('medical_id_emergencyContact') ?? '',
        'emergencyPhone': prefs.getString('medical_id_emergencyPhone') ?? '',
        'insuranceProvider': prefs.getString('medical_id_insuranceProvider') ?? '',
        'insuranceNumber': prefs.getString('medical_id_insuranceNumber') ?? '',
        'organDonor': prefs.getString('medical_id_organDonor') ?? 'Not Specified',
        'notes': prefs.getString('medical_id_notes') ?? '',
      };
    } catch (e) {
      debugPrint(' Get local medical ID error: $e');
      return null;
    }
  }

  /// Check if medical ID exists
  Future<bool> hasMedicalID(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medical_info')
          .doc('medical_id')
          .get();

      if (doc.exists) return true;

      // Check local storage
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('medical_id_name');
      return name != null && name.isNotEmpty;
    } catch (e) {
      debugPrint(' Check medical ID error: $e');
      return false;
    }
  }

  /// Delete medical ID
  Future<void> deleteMedicalID(String userId) async {
    try {
      // Delete from Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('medical_info')
          .doc('medical_id')
          .delete();

      // Delete from local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('medical_id_name');
      await prefs.remove('medical_id_age');
      await prefs.remove('medical_id_bloodType');
      await prefs.remove('medical_id_allergies');
      await prefs.remove('medical_id_medications');
      await prefs.remove('medical_id_conditions');
      await prefs.remove('medical_id_emergencyContact');
      await prefs.remove('medical_id_emergencyPhone');
      await prefs.remove('medical_id_insuranceProvider');
      await prefs.remove('medical_id_insuranceNumber');
      await prefs.remove('medical_id_organDonor');
      await prefs.remove('medical_id_notes');

      debugPrint(' Medical ID deleted');
    } catch (e) {
      debugPrint(' Delete medical ID error: $e');
      rethrow;
    }
  }

  /// Get blood type icon
  static IconData getBloodTypeIcon(String bloodType) {
    return Icons.bloodtype;
  }

  /// Get blood type color
  static Color getBloodTypeColor(String bloodType) {
    if (bloodType.startsWith('A')) return Colors.red;
    if (bloodType.startsWith('B')) return Colors.blue;
    if (bloodType.startsWith('AB')) return Colors.purple;
    if (bloodType.startsWith('O')) return Colors.orange;
    return Colors.grey;
  }

  /// Validate medical ID data
  static String? validateMedicalID(Map<String, dynamic> data) {
    if (data['name'] == null || (data['name'] as String).trim().isEmpty) {
      return 'Name is required';
    }

    if (data['age'] == null || data['age'] == 0) {
      return 'Age is required';
    }

    if (data['bloodType'] == null || (data['bloodType'] as String).isEmpty) {
      return 'Blood type is required';
    }

    if (data['emergencyContact'] == null || (data['emergencyContact'] as String).trim().isEmpty) {
      return 'Emergency contact is required';
    }

    if (data['emergencyPhone'] == null || (data['emergencyPhone'] as String).trim().isEmpty) {
      return 'Emergency phone is required';
    }

    return null; // Valid
  }

  /// Format medical ID for display
  static String formatMedicalIDSummary(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    buffer.writeln('Name: ${data['name']}');
    buffer.writeln('Age: ${data['age']}');
    buffer.writeln('Blood Type: ${data['bloodType']}');

    if (data['allergies'] != null && (data['allergies'] as String).isNotEmpty) {
      buffer.writeln('Allergies: ${data['allergies']}');
    }

    if (data['medications'] != null && (data['medications'] as String).isNotEmpty) {
      buffer.writeln('Medications: ${data['medications']}');
    }

    if (data['conditions'] != null && (data['conditions'] as String).isNotEmpty) {
      buffer.writeln('Medical Conditions: ${data['conditions']}');
    }

    buffer.writeln('Emergency Contact: ${data['emergencyContact']}');
    buffer.writeln('Emergency Phone: ${data['emergencyPhone']}');

    return buffer.toString();
  }
}