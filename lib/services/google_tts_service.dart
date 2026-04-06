import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/voice_profile.dart';
import '../models/voice_analytics.dart';
import '../models/voice_schedule.dart';

class GoogleTTSService {
  static final GoogleTTSService _instance = GoogleTTSService._internal();
  factory GoogleTTSService() => _instance;
  GoogleTTSService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _apiKey;
  String _voiceName = 'en-US-Wavenet-F';
  String _languageCode = 'en-US';
  double _pitch = 0.0;
  double _speakingRate = 1.0;
  double _volume = 1.0;
  bool _isInitialized = false;
  bool _isSpeaking = false;

  // ========================================
  // NEW: PROFILES, ANALYTICS, SCHEDULING
  // ========================================
  VoiceProfile? _activeProfile;
  List<VoiceProfile> _profiles = [];
  VoiceAnalytics _analytics = VoiceAnalytics.empty();
  List<VoiceScheduleEntry> _schedules = [];
  List<VoiceUsageRecord> _usageHistory = [];
  String _currentContext = 'general';
  bool _autoSwitchEnabled = true;
  bool _schedulingEnabled = true;

  // Accessibility features
  bool _accessibilityMode = false;
  double _clarityBoost = 0.0;
  bool _extraPauses = false;

  // ========================================
  // INITIALIZATION
  // ========================================

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _apiKey = dotenv.env['GOOGLE_CLOUD_TTS_API_KEY'];

      if (_apiKey == null || _apiKey!.isEmpty) {
        debugPrint(' Google Cloud TTS API key not found in .env');
        throw Exception('Google Cloud TTS API key not configured');
      }

      await _loadVoiceSettings();
      await _loadProfiles();
      await _loadAnalytics();
      await _loadSchedules();
      await _initializeDefaultProfiles();

      _isInitialized = true;
      debugPrint(' Google Cloud TTS initialized');
      debugPrint(' Voice: $_voiceName');
      debugPrint(' Language: $_languageCode');
      debugPrint(' Profiles loaded: ${_profiles.length}');
      debugPrint(' Schedules loaded: ${_schedules.length}');

