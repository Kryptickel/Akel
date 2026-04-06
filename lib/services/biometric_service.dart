import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      return isAvailable && isDeviceSupported;
    } catch (e) {
      debugPrint(' Check biometric availability error: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint(' Get available biometrics error: $e');
      return [];
    }
  }

  /// Get biometric type name
  Future<String> getBiometricTypeName() async {
    try {
      final biometrics = await getAvailableBiometrics();

      if (biometrics.isEmpty) {
        return 'Biometric';
      }

      if (biometrics.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        return 'Fingerprint';
      } else if (biometrics.contains(BiometricType.iris)) {
        return 'Iris';
      } else {
        return 'Biometric';
      }
    } catch (e) {
      debugPrint(' Get biometric type name error: $e');
      return 'Biometric';
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticate({
    String reason = 'Please authenticate to access AKEL',
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();

      if (!isAvailable) {
        debugPrint(' Biometric authentication not available');
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
      );

      debugPrint(authenticated
          ? ' Biometric authentication successful'
          : ' Biometric authentication failed');

      return authenticated;
    } catch (e) {
      debugPrint(' Authenticate error: $e');
      return false;
    }
  }

  /// Check if biometric lock is enabled in settings
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('biometric_lock_enabled') ?? false;
    } catch (e) {
      debugPrint(' Check biometric enabled error: $e');
      return false;
    }
  }

  /// Enable/disable biometric lock
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_lock_enabled', enabled);

      debugPrint(' Biometric lock ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint(' Set biometric enabled error: $e');
      rethrow;
    }
  }

  /// Get lock timeout
  Future<int> getLockTimeout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('biometric_lock_timeout') ?? 0;
    } catch (e) {
      debugPrint(' Get lock timeout error: $e');
      return 0;
    }
  }

  /// Set lock timeout
  Future<void> setLockTimeout(int seconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('biometric_lock_timeout', seconds);

      debugPrint(' Lock timeout set to $seconds seconds');
    } catch (e) {
      debugPrint(' Set lock timeout error: $e');
      rethrow;
    }
  }

  /// Get biometric type icon
  static IconData getBiometricTypeIcon(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return Icons.face;
      case BiometricType.fingerprint:
        return Icons.fingerprint;
      case BiometricType.iris:
        return Icons.remove_red_eye;
      case BiometricType.strong:
        return Icons.security;
      case BiometricType.weak:
        return Icons.lock;
    }
  }

  /// Get biometric type display name
  static String getBiometricTypeDisplayName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris Scan';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
    }
  }

  /// Stop authentication (if needed)
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
      debugPrint(' Biometric authentication stopped');
    } catch (e) {
      debugPrint(' Stop authentication error: $e');
    }
  }
}