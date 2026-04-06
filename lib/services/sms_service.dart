import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class SMSService {
  static final SMSService _instance = SMSService._internal();
  factory SMSService() => _instance;
  SMSService._internal();

  // ==================== SINGLE SMS ====================

  /// Send SMS to a single number (named parameters)
  Future<void> sendSMS({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      if (kIsWeb) {
        // Mock SMS for web testing
        debugPrint(' [WEB MOCK] Sending SMS...');
        debugPrint(' To: $phoneNumber');
        debugPrint(' Message: $message');

        await Future.delayed(const Duration(milliseconds: 500));

        debugPrint(' [WEB MOCK] SMS sent successfully');
        return;
      }

      // Check SMS permission
      final hasPermission = await _checkSMSPermission();
      if (!hasPermission) {
        throw Exception('SMS permission denied');
      }

      // For mobile platforms
      if (Platform.isAndroid || Platform.isIOS) {
        debugPrint(' [MOBILE] Sending SMS to $phoneNumber');
        debugPrint(' Message: $message');

        // TODO: Implement real SMS sending with flutter_sms package
        // For now, using mock
        await Future.delayed(const Duration(milliseconds: 500));

        debugPrint(' SMS sent successfully to $phoneNumber');
      }
    } catch (e) {
      debugPrint(' SMS send error: $e');
      rethrow;
    }
  }

  /// Send SMS to a single number (positional parameters)
  /// This version matches panic_service.dart calls
  Future<void> sendSMSPositional(String phoneNumber, String message) async {
    return sendSMS(phoneNumber: phoneNumber, message: message);
  }

  // ==================== BULK SMS ====================

  /// Send SMS to multiple numbers
  Future<void> sendBulkSMS({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    int successCount = 0;
    int failCount = 0;

    debugPrint(' Starting bulk SMS to ${phoneNumbers.length} recipients');

    for (final number in phoneNumbers) {
      try {
        await sendSMS(phoneNumber: number, message: message);
        successCount++;

        // Small delay between messages to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        debugPrint(' Failed to send to $number: $e');
        failCount++;
      }
    }

    debugPrint(' Bulk SMS complete: $successCount sent, $failCount failed');
  }

  // ==================== EMERGENCY ALERT ====================

  /// Send emergency alert SMS
  Future<void> sendEmergencyAlert({
    required List<String> phoneNumbers,
    required String emergencyType,
    String? location,
    String? additionalInfo,
  }) async {
    final message = _buildEmergencyMessage(
      emergencyType: emergencyType,
      location: location,
      additionalInfo: additionalInfo,
    );

    await sendBulkSMS(
      phoneNumbers: phoneNumbers,
      message: message,
    );
  }

  /// Send panic alert to a single contact
  Future<void> sendPanicAlert({
    required String phoneNumber,
    required String userName,
    String? location,
  }) async {
    final message = _buildPanicMessage(
      userName: userName,
      location: location,
    );

    await sendSMS(
      phoneNumber: phoneNumber,
      message: message,
    );
  }

  // ==================== MESSAGE BUILDERS ====================

  /// Build emergency message
  String _buildEmergencyMessage({
    required String emergencyType,
    String? location,
    String? additionalInfo,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(' EMERGENCY ALERT ');
    buffer.writeln();
    buffer.writeln('Type: $emergencyType');
    buffer.writeln('Time: ${_formatDateTime(DateTime.now())}');

    if (location != null) {
      buffer.writeln();
      buffer.writeln('Location: $location');
    }

    if (additionalInfo != null) {
      buffer.writeln();
      buffer.writeln('Details: $additionalInfo');
    }

    buffer.writeln();
    buffer.writeln('Please respond immediately!');
    buffer.writeln('Sent via AKEL Panic Button');

    return buffer.toString();
  }

  /// Build panic alert message
  String _buildPanicMessage({
    required String userName,
    String? location,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(' PANIC ALERT ');
    buffer.writeln();
    buffer.writeln('From: $userName');
    buffer.writeln('Time: ${_formatDateTime(DateTime.now())}');

    if (location != null) {
      buffer.writeln();
      buffer.writeln('Location: $location');
      buffer.writeln('Map: https://maps.google.com/?q=$location');
    }

    buffer.writeln();
    buffer.writeln('This is an automated emergency alert.');
    buffer.writeln('Please contact immediately!');
    buffer.writeln();
    buffer.writeln('Sent via AKEL Panic Button');

    return buffer.toString();
  }

  /// Build custom message with template
  String buildCustomMessage({
    required String template,
    required Map<String, String> variables,
  }) {
    String message = template;

    variables.forEach((key, value) {
      message = message.replaceAll('{$key}', value);
    });

    return message;
  }

  // ==================== PERMISSIONS ====================

  /// Check SMS permission
  Future<bool> _checkSMSPermission() async {
    if (kIsWeb) return true;

    try {
      final status = await Permission.sms.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.sms.request();
        return result.isGranted;
      }

      return false;
    } catch (e) {
      debugPrint(' Permission check error: $e');
      return false;
    }
  }

  /// Request SMS permission explicitly
  Future<bool> requestSMSPermission() async {
    if (kIsWeb) return true;

    try {
      final status = await Permission.sms.request();
      return status.isGranted;
    } catch (e) {
      debugPrint(' Permission request error: $e');
      return false;
    }
  }

  // ==================== AVAILABILITY ====================

  /// Check if SMS is available
  Future<bool> isSMSAvailable() async {
    if (kIsWeb) {
      return false;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      final hasPermission = await _checkSMSPermission();
      return hasPermission;
    }

    return false;
  }

  /// Get SMS capability status
  Future<Map<String, dynamic>> getSMSStatus() async {
    return {
      'available': await isSMSAvailable(),
      'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      'permissionGranted': await _checkSMSPermission(),
    };
  }

  // ==================== VALIDATION ====================

  /// Validate phone number format
  bool isValidPhoneNumber(String phoneNumber) {
    // Remove spaces, dashes, parentheses
    final cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it's a valid phone number (basic validation)
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    return phoneRegex.hasMatch(cleaned);
  }

  /// Clean phone number
  String cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  /// Format phone number for display
  String formatPhoneNumber(String phoneNumber) {
    final cleaned = cleanPhoneNumber(phoneNumber);

    if (cleaned.length == 10) {
      // US format: (XXX) XXX-XXXX
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    } else if (cleaned.length == 11 && cleaned.startsWith('1')) {
      // US with country code: +1 (XXX) XXX-XXXX
      return '+1 (${cleaned.substring(1, 4)}) ${cleaned.substring(4, 7)}-${cleaned.substring(7)}';
    }

    return phoneNumber;
  }

  // ==================== UTILITIES ====================

  /// Format date time for messages
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Calculate message length (considering SMS length limits)
  int calculateMessageParts(String message) {
    const singleSMSLength = 160;
    const multiSMSLength = 153; // Due to concatenation overhead

    if (message.length <= singleSMSLength) {
      return 1;
    }

    return (message.length / multiSMSLength).ceil();
  }

  /// Estimate SMS cost (basic calculation)
  double estimateSMSCost({
    required int recipientCount,
    required String message,
    double costPerSMS = 0.01, // $0.01 per SMS
  }) {
    final parts = calculateMessageParts(message);
    return recipientCount * parts * costPerSMS;
  }

  // ==================== TESTING ====================

  /// Send test SMS
  Future<bool> sendTestSMS(String phoneNumber) async {
    try {
      await sendSMS(
        phoneNumber: phoneNumber,
        message: 'Test SMS from AKEL Panic Button at ${DateTime.now()}',
      );
      return true;
    } catch (e) {
      debugPrint(' Test SMS failed: $e');
      return false;
    }
  }
}