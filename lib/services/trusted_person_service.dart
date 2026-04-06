import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

enum TrustedPersonStatus { safe, needHelp, unknown }

class TrustedPersonPin {
  final String id;
  final String userId;
  final String pin;
  final String contactName;
  final String contactPhone;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isUsed;
  final TrustedPersonStatus? status;
  final DateTime? verifiedAt;

  TrustedPersonPin({
    required this.id,
    required this.userId,
    required this.pin,
    required this.contactName,
    required this.contactPhone,
    required this.createdAt,
    required this.expiresAt,
    this.isUsed = false,
    this.status,
    this.verifiedAt,
  });

  factory TrustedPersonPin.fromMap(Map<String, dynamic> map, String id) {
    return TrustedPersonPin(
      id: id,
      userId: map['userId'] ?? '',
      pin: map['pin'] ?? '',
      contactName: map['contactName'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isUsed: map['isUsed'] ?? false,
      status: map['status'] != null ? _statusFromString(map['status']) : null,
      verifiedAt: (map['verifiedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'pin': pin,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isUsed': isUsed,
      'status': status != null ? _statusToString(status!) : null,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
    };
  }

  static TrustedPersonStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'safe':
        return TrustedPersonStatus.safe;
      case 'needhelp':
        return TrustedPersonStatus.needHelp;
      default:
        return TrustedPersonStatus.unknown;
    }
  }

  static String _statusToString(TrustedPersonStatus status) {
    switch (status) {
      case TrustedPersonStatus.safe:
        return 'safe';
      case TrustedPersonStatus.needHelp:
        return 'needHelp';
      case TrustedPersonStatus.unknown:
        return 'unknown';
    }
  }
}

class TrustedPersonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate a random PIN
  String _generatePin() {
    final random = Random();
    final pin = random.nextInt(900000) + 100000; // 6-digit PIN (100000-999999)
    return pin.toString();
  }

  // Create a new PIN for a trusted person
  Future<TrustedPersonPin?> createPin({
    required String userId,
    required String contactName,
    required String contactPhone,
    int expirationHours = 24,
  }) async {
    try {
      final pin = _generatePin();
      final now = DateTime.now();
      final expiresAt = now.add(Duration(hours: expirationHours));

      final pinEntry = TrustedPersonPin(
        id: '',
        userId: userId,
        pin: pin,
        contactName: contactName,
        contactPhone: contactPhone,
        createdAt: now,
        expiresAt: expiresAt,
      );

      final docRef = await _firestore
          .collection('trusted_person_pins')
          .add(pinEntry.toMap());

      debugPrint(' PIN created for $contactName: $pin');

      return TrustedPersonPin(
        id: docRef.id,
        userId: userId,
        pin: pin,
        contactName: contactName,
        contactPhone: contactPhone,
        createdAt: now,
        expiresAt: expiresAt,
      );
    } catch (e) {
      debugPrint(' Create PIN error: $e');
      return null;
    }
  }

  // Verify a PIN
  Future<TrustedPersonPin?> verifyPin(String pin) async {
    try {
      final snapshot = await _firestore
          .collection('trusted_person_pins')
          .where('pin', isEqualTo: pin)
          .where('isUsed', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint(' PIN not found: $pin');
        return null;
      }

      final doc = snapshot.docs.first;
      final pinEntry = TrustedPersonPin.fromMap(doc.data(), doc.id);

      // Check if expired
      if (pinEntry.expiresAt.isBefore(DateTime.now())) {
        debugPrint(' PIN expired: $pin');
        return null;
      }

      debugPrint(' PIN verified: $pin');
      return pinEntry;
    } catch (e) {
      debugPrint(' Verify PIN error: $e');
      return null;
    }
  }

  // Update status after PIN verification
  Future<bool> updateStatus({
    required String pinId,
    required TrustedPersonStatus status,
  }) async {
    try {
      await _firestore.collection('trusted_person_pins').doc(pinId).update({
        'isUsed': true,
        'status': TrustedPersonPin._statusToString(status),
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(' Status updated: $status');
      return true;
    } catch (e) {
      debugPrint(' Update status error: $e');
      return false;
    }
  }

  // Get all PINs for user
  Future<List<TrustedPersonPin>> getPinsForUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('trusted_person_pins')
          .where('userId', isEqualTo: userId)
          .get();

      final pins = snapshot.docs.map((doc) {
        return TrustedPersonPin.fromMap(doc.data(), doc.id);
      }).toList();

      // Sort by creation date descending
      pins.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return pins;
    } catch (e) {
      debugPrint(' Get PINs error: $e');
      return [];
    }
  }

