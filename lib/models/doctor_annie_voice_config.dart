import 'package:flutter/foundation.dart';

/// Doctor Annie Voice Configuration
class DoctorAnnieVoiceConfig {
  // Voice Properties
  final VoicePitch pitch;
  final double speakingSpeed; // 0.5 to 2.0
  final VoiceAccent accent;
  final FormalityLevel formality;
  final VerbosityLevel verbosity;

  // AWS Polly Settings
  final String pollyVoiceId;
  final String pollyEngine;

  // Audio Effects
  final double volume; // 0.0 to 1.0
  final bool enableEmphasis;
  final bool enableBreaths;
  final bool enableWhisper;

  const DoctorAnnieVoiceConfig({
    this.pitch = VoicePitch.medium,
    this.speakingSpeed = 1.0,
    this.accent = VoiceAccent.usStandard,
    this.formality = FormalityLevel.professional,
    this.verbosity = VerbosityLevel.balanced,
    this.pollyVoiceId = 'Joanna',
    this.pollyEngine = 'neural',
    this.volume = 1.0,
    this.enableEmphasis = true,
    this.enableBreaths = true,
    this.enableWhisper = false,
  });

  DoctorAnnieVoiceConfig copyWith({
    VoicePitch? pitch,
    double? speakingSpeed,
    VoiceAccent? accent,
    FormalityLevel? formality,
    VerbosityLevel? verbosity,
    String? pollyVoiceId,
    String? pollyEngine,
    double? volume,
    bool? enableEmphasis,
    bool? enableBreaths,
    bool? enableWhisper,
  }) {
    return DoctorAnnieVoiceConfig(
      pitch: pitch ?? this.pitch,
      speakingSpeed: speakingSpeed ?? this.speakingSpeed,
      accent: accent ?? this.accent,
      formality: formality ?? this.formality,
      verbosity: verbosity ?? this.verbosity,
      pollyVoiceId: pollyVoiceId ?? this.pollyVoiceId,
      pollyEngine: pollyEngine ?? this.pollyEngine,
      volume: volume ?? this.volume,
      enableEmphasis: enableEmphasis ?? this.enableEmphasis,
      enableBreaths: enableBreaths ?? this.enableBreaths,
      enableWhisper: enableWhisper ?? this.enableWhisper,
    );
  }

  String getPollyVoiceIdForAccent() {
    switch (accent) {
      case VoiceAccent.usStandard:
        return pitch == VoicePitch.low ? 'Matthew' : 'Joanna';
      case VoiceAccent.usSouthern:
        return 'Joey';
      case VoiceAccent.british:
        return pitch == VoicePitch.low ? 'Brian' : 'Amy';
      case VoiceAccent.australian:
        return pitch == VoicePitch.low ? 'Russell' : 'Nicole';
      case VoiceAccent.indian:
        return pitch == VoicePitch.low ? 'Aditi' : 'Raveena';
      case VoiceAccent.canadian:
        return 'Joanna'; // Canadian is similar to US Standard
      case VoiceAccent.scottish:
        return 'Brian'; // Use Brian for Scottish
      case VoiceAccent.irish:
        return 'Brian'; // Use Brian for Irish
      case VoiceAccent.newZealand:
        return 'Nicole'; // Similar to Australian
      case VoiceAccent.southAfrican:
        return 'Amy'; // Use British as alternative
    }
  }

  String formatTextForSSML(String text) {
    String ssml = '<speak>';

    // Add pitch
    if (pitch != VoicePitch.medium) {
      final pitchValue = pitch == VoicePitch.low ? '-10%' : '+10%';
      ssml += '<prosody pitch="$pitchValue">';
    }

    // Add speaking rate
    if (speakingSpeed != 1.0) {
      final rate = '${(speakingSpeed * 100).toInt()}%';
      ssml += '<prosody rate="$rate">';
    }

    // Add emphasis if enabled
    if (enableEmphasis) {
      ssml += '<emphasis level="moderate">';
    }

    // Add the text
    ssml += text;

    // Close tags
    if (enableEmphasis) ssml += '</emphasis>';
    if (speakingSpeed != 1.0) ssml += '</prosody>';
    if (pitch != VoicePitch.medium) ssml += '</prosody>';

    ssml += '</speak>';

    return ssml;
  }

