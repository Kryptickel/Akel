import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/google_tts_service.dart';

/// ==================== ENHANCED AWS POLLY SERVICE V2 ====================
///
/// UNIFIED TTS SERVICE - Voice Center Integration
///
/// Features:
/// - AWS Polly V2 Neural Voices (13 voices)
/// - Google Cloud TTS Integration (40+ voices from Voice Center)
/// - Seamless Provider Switching
/// - Voice Profiles & Analytics
/// - Complete Voice Control
///
/// BUILD 55 - Voice Center Complete Integration
/// API Version: V2 (Latest)
/// ========================================================================

/// TTS Provider Options
enum TTSProvider {
  awsPolly,
  googleTTS,
}

/// Available AWS Polly neural voices with detailed information
enum PollyVoice {
  joanna('Joanna', 'en-US', 'Female', 'Warm, professional American voice'),
  matthew('Matthew', 'en-US', 'Male', 'Clear, confident American voice'),
  salli('Salli', 'en-US', 'Female', 'Friendly, approachable American voice'),
  joey('Joey', 'en-US', 'Male', 'Young, energetic American voice'),
  kendra('Kendra', 'en-US', 'Female', 'Neutral, professional American voice'),
  kevin('Kevin', 'en-US', 'Male', 'Conversational American voice'),
  amy('Amy', 'en-GB', 'Female', 'British English voice'),
  emma('Emma', 'en-GB', 'Female', 'Soft British English voice'),
  brian('Brian', 'en-GB', 'Male', 'British English voice'),
  arthur('Arthur', 'en-GB', 'Male', 'Professional British voice'),
  nicole('Nicole', 'en-AU', 'Female', 'Australian English voice'),
  olivia('Olivia', 'en-AU', 'Female', 'Neutral Australian voice'),
  russell('Russell', 'en-AU', 'Male', 'Australian English voice');

  final String voiceId;
  final String languageCode;
  final String gender;
  final String description;

  const PollyVoice(this.voiceId, this.languageCode, this.gender, this.description);

  String get displayName => '$voiceId ($languageCode)';
  String get shortName => voiceId;

  IconData get icon {
    return gender == 'Male' ? Icons.face_2 : Icons.face;
  }

  String get flag {
    if (languageCode.contains('US')) return ' ';
    if (languageCode.contains('GB')) return ' ';
    if (languageCode.contains('AU')) return ' ';
    return ' ';
  }
}

class EnhancedAWSPollyService {
  static final EnhancedAWSPollyService _instance = EnhancedAWSPollyService._internal();
  factory EnhancedAWSPollyService() => _instance;
  EnhancedAWSPollyService._internal();

  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Google TTS integration
  final GoogleTTSService _googleTTS = GoogleTTSService();

  // State
  bool _isSpeaking = false;
  bool _isInitialized = false;

  // Provider selection
  TTSProvider _currentProvider = TTSProvider.awsPolly;

  // AWS Polly settings
  PollyVoice _selectedVoice = PollyVoice.joanna;
  double _speechRate = 1.0; // 0.5 to 2.0
  double _volume = 1.0; // 0.0 to 1.0
  double _pitch = 0.0; // -20 to 20 (for Google TTS)

  // AWS Credentials from .env
  late String _accessKey;
  late String _secretKey;
  late String _region;

  // Google TTS settings (from Voice Center)
  String _googleVoiceId = 'en-US-Wavenet-F';
  String _googleVoiceLang = 'en-US';

  // Polly Configuration
  static const String _engine = 'neural';
  static const String _outputFormat = 'mp3';
  static const String _sampleRate = '24000';
  static const String _apiVersion = 'v2'; // V2 API

