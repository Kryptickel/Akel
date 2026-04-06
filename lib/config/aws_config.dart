/// ==================== AWS CONFIGURATION ====================
///
/// AWS Polly V2 Configuration for AKEL Panic Button
///
/// Region: US-East-1 (N. Virginia)
/// Voice: Joanna (Neural)
///
/// ==========================================================

class AWSConfig {
// ==================== REGION SETTINGS ====================

  /// Primary AWS region
  static const String region = 'us-east-1';

  /// Backup region (failover)
  static const String backupRegion = 'us-west-2';

// ==================== POLLY SETTINGS ====================

  /// AWS Polly endpoint URL
  static const String pollyEndpoint = 'https://polly.us-east-1.amazonaws.com';

  /// Default voice ID
  static const String voiceId = 'Joanna';
  /// Voice engine type (neural or standard)
  static const String engine = 'neural';

  /// Language code
  static const String languageCode = 'en-US';

// ==================== VOICE SETTINGS ====================

  /// Default speech rate (x-slow, slow, medium, fast, x-fast)
  static const String defaultSpeechRate = 'medium';

  /// Default pitch (x-low, low, medium, high, x-high)
  static const String defaultPitch = 'medium';

  /// Default volume (silent, x-soft, soft, medium, loud, x-loud)
  static const String defaultVolume = 'medium';

// ==================== PRICING ====================

  /// Cost per million characters (Neural)
  static const double costPerMillionCharsNeural = 16.0;

  /// Cost per million characters (Standard)
  static const double costPerMillionCharsStandard = 4.0;

// ==================== AVAILABLE VOICES ====================

  /// List of available US English voices
  static const List<String> availableVoices = [
    'Joanna', // Female (Neural) - Recommended
    'Matthew', // Male (Neural)
    'Ivy', // Female (Neural) - Child
    'Kendra', // Female (Neural)
    'Kimberly', // Female (Neural)
    'Salli', // Female (Neural)
    'Joey', // Male (Neural)
    'Justin', // Male (Neural) - Child
    'Kevin', // Male (Neural) - Child
    'Ruth', // Female (Neural)
    'Stephen', // Male (Neural)
  ];

// ==================== VOICE CHARACTERISTICS ====================

  static const Map<String, Map<String, String>> voiceCharacteristics = {
    'Joanna': {
      'gender': 'Female',
      'description': 'Professional, clear, versatile',
      'recommended': 'Emergency announcements, navigation',
    },
    'Matthew': {
      'gender': 'Male',
      'description': 'Authoritative, clear, professional',
      'recommended': 'Alerts, warnings',
    },
    'Ivy': {
      'gender': 'Female',
      'description': 'Young, friendly',
      'recommended': 'Child-friendly announcements',
    },
    'Kendra': {
      'gender': 'Female',
      'description': 'Conversational, friendly',
      'recommended': 'General use',
    },
    'Kimberly': {
      'gender': 'Female',
      'description': 'Professional, warm',
      'recommended': 'Medical information',
    },
    'Salli': {
      'gender': 'Female',
      'description': 'Soft, gentle',
      'recommended': 'Calming announcements',
    },
    'Joey': {
      'gender': 'Male',
      'description': 'Casual, friendly',
      'recommended': 'General use',
    },
    'Justin': {
      'gender': 'Male',
      'description': 'Young, energetic',
      'recommended': 'Youth-oriented content',
    },
  };

// ==================== RATE LIMITS ====================

  /// Maximum characters per request
  static const int maxCharsPerRequest = 3000;

  /// Maximum requests per second
  static const int maxRequestsPerSecond = 100;

// ==================== CACHE SETTINGS ====================

  /// Enable audio caching
  static const bool enableCaching = true;

  /// Cache duration in days
  static const int cacheDurationDays = 7;

// ==================== HELPER METHODS ====================

  /// Get voice description
  static String getVoiceDescription(String voiceId) {
    return voiceCharacteristics[voiceId]?['description'] ?? 'Unknown voice';
  }

  /// Get voice gender
  static String getVoiceGender(String voiceId) {
    return voiceCharacteristics[voiceId]?['gender'] ?? 'Unknown';
  }

  /// Get voice recommendation
  static String getVoiceRecommendation(String voiceId) {
    return voiceCharacteristics[voiceId]?['recommended'] ?? 'General use';
  }

  /// Calculate cost for text
  static double calculateCost(String text, {bool neural = true}) {
    final charCount = text.length;
    final costPerChar = neural
        ? costPerMillionCharsNeural / 1000000
        : costPerMillionCharsStandard / 1000000;
    return charCount * costPerChar;
  }

  /// Format cost as string
  static String formatCost(double cost) {
    if (cost < 0.01) {
      return '<\$0.01';
    }
    return '\$${cost.toStringAsFixed(2)}';
  }
}