  Map<String, dynamic> toJson() {
    return {
      'pitch': pitch.name,
      'speakingSpeed': speakingSpeed,
      'accent': accent.name,
      'formality': formality.name,
      'verbosity': verbosity.name,
      'pollyVoiceId': pollyVoiceId,
      'pollyEngine': pollyEngine,
      'volume': volume,
      'enableEmphasis': enableEmphasis,
      'enableBreaths': enableBreaths,
      'enableWhisper': enableWhisper,
    };
  }

  factory DoctorAnnieVoiceConfig.fromJson(Map<String, dynamic> json) {
    return DoctorAnnieVoiceConfig(
      pitch: VoicePitch.values.firstWhere(
            (e) => e.name == json['pitch'],
        orElse: () => VoicePitch.medium,
      ),
      speakingSpeed: (json['speakingSpeed'] as num?)?.toDouble() ?? 1.0,
      accent: VoiceAccent.values.firstWhere(
            (e) => e.name == json['accent'],
        orElse: () => VoiceAccent.usStandard,
      ),
      formality: FormalityLevel.values.firstWhere(
            (e) => e.name == json['formality'],
        orElse: () => FormalityLevel.professional,
      ),
      verbosity: VerbosityLevel.values.firstWhere(
            (e) => e.name == json['verbosity'],
        orElse: () => VerbosityLevel.balanced,
      ),
      pollyVoiceId: json['pollyVoiceId'] as String? ?? 'Joanna',
      pollyEngine: json['pollyEngine'] as String? ?? 'neural',
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      enableEmphasis: json['enableEmphasis'] as bool? ?? true,
      enableBreaths: json['enableBreaths'] as bool? ?? true,
      enableWhisper: json['enableWhisper'] as bool? ?? false,
    );
  }
}

// ==================== ENUMS ====================

enum VoicePitch {
  low,
  medium,
  high,
}

enum VoiceAccent {
  usStandard,
  usSouthern,
  british,
  australian,
  indian,
  canadian,
  scottish,
  irish,
  newZealand,
  southAfrican,
}

enum FormalityLevel {
  casual,
  friendly,
  professional,
  formal,
  academic,
}

enum VerbosityLevel {
  concise,
  balanced,
  detailed,
  comprehensive,
}

// ==================== HELPER EXTENSIONS ====================

extension VoiceAccentExtension on VoiceAccent {
  String get displayName {
    switch (this) {
      case VoiceAccent.usStandard:
        return 'US Standard';
      case VoiceAccent.usSouthern:
        return 'US Southern';
      case VoiceAccent.british:
        return 'British';
      case VoiceAccent.australian:
        return 'Australian';
      case VoiceAccent.indian:
        return 'Indian';
      case VoiceAccent.canadian:
        return 'Canadian';
      case VoiceAccent.scottish:
        return 'Scottish';
      case VoiceAccent.irish:
        return 'Irish';
      case VoiceAccent.newZealand:
        return 'New Zealand';
      case VoiceAccent.southAfrican:
        return 'South African';
    }
  }
}

extension FormalityLevelExtension on FormalityLevel {
  String get displayName {
    switch (this) {
      case FormalityLevel.casual:
        return 'Casual';
      case FormalityLevel.friendly:
        return 'Friendly';
      case FormalityLevel.professional:
        return 'Professional';
      case FormalityLevel.formal:
        return 'Formal';
      case FormalityLevel.academic:
        return 'Academic';
    }
  }

  String get example {
    switch (this) {
      case FormalityLevel.casual:
        return "Hey! Let's talk about your symptoms.";
      case FormalityLevel.friendly:
        return "Hi! Let me help you with your health concerns.";
      case FormalityLevel.professional:
        return "Hello. I'll assist you with your medical questions today.";
      case FormalityLevel.formal:
        return "Good day. I shall provide medical guidance for your condition.";
      case FormalityLevel.academic:
        return "Greetings. I will elucidate the medical considerations pertinent to your inquiry.";
    }
  }
}