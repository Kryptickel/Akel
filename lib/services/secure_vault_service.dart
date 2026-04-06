import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureVaultService {
  static final SecureVaultService _instance = SecureVaultService._internal();
  factory SecureVaultService() => _instance;
  SecureVaultService._internal();

  /// Save item to vault
  Future<void> saveToVault(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vault_$key', value);

      debugPrint('✅ Item saved to vault: $key');
    } catch (e) {
      debugPrint('❌ Save to vault error: $e');
      rethrow;
    }
  }

  /// Get item from vault
  Future<String?> getFromVault(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('vault_$key');
    } catch (e) {
      debugPrint('❌ Get from vault error: $e');
      return null;
    }
  }

  /// Delete item from vault
  Future<void> deleteFromVault(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('vault_$key');

      debugPrint('✅ Item deleted from vault: $key');
    } catch (e) {
      debugPrint('❌ Delete from vault error: $e');
      rethrow;
    }
  }

  /// Get all vault items
  Future<List<Map<String, String>>> getAllVaultItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('vault_'));

      final items = <Map<String, String>>[];

      for (final key in keys) {
        final value = prefs.getString(key);
        if (value != null) {
          items.add({
            'key': key.replaceFirst('vault_', ''),
            'value': value,
          });
        }
      }

      return items;
    } catch (e) {
      debugPrint('❌ Get all vault items error: $e');
      return [];
    }
  }

  /// Clear entire vault
  Future<void> clearVault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('vault_'));

      for (final key in keys) {
        await prefs.remove(key);
      }

      debugPrint('🧹 Vault cleared');
    } catch (e) {
      debugPrint('❌ Clear vault error: $e');
      rethrow;
    }
  }
}