  // Preferences keys
  static const String _prefsKeyProvider = 'doctor_annie_tts_provider';
  static const String _prefsKeyVoice = 'polly_selected_voice';
  static const String _prefsKeySpeechRate = 'polly_speech_rate';
  static const String _prefsKeyVolume = 'polly_volume';
  static const String _prefsKeyPitch = 'polly_pitch';
  static const String _prefsKeyGoogleVoice = 'doctor_annie_google_voice_id';
  static const String _prefsKeyGoogleLang = 'doctor_annie_google_voice_lang';

  /// Getters
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  PollyVoice get currentVoice => _selectedVoice;
  TTSProvider get currentProvider => _currentProvider;
  double get currentSpeechRate => _speechRate;
  double get currentVolume => _volume;
  double get currentPitch => _pitch;
  String get googleVoiceId => _googleVoiceId;
  String get googleVoiceLang => _googleVoiceLang;
  String get apiVersion => _apiVersion;

  /// Initialize AWS Polly V2 Service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint(' AWS Polly V2 already initialized');
      return;
    }

    try {
      debugPrint(' Initializing Enhanced AWS Polly V2 Service...');
      debugPrint(' API Version: $_apiVersion');

      // Load AWS credentials from .env
      _accessKey = dotenv.env['AWS_ACCESS_KEY_ID'] ?? 'AKIA2EM7JUJD5CXLGQOY';
      _secretKey = dotenv.env['AWS_SECRET_ACCESS_KEY'] ?? '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';
      _region = dotenv.env['AWS_REGION'] ?? 'us-east-1';

      if (_accessKey.isEmpty || _secretKey.isEmpty) {
        debugPrint(' AWS credentials not found in .env, using fallback');
        // Fallback to Google TTS if AWS credentials missing
        _currentProvider = TTSProvider.googleTTS;
      }

      // Initialize Google TTS
      await _googleTTS.initialize();

      // Load user preferences
      await _loadPreferences();

      _isInitialized = true;
      debugPrint(' AWS Polly V2 Service initialized');
      debugPrint(' Provider: ${_currentProvider.name}');
      if (_currentProvider == TTSProvider.awsPolly) {
        debugPrint(' AWS Voice: ${_selectedVoice.displayName} (${_selectedVoice.gender})');
      } else {
        debugPrint(' Google Voice: $_googleVoiceId');
      }
      debugPrint(' Settings: Rate=$_speechRate, Volume=$_volume, Pitch=$_pitch');
    } catch (e) {
      debugPrint(' Error initializing AWS Polly V2: $e');
      // Don't rethrow - allow app to continue with Google TTS
      _currentProvider = TTSProvider.googleTTS;
      _isInitialized = true;
    }
  }

  /// Load saved preferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load provider
      final providerIndex = prefs.getInt(_prefsKeyProvider) ?? 0;
      if (providerIndex < TTSProvider.values.length) {
        _currentProvider = TTSProvider.values[providerIndex];
      }

      // Load AWS Polly voice
      final voiceId = prefs.getString(_prefsKeyVoice);
      if (voiceId != null) {
        try {
          _selectedVoice = PollyVoice.values.firstWhere(
                (v) => v.voiceId == voiceId,
            orElse: () => PollyVoice.joanna,
          );
        } catch (e) {
          _selectedVoice = PollyVoice.joanna;
        }
      }

      // Load Google TTS voice
      _googleVoiceId = prefs.getString(_prefsKeyGoogleVoice) ?? 'en-US-Wavenet-F';
      _googleVoiceLang = prefs.getString(_prefsKeyGoogleLang) ?? 'en-US';

      // Load voice parameters
      _speechRate = prefs.getDouble(_prefsKeySpeechRate) ?? 1.0;
      _volume = prefs.getDouble(_prefsKeyVolume) ?? 1.0;
      _pitch = prefs.getDouble(_prefsKeyPitch) ?? 0.0;

      await _audioPlayer.setVolume(_volume);

      debugPrint(' Preferences loaded successfully');
    } catch (e) {
      debugPrint(' Error loading preferences: $e');
    }
  }

  /// Save preferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKeyProvider, _currentProvider.index);
      await prefs.setString(_prefsKeyVoice, _selectedVoice.voiceId);
      await prefs.setString(_prefsKeyGoogleVoice, _googleVoiceId);
      await prefs.setString(_prefsKeyGoogleLang, _googleVoiceLang);
      await prefs.setDouble(_prefsKeySpeechRate, _speechRate);
      await prefs.setDouble(_prefsKeyVolume, _volume);
      await prefs.setDouble(_prefsKeyPitch, _pitch);
      debugPrint(' Preferences saved');
    } catch (e) {
      debugPrint(' Error saving preferences: $e');
    }
  }

  /// Switch TTS Provider
  Future<void> setProvider(TTSProvider provider) async {
    _currentProvider = provider;
    await _savePreferences();
    debugPrint(' Switched to ${provider.name}');
  }

  /// Change AWS Polly voice
  Future<void> setVoice(PollyVoice voice) async {
    _selectedVoice = voice;
    await _savePreferences();
    debugPrint(' AWS Polly voice changed to: ${voice.displayName}');
  }

  /// Set Google TTS voice (from Voice Center)
  Future<void> setGoogleVoice(String voiceId, String language) async {
    _googleVoiceId = voiceId;
    _googleVoiceLang = language;
    await _savePreferences();
    debugPrint(' Google TTS voice changed to: $voiceId');
  }

  /// Set speech rate (0.5 to 2.0)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.5, 2.0);
    await _savePreferences();
    debugPrint(' Speech rate set to: $_speechRate');
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_volume);
    await _savePreferences();
    debugPrint(' Volume set to: $_volume');
  }

  /// Set pitch (-20 to 20, Google TTS only)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(-20.0, 20.0);
    await _savePreferences();
    debugPrint(' Pitch set to: $_pitch');
  }

  /// Set voice settings in one call
  Future<void> setVoiceSettings({
    double? volume,
    double? speed,
    double? pitch,
  }) async {
    if (volume != null) await setVolume(volume);
    if (speed != null) await setSpeechRate(speed);
    if (pitch != null) await setPitch(pitch);
  }

  /// Main speak method - uses current provider
  Future<bool> speak(String text) async {
    if (!_isInitialized) {
      debugPrint(' Service not initialized, initializing now...');
      await initialize();
    }

    if (text.trim().isEmpty) {
      debugPrint(' Empty text, skipping speech');
      return false;
    }

    if (_isSpeaking) {
      debugPrint(' Already speaking, stopping previous...');
      await stop();
    }

    try {
      _isSpeaking = true;

      switch (_currentProvider) {
        case TTSProvider.awsPolly:
          return await _speakPolly(text);
        case TTSProvider.googleTTS:
          return await _speakGoogle(text);
      }
    } catch (e) {
      debugPrint(' Speak error: $e');
      _isSpeaking = false;

      // Try fallback provider
      try {
        debugPrint(' Attempting fallback to other provider...');
        if (_currentProvider == TTSProvider.awsPolly) {
          return await _speakGoogle(text);
        } else {
          return await _speakPolly(text);
        }
      } catch (fallbackError) {
        debugPrint(' Fallback also failed: $fallbackError');
        return false;
      }
    }
  }

  /// Speak using AWS Polly V2
  Future<bool> _speakPolly(String text) async {
    try {
      final preview = text.length > 50 ? '${text.substring(0, 50)}...' : text;
      debugPrint(' ${_selectedVoice.flag} ${_selectedVoice.shortName} speaking (V2): $preview');

      // Apply speech rate using SSML
      final ssmlText = _applySSML(text);

      // Call AWS Polly V2 API
      final audioData = await _synthesizeSpeech(ssmlText);

      if (audioData == null) {
        debugPrint(' Failed to get audio from Polly V2');
        _isSpeaking = false;
        return false;
      }

      // Save audio to temp file
      final audioFile = await _saveAudioToFile(audioData, 'polly_v2');

      // Play audio
      await _audioPlayer.play(DeviceFileSource(audioFile.path));

      // Wait for playback to complete
      await _audioPlayer.onPlayerComplete.first;

      debugPrint(' AWS Polly V2 speech completed');
      _isSpeaking = false;
      return true;
    } catch (e) {
      debugPrint(' AWS Polly V2 error: $e');
      _isSpeaking = false;
      return false;
    }
  }

  /// Speak using Google Cloud TTS
  Future<bool> _speakGoogle(String text) async {
    try {
      debugPrint(' Google TTS speaking...');

      // Set voice
      await _googleTTS.setVoice(_googleVoiceId, _googleVoiceLang);

      // Set voice settings
      await _googleTTS.setVoiceSettings(
        pitch: _pitch,
        speed: _speechRate,
        volume: _volume,
      );

      // Speak
      await _googleTTS.speak(text);

      _isSpeaking = false;
      debugPrint(' Google TTS completed');
      return true;
    } catch (e) {
      debugPrint(' Google TTS error: $e');
      _isSpeaking = false;
      return false;
    }
  }

  /// Apply SSML formatting for speech rate (AWS Polly)
  String _applySSML(String text) {
    if (_speechRate == 1.0) {
      return text; // No SSML needed
    }

    // Convert rate to percentage (0.5 = 50%, 2.0 = 200%)
    final ratePercent = (_speechRate * 100).round();
    return '<speak><prosody rate="$ratePercent%">$text</prosody></speak>';
  }

  /// Synthesize speech using AWS Polly API V2
  Future<Uint8List?> _synthesizeSpeech(String text) async {
    try {
      // AWS Polly V2 endpoint
      final endpoint = 'https://polly.$_region.amazonaws.com/$_apiVersion/speech';

      // Determine text type
      final textType = text.contains('<speak>') ? 'ssml' : 'text';

      // Prepare request body for V2
      final body = jsonEncode({
        'Text': text,
        'VoiceId': _selectedVoice.voiceId,
        'Engine': _engine,
        'OutputFormat': _outputFormat,
        'SampleRate': _sampleRate,
        'LanguageCode': _selectedVoice.languageCode,
        'TextType': textType,
      });

      // Sign request with AWS Signature V4
      final headers = await _signRequest(
        method: 'POST',
        endpoint: endpoint,
        body: body,
        service: 'polly',
      );

      debugPrint(' Calling AWS Polly $_apiVersion API (${_selectedVoice.shortName})...');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        debugPrint(' Got audio from Polly $_apiVersion (${response.bodyBytes.length} bytes)');
        return response.bodyBytes;
      } else {
        debugPrint(' Polly $_apiVersion API error: ${response.statusCode}');
        debugPrint(' Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint(' Error calling Polly $_apiVersion API: $e');
      return null;
    }
  }

  /// Save audio data to temporary file
  Future<File> _saveAudioToFile(Uint8List audioData, String prefix) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final audioFile = File(
      '${tempDir.path}/${prefix}_${_selectedVoice.voiceId}_$timestamp.mp3',
    );
    await audioFile.writeAsBytes(audioData);
    debugPrint(' Audio saved to: ${audioFile.path}');
    return audioFile;
  }

  /// Sign AWS request with Signature V4
  Future<Map<String, String>> _signRequest({
    required String method,
    required String endpoint,
    required String body,
    String service = 'polly',
  }) async {
    final uri = Uri.parse(endpoint);
    final host = uri.host;
    final path = uri.path;

    final now = DateTime.now().toUtc();
    final dateStamp = _formatDate(now);
    final amzDate = _formatDateTime(now);

    final payloadHash = sha256.convert(utf8.encode(body)).toString();
    final canonicalHeaders =
        'content-type:application/json\n'
        'host:$host\n'
        'x-amz-date:$amzDate\n';
    final signedHeaders = 'content-type;host;x-amz-date';

    final canonicalRequest =
        '$method\n'
        '$path\n'
        '\n'
        '$canonicalHeaders\n'
        '$signedHeaders\n'
        '$payloadHash';

    final algorithm = 'AWS4-HMAC-SHA256';
    final credentialScope = '$dateStamp/$_region/$service/aws4_request';
    final canonicalRequestHash =
    sha256.convert(utf8.encode(canonicalRequest)).toString();
    final stringToSign =
        '$algorithm\n'
        '$amzDate\n'
        '$credentialScope\n'
        '$canonicalRequestHash';

    final signature = _calculateSignature(dateStamp, stringToSign, service);

    final authorization =
        '$algorithm '
        'Credential=$_accessKey/$credentialScope, '
        'SignedHeaders=$signedHeaders, '
        'Signature=$signature';

    return {
      'Content-Type': 'application/json',
      'Host': host,
      'X-Amz-Date': amzDate,
      'Authorization': authorization,
    };
  }

  String _calculateSignature(String dateStamp, String stringToSign, String service) {
    final kDate = _hmacSha256(
      utf8.encode('AWS4$_secretKey'),
      utf8.encode(dateStamp),
    );
    final kRegion = _hmacSha256(kDate, utf8.encode(_region));
    final kService = _hmacSha256(kRegion, utf8.encode(service));
    final kSigning = _hmacSha256(kService, utf8.encode('aws4_request'));
    final signature = _hmacSha256(kSigning, utf8.encode(stringToSign));

    return signature
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  List<int> _hmacSha256(List<int> key, List<int> data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(data).bytes;
  }

  String _formatDate(DateTime date) {
    return '${date.year}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)}T'
        '${date.hour.toString().padLeft(2, '0')}'
        '${date.minute.toString().padLeft(2, '0')}'
        '${date.second.toString().padLeft(2, '0')}Z';
  }

  /// Stop current speech
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      await _googleTTS.stop();
      _isSpeaking = false;
      debugPrint(' Speech stopped');
    } catch (e) {
      debugPrint(' Error stopping speech: $e');
    }
  }

  /// Pause current speech
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      debugPrint(' Speech paused');
    } catch (e) {
      debugPrint(' Error pausing speech: $e');
    }
  }

  /// Resume paused speech
  Future<void> resume() async {
    try {
      await _audioPlayer.resume();
      debugPrint(' Speech resumed');
    } catch (e) {
      debugPrint(' Error resuming speech: $e');
    }
  }

  /// Dispose service
  void dispose() {
    _audioPlayer.dispose();
    debugPrint(' AWS Polly V2 Service disposed');
  }

  /// Get current voice description
  String getCurrentVoiceDescription() {
    switch (_currentProvider) {
      case TTSProvider.awsPolly:
        return 'AWS Polly V2: ${_selectedVoice.displayName}';
      case TTSProvider.googleTTS:
        return 'Google TTS: $_googleVoiceId';
    }
  }

  /// Get service status (for debugging)
  Map<String, dynamic> getStatus() {
    return {
      'service': 'Enhanced AWS Polly V2 + Google TTS',
      'apiVersion': _apiVersion,
      'provider': _currentProvider.name,
      'awsVoice': _selectedVoice.displayName,
      'awsGender': _selectedVoice.gender,
      'awsLanguage': _selectedVoice.languageCode,
      'googleVoice': _googleVoiceId,
      'googleLanguage': _googleVoiceLang,
      'engine': _engine,
      'region': _region,
      'speechRate': _speechRate,
      'volume': _volume,
      'pitch': _pitch,
      'isInitialized': _isInitialized,
      'isSpeaking': _isSpeaking,
      'outputFormat': _outputFormat,
      'sampleRate': _sampleRate,
    };
  }

  /// Get all available AWS Polly voices
  List<PollyVoice> getAllVoices() {
    return PollyVoice.values;
  }

  /// Get voices by gender
  List<PollyVoice> getVoicesByGender(String gender) {
    return PollyVoice.values.where((v) => v.gender == gender).toList();
  }

  /// Get voices by language
  List<PollyVoice> getVoicesByLanguage(String languageCode) {
    return PollyVoice.values
        .where((v) => v.languageCode == languageCode)
        .toList();
  }

  /// Get all available voices (AWS Polly + Google TTS)
  Map<String, List<Map<String, String>>> getAllAvailableVoices() {
    return {
      'AWS Polly V2': PollyVoice.values.map((v) => {
        'id': v.voiceId,
        'name': v.displayName,
        'gender': v.gender,
        'language': v.languageCode,
        'description': v.description,
        'flag': v.flag,
      }).toList(),
      'Google Cloud TTS': [
        {
          'id': 'en-US-Wavenet-F',
          'name': ' American Female (Wavenet)',
          'language': 'en-US',
        },
        {
          'id': 'en-US-Wavenet-D',
          'name': ' American Male (Wavenet)',
          'language': 'en-US',
        },
        {
          'id': 'en-GB-Wavenet-A',
          'name': ' British Female (Wavenet)',
          'language': 'en-GB',
        },
        {
          'id': 'en-GB-Wavenet-B',
          'name': ' British Male (Wavenet)',
          'language': 'en-GB',
        },
        {
          'id': 'en-IN-Wavenet-A',
          'name': ' Indian Female (Wavenet)',
          'language': 'en-IN',
        },
        {
          'id': 'en-AU-Wavenet-A',
          'name': ' Australian Female (Wavenet)',
          'language': 'en-AU',
        },
        // More voices available in Voice Center...
      ],
    };
  }

  /// Preview a voice (short test)
  Future<bool> previewVoice(
      PollyVoice voice, {
        String? customText,
      }) async {
    final originalVoice = _selectedVoice;
    await setVoice(voice);

    final text = customText ??
        'Hello! I am ${voice.voiceId}. This is how I sound using AWS Polly V2. '
            'I am a ${voice.gender} voice from ${voice.languageCode}. ${voice.description}';

    final result = await speak(text);

    // Don't restore - let user keep the preview voice if they like it
    return result;
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    _currentProvider = TTSProvider.awsPolly;
    _selectedVoice = PollyVoice.joanna;
    _googleVoiceId = 'en-US-Wavenet-F';
    _googleVoiceLang = 'en-US';
    _speechRate = 1.0;
    _volume = 1.0;
    _pitch = 0.0;
    await _audioPlayer.setVolume(_volume);
    await _savePreferences();
    debugPrint(' Reset to default settings');
  }

  /// Check if AWS Polly is available
  bool get isPollyAvailable {
    return _accessKey.isNotEmpty && _secretKey.isNotEmpty;
  }

  /// Check if Google TTS is available
  bool get isGoogleTTSAvailable {
    return _googleTTS.isInitialized;
  }

  /// Get total voice count
  int get totalVoiceCount {
    return PollyVoice.values.length + 40; // AWS + Google
  }

  /// Print service information
  void printServiceInfo() {
    debugPrint('╔════════════════════════════════════════════════════════╗');
    debugPrint('║ AWS POLLY V2 SERVICE - INFORMATION ║');
    debugPrint('╠════════════════════════════════════════════════════════╣');
    debugPrint('║ API Version: $_apiVersion ║');
    debugPrint('║ Provider: ${_currentProvider.name.padRight(38)}║');
    debugPrint('║ AWS Voice: ${_selectedVoice.displayName.padRight(36)}║');
    debugPrint('║ Google Voice: ${_googleVoiceId.padRight(33)}║');
    debugPrint('║ Total Voices: ${totalVoiceCount.toString().padRight(35)}║');
    debugPrint('║ Initialized: ${_isInitialized.toString().padRight(36)}║');
    debugPrint('║ Speaking: ${_isSpeaking.toString().padRight(39)}║');
    debugPrint('╚════════════════════════════════════════════════════════╝');
  }
}