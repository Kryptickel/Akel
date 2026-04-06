import 'dart:convert';

enum VoiceProfileType {
  personal,
  medical,
  emergency,
  nightMode,
  custom,
}

enum VoiceTone {
  friendly,
  calm,
  professional,
  enthusiastic,
  neutral,
  empathetic,
}

class VoiceProfile {
  final String id;
  final String name;
  final String description;
  final VoiceProfileType type;
  final String voiceId;
  final String voiceLang;
  final String voiceDisplay;
  final double speed;
  final double pitch;
  final double volume;
  final VoiceTone tone;
  final bool autoActivate;
  final List<String>? activationTriggers;
  final DateTime createdAt;
  final DateTime? lastUsed;
  final int usageCount;
  final bool isFavorite;

  VoiceProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.voiceId,
    required this.voiceLang,
    required this.voiceDisplay,
    this.speed = 1.0,
    this.pitch = 0.0,
    this.volume = 1.0,
    this.tone = VoiceTone.neutral,
    this.autoActivate = false,
    this.activationTriggers,
    DateTime? createdAt,
    this.lastUsed,
    this.usageCount = 0,
    this.isFavorite = false,
  }) : createdAt = createdAt ?? DateTime.now();

  // Factory constructors for default profiles
  factory VoiceProfile.personal() {
    return VoiceProfile(
      id: 'profile_personal',
      name: 'Personal',
      description: 'Casual, friendly voice for everyday use',
      type: VoiceProfileType.personal,
      voiceId: 'en-US-Wavenet-F',
      voiceLang: 'en-US',
      voiceDisplay: ' American Female',
      speed: 1.0,
      pitch: 0.0,
      volume: 0.9,
      tone: VoiceTone.friendly,
    );
  }

  factory VoiceProfile.medical() {
    return VoiceProfile(
      id: 'profile_medical',
      name: 'Medical Professional',
      description: 'Professional, calm voice for medical conversations',
      type: VoiceProfileType.medical,
      voiceId: 'en-GB-Wavenet-A',
      voiceLang: 'en-GB',
      voiceDisplay: ' British Female',
      speed: 0.9,
      pitch: -2.0,
      volume: 0.95,
      tone: VoiceTone.professional,
      autoActivate: true,
      activationTriggers: ['doctor_annie', 'medical_chat'],
    );
  }

  factory VoiceProfile.emergency() {
    return VoiceProfile(
      id: 'profile_emergency',
      name: 'Emergency',
      description: 'Clear, urgent voice for emergencies',
      type: VoiceProfileType.emergency,
      voiceId: 'en-GB-Wavenet-B',
      voiceLang: 'en-GB',
      voiceDisplay: ' British Male',
      speed: 1.2,
      pitch: 3.0,
      volume: 1.0,
      tone: VoiceTone.professional,
      autoActivate: true,
      activationTriggers: ['panic_button', 'emergency_alert'],
    );
  }

  factory VoiceProfile.nightMode() {
    return VoiceProfile(
      id: 'profile_night',
      name: 'Night Mode',
      description: 'Quiet, soothing voice for nighttime',
      type: VoiceProfileType.nightMode,
      voiceId: 'en-IN-Wavenet-A',
      voiceLang: 'en-IN',
      voiceDisplay: ' Indian Female',
      speed: 0.8,
      pitch: -5.0,
      volume: 0.6,
      tone: VoiceTone.calm,
      autoActivate: true,
      activationTriggers: ['time_22_06'],
    );
  }

  VoiceProfile copyWith({
    String? id,
    String? name,
    String? description,
    VoiceProfileType? type,
    String? voiceId,
    String? voiceLang,
    String? voiceDisplay,
    double? speed,
    double? pitch,
    double? volume,
    VoiceTone? tone,
    bool? autoActivate,
    List<String>? activationTriggers,
    DateTime? createdAt,
    DateTime? lastUsed,
    int? usageCount,
    bool? isFavorite,
  }) {
    return VoiceProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      voiceId: voiceId ?? this.voiceId,
      voiceLang: voiceLang ?? this.voiceLang,
      voiceDisplay: voiceDisplay ?? this.voiceDisplay,
      speed: speed ?? this.speed,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      tone: tone ?? this.tone,
      autoActivate: autoActivate ?? this.autoActivate,
      activationTriggers: activationTriggers ?? this.activationTriggers,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      usageCount: usageCount ?? this.usageCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString(),
      'voiceId': voiceId,
      'voiceLang': voiceLang,
      'voiceDisplay': voiceDisplay,
      'speed': speed,
      'pitch': pitch,
      'volume': volume,
      'tone': tone.toString(),
      'autoActivate': autoActivate,
      'activationTriggers': activationTriggers,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
      'usageCount': usageCount,
      'isFavorite': isFavorite,
    };
  }

  factory VoiceProfile.fromJson(Map<String, dynamic> json) {
    return VoiceProfile(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: VoiceProfileType.values.firstWhere(
            (e) => e.toString() == json['type'],
        orElse: () => VoiceProfileType.custom,
      ),
      voiceId: json['voiceId'],
      voiceLang: json['voiceLang'],
      voiceDisplay: json['voiceDisplay'],
      speed: json['speed'],
      pitch: json['pitch'],
      volume: json['volume'],
      tone: VoiceTone.values.firstWhere(
            (e) => e.toString() == json['tone'],
        orElse: () => VoiceTone.neutral,
      ),
      autoActivate: json['autoActivate'] ?? false,
      activationTriggers: json['activationTriggers'] != null
          ? List<String>.from(json['activationTriggers'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      lastUsed: json['lastUsed'] != null ? DateTime.parse(json['lastUsed']) : null,
      usageCount: json['usageCount'] ?? 0,
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  String get toneEmoji {
    switch (tone) {
      case VoiceTone.friendly:
        return ' ';
      case VoiceTone.calm:
        return ' ';
      case VoiceTone.professional:
        return ' ';
      case VoiceTone.enthusiastic:
        return ' ';
      case VoiceTone.neutral:
        return ' ';
      case VoiceTone.empathetic:
        return ' ';
    }
  }

  String get typeEmoji {
    switch (type) {
      case VoiceProfileType.personal:
        return ' ';
      case VoiceProfileType.medical:
        return ' ';
      case VoiceProfileType.emergency:
        return ' ';
      case VoiceProfileType.nightMode:
        return ' ';
      case VoiceProfileType.custom:
        return ' ';
    }
  }
}