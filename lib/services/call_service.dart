import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

enum CallStatus {
  success,
  failed,
  noPermission,
  invalidNumber,
  cancelled,
}

class CallResult {
  final String contactId;
  final String phoneNumber;
  final CallStatus status;
  final DateTime timestamp;
  final String? errorMessage;

  CallResult({
    required this.contactId,
    required this.phoneNumber,
    required this.status,
    required this.timestamp,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'contactId': contactId,
      'phoneNumber': phoneNumber,
      'status': status.toString(),
      'timestamp': timestamp.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }
}

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

// Track call history
  final List<CallResult> _callHistory = [];

// Make a phone call
  Future<CallResult> makeCall({
    required String contactId,
    required String phoneNumber,
    required String contactName,
  }) async {
    try {
      print('📞 Attempting to call: $contactName ($phoneNumber)');

// Validate phone number
      if (!_isValidPhoneNumber(phoneNumber)) {
        return _createResult(
          contactId: contactId,
          phoneNumber: phoneNumber,
          status: CallStatus.invalidNumber,
          errorMessage: 'Invalid phone number format',
        );
      }

// Check phone permission
      final phonePermission = await Permission.phone.status;
      if (!phonePermission.isGranted) {
// Request permission
        final result = await Permission.phone.request();
        if (!result.isGranted) {
          return _createResult(
            contactId: contactId,
            phoneNumber: phoneNumber,
            status: CallStatus.noPermission,
            errorMessage: 'Phone permission denied',
          );
        }
      }

// Format phone number for calling
      final formattedNumber = _formatForCalling(phoneNumber);
      final uri = Uri.parse('tel:$formattedNumber');

// Check if device can make calls
      if (!await canLaunchUrl(uri)) {
        return _createResult(
          contactId: contactId,
          phoneNumber: phoneNumber,
          status: CallStatus.failed,
          errorMessage: 'Cannot make phone calls on this device',
        );
      }

// Launch phone dialer
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        print('✅ Call initiated to: $contactName');
        return _createResult(
          contactId: contactId,
          phoneNumber: phoneNumber,
          status: CallStatus.success,
        );
      } else {
        return _createResult(
          contactId: contactId,
          phoneNumber: phoneNumber,
          status: CallStatus.failed,
          errorMessage: 'Failed to launch phone dialer',
        );
      }

    } catch (e) {
      print('❌ Call error: $e');
      return _createResult(
        contactId: contactId,
        phoneNumber: phoneNumber,
        status: CallStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

// Make calls to multiple contacts with retry logic
  Future<List<CallResult>> makeEmergencyCalls({
    required List<Map<String, dynamic>> contacts,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    Function(String contactName, int attempt)? onAttempt,
    Function(String contactName, CallStatus status)? onResult,
  }) async {
    final results = <CallResult>[];

// Sort contacts by priority (1 = highest, 3 = lowest)
    contacts.sort((a, b) {
      final priorityA = a['priority'] ?? 2;
      final priorityB = b['priority'] ?? 2;
      return priorityA.compareTo(priorityB);
    });

    for (final contact in contacts) {
      final contactId = contact['id'];
      final name = contact['name'];
      final phone = contact['phone'];

      print('📞 Calling contact: $name (Priority ${contact['priority']})');

      bool callSuccessful = false;
      CallResult? lastResult;

// Retry logic
      for (int attempt = 1; attempt <= maxRetries && !callSuccessful; attempt++) {
        if (onAttempt != null) {
          onAttempt(name, attempt);
        }

        print(' Attempt $attempt of $maxRetries...');

        lastResult = await makeCall(
          contactId: contactId,
          phoneNumber: phone,
          contactName: name,
        );

        if (lastResult.status == CallStatus.success) {
          callSuccessful = true;
          print(' ✅ Call successful on attempt $attempt');
        } else {
          print(' ❌ Call failed: ${lastResult.errorMessage}');

// Wait before retry (except on last attempt)
          if (attempt < maxRetries) {
            await Future.delayed(retryDelay);
          }
        }
      }

      if (lastResult != null) {
        results.add(lastResult);

        if (onResult != null) {
          onResult(name, lastResult.status);
        }
      }

// Small delay between contacts
      if (contact != contacts.last) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    return results;
  }

// Validate phone number format
  bool _isValidPhoneNumber(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    return digitsOnly.length >= 10 && digitsOnly.length <= 15;
  }

// Format phone number for calling
  String _formatForCalling(String phone) {
// Remove all non-digit characters except +
    String formatted = phone.replaceAll(RegExp(r'[^\d+]'), '');

// If no country code, assume US
    if (!formatted.startsWith('+') && formatted.length == 10) {
      formatted = '+1$formatted';
    }

    return formatted;
  }

// Create call result
  CallResult _createResult({
    required String contactId,
    required String phoneNumber,
    required CallStatus status,
    String? errorMessage,
  }) {
    final result = CallResult(
      contactId: contactId,
      phoneNumber: phoneNumber,
      status: status,
      timestamp: DateTime.now(),
      errorMessage: errorMessage,
    );

    _callHistory.add(result);
    return result;
  }

// Get call history
  List<CallResult> getCallHistory() {
    return List.unmodifiable(_callHistory);
  }

// Get call statistics
  Map<String, int> getCallStats() {
    return {
      'total': _callHistory.length,
      'successful': _callHistory.where((r) => r.status == CallStatus.success).length,
      'failed': _callHistory.where((r) => r.status == CallStatus.failed).length,
      'noPermission': _callHistory.where((r) => r.status == CallStatus.noPermission).length,
    };
  }

// Clear call history
  void clearHistory() {
    _callHistory.clear();
  }
}