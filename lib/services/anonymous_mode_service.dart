import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnonymousModeService {
  static final AnonymousModeService _instance = AnonymousModeService._internal();
  factory AnonymousModeService() => _instance;
  AnonymousModeService._internal();

  /// Check if anonymous mode is enabled
  Future<bool> isAnonymousModeEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('anonymous_mode_enabled') ?? false;
    } catch (e) {
      debugPrint('❌ Check anonymous mode error: $e');
      return false;
    }
  }

  /// Enable/disable anonymous mode
  Future<void> setAnonymousMode(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('anonymous_mode_enabled', enabled);

      debugPrint(enabled ? '🥷 Anonymous mode enabled' : '👤 Anonymous mode disabled');
    } catch (e) {
      debugPrint('❌ Set anonymous mode error: $e');
      rethrow;
    }
  }

  /// Get anonymous settings
  Future<Map<String, bool>> getAnonymousSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'enabled': prefs.getBool('anonymous_mode_enabled') ?? false,
        'hide_identity': prefs.getBool('anon_hide_identity') ?? false,
        'mask_location': prefs.getBool('anon_mask_location') ?? false,
        'randomize_data': prefs.getBool('anon_randomize_data') ?? false,
        'use_vpn': prefs.getBool('anon_use_vpn') ?? false,
        'clear_cookies': prefs.getBool('anon_clear_cookies') ?? false,
        'disable_tracking': prefs.getBool('anon_disable_tracking') ?? false,
        'anonymous_messaging': prefs.getBool('anon_anonymous_messaging') ?? false,
        'private_browsing': prefs.getBool('anon_private_browsing') ?? false,
      };
    } catch (e) {
      debugPrint('❌ Get anonymous settings error: $e');
      return {};
    }
  }

  /// Save anonymous setting
  Future<void> saveAnonymousSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('anon_$key', value);

      debugPrint('✅ Anonymous setting saved: $key = $value');
    } catch (e) {
      debugPrint('❌ Save anonymous setting error: $e');
      rethrow;
    }
  }

  /// Generate anonymous ID
  Future<String> generateAnonymousId() async {
    try {
      final prefs = await SharedPreferences.getInstance();

// Check if we already have an anonymous ID
      String? existingId = prefs.getString('anonymous_id');

      if (existingId != null && existingId.isNotEmpty) {
        return existingId;
      }

// Generate new anonymous ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = DateTime.now().microsecond;
      final anonymousId = 'ANON-${timestamp.toString().substring(5)}-${random.toString().padLeft(6, '0')}';

      await prefs.setString('anonymous_id', anonymousId);

      debugPrint('🆔 Anonymous ID generated: $anonymousId');
      return anonymousId;
    } catch (e) {
      debugPrint('❌ Generate anonymous ID error: $e');
      return 'ANON-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Get current anonymous ID
  Future<String?> getAnonymousId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('anonymous_id');
    } catch (e) {
      debugPrint('❌ Get anonymous ID error: $e');
      return null;
    }
  }

  /// Clear anonymous ID
  Future<void> clearAnonymousId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('anonymous_id');

      debugPrint('🧹 Anonymous ID cleared');
    } catch (e) {
      debugPrint('❌ Clear anonymous ID error: $e');
      rethrow;
    }
  }
}