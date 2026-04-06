import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// ==================== MEDICAL INTELLIGENCE SERVICE ====================
///
/// COMPREHENSIVE MEDICAL INTELLIGENCE SYSTEM
/// Your personal health guardian with:
/// - Hospital Network (ratings, reviews, availability)
/// - Doctor Annie AI (medical advice, symptom analysis)
/// - Digital Medical ID (allergies, conditions, medications)
/// - Medication Tracker (reminders, interactions, refills)
/// - Health Analytics (vitals tracking, trends)
/// - Emergency Medical Profile
///
/// 24-HOUR MARATHON - PHASE 4 (HOURS 13-16)
/// ================================================================

class MedicalIntelligenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;

  // Medical ID
  MedicalIDCard? _medicalId;

  // Medications
  List<Medication> _medications = [];

  // Health vitals
  List<HealthVital> _vitals = [];

  // Hospitals cache
  List<Hospital> _nearbyHospitals = [];

  // Callbacks
  Function(String)? onLog;
  Function(Medication)? onMedicationReminder;
  VoidCallback? onEmergencyAlert;

  // ==================== INITIALIZATION ====================

  Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint(' Medical Intelligence Service already initialized');
      return true;
    }

    try {
      debugPrint(' Initializing Medical Intelligence Service...');

      _isInitialized = true;
      debugPrint(' Medical Intelligence Service initialized');
      return true;
    } catch (e) {
      debugPrint(' Medical Intelligence initialization error: $e');
      return false;
    }
  }

  // ==================== MEDICAL ID CARD ====================

  Future<MedicalIDCard?> getMedicalID(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medical')
          .doc('id_card')
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      _medicalId = MedicalIDCard.fromMap(data, userId);

      debugPrint(' Medical ID loaded');
      return _medicalId;
    } catch (e) {
      debugPrint(' Get medical ID error: $e');
      return null;
    }
  }

  Future<void> saveMedicalID({
    required String userId,
    required String fullName,
    required DateTime dateOfBirth,
    required String bloodType,
    required List<String> allergies,
    required List<String> medicalConditions,
    required List<String> medications,
    required List<EmergencyContact> emergencyContacts,
    String? organDonor,
    String? insuranceProvider,
    String? insuranceNumber,
    String? additionalNotes,
  }) async {
    try {
      final medicalId = MedicalIDCard(
        userId: userId,
        fullName: fullName,
        dateOfBirth: dateOfBirth,
        bloodType: bloodType,
        allergies: allergies,
        medicalConditions: medicalConditions,
        medications: medications,
        emergencyContacts: emergencyContacts,
        organDonor: organDonor,
        insuranceProvider: insuranceProvider,
        insuranceNumber: insuranceNumber,
        additionalNotes: additionalNotes,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('medical')
          .doc('id_card')
          .set(medicalId.toMap());

      _medicalId = medicalId;

      debugPrint(' Medical ID saved');
      onLog?.call('Medical ID updated');
    } catch (e) {
      debugPrint(' Save medical ID error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> exportMedicalIDForEmergency(String userId) async {
    final medicalId = await getMedicalID(userId);

    if (medicalId == null) {
      return {
        'available': false,
        'message': 'No medical ID on file',
      };
    }

    return {
      'available': true,
      'fullName': medicalId.fullName,
      'dateOfBirth': medicalId.dateOfBirth.toIso8601String(),
      'bloodType': medicalId.bloodType,
      'allergies': medicalId.allergies,
      'medicalConditions': medicalId.medicalConditions,
      'currentMedications': medicalId.medications,
      'emergencyContacts': medicalId.emergencyContacts
          .map((c) => {
        'name': c.name,
        'relationship': c.relationship,
        'phone': c.phone,
      })
          .toList(),
      'organDonor': medicalId.organDonor,
      'insurance': medicalId.insuranceProvider != null
          ? {
        'provider': medicalId.insuranceProvider,
        'number': medicalId.insuranceNumber,
      }
          : null,
      'notes': medicalId.additionalNotes,
    };
  }

  // ==================== MEDICATION TRACKER ====================

  Future<List<Medication>> getMedications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medications')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      _medications = snapshot.docs
          .map((doc) => Medication.fromMap(doc.data(), doc.id))
          .toList();

      debugPrint(' ${_medications.length} medications loaded');
      return _medications;
    } catch (e) {
      debugPrint(' Get medications error: $e');
      return [];
    }
  }

  Future<void> addMedication({
    required String userId,
    required String name,
    required String dosage,
    required String frequency,
    required List<String> reminderTimes,
    String? purpose,
    DateTime? startDate,
    DateTime? endDate,
    String? prescribedBy,
    String? notes,
  }) async {
    try {
      final medication = Medication(
        id: _generateMedicationId(),
        userId: userId,
        name: name,
        dosage: dosage,
        frequency: frequency,
        reminderTimes: reminderTimes,
        purpose: purpose,
        startDate: startDate ?? DateTime.now(),
        endDate: endDate,
        prescribedBy: prescribedBy,
        notes: notes,
        isActive: true,
        adherenceRate: 0.0,
        missedDoses: 0,
        takenDoses: 0,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('medications')
          .doc(medication.id)
          .set(medication.toMap());

      _medications.add(medication);

      debugPrint(' Medication added: $name');
      onLog?.call('Medication $name added');
    } catch (e) {
      debugPrint(' Add medication error: $e');
      rethrow;
    }
  }

  Future<void> recordMedicationTaken(String medicationId) async {
    try {
      final medIndex = _medications.indexWhere((m) => m.id == medicationId);
      if (medIndex == -1) return;

      final medication = _medications[medIndex];
      final takenDoses = medication.takenDoses + 1;
      final totalDoses = takenDoses + medication.missedDoses;
      final adherenceRate = totalDoses > 0 ? (takenDoses / totalDoses) * 100 : 0.0;

      await _firestore
          .collection('users')
          .doc(medication.userId)
          .collection('medications')
          .doc(medicationId)
          .update({
        'takenDoses': takenDoses,
        'adherenceRate': adherenceRate,
      });

      // Log the dose
      await _firestore
          .collection('users')
          .doc(medication.userId)
          .collection('medications')
          .doc(medicationId)
          .collection('doses')
          .add({
        'timestamp': DateTime.now().toIso8601String(),
        'taken': true,
      });

      debugPrint(' Medication dose recorded');
    } catch (e) {
      debugPrint(' Record medication error: $e');
    }
  }

  Future<void> recordMedicationMissed(String medicationId) async {
    try {
      final medIndex = _medications.indexWhere((m) => m.id == medicationId);
      if (medIndex == -1) return;

      final medication = _medications[medIndex];
      final missedDoses = medication.missedDoses + 1;
      final totalDoses = medication.takenDoses + missedDoses;
      final adherenceRate = totalDoses > 0 ? (medication.takenDoses / totalDoses) * 100 : 0.0;

      await _firestore
          .collection('users')
          .doc(medication.userId)
          .collection('medications')
          .doc(medicationId)
          .update({
        'missedDoses': missedDoses,
        'adherenceRate': adherenceRate,
      });

      // Log the missed dose
      await _firestore
          .collection('users')
          .doc(medication.userId)
          .collection('medications')
          .doc(medicationId)
          .collection('doses')
          .add({
        'timestamp': DateTime.now().toIso8601String(),
        'taken': false,
      });

      debugPrint(' Medication dose missed');
    } catch (e) {
      debugPrint(' Record missed medication error: $e');
    }
  }

  Future<List<String>> checkMedicationInteractions(List<String> medicationNames) async {
    // In production, integrate with a drug interaction API
    // For now, return mock data

    final interactions = <String>[];

    // Mock interaction checker
    if (medicationNames.contains('Warfarin') && medicationNames.contains('Aspirin')) {
      interactions.add(' Warfarin + Aspirin: Increased bleeding risk');
    }

    if (medicationNames.contains('Lisinopril') && medicationNames.contains('Ibuprofen')) {
      interactions.add(' Lisinopril + Ibuprofen: Reduced effectiveness');
    }

    return interactions;
  }

  // ==================== HEALTH VITALS TRACKING ====================

  Future<void> recordHealthVital({
    required String userId,
    required VitalType type,
    required double value,
    String? unit,
    String? notes,
  }) async {
    try {
      final vital = HealthVital(
        id: _generateVitalId(),
        userId: userId,
        type: type,
        value: value,
        unit: unit ?? type.defaultUnit,
        timestamp: DateTime.now(),
        notes: notes,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('health_vitals')
          .doc(vital.id)
          .set(vital.toMap());

      _vitals.add(vital);

      debugPrint(' Health vital recorded: ${type.displayName}');
    } catch (e) {
      debugPrint(' Record vital error: $e');
      rethrow;
    }
  }

  Future<List<HealthVital>> getHealthVitals(
      String userId, {
        VitalType? type,
        DateTime? startDate,
        DateTime? endDate,
      }) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('health_vitals');

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      final snapshot = await query
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final vitals = snapshot.docs
          .map((doc) => HealthVital.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Filter by date range if specified
      if (startDate != null || endDate != null) {
        return vitals.where((v) {
          if (startDate != null && v.timestamp.isBefore(startDate)) return false;
          if (endDate != null && v.timestamp.isAfter(endDate)) return false;
          return true;
        }).toList();
      }

      return vitals;
    } catch (e) {
      debugPrint(' Get health vitals error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getHealthAnalytics(String userId) async {
    try {
      final vitals = await getHealthVitals(userId);

      // Calculate averages for each vital type
      final analytics = <String, dynamic>{};

      for (final type in VitalType.values) {
        final typeVitals = vitals.where((v) => v.type == type).toList();

        if (typeVitals.isEmpty) continue;

        final sum = typeVitals.fold<double>(0, (sum, v) => sum + v.value);
        final average = sum / typeVitals.length;

        final sorted = typeVitals.map((v) => v.value).toList()..sort();
        final min = sorted.first;
        final max = sorted.last;

        analytics[type.name] = {
          'average': average,
          'min': min,
          'max': max,
          'count': typeVitals.length,
          'unit': type.defaultUnit,
          'trend': _calculateTrend(typeVitals),
        };
      }

      return analytics;
    } catch (e) {
      debugPrint(' Get health analytics error: $e');
      return {};
    }
  }

  String _calculateTrend(List<HealthVital> vitals) {
    if (vitals.length < 2) return 'insufficient_data';

    // Sort by timestamp
    vitals.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final recentValues = vitals.length > 5
        ? vitals.sublist(vitals.length - 5)
        : vitals;

    double sum = 0;
    for (int i = 1; i < recentValues.length; i++) {
      sum += recentValues[i].value - recentValues[i - 1].value;
    }

    final avgChange = sum / (recentValues.length - 1);

    if (avgChange > 0.5) return 'increasing';
    if (avgChange < -0.5) return 'decreasing';
    return 'stable';
  }

  // ==================== HOSPITAL NETWORK ====================

  Future<List<Hospital>> findNearbyHospitals({
    required Position position,
    double radiusKm = 10.0,
    String? specialty,
  }) async {
    try {
      // In production, integrate with Google Places API or hospital database
      // For now, return mock data

      _nearbyHospitals = _generateMockHospitals(position);

      // Filter by distance
      final filtered = _nearbyHospitals.where((h) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          h.latitude,
          h.longitude,
        );
        return distance / 1000 <= radiusKm;
      }).toList();

      // Sort by rating
      filtered.sort((a, b) => b.rating.compareTo(a.rating));

      debugPrint(' ${filtered.length} hospitals found');
      return filtered;
    } catch (e) {
      debugPrint(' Find hospitals error: $e');
      return [];
    }
  }

  List<Hospital> _generateMockHospitals(Position position) {
    return [
      Hospital(
        id: 'h1',
        name: 'City General Hospital',
        address: '123 Main St',
        latitude: position.latitude + 0.01,
        longitude: position.longitude + 0.01,
        phone: '+1-555-0100',
        rating: 4.5,
        reviewCount: 250,
        hasEmergency: true,
        specialties: ['Emergency', 'Cardiology', 'Surgery'],
        waitTime: '15 min',
        acceptsInsurance: true,
      ),
      Hospital(
        id: 'h2',
        name: 'St. Mary Medical Center',
        address: '456 Oak Ave',
        latitude: position.latitude - 0.02,
        longitude: position.longitude + 0.01,
        phone: '+1-555-0200',
        rating: 4.7,
        reviewCount: 180,
        hasEmergency: true,
        specialties: ['Emergency', 'Pediatrics', 'Obstetrics'],
        waitTime: '20 min',
        acceptsInsurance: true,
      ),
      Hospital(
        id: 'h3',
        name: 'Regional Trauma Center',
        address: '789 Pine Rd',
        latitude: position.latitude + 0.03,
        longitude: position.longitude - 0.02,
        phone: '+1-555-0300',
        rating: 4.8,
        reviewCount: 320,
        hasEmergency: true,
        specialties: ['Trauma', 'Emergency', 'Neurology'],
        waitTime: '10 min',
        acceptsInsurance: true,
      ),
    ];
  }

  // ==================== DOCTOR ANNIE AI ====================

  Future<String> askDoctorAnnie({
    required String userId,
    required String question,
    List<String>? symptoms,
    String? medicalHistory,
  }) async {
    try {
      // In production, integrate with medical AI API
      // For now, return contextual responses

      final response = _generateAnnieResponse(question, symptoms);

      // Log the consultation
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('annie_consultations')
          .add({
        'question': question,
        'symptoms': symptoms,
        'response': response,
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint(' Doctor Annie responded');
      return response;
    } catch (e) {
      debugPrint(' Ask Doctor Annie error: $e');
      return 'I apologize, but I\'m having trouble processing your request right now. Please consult a healthcare professional for medical advice.';
    }
  }

  String _generateAnnieResponse(String question, List<String>? symptoms) {
    final lowerQuestion = question.toLowerCase();

    // Emergency symptoms
    if (symptoms != null && _hasEmergencySymptoms(symptoms)) {
      return ' URGENT: Based on your symptoms, you should seek immediate medical attention. Call emergency services (911) or go to the nearest emergency room right away.\n\nEmergency symptoms require immediate care and should not be delayed.';
    }

    // Common queries
    if (lowerQuestion.contains('fever') || lowerQuestion.contains('temperature')) {
      return ' For fever:\n\n• Adults: Take over-the-counter fever reducers like acetaminophen or ibuprofen\n• Stay hydrated and rest\n• Seek medical care if fever exceeds 103°F (39.4°C) or lasts more than 3 days\n\n This is general information. Please consult a doctor for personalized advice.';
    }

    if (lowerQuestion.contains('headache')) {
      return ' For headaches:\n\n• Rest in a quiet, dark room\n• Stay hydrated\n• Try over-the-counter pain relievers\n• Apply cold or warm compress\n\nSeek immediate care if accompanied by:\n• Sudden severe pain\n• Vision changes\n• Confusion\n• Stiff neck\n\n This is general information. Consult a healthcare provider for persistent headaches.';
    }

    // Default response
    return ' I\'m Doctor Annie, your AI health assistant. While I can provide general health information, I cannot diagnose conditions or prescribe treatment.\n\nFor your specific concern, I recommend:\n\n1. Monitor your symptoms\n2. Consult with a licensed healthcare provider\n3. Use the Medical ID feature to share your health information\n\n In case of emergency, call 911 immediately.';
  }

  bool _hasEmergencySymptoms(List<String> symptoms) {
    final emergencyKeywords = [
      'chest pain',
      'can\'t breathe',
      'severe bleeding',
      'unconscious',
      'stroke',
      'heart attack',
      'severe injury',
      'poisoning',
    ];

    for (final symptom in symptoms) {
      final lower = symptom.toLowerCase();
      if (emergencyKeywords.any((k) => lower.contains(k))) {
        return true;
      }
    }

    return false;
  }

  // ==================== STATISTICS ====================

  Future<Map<String, dynamic>> getMedicalStatistics(String userId) async {
    try {
      final medicalId = await getMedicalID(userId);
      final medications = await getMedications(userId);
      final vitals = await getHealthVitals(userId);

      // Calculate medication adherence
      double overallAdherence = 0.0;
      if (medications.isNotEmpty) {
        final sum = medications.fold<double>(
          0,
              (sum, m) => sum + m.adherenceRate,
        );
        overallAdherence = sum / medications.length;
      }

      return {
        'hasMedicalID': medicalId != null,
        'activeMedications': medications.length,
        'medicationAdherence': overallAdherence,
        'vitalsRecorded': vitals.length,
        'allergiesCount': medicalId?.allergies.length ?? 0,
        'conditionsCount': medicalId?.medicalConditions.length ?? 0,
      };
    } catch (e) {
      debugPrint(' Get medical statistics error: $e');
      return {};
    }
  }

  // ==================== HELPERS ====================

  String _generateMedicationId() {
    return 'MED_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateVitalId() {
    return 'VITAL_${DateTime.now().millisecondsSinceEpoch}';
  }

  // ==================== GETTERS ====================

  bool isInitialized() => _isInitialized;
  MedicalIDCard? getCurrentMedicalID() => _medicalId;
  List<Medication> getCurrentMedications() => _medications;
  List<Hospital> getNearbyHospitals() => _nearbyHospitals;

  // ==================== CLEANUP ====================

  void dispose() {
    debugPrint(' Medical Intelligence Service disposed');
  }
}

// ==================== MODELS ====================

class MedicalIDCard {
  final String userId;
  final String fullName;
  final DateTime dateOfBirth;
  final String bloodType;
  final List<String> allergies;
  final List<String> medicalConditions;
  final List<String> medications;
  final List<EmergencyContact> emergencyContacts;
  final String? organDonor;
  final String? insuranceProvider;
  final String? insuranceNumber;
  final String? additionalNotes;
  final DateTime lastUpdated;

  MedicalIDCard({
    required this.userId,
    required this.fullName,
    required this.dateOfBirth,
    required this.bloodType,
    required this.allergies,
    required this.medicalConditions,
    required this.medications,
    required this.emergencyContacts,
    this.organDonor,
    this.insuranceProvider,
    this.insuranceNumber,
    this.additionalNotes,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'bloodType': bloodType,
      'allergies': allergies,
      'medicalConditions': medicalConditions,
      'medications': medications,
      'emergencyContacts': emergencyContacts.map((c) => c.toMap()).toList(),
      'organDonor': organDonor,
      'insuranceProvider': insuranceProvider,
      'insuranceNumber': insuranceNumber,
      'additionalNotes': additionalNotes,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  static MedicalIDCard fromMap(Map<String, dynamic> map, String userId) {
    return MedicalIDCard(
      userId: userId,
      fullName: map['fullName'] ?? '',
      dateOfBirth: DateTime.parse(map['dateOfBirth']),
      bloodType: map['bloodType'] ?? '',
      allergies: List<String>.from(map['allergies'] ?? []),
      medicalConditions: List<String>.from(map['medicalConditions'] ?? []),
      medications: List<String>.from(map['medications'] ?? []),
      emergencyContacts: (map['emergencyContacts'] as List<dynamic>?)
          ?.map((c) => EmergencyContact.fromMap(c as Map<String, dynamic>))
          .toList() ??
          [],
      organDonor: map['organDonor'],
      insuranceProvider: map['insuranceProvider'],
      insuranceNumber: map['insuranceNumber'],
      additionalNotes: map['additionalNotes'],
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }
}

class EmergencyContact {
  final String name;
  final String relationship;
  final String phone;

  EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relationship': relationship,
      'phone': phone,
    };
  }

  static EmergencyContact fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] ?? '',
      relationship: map['relationship'] ?? '',
      phone: map['phone'] ?? '',
    );
  }
}

class Medication {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final String frequency;
  final List<String> reminderTimes;
  final String? purpose;
  final DateTime startDate;
  final DateTime? endDate;
  final String? prescribedBy;
  final String? notes;
  final bool isActive;
  final double adherenceRate;
  final int missedDoses;
  final int takenDoses;

  Medication({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.reminderTimes,
    this.purpose,
    required this.startDate,
    this.endDate,
    this.prescribedBy,
    this.notes,
    required this.isActive,
    required this.adherenceRate,
    required this.missedDoses,
    required this.takenDoses,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'reminderTimes': reminderTimes,
      'purpose': purpose,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'prescribedBy': prescribedBy,
      'notes': notes,
      'isActive': isActive,
      'adherenceRate': adherenceRate,
      'missedDoses': missedDoses,
      'takenDoses': takenDoses,
    };
  }

  static Medication fromMap(Map<String, dynamic> map, String id) {
    return Medication(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      reminderTimes: List<String>.from(map['reminderTimes'] ?? []),
      purpose: map['purpose'],
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      prescribedBy: map['prescribedBy'],
      notes: map['notes'],
      isActive: map['isActive'] ?? true,
      adherenceRate: (map['adherenceRate'] ?? 0.0).toDouble(),
      missedDoses: map['missedDoses'] ?? 0,
      takenDoses: map['takenDoses'] ?? 0,
    );
  }
}

enum VitalType {
  bloodPressureSystolic,
  bloodPressureDiastolic,
  heartRate,
  temperature,
  weight,
  height,
  bloodSugar,
  oxygenSaturation,
}

extension VitalTypeExtension on VitalType {
  String get displayName {
    switch (this) {
      case VitalType.bloodPressureSystolic:
        return 'Blood Pressure (Systolic)';
      case VitalType.bloodPressureDiastolic:
        return 'Blood Pressure (Diastolic)';
      case VitalType.heartRate:
        return 'Heart Rate';
      case VitalType.temperature:
        return 'Body Temperature';
      case VitalType.weight:
        return 'Weight';
      case VitalType.height:
        return 'Height';
      case VitalType.bloodSugar:
        return 'Blood Sugar';
      case VitalType.oxygenSaturation:
        return 'Oxygen Saturation';
    }
  }

  String get defaultUnit {
    switch (this) {
      case VitalType.bloodPressureSystolic:
      case VitalType.bloodPressureDiastolic:
        return 'mmHg';
      case VitalType.heartRate:
        return 'bpm';
      case VitalType.temperature:
        return '°F';
      case VitalType.weight:
        return 'lbs';
      case VitalType.height:
        return 'cm';
      case VitalType.bloodSugar:
        return 'mg/dL';
      case VitalType.oxygenSaturation:
        return '%';
    }
  }

  IconData get icon {
    switch (this) {
      case VitalType.bloodPressureSystolic:
      case VitalType.bloodPressureDiastolic:
        return Icons.favorite;
      case VitalType.heartRate:
        return Icons.monitor_heart;
      case VitalType.temperature:
        return Icons.thermostat;
      case VitalType.weight:
        return Icons.monitor_weight;
      case VitalType.height:
        return Icons.height;
      case VitalType.bloodSugar:
        return Icons.bloodtype;
      case VitalType.oxygenSaturation:
        return Icons.air;
    }
  }
}

class HealthVital {
  final String id;
  final String userId;
  final VitalType type;
  final double value;
  final String unit;
  final DateTime timestamp;
  final String? notes;

  HealthVital({
    required this.id,
    required this.userId,
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  static HealthVital fromMap(Map<String, dynamic> map, String id) {
    return HealthVital(
      id: id,
      userId: map['userId'] ?? '',
      type: VitalType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => VitalType.heartRate,
      ),
      value: (map['value'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      notes: map['notes'],
    );
  }
}

class Hospital {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final double rating;
  final int reviewCount;
  final bool hasEmergency;
  final List<String> specialties;
  final String? waitTime;
  final bool acceptsInsurance;

  Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.rating,
    required this.reviewCount,
    required this.hasEmergency,
    required this.specialties,
    this.waitTime,
    required this.acceptsInsurance,
  });

  double distanceFrom(Position position) {
    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      latitude,
      longitude,
    );
  }

  String formatDistance(Position position) {
    final meters = distanceFrom(position);
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }
}