      // Check if any schedule should be active now
      await _checkSchedules();

    } catch (e) {
      debugPrint(' Google TTS initialization failed: $e');
      rethrow;
    }
  }

  // ========================================
  // VOICE SETTINGS (EXISTING + ENHANCED)
  // ========================================

  Future<void> _loadVoiceSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _voiceName = prefs.getString('google_tts_voice') ??
          dotenv.env['GOOGLE_TTS_VOICE'] ??
          'en-US-Wavenet-F';

      _languageCode = prefs.getString('google_tts_language') ??
          dotenv.env['GOOGLE_TTS_LANGUAGE'] ??
          'en-US';

      _pitch = prefs.getDouble('google_tts_pitch') ?? 0.0;
      _speakingRate = prefs.getDouble('google_tts_rate') ?? 1.0;
      _volume = prefs.getDouble('google_tts_volume') ?? 1.0;

      // NEW: Load advanced settings
      _autoSwitchEnabled = prefs.getBool('voice_auto_switch') ?? true;
      _schedulingEnabled = prefs.getBool('voice_scheduling') ?? true;
      _accessibilityMode = prefs.getBool('voice_accessibility') ?? false;
      _clarityBoost = prefs.getDouble('voice_clarity_boost') ?? 0.0;
      _extraPauses = prefs.getBool('voice_extra_pauses') ?? false;

      debugPrint(' Loaded voice: $_voiceName ($_languageCode)');
    } catch (e) {
      debugPrint(' Using default voice');
      _voiceName = dotenv.env['GOOGLE_TTS_VOICE'] ?? 'en-US-Wavenet-F';
      _languageCode = dotenv.env['GOOGLE_TTS_LANGUAGE'] ?? 'en-US';
    }
  }

  Future<void> _saveVoiceSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('google_tts_voice', _voiceName);
      await prefs.setString('google_tts_language', _languageCode);
      await prefs.setDouble('google_tts_pitch', _pitch);
      await prefs.setDouble('google_tts_rate', _speakingRate);
      await prefs.setDouble('google_tts_volume', _volume);
      await prefs.setBool('voice_auto_switch', _autoSwitchEnabled);
      await prefs.setBool('voice_scheduling', _schedulingEnabled);
      await prefs.setBool('voice_accessibility', _accessibilityMode);
      await prefs.setDouble('voice_clarity_boost', _clarityBoost);
      await prefs.setBool('voice_extra_pauses', _extraPauses);

      debugPrint(' Voice settings saved: $_voiceName');
    } catch (e) {
      debugPrint(' Could not save voice settings: $e');
    }
  }

  // ========================================
  // PROFILE MANAGEMENT (NEW)
  // ========================================

  Future<void> _initializeDefaultProfiles() async {
    if (_profiles.isEmpty) {
      _profiles = [
        VoiceProfile.personal(),
        VoiceProfile.medical(),
        VoiceProfile.emergency(),
        VoiceProfile.nightMode(),
      ];
      await _saveProfiles();
      debugPrint(' Default profiles created');
    }
  }

  Future<void> _loadProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getString('voice_profiles');

      if (profilesJson != null) {
        final List<dynamic> decoded = jsonDecode(profilesJson);
        _profiles = decoded.map((e) => VoiceProfile.fromJson(e)).toList();

        // Load active profile
        final activeProfileId = prefs.getString('active_profile_id');
        if (activeProfileId != null) {
          _activeProfile = _profiles.firstWhere(
                (p) => p.id == activeProfileId,
            orElse: () => _profiles.first,
          );
          await _applyProfile(_activeProfile!);
        }
      }
    } catch (e) {
      debugPrint(' Error loading profiles: $e');
    }
  }

  Future<void> _saveProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = jsonEncode(_profiles.map((e) => e.toJson()).toList());
      await prefs.setString('voice_profiles', profilesJson);

      if (_activeProfile != null) {
        await prefs.setString('active_profile_id', _activeProfile!.id);
      }

      debugPrint(' Profiles saved: ${_profiles.length}');
    } catch (e) {
      debugPrint(' Error saving profiles: $e');
    }
  }

  Future<void> applyProfile(VoiceProfile profile) async {
    await _applyProfile(profile);
    _activeProfile = profile;

    // Update usage count
    final index = _profiles.indexWhere((p) => p.id == profile.id);
    if (index != -1) {
      _profiles[index] = profile.copyWith(
        usageCount: profile.usageCount + 1,
        lastUsed: DateTime.now(),
      );
      await _saveProfiles();
    }

    debugPrint(' Applied profile: ${profile.name}');
  }

  Future<void> _applyProfile(VoiceProfile profile) async {
    _voiceName = profile.voiceId;
    _languageCode = profile.voiceLang;
    _speakingRate = profile.speed;
    _pitch = profile.pitch;
    _volume = profile.volume;
    await _saveVoiceSettings();
  }

  Future<void> addProfile(VoiceProfile profile) async {
    _profiles.add(profile);
    await _saveProfiles();
    debugPrint(' Profile added: ${profile.name}');
  }

  Future<void> updateProfile(VoiceProfile profile) async {
    final index = _profiles.indexWhere((p) => p.id == profile.id);
    if (index != -1) {
      _profiles[index] = profile;
      await _saveProfiles();
      debugPrint(' Profile updated: ${profile.name}');
    }
  }

  Future<void> deleteProfile(String profileId) async {
    _profiles.removeWhere((p) => p.id == profileId);
    if (_activeProfile?.id == profileId) {
      _activeProfile = _profiles.isNotEmpty ? _profiles.first : null;
    }
    await _saveProfiles();
    debugPrint(' Profile deleted: $profileId');
  }

  List<VoiceProfile> getProfiles() => List.unmodifiable(_profiles);
  VoiceProfile? get activeProfile => _activeProfile;

  // ========================================
  // CONTEXT-AWARE SWITCHING (NEW)
  // ========================================

  Future<void> setContext(String context) async {
    _currentContext = context;

    if (!_autoSwitchEnabled) return;

    // Find profile with matching activation trigger
    final matchingProfile = _profiles.firstWhere(
          (p) => p.autoActivate &&
          p.activationTriggers != null &&
          p.activationTriggers!.contains(context),
      orElse: () => _profiles.first,
    );

    if (matchingProfile.id != _activeProfile?.id) {
      await applyProfile(matchingProfile);
      debugPrint(' Auto-switched to profile: ${matchingProfile.name} (context: $context)');
    }
  }

  // ========================================
  // SCHEDULING (NEW)
  // ========================================

  Future<void> _loadSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schedulesJson = prefs.getString('voice_schedules');

      if (schedulesJson != null) {
        final List<dynamic> decoded = jsonDecode(schedulesJson);
        _schedules = decoded.map((e) => VoiceScheduleEntry.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint(' Error loading schedules: $e');
    }
  }

  Future<void> _saveSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schedulesJson = jsonEncode(_schedules.map((e) => e.toJson()).toList());
      await prefs.setString('voice_schedules', schedulesJson);
      debugPrint(' Schedules saved: ${_schedules.length}');
    } catch (e) {
      debugPrint(' Error saving schedules: $e');
    }
  }

  Future<void> _checkSchedules() async {
    if (!_schedulingEnabled) return;

    for (var schedule in _schedules) {
      if (schedule.isActiveNow()) {
        final profile = _profiles.firstWhere(
              (p) => p.id == schedule.profileId,
          orElse: () => _profiles.first,
        );

        if (profile.id != _activeProfile?.id) {
          await applyProfile(profile);
          debugPrint(' Schedule activated: ${schedule.profileName}');
        }
        break; // Only apply first matching schedule
      }
    }
  }

  Future<void> addSchedule(VoiceScheduleEntry schedule) async {
    _schedules.add(schedule);
    await _saveSchedules();
    await _checkSchedules();
    debugPrint(' Schedule added: ${schedule.profileName}');
  }

  Future<void> updateSchedule(VoiceScheduleEntry schedule) async {
    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index != -1) {
      _schedules[index] = schedule;
      await _saveSchedules();
      await _checkSchedules();
      debugPrint(' Schedule updated: ${schedule.profileName}');
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    _schedules.removeWhere((s) => s.id == scheduleId);
    await _saveSchedules();
    debugPrint(' Schedule deleted: $scheduleId');
  }

  List<VoiceScheduleEntry> getSchedules() => List.unmodifiable(_schedules);

  // ========================================
  // ANALYTICS (NEW)
  // ========================================

  Future<void> _loadAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final analyticsJson = prefs.getString('voice_analytics');
      final historyJson = prefs.getString('voice_usage_history');

      if (analyticsJson != null) {
        _analytics = VoiceAnalytics.fromJson(jsonDecode(analyticsJson));
      }

      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _usageHistory = decoded.map((e) => VoiceUsageRecord.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint(' Error loading analytics: $e');
    }
  }

  Future<void> _saveAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('voice_analytics', jsonEncode(_analytics.toJson()));

      // Keep last 100 usage records
      final recentHistory = _usageHistory.length > 100
          ? _usageHistory.sublist(_usageHistory.length - 100)
          : _usageHistory;
      await prefs.setString(
        'voice_usage_history',
        jsonEncode(recentHistory.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint(' Error saving analytics: $e');
    }
  }

  Future<void> _trackUsage(String text, int durationSeconds) async {
    final record = VoiceUsageRecord(
      voiceId: _voiceName,
      voiceDisplay: _activeProfile?.voiceDisplay ?? _voiceName,
      timestamp: DateTime.now(),
      characterCount: text.length,
      durationSeconds: durationSeconds,
      context: _currentContext,
    );

    _usageHistory.add(record);

    // Update analytics
    final usageByVoice = Map<String, int>.from(_analytics.usageByVoice);
    usageByVoice[_voiceName] = (usageByVoice[_voiceName] ?? 0) + 1;

    final hour = DateTime.now().hour.toString();
    final usageByHour = Map<String, int>.from(_analytics.usageByHour);
    usageByHour[hour] = (usageByHour[hour] ?? 0) + 1;

    final usageByContext = Map<String, int>.from(_analytics.usageByContext);
    usageByContext[_currentContext] = (usageByContext[_currentContext] ?? 0) + 1;

    _analytics = VoiceAnalytics(
      usageByVoice: usageByVoice,
      usageByHour: usageByHour,
      usageByContext: usageByContext,
      recentUsage: _usageHistory.length > 10
          ? _usageHistory.sublist(_usageHistory.length - 10)
          : _usageHistory,
      totalCharacters: _analytics.totalCharacters + text.length,
      totalDuration: _analytics.totalDuration + durationSeconds,
      firstUse: _analytics.firstUse,
      lastUse: DateTime.now(),
    );

    await _saveAnalytics();
  }

  VoiceAnalytics getAnalytics() => _analytics;
  List<VoiceUsageRecord> getUsageHistory() => List.unmodifiable(_usageHistory);

  // ========================================
  // ACCESSIBILITY (NEW)
  // ========================================

  Future<void> setAccessibilityMode(bool enabled) async {
    _accessibilityMode = enabled;

    if (enabled) {
      // Optimize for accessibility
      _clarityBoost = 0.3;
      _extraPauses = true;
      _speakingRate = 0.9; // Slightly slower
      _pitch = 2.0; // Slightly higher for clarity
    } else {
      _clarityBoost = 0.0;
      _extraPauses = false;
    }

    await _saveVoiceSettings();
    debugPrint(' Accessibility mode: ${enabled ? "ON" : "OFF"}');
  }

  bool get accessibilityMode => _accessibilityMode;

  // ========================================
  // SYNTHESIS (EXISTING + ENHANCED)
  // ========================================

  Future<Uint8List?> synthesize(String text) async {
    if (!_isInitialized) await initialize();
    if (text.isEmpty) return null;

    try {
      // Add extra pauses for accessibility
      String processedText = text;
      if (_extraPauses) {
        processedText = text.replaceAll('. ', '... ').replaceAll(', ', ',, ');
      }

      final displayText = processedText.length > 50
          ? '${processedText.substring(0, 50)}...'
          : processedText;
      debugPrint(' Synthesizing ($_voiceName): "$displayText"');

      // Apply clarity boost
      final finalPitch = _pitch + _clarityBoost;

      final response = await http.post(
        Uri.parse('https://texttospeech.googleapis.com/v1/text:synthesize?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'input': {'text': processedText},
          'voice': {
            'languageCode': _languageCode,
            'name': _voiceName,
          },
          'audioConfig': {
            'audioEncoding': 'MP3',
            'pitch': finalPitch,
            'speakingRate': _speakingRate,
            'volumeGainDb': (_volume - 1.0) * 10, // Convert to dB
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final audioBytes = base64Decode(data['audioContent']);
        debugPrint(' Audio synthesized: ${audioBytes.length} bytes');
        return audioBytes;
      } else {
        debugPrint(' API error: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint(' Synthesis error: $e');
      return null;
    }
  }

  Future<void> speak(String text) async {
    if (_isSpeaking) await stop();

    try {
      _isSpeaking = true;
      final startTime = DateTime.now();

      final audioBytes = await synthesize(text);

      if (audioBytes == null) {
        _isSpeaking = false;
        return;
      }

      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.play(BytesSource(audioBytes));
      debugPrint(' Playing ($_voiceName)...');

      _audioPlayer.onPlayerComplete.listen((event) {
        _isSpeaking = false;
        final duration = DateTime.now().difference(startTime).inSeconds;
        _trackUsage(text, duration);
        debugPrint(' Playback complete');
      });
    } catch (e) {
      debugPrint(' Speak error: $e');
      _isSpeaking = false;
    }
  }

  Future<void> stop() async {
    if (_isSpeaking) {
      await _audioPlayer.stop();
      _isSpeaking = false;
    }
  }

  // ========================================
  // SETTERS (EXISTING + ENHANCED)
  // ========================================

  Future<void> setVoice(String voiceName, String languageCode) async {
    _voiceName = voiceName;
    _languageCode = languageCode;
    await _saveVoiceSettings();
    debugPrint(' Voice changed to: $_voiceName ($_languageCode)');
  }

  Future<void> setVoiceSettings({
    double? pitch,
    double? speed,
    double? volume,
  }) async {
    if (pitch != null) _pitch = pitch;
    if (speed != null) _speakingRate = speed;
    if (volume != null) _volume = volume;
    await _saveVoiceSettings();
    debugPrint(' Voice settings updated');
  }

  Future<void> setAutoSwitch(bool enabled) async {
    _autoSwitchEnabled = enabled;
    await _saveVoiceSettings();
    debugPrint(' Auto-switch: ${enabled ? "ON" : "OFF"}');
  }

  Future<void> setScheduling(bool enabled) async {
    _schedulingEnabled = enabled;
    await _saveVoiceSettings();
    if (enabled) await _checkSchedules();
    debugPrint(' Scheduling: ${enabled ? "ON" : "OFF"}');
  }

  // ========================================
  // GETTERS (EXISTING + NEW)
  // ========================================

  void dispose() {
    _audioPlayer.dispose();
  }

  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  String get currentVoice => _voiceName;
  String get currentLanguage => _languageCode;
  double get currentPitch => _pitch;
  double get currentSpeed => _speakingRate;
  double get currentVolume => _volume;
  bool get autoSwitchEnabled => _autoSwitchEnabled;
  bool get schedulingEnabled => _schedulingEnabled;
  String get currentContext => _currentContext;
}