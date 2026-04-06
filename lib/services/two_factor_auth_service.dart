import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class TwoFactorAuthService {
  static final TwoFactorAuthService _instance = TwoFactorAuthService._internal();
  factory TwoFactorAuthService() => _instance;
  TwoFactorAuthService._internal();

  /// Check if 2FA is enabled
  Future<bool> isTwoFactorEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('two_factor_enabled') ?? false;
    } catch (e) {
      debugPrint('❌ Check 2FA error: $e');
      return false;
    }
  }

  /// Enable/disable 2FA
  Future<void> setTwoFactor(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('two_factor_enabled', enabled);

      debugPrint(enabled ? '🔐 2FA enabled' : '🔓 2FA disabled');
    } catch (e) {
      debugPrint('❌ Set 2FA error: $e');
      rethrow;
    }
  }

  /// Generate 6-digit verification code
  String generateVerificationCode() {
    final random = Random();
    final code = random.nextInt(900000) + 100000; // 6-digit code
    return code.toString();
  }

  /// Store verification code
  Future<void> storeVerificationCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('2fa_code', code);
      await prefs.setInt('2fa_code_timestamp', DateTime.now().millisecondsSinceEpoch);

      debugPrint('✅ Verification code stored');
    } catch (e) {
      debugPrint('❌ Store verification code error: $e');
      rethrow;
    }
  }

  /// Verify code
  Future<bool> verifyCode(String enteredCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedCode = prefs.getString('2fa_code');
      final timestamp = prefs.getInt('2fa_code_timestamp') ?? 0;

// Check if code expired (5 minutes)
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsed = now - timestamp;
      final fiveMinutes = 5 * 60 * 1000;

      if (elapsed > fiveMinutes) {
        debugPrint('❌ Code expired');
        return false;
      }

      final isValid = storedCode == enteredCode;
      debugPrint(isValid ? '✅ Code verified' : '❌ Invalid code');

      return isValid;
    } catch (e) {
      debugPrint('❌ Verify code error: $e');
      return false;
    }
  }

  /// Get 2FA settings
  Future<Map<String, dynamic>> getTwoFactorSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'enabled': prefs.getBool('two_factor_enabled') ?? false,
        'sms_method': prefs.getBool('2fa_sms_method') ?? true,
        'email_method': prefs.getBool('2fa_email_method') ?? false,
        'app_method': prefs.getBool('2fa_app_method') ?? false,
        'phone_number': prefs.getString('2fa_phone_number') ?? '',
        'email': prefs.getString('2fa_email') ?? '',
      };
    } catch (e) {
      debugPrint('❌ Get 2FA settings error: $e');
      return {};
    }
  }

  /// Save 2FA setting
  Future<void> saveTwoFactorSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (value is bool) {
        await prefs.setBool('2fa_$key', value);
      } else if (value is String) {
        await prefs.setString('2fa_$key', value);
      }

      debugPrint('✅ 2FA setting saved: $key = $value');
    } catch (e) {
      debugPrint('❌ Save 2FA setting error: $e');
      rethrow;
    }
  }

  /// Send verification code (simulated)
  Future<String> sendVerificationCode(String method, String destination) async {
    try {
      final code = generateVerificationCode();
      await storeVerificationCode(code);

// In production, this would send actual SMS/Email
      debugPrint('📱 Code sent via $method to $destination: $code');

      return code;
    } catch (e) {
      debugPrint('❌ Send verification code error: $e');
      rethrow;
    }
  }

  /// Get backup codes
  Future<List<String>> getBackupCodes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('2fa_backup_codes') ?? [];
    } catch (e) {
      debugPrint('❌ Get backup codes error: $e');
      return [];
    }
  }

  /// Generate backup codes
  Future<List<String>> generateBackupCodes() async {
    try {
      final codes = <String>[];
      final random = Random();

      for (int i = 0; i < 10; i++) {
        final code = random.nextInt(90000000) + 10000000; // 8-digit code
        codes.add(code.toString());
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('2fa_backup_codes', codes);

      debugPrint('✅ Backup codes generated');
      return codes;
    } catch (e) {
      debugPrint('❌ Generate backup codes error: $e');
      return [];
    }
  }
}