/// API Keys Configuration
/// Store all API keys and sensitive credentials here
/// DO NOT commit this file to version control!

class ApiKeys {
// ==================== PRIVATE CONSTRUCTOR ====================

  /// Private constructor to prevent instantiation
  ApiKeys._();

// ==================== DEBUG CONFIGURATION ====================

  /// Enable debug logs for API calls
  static const bool debugLogsEnabled = true;

// ==================== FIREBASE ====================

  /// Firebase configuration (from google-services.json / GoogleService-Info.plist)
  static const String firebaseApiKey = 'YOUR_FIREBASE_API_KEY';
  static const String firebaseProjectId = 'YOUR_FIREBASE_PROJECT_ID';
  static const String firebaseMessagingSenderId = 'YOUR_MESSAGING_SENDER_ID';
  static const String firebaseAppId = 'YOUR_FIREBASE_APP_ID';
  static const String firebaseMeasurementId = 'YOUR_MEASUREMENT_ID';

// ==================== GOOGLE MAPS ====================

  /// Google Maps API Key (for Android)
  static const String googleMapsApiKeyAndroid = 'YOUR_GOOGLE_MAPS_ANDROID_KEY';

  /// Google Maps API Key (for iOS)
  static const String googleMapsApiKeyIOS = 'YOUR_GOOGLE_MAPS_IOS_KEY';

// ==================== GOOGLE PLACES API ====================

  /// Google Places API Key (ADDED - fixes hospital_service error)
  static const String googlePlacesApiKey = 'YOUR_GOOGLE_PLACES_API_KEY';

// ==================== AWS (if using) ====================

  /// AWS Access Key ID
  static const String awsAccessKeyId = 'YOUR_AWS_ACCESS_KEY_ID';

  /// AWS Secret Access Key
  static const String awsSecretAccessKey = 'YOUR_AWS_SECRET_ACCESS_KEY';

  /// AWS Region
  static const String awsRegion = 'us-east-1';

  /// AWS S3 Bucket Name
  static const String awsS3BucketName = 'your-bucket-name';

// ==================== OTHER APIs ====================

  /// OpenAI API Key (for Doctor Annie AI)
  static const String openAiApiKey = 'YOUR_OPENAI_API_KEY';

  /// Weather API Key (if using weather service)
  static const String weatherApiKey = 'YOUR_WEATHER_API_KEY';

  /// SMS Service API Key (Twilio, etc.)
  static const String smsServiceApiKey = 'YOUR_SMS_API_KEY';
  static const String smsServiceAccountSid = 'YOUR_SMS_ACCOUNT_SID';
  static const String smsServiceAuthToken = 'YOUR_SMS_AUTH_TOKEN';

// ==================== VERIFICATION METHODS ====================

  /// Check if Firebase is configured
  static bool get isFirebaseConfigured =>
      firebaseApiKey.isNotEmpty &&
          firebaseApiKey != 'YOUR_FIREBASE_API_KEY';

  /// Check if Google Maps is configured
  static bool get isGoogleMapsConfigured =>
      googleMapsApiKeyAndroid.isNotEmpty &&
          googleMapsApiKeyAndroid != 'YOUR_GOOGLE_MAPS_ANDROID_KEY';

  /// Check if Google Places is configured (ADDED - fixes hospital_service error)
  static bool get isGooglePlacesConfigured =>
      googlePlacesApiKey.isNotEmpty &&
          googlePlacesApiKey != 'YOUR_GOOGLE_PLACES_API_KEY';

  /// Check if AWS is configured
  static bool get isAwsConfigured =>
      awsAccessKeyId.isNotEmpty &&
          awsAccessKeyId != 'YOUR_AWS_ACCESS_KEY_ID';

  /// Check if OpenAI is configured
  static bool get isOpenAiConfigured =>
      openAiApiKey.isNotEmpty &&
          openAiApiKey != 'YOUR_OPENAI_API_KEY';

// ==================== DEBUG & TEST METHODS ====================

  /// Enable debug logs getter
  static bool get enableDebugLogs => debugLogsEnabled;

  /// Enable test mode for development
  static bool get enableTestMode => debugLogsEnabled;

  /// Print API configuration status to console
  static void printConfigurationStatus() {
    if (!debugLogsEnabled) return;

    print('\n════════════════════════════════════════');
    print('🔑 API KEYS CONFIGURATION STATUS');
    print('════════════════════════════════════════');
    print('✅ Firebase: ${isFirebaseConfigured ? "CONFIGURED" : "NOT CONFIGURED"}');
    print('✅ Google Maps: ${isGoogleMapsConfigured ? "CONFIGURED" : "NOT CONFIGURED"}');
    print('✅ Google Places: ${isGooglePlacesConfigured ? "CONFIGURED" : "NOT CONFIGURED"}');
    print('✅ AWS: ${isAwsConfigured ? "CONFIGURED" : "NOT CONFIGURED"}');
    print('✅ OpenAI: ${isOpenAiConfigured ? "CONFIGURED" : "NOT CONFIGURED"}');
    print('════════════════════════════════════════\n');
  }
}