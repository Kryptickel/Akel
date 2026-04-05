import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// AWS Credentials Manager
/// Handles AWS credential management with Cognito Identity Pool support
/// and local caching (using SharedPreferences as fallback)
class AWSCredentialsManager {
  static final AWSCredentialsManager _instance = AWSCredentialsManager._internal();
  factory AWSCredentialsManager() => _instance;
  AWSCredentialsManager._internal();

  String? _accessKeyId;
  String? _secretAccessKey;
  String? _sessionToken;
  DateTime? _credentialsExpiration;
  bool _isInitialized = false;

  // Hardcoded configuration (replace with your actual values)
  // TODO: Move these to a config file or environment
  static const String _region = 'us-east-1';
  static const String _lexBotId = 'K8A276W4BC';
  static const String _lexBotAliasId = 'MRGY7SMUPH';
  static const String _lexLocaleId = 'en_US';

  // AWS Credentials (IMPORTANT: Never commit these to git!)
  // TODO: Move to secure storage or use Cognito
  static const String? _awsAccessKeyId = null; // Replace with your key
  static const String? _awsSecretAccessKey = null; // Replace with your secret
  static const String? _awsSessionToken = null; // Optional
  static const String? _cognitoIdentityPoolId = null; // Optional for Cognito
  static const String? _cognitoRegion = null; // Optional

  // Configuration getters
  String get region => _region;
  String get lexBotId => _lexBotId;
  String get lexBotAliasId => _lexBotAliasId;
  String get lexLocaleId => _lexLocaleId;

