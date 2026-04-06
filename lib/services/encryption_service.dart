import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  /// Check if encryption is enabled
  Future<bool> isEncryptionEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('encryption_enabled') ?? false;
    } catch (e) {
      debugPrint(' Check encryption error: $e');
      return false;
    }
  }

  /// Enable/disable encryption
  Future<void> setEncryption(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('encryption_enabled', enabled);

      debugPrint(enabled ? ' Encryption enabled' : ' Encryption disabled');
    } catch (e) {
      debugPrint(' Set encryption error: $e');
      rethrow;
    }
  }

  /// Get encryption settings
  Future<Map<String, dynamic>> getEncryptionSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'enabled': prefs.getBool('encryption_enabled') ?? false,
        'encrypt_contacts': prefs.getBool('encrypt_contacts') ?? false,
        'encrypt_messages': prefs.getBool('encrypt_messages') ?? false,
        'encrypt_location': prefs.getBool('encrypt_location') ?? false,
        'encrypt_history': prefs.getBool('encrypt_history') ?? false,
        'encrypt_medical': prefs.getBool('encrypt_medical') ?? false,
        'encryption_level': prefs.getString('encryption_level') ?? 'standard',
      };
    } catch (e) {
      debugPrint(' Get encryption settings error: $e');
      return {};
    }
  }

  /// Save encryption setting
  Future<void> saveEncryptionSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (value is bool) {
        await prefs.setBool('encrypt_$key', value);
      } else if (value is String) {
        await prefs.setString('encryption_$key', value);
      }

      debugPrint(' Encryption setting saved: $key = $value');
    } catch (e) {
      debugPrint(' Save encryption setting error: $e');
      rethrow;
    }
  }

  /// Encryption levels
  static const List<Map<String, dynamic>> encryptionLevels = [
    {
      'value': 'basic',
      'name': 'Basic (AES-128)',
      'description': 'Fast encryption, good security',
      'icon': Icons.lock_outline,
    },
    {
      'value': 'standard',
      'name': 'Standard (AES-256)',
      'description': 'Balanced speed and security',
      'icon': Icons.lock,
    },
    {
      'value': 'maximum',
      'name': 'Maximum (AES-256 + RSA)',
      'description': 'Military-grade encryption',
      'icon': Icons.security,
    },
  ];
}