import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

/// ==================== CONTACT VERIFICATION SERVICE ====================
///
/// Verify emergency contacts via SMS/call
/// BUILD 55 - NO TELEPHONY DEPENDENCY
/// ================================================================

class ContactVerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== SEND VERIFICATION CODE ====================

  Future<Map<String, dynamic>> sendVerificationCode({
    required String userId,
    required String contactId,
    required String phoneNumber,
    required String contactName,
  }) async {
    try {
      // Generate 6-digit code
      final code = _generateVerificationCode();

      // Save code to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .doc(contactId)
          .update({
        'verificationCode': code,
        'verificationCodeExpiry': DateTime.now().add(const Duration(minutes: 10)),
        'verificationSentAt': FieldValue.serverTimestamp(),
      });

      // Build verification message
      final message = 'AKEL Verification Code: $code\n\n'
          'Enter this code to verify your emergency contact.\n'
          'Code expires in 10 minutes.';

      // Send SMS via URL launcher
      final smsUri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');

      bool sent = false;
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        sent = true;
      }

      debugPrint(' Verification code sent to $contactName: $code');

      return {
        'success': sent,
        'code': code, // For testing/debugging
        'message': sent
            ? 'Verification code sent to $contactName'
            : 'Could not open SMS app',
      };
    } catch (e) {
      debugPrint(' Send verification code error: $e');
      return {
        'success': false,
        'message': 'Failed to send verification code: $e',
      };
    }
  }

  // ==================== VERIFY CODE ====================

  Future<Map<String, dynamic>> verifyCode({
    required String userId,
    required String contactId,
    required String code,
  }) async {
    try {
      final contactDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .doc(contactId)
          .get();

      if (!contactDoc.exists) {
        return {
          'success': false,
          'message': 'Contact not found',
        };
      }

      final data = contactDoc.data()!;
      final storedCode = data['verificationCode'] as String?;
      final expiry = (data['verificationCodeExpiry'] as Timestamp?)?.toDate();

      if (storedCode == null) {
        return {
          'success': false,
          'message': 'No verification code found. Please request a new code.',
        };
      }

      if (expiry != null && DateTime.now().isAfter(expiry)) {
        return {
          'success': false,
          'message': 'Verification code expired. Please request a new code.',
        };
      }

      if (storedCode != code) {
        return {
          'success': false,
          'message': 'Invalid verification code',
        };
      }

      // Mark as verified
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .doc(contactId)
          .update({
        'verified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        'verificationCode': FieldValue.delete(),
        'verificationCodeExpiry': FieldValue.delete(),
      });

      debugPrint(' Contact verified successfully');

      return {
        'success': true,
        'message': 'Contact verified successfully!',
      };
    } catch (e) {
      debugPrint(' Verify code error: $e');
      return {
        'success': false,
        'message': 'Verification failed: $e',
      };
    }
  }

  // ==================== RESEND VERIFICATION CODE ====================

  Future<Map<String, dynamic>> resendVerificationCode({
    required String userId,
    required String contactId,
    required String phoneNumber,
    required String contactName,
  }) async {
    // Check if enough time has passed since last send (prevent spam)
    final prefs = await SharedPreferences.getInstance();
    final lastSendKey = 'last_verification_send_$contactId';
    final lastSendTimestamp = prefs.getInt(lastSendKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastSendTimestamp < 60000) {
      // Less than 1 minute
      final waitTime = 60 - ((now - lastSendTimestamp) ~/ 1000);
      return {
        'success': false,
        'message': 'Please wait $waitTime seconds before resending',
      };
    }

    // Send new code
    final result = await sendVerificationCode(
      userId: userId,
      contactId: contactId,
      phoneNumber: phoneNumber,
      contactName: contactName,
    );

    if (result['success'] == true) {
      await prefs.setInt(lastSendKey, now);
    }

    return result;
  }

  // ==================== CHECK VERIFICATION STATUS ====================

  Future<bool> isContactVerified({
    required String userId,
    required String contactId,
  }) async {
    try {
      final contactDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .doc(contactId)
          .get();

      if (!contactDoc.exists) return false;

      final data = contactDoc.data()!;
      return data['verified'] == true;
    } catch (e) {
      debugPrint(' Check verification status error: $e');
      return false;
    }
  }

  // ==================== GET VERIFICATION STATUS ====================

  Future<Map<String, dynamic>> getVerificationStatus({
    required String userId,
    required String contactId,
  }) async {
    try {
      final contactDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .doc(contactId)
          .get();

      if (!contactDoc.exists) {
        return {
          'verified': false,
          'canResend': true,
        };
      }

      final data = contactDoc.data()!;
      final verified = data['verified'] == true;
      final expiry = (data['verificationCodeExpiry'] as Timestamp?)?.toDate();
      final hasActiveCode = expiry != null && DateTime.now().isBefore(expiry);

      return {
        'verified': verified,
        'hasActiveCode': hasActiveCode,
        'canResend': !verified,
        'expiryTime': expiry,
      };
    } catch (e) {
      debugPrint(' Get verification status error: $e');
      return {
        'verified': false,
        'canResend': true,
      };
    }
  }

  // ==================== VERIFY ALL CONTACTS ====================

  Future<Map<String, dynamic>> verifyAllContacts({
    required String userId,
  }) async {
    try {
      final contactsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .get();

      int total = contactsSnapshot.docs.length;
      int verified = 0;
      int unverified = 0;

      for (final doc in contactsSnapshot.docs) {
        final data = doc.data();
        if (data['verified'] == true) {
          verified++;
        } else {
          unverified++;
        }
      }

      return {
        'total': total,
        'verified': verified,
        'unverified': unverified,
        'verificationRate': total > 0 ? (verified / total * 100).toStringAsFixed(0) : '0',
      };
    } catch (e) {
      debugPrint(' Verify all contacts error: $e');
      return {
        'total': 0,
        'verified': 0,
        'unverified': 0,
        'verificationRate': '0',
      };
    }
  }

  // ==================== SEND VERIFICATION CALL ====================

  Future<Map<String, dynamic>> sendVerificationCall({
    required String userId,
    required String contactId,
    required String phoneNumber,
    required String contactName,
  }) async {
    try {
      // Generate call verification code
      final code = _generateVerificationCode();

      // Save code
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .doc(contactId)
          .update({
        'verificationCode': code,
        'verificationCodeExpiry': DateTime.now().add(const Duration(minutes: 10)),
        'verificationMethod': 'call',
        'verificationSentAt': FieldValue.serverTimestamp(),
      });

      // Initiate call
      final callUri = Uri.parse('tel:$phoneNumber');

      bool called = false;
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
        called = true;
      }

      debugPrint(' Verification call initiated to $contactName. Code: $code');

      return {
        'success': called,
        'code': code,
        'message': called
            ? 'Calling $contactName. Tell them the code: $code'
            : 'Could not initiate call',
      };
    } catch (e) {
      debugPrint(' Send verification call error: $e');
      return {
        'success': false,
        'message': 'Failed to initiate call: $e',
      };
    }
  }

  // ==================== HELPERS ====================

  String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString(); // 6-digit code
  }

  // ==================== REMOVE VERIFICATION ====================

  Future<void> removeVerification({
    required String userId,
    required String contactId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .doc(contactId)
          .update({
        'verified': false,
        'verifiedAt': FieldValue.delete(),
        'verificationCode': FieldValue.delete(),
        'verificationCodeExpiry': FieldValue.delete(),
      });

      debugPrint(' Verification removed');
    } catch (e) {
      debugPrint(' Remove verification error: $e');
    }
  }
}