  /// Initialize credentials manager
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint(' AWS Credentials Manager already initialized');
      return;
    }

    try {
      debugPrint(' Initializing AWS Credentials Manager...');

      // Try to load cached credentials first
      await _loadCachedCredentials();

      // If no valid cached credentials, get new ones
      if (!_hasValidCredentials()) {
        debugPrint(' No valid cached credentials, fetching new ones...');
        await refreshCredentials();
      } else {
        debugPrint(' Using cached credentials (expires: $_credentialsExpiration)');
      }

      _isInitialized = true;
      debugPrint(' AWS Credentials Manager initialized successfully');
    } catch (e) {
      debugPrint(' Error initializing AWS Credentials Manager: $e');
      rethrow;
    }
  }

  /// Check if credentials manager is initialized
  bool get isInitialized => _isInitialized;

  /// Check if we have valid credentials
  bool _hasValidCredentials() {
    if (_accessKeyId == null || _secretAccessKey == null) {
      return false;
    }

    // Check if credentials are expired (with 5 minute buffer)
    if (_credentialsExpiration != null) {
      final expirationBuffer = _credentialsExpiration!.subtract(const Duration(minutes: 5));
      return DateTime.now().isBefore(expirationBuffer);
    }

    // If no expiration (static credentials), consider them valid
    return true;
  }

  /// Get current credentials
  Future<Map<String, String>> getCredentials() async {
    if (!_hasValidCredentials()) {
      await refreshCredentials();
    }

    return {
      'accessKeyId': _accessKeyId!,
      'secretAccessKey': _secretAccessKey!,
      if (_sessionToken != null) 'sessionToken': _sessionToken!,
    };
  }

  /// Refresh credentials
  Future<void> refreshCredentials() async {
    try {
      if (_cognitoIdentityPoolId != null && _cognitoIdentityPoolId!.isNotEmpty) {
        // Use Cognito for production
        debugPrint(' Refreshing credentials from Cognito...');
        await _getCredentialsFromCognito(_cognitoIdentityPoolId!);
      } else {
        // Use static credentials
        debugPrint(' Using static credentials...');
        await _getStaticCredentials();
      }

      // Cache credentials
      await _cacheCredentials();
      debugPrint(' Credentials refreshed successfully');
    } catch (e) {
      debugPrint(' Error refreshing credentials: $e');
      rethrow;
    }
  }

  /// Get credentials from AWS Cognito Identity Pool (Production)
  Future<void> _getCredentialsFromCognito(String identityPoolId) async {
    try {
      final cognitoRegion = _cognitoRegion ?? region;

      // Step 1: Get Identity ID
      final identityResponse = await http
          .post(
        Uri.https('cognito-identity.$cognitoRegion.amazonaws.com', '/'),
        headers: {
          'Content-Type': 'application/x-amz-json-1.1',
          'X-Amz-Target': 'AWSCognitoIdentityService.GetId',
        },
        body: jsonEncode({
          'IdentityPoolId': identityPoolId,
        }),
      )
          .timeout(const Duration(seconds: 10));

      if (identityResponse.statusCode != 200) {
        throw Exception('Failed to get identity ID: ${identityResponse.body}');
      }

      final identityData = jsonDecode(identityResponse.body);
      final identityId = identityData['IdentityId'] as String;

      debugPrint(' Got Identity ID: $identityId');

      // Step 2: Get credentials for identity
      final credentialsResponse = await http
          .post(
        Uri.https('cognito-identity.$cognitoRegion.amazonaws.com', '/'),
        headers: {
          'Content-Type': 'application/x-amz-json-1.1',
          'X-Amz-Target': 'AWSCognitoIdentityService.GetCredentialsForIdentity',
        },
        body: jsonEncode({
          'IdentityId': identityId,
        }),
      )
          .timeout(const Duration(seconds: 10));

      if (credentialsResponse.statusCode != 200) {
        throw Exception('Failed to get credentials: ${credentialsResponse.body}');
      }

      final credentialsData = jsonDecode(credentialsResponse.body);
      final credentials = credentialsData['Credentials'];

      _accessKeyId = credentials['AccessKeyId'];
      _secretAccessKey = credentials['SecretKey'];
      _sessionToken = credentials['SessionToken'];
      _credentialsExpiration = DateTime.parse(credentials['Expiration']);

      debugPrint(' Credentials obtained from Cognito (expires: $_credentialsExpiration)');
    } catch (e) {
      debugPrint(' Error getting Cognito credentials: $e');
      // Fallback to static credentials
      await _getStaticCredentials();
    }
  }

  /// Get static credentials from constants
  Future<void> _getStaticCredentials() async {
    _accessKeyId = _awsAccessKeyId;
    _secretAccessKey = _awsSecretAccessKey;
    _sessionToken = _awsSessionToken;
    _credentialsExpiration = null;

    if (_accessKeyId == null || _secretAccessKey == null) {
      throw Exception(
        'AWS credentials not configured. '
            'Please set _awsAccessKeyId and _awsSecretAccessKey constants '
            'or configure Cognito Identity Pool.',
      );
    }

    debugPrint(' Using static credentials');
  }

  /// Cache credentials
  Future<void> _cacheCredentials() async {
    try {
      if (_accessKeyId != null && _secretAccessKey != null) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('aws_access_key_id', _accessKeyId!);
        await prefs.setString('aws_secret_access_key', _secretAccessKey!);

        if (_sessionToken != null) {
          await prefs.setString('aws_session_token', _sessionToken!);
        } else {
          await prefs.remove('aws_session_token');
        }

        if (_credentialsExpiration != null) {
          await prefs.setString(
            'aws_credentials_expiration',
            _credentialsExpiration!.toIso8601String(),
          );
        } else {
          await prefs.remove('aws_credentials_expiration');
        }

        debugPrint(' Credentials cached');
      }
    } catch (e) {
      debugPrint(' Error caching credentials: $e');
      // Don't throw - caching is optional
    }
  }

  /// Load cached credentials
  Future<void> _loadCachedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _accessKeyId = prefs.getString('aws_access_key_id');
      _secretAccessKey = prefs.getString('aws_secret_access_key');
      _sessionToken = prefs.getString('aws_session_token');

      final expirationStr = prefs.getString('aws_credentials_expiration');
      if (expirationStr != null) {
        _credentialsExpiration = DateTime.parse(expirationStr);
      }

      if (_accessKeyId != null && _secretAccessKey != null) {
        debugPrint(' Loaded cached credentials');
      }
    } catch (e) {
      debugPrint(' No cached credentials found: $e');
      await clearCredentials();
    }
  }

  /// Clear all cached credentials
  Future<void> clearCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('aws_access_key_id');
      await prefs.remove('aws_secret_access_key');
      await prefs.remove('aws_session_token');
      await prefs.remove('aws_credentials_expiration');

      _accessKeyId = null;
      _secretAccessKey = null;
      _sessionToken = null;
      _credentialsExpiration = null;

      debugPrint(' Credentials cleared');
    } catch (e) {
      debugPrint(' Error clearing credentials: $e');
    }
  }

  /// Get access key (with automatic refresh)
  Future<String> get accessKey async {
    if (!_hasValidCredentials()) {
      await refreshCredentials();
    }
    if (_accessKeyId == null) {
      throw Exception('Access key not available after refresh');
    }
    return _accessKeyId!;
  }

  /// Get secret key (with automatic refresh)
  Future<String> get secretKey async {
    if (!_hasValidCredentials()) {
      await refreshCredentials();
    }
    if (_secretAccessKey == null) {
      throw Exception('Secret key not available after refresh');
    }
    return _secretAccessKey!;
  }

  /// Get session token if available
  Future<String?> get sessionToken async {
    if (!_hasValidCredentials()) {
      await refreshCredentials();
    }
    return _sessionToken;
  }

  /// Check credentials status (for debugging)
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'hasCredentials': _accessKeyId != null && _secretAccessKey != null,
      'hasSessionToken': _sessionToken != null,
      'expiresAt': _credentialsExpiration?.toIso8601String(),
      'isExpired': _credentialsExpiration != null
          ? DateTime.now().isAfter(_credentialsExpiration!)
          : false,
      'region': region,
      'lexBotId': lexBotId,
    };
  }
}