  // Get active (unused, non-expired) PINs
  Future<List<TrustedPersonPin>> getActivePins(String userId) async {
    try {
      final allPins = await getPinsForUser(userId);
      final now = DateTime.now();

      return allPins.where((pin) {
        return !pin.isUsed && pin.expiresAt.isAfter(now);
      }).toList();
    } catch (e) {
      debugPrint(' Get active PINs error: $e');
      return [];
    }
  }

  // Delete a PIN
  Future<bool> deletePin(String pinId) async {
    try {
      await _firestore.collection('trusted_person_pins').doc(pinId).delete();
      debugPrint(' PIN deleted: $pinId');
      return true;
    } catch (e) {
      debugPrint(' Delete PIN error: $e');
      return false;
    }
  }

  // Delete all expired PINs for user
  Future<int> deleteExpiredPins(String userId) async {
    try {
      final pins = await getPinsForUser(userId);
      final now = DateTime.now();
      int deleted = 0;

      for (final pin in pins) {
        if (pin.expiresAt.isBefore(now)) {
          await deletePin(pin.id);
          deleted++;
        }
      }

      debugPrint(' Deleted $deleted expired PINs');
      return deleted;
    } catch (e) {
      debugPrint(' Delete expired PINs error: $e');
      return 0;
    }
  }

  // Get PIN statistics
  Future<Map<String, dynamic>> getPinStatistics(String userId) async {
    try {
      final pins = await getPinsForUser(userId);
      final now = DateTime.now();

      final totalPins = pins.length;
      final activePins = pins.where((p) => !p.isUsed && p.expiresAt.isAfter(now)).length;
      final usedPins = pins.where((p) => p.isUsed).length;
      final expiredPins = pins.where((p) => !p.isUsed && p.expiresAt.isBefore(now)).length;

      final safePins = pins.where((p) => p.status == TrustedPersonStatus.safe).length;
      final needHelpPins = pins.where((p) => p.status == TrustedPersonStatus.needHelp).length;

      return {
        'totalPins': totalPins,
        'activePins': activePins,
        'usedPins': usedPins,
        'expiredPins': expiredPins,
        'safePins': safePins,
        'needHelpPins': needHelpPins,
      };
    } catch (e) {
      debugPrint(' Get PIN statistics error: $e');
      return {
        'totalPins': 0,
        'activePins': 0,
        'usedPins': 0,
        'expiredPins': 0,
        'safePins': 0,
        'needHelpPins': 0,
      };
    }
  }

  // Get user contacts from Firestore
  Future<List<Map<String, String>>> getUserContacts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .get();

      final List<Map<String, String>> contacts = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final String name = data['name']?.toString() ?? 'Unknown';
        final String phone = data['phone']?.toString() ?? '';

        contacts.add({
          'name': name,
          'phone': phone,
        });
      }

      return contacts;
    } catch (e) {
      debugPrint(' Get user contacts error: $e');
      return [];
    }
  }

  // Format PIN for display (e.g., 123456 -> 123-456)
  String formatPin(String pin) {
    if (pin.length == 6) {
      return '${pin.substring(0, 3)}-${pin.substring(3)}';
    }
    return pin;
  }

  // Get status icon
  static String getStatusIcon(TrustedPersonStatus status) {
    switch (status) {
      case TrustedPersonStatus.safe:
        return ' ';
      case TrustedPersonStatus.needHelp:
        return ' ';
      case TrustedPersonStatus.unknown:
        return ' ';
    }
  }

  // Get status color
  static String getStatusColor(TrustedPersonStatus status) {
    switch (status) {
      case TrustedPersonStatus.safe:
        return '#4CAF50'; // Green
      case TrustedPersonStatus.needHelp:
        return '#F44336'; // Red
      case TrustedPersonStatus.unknown:
        return '#9E9E9E'; // Grey
    }
  }

  // Get status label
  static String getStatusLabel(TrustedPersonStatus status) {
    switch (status) {
      case TrustedPersonStatus.safe:
        return 'Safe';
      case TrustedPersonStatus.needHelp:
        return 'Need Help';
      case TrustedPersonStatus.unknown:
        return 'Unknown';
    }
  }
}