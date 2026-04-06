import 'dart:convert';

class VoiceUsageRecord {
  final String voiceId;
  final String voiceDisplay;
  final DateTime timestamp;
  final int characterCount;
  final int durationSeconds;
  final String context;

  VoiceUsageRecord({
    required this.voiceId,
    required this.voiceDisplay,
    required this.timestamp,
    required this.characterCount,
    required this.durationSeconds,
    required this.context,
  });

  Map<String, dynamic> toJson() {
    return {
      'voiceId': voiceId,
      'voiceDisplay': voiceDisplay,
      'timestamp': timestamp.toIso8601String(),
      'characterCount': characterCount,
      'durationSeconds': durationSeconds,
      'context': context,
    };
  }

  factory VoiceUsageRecord.fromJson(Map<String, dynamic> json) {
    return VoiceUsageRecord(
      voiceId: json['voiceId'],
      voiceDisplay: json['voiceDisplay'],
      timestamp: DateTime.parse(json['timestamp']),
      characterCount: json['characterCount'],
      durationSeconds: json['durationSeconds'],
      context: json['context'],
    );
  }
}

class VoiceAnalytics {
  final Map<String, int> usageByVoice;
  final Map<String, int> usageByHour;
  final Map<String, int> usageByContext;
  final List<VoiceUsageRecord> recentUsage;
  final int totalCharacters;
  final int totalDuration;
  final DateTime firstUse;
  final DateTime lastUse;

  VoiceAnalytics({
    required this.usageByVoice,
    required this.usageByHour,
    required this.usageByContext,
    required this.recentUsage,
    required this.totalCharacters,
    required this.totalDuration,
    required this.firstUse,
    required this.lastUse,
  });

  String get mostUsedVoice {
    if (usageByVoice.isEmpty) return 'None';
    return usageByVoice.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  int get mostActiveHour {
    if (usageByHour.isEmpty) return 12;
    return int.parse(usageByHour.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key);
  }

  String get mostCommonContext {
    if (usageByContext.isEmpty) return 'None';
    return usageByContext.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  double getVoiceUsagePercentage(String voiceId) {
    if (usageByVoice.isEmpty) return 0.0;
    final total = usageByVoice.values.reduce((a, b) => a + b);
    return ((usageByVoice[voiceId] ?? 0) / total * 100);
  }

  Map<String, dynamic> toJson() {
    return {
      'usageByVoice': usageByVoice,
      'usageByHour': usageByHour,
      'usageByContext': usageByContext,
      'recentUsage': recentUsage.map((e) => e.toJson()).toList(),
      'totalCharacters': totalCharacters,
      'totalDuration': totalDuration,
      'firstUse': firstUse.toIso8601String(),
      'lastUse': lastUse.toIso8601String(),
    };
  }

  factory VoiceAnalytics.fromJson(Map<String, dynamic> json) {
    return VoiceAnalytics(
      usageByVoice: Map<String, int>.from(json['usageByVoice']),
      usageByHour: Map<String, int>.from(json['usageByHour']),
      usageByContext: Map<String, int>.from(json['usageByContext']),
      recentUsage: (json['recentUsage'] as List)
          .map((e) => VoiceUsageRecord.fromJson(e))
          .toList(),
      totalCharacters: json['totalCharacters'],
      totalDuration: json['totalDuration'],
      firstUse: DateTime.parse(json['firstUse']),
      lastUse: DateTime.parse(json['lastUse']),
    );
  }

  factory VoiceAnalytics.empty() {
    return VoiceAnalytics(
      usageByVoice: {},
      usageByHour: {},
      usageByContext: {},
      recentUsage: [],
      totalCharacters: 0,
      totalDuration: 0,
      firstUse: DateTime.now(),
      lastUse: DateTime.now(),
    );
  }
}