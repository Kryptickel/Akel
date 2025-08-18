// Application constants
class AppConstants {
  // App Information
  static const String appName = 'Akel';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Comprehensive panic button safety app';
  
  // Emergency Numbers
  static const String emergencyNumberUS = '911';
  static const String emergencyNumberInternational = '112';
  static const String crisisTextLine = '741741';
  static const String suicidePreventionHotline = '988';
  
  // Feature Flags
  static const bool enableVoiceActivation = true;
  static const bool enableSilentMode = true;
  static const bool enableLocationTracking = true;
  static const bool enableAudioRecording = true;
  static const bool enableVideoRecording = true;
  static const bool enableCloudStorage = true;
  static const bool enableMultiDevice = true;
  static const bool enableAIThreatDetection = false; // Coming soon
  static const bool enableCrashDetection = false; // Coming soon
  
  // Storage Keys
  static const String userProfileKey = 'user_profile';
  static const String emergencyContactsKey = 'emergency_contacts';
  static const String appSettingsKey = 'app_settings';
  static const String linkedDevicesKey = 'linked_devices';
  
  // API Endpoints (placeholder)
  static const String baseApiUrl = 'https://api.akel.app';
  static const String emergencyEndpoint = '/emergency';
  static const String locationEndpoint = '/location';
  static const String contactsEndpoint = '/contacts';
  
  // Timeouts and Intervals
  static const int emergencyResponseTimeout = 30; // seconds
  static const int locationUpdateInterval = 10; // seconds
  static const int healthCheckInterval = 60; // seconds
  
  // Security Settings
  static const int maxFailedAttempts = 3;
  static const int lockoutDuration = 300; // seconds (5 minutes)
  static const bool requireBiometric = true;
  
  // UI Constants
  static const double panicButtonSize = 200.0;
  static const double cardBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
}