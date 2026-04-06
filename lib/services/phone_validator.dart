import 'package:flutter/services.dart';

/// Phone number validation and formatting service
class PhoneValidator {
  /// Validates if phone number is in correct format
  static bool isValid(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.length < 10 || cleaned.length > 15) {
      return false;
    }

    if (!cleaned.startsWith('+') && !RegExp(r'^\d').hasMatch(cleaned)) {
      return false;
    }

    final patterns = [
      RegExp(r'^\+1\d{10}$'),
      RegExp(r'^\d{10}$'),
      RegExp(r'^\+\d{10,14}$'),
      RegExp(r'^\d{11,15}$'),
    ];

    return patterns.any((pattern) => pattern.hasMatch(cleaned));
  }

  /// Formats phone number as user types
  static String format(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.startsWith('+')) {
      final digits = cleaned.substring(1);
      if (digits.length <= 3) {
        return '+$digits';
      } else if (digits.length <= 6) {
        return '+${digits.substring(0, 3)} ${digits.substring(3)}';
      } else if (digits.length <= 10) {
        return '+${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
      } else {
        return '+${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 10)} ${digits.substring(10)}';
      }
    }

    if (cleaned.length <= 3) {
      return cleaned;
    } else if (cleaned.length <= 6) {
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3)}';
    } else if (cleaned.length <= 10) {
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    } else {
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6, 10)}';
    }
  }

  /// Cleans phone number for storage
  static String clean(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  /// Gets validation error message
  static String? getErrorMessage(String phone) {
    if (phone.isEmpty) {
      return 'Phone number is required';
    }

    final cleaned = clean(phone);

    if (cleaned.length < 10) {
      return 'Phone number must be at least 10 digits';
    }

    if (cleaned.length > 15) {
      return 'Phone number is too long';
    }

    if (!isValid(phone)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }
}

/// Phone number text input formatter
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text;

    if (text.length < oldValue.text.length) {
      return newValue;
    }

    final formatted = PhoneValidator.format(text);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}