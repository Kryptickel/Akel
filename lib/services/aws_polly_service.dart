import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AwsPollyService {
  static final AwsPollyService _instance = AwsPollyService._internal();
  factory AwsPollyService() => _instance;
  AwsPollyService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSpeaking = false;
  bool _isInitialized = false;

  // AWS Credentials from .env
  late String _accessKey;
  late String _secretKey;
  late String _region;

  // Default Polly Configuration - Joanna Neural Voice
  String _voiceId = 'Joanna';
  String _engine = 'neural';
  static const String _outputFormat = 'mp3';
  static const String _sampleRate = '24000';
  String _languageCode = 'en-US';

  /// Initialize AWS Polly Service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint(' AWS Polly already initialized');
      return;
    }

    try {
      debugPrint(' Initializing AWS Polly Service...');

      // Load credentials from .env
      _accessKey = dotenv.env['AWS_ACCESS_KEY_ID'] ?? 'AKIA2EM7JUJDU7O7DWO4';
      _secretKey = dotenv.env['AWS_SECRET_ACCESS_KEY'] ?? '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';
      _region = dotenv.env['AWS_REGION'] ?? 'us-east-1';

      if (_accessKey.isEmpty || _secretKey.isEmpty) {
        throw Exception('AWS credentials not found in .env file');
      }

      _isInitialized = true;
      debugPrint(' AWS Polly Service initialized (Voice: $_voiceId, Engine: $_engine)');
    } catch (e) {
      debugPrint(' Error initializing AWS Polly: $e');
      rethrow;
    }
  }

  /// Convert text to speech using AWS Polly
  /// Enhanced with configurable voice, engine, and rate
  Future<bool> speak({
    required String text,
    String? voiceId,
    String? engine,
    double rate = 1.0,
    String? languageCode,
  }) async {
    if (!_isInitialized) {
      debugPrint(' Polly not initialized, initializing now...');
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

      // Use provided values or defaults
      final currentVoice = voiceId ?? _voiceId;
      final currentEngine = engine ?? _engine;
      final currentLanguage = languageCode ?? _languageCode;

      final preview = text.length > 50 ? '${text.substring(0, 50)}...' : text;
      debugPrint(' Speaking ($currentVoice $currentEngine): $preview');

      // Build SSML with rate control
      final ssmlText = _buildSSML(text, rate);

      // Call AWS Polly API
      final audioData = await _synthesizeSpeech(
        text: ssmlText,
        voiceId: currentVoice,
        engine: currentEngine,
        languageCode: currentLanguage,
        textType: 'ssml',
      );

      if (audioData == null) {
        debugPrint(' Failed to get audio from Polly');
        _isSpeaking = false;
        return false;
      }

      // Save audio to temp file
      final audioFile = await _saveAudioToFile(audioData);

      // Play audio
      await _audioPlayer.play(DeviceFileSource(audioFile.path));

      // Wait for playback to complete
      await _audioPlayer.onPlayerComplete.first;

      debugPrint(' Speech completed');
      _isSpeaking = false;
      return true;
    } catch (e) {
      debugPrint(' Error in speak: $e');
      _isSpeaking = false;
      return false;
    }
  }

  /// Build SSML with prosody controls
  String _buildSSML(String text, double rate) {
    final ratePercent = '${(rate * 100).toInt()}%';
    return '''
 <speak>
 <prosody rate="$ratePercent">
 $text
 </prosody>
 </speak>
 ''';
  }

  /// Synthesize speech using AWS Polly API
  Future<Uint8List?> _synthesizeSpeech({
    required String text,
    required String voiceId,
    required String engine,
    required String languageCode,
    String textType = 'text',
  }) async {
    try {
      final endpoint = 'https://polly.$_region.amazonaws.com/v1/speech';

      // Prepare request body
      final body = jsonEncode({
        'Text': text,
        'VoiceId': voiceId,
        'Engine': engine,
        'OutputFormat': _outputFormat,
        'SampleRate': _sampleRate,
        'LanguageCode': languageCode,
        'TextType': textType,
      });

      // Sign request with AWS Signature V4
      final headers = await _signRequest(
        method: 'POST',
        endpoint: endpoint,
        body: body,
      );

      debugPrint(' Calling AWS Polly ($voiceId $engine)...');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        debugPrint(' Got audio from Polly (${response.bodyBytes.length} bytes)');
        return response.bodyBytes;
      } else {
        debugPrint(' Polly API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint(' Error calling Polly: $e');
      return null;
    }
  }

  /// Save audio data to temporary file
  Future<File> _saveAudioToFile(Uint8List audioData) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final audioFile = File('${tempDir.path}/polly_$_voiceId\_$timestamp.mp3');
    await audioFile.writeAsBytes(audioData);
    debugPrint(' Audio saved to: ${audioFile.path}');
    return audioFile;
  }

  /// Sign AWS request with Signature V4
  Future<Map<String, String>> _signRequest({
    required String method,
    required String endpoint,
    required String body,
  }) async {
    final uri = Uri.parse(endpoint);
    final host = uri.host;
    final path = uri.path;

    final now = DateTime.now().toUtc();
    final dateStamp = _formatDate(now);
    final amzDate = _formatDateTime(now);

    // Create canonical request
    final payloadHash = sha256.convert(utf8.encode(body)).toString();
    final canonicalHeaders = 'content-type:application/json\nhost:$host\nx-amz-date:$amzDate\n';
    final signedHeaders = 'content-type;host;x-amz-date';

    final canonicalRequest = '$method\n$path\n\n$canonicalHeaders\n$signedHeaders\n$payloadHash';

    // Create string to sign
    final algorithm = 'AWS4-HMAC-SHA256';
    final credentialScope = '$dateStamp/$_region/polly/aws4_request';
    final canonicalRequestHash = sha256.convert(utf8.encode(canonicalRequest)).toString();
    final stringToSign = '$algorithm\n$amzDate\n$credentialScope\n$canonicalRequestHash';

    // Calculate signature
    final signature = _calculateSignature(dateStamp, stringToSign);

    // Create authorization header
    final authorization = '$algorithm Credential=$_accessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';

    return {
      'Content-Type': 'application/json',
      'Host': host,
      'X-Amz-Date': amzDate,
      'Authorization': authorization,
    };
  }

  /// Calculate AWS Signature V4
  String _calculateSignature(String dateStamp, String stringToSign) {
    final kDate = _hmacSha256(utf8.encode('AWS4$_secretKey'), utf8.encode(dateStamp));
    final kRegion = _hmacSha256(kDate, utf8.encode(_region));
    final kService = _hmacSha256(kRegion, utf8.encode('polly'));
    final kSigning = _hmacSha256(kService, utf8.encode('aws4_request'));
    final signature = _hmacSha256(kSigning, utf8.encode(stringToSign));

    return signature.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  /// HMAC SHA256
  List<int> _hmacSha256(List<int> key, List<int> data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(data).bytes;
  }

  /// Format date for AWS (YYYYMMDD)
  String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  /// Format datetime for AWS (YYYYMMDDTHHMMSSZ)
  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)}T${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}${date.second.toString().padLeft(2, '0')}Z';
  }

  /// Stop current speech
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isSpeaking = false;
      debugPrint(' Speech stopped');
    } catch (e) {
      debugPrint(' Error stopping speech: $e');
    }
  }

  /// Update default voice configuration
  void setDefaultVoice({
    String? voiceId,
    String? engine,
    String? languageCode,
  }) {
    if (voiceId != null) _voiceId = voiceId;
    if (engine != null) _engine = engine;
    if (languageCode != null) _languageCode = languageCode;

    debugPrint(' Voice config updated: $_voiceId ($_engine, $_languageCode)');
  }

  /// Get voice ID for accent (helper method from enhanced version)
  String getPollyVoiceIdForAccent(String accent, bool isMaleVoice) {
    switch (accent.toLowerCase()) {
      case 'us':
      case 'usstandard':
        return isMaleVoice ? 'Matthew' : 'Joanna';
      case 'ussouthern':
        return 'Joey';
      case 'british':
        return isMaleVoice ? 'Brian' : 'Amy';
      case 'australian':
        return isMaleVoice ? 'Russell' : 'Nicole';
      case 'indian':
        return isMaleVoice ? 'Aditi' : 'Raveena';
      case 'canadian':
        return 'Joanna';
      case 'scottish':
      case 'irish':
        return 'Brian';
      case 'newzealand':
        return 'Nicole';
      case 'southafrican':
        return 'Amy';
      default:
        return 'Joanna';
    }
  }

  /// Format text for SSML (enhanced version)
  String formatTextForSSML({
    required String text,
    double rate = 1.0,
    String pitch = 'medium',
    bool enableEmphasis = false,
  }) {
    String ssml = '<speak>';

    // Add prosody for rate
    if (rate != 1.0) {
      final ratePercent = '${(rate * 100).toInt()}%';
      ssml += '<prosody rate="$ratePercent">';
    }

    // Add pitch if not medium
    if (pitch != 'medium') {
      final pitchValue = pitch == 'low' ? '-10%' : '+10%';
      ssml += '<prosody pitch="$pitchValue">';
    }

    // Add emphasis if enabled
    if (enableEmphasis) {
      ssml += '<emphasis level="moderate">';
    }

    // Add the text
    ssml += text;

    // Close tags in reverse order
    if (enableEmphasis) ssml += '</emphasis>';
    if (pitch != 'medium') ssml += '</prosody>';
    if (rate != 1.0) ssml += '</prosody>';

    ssml += '</speak>';

    return ssml;
  }

  /// Check if currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Get current voice configuration
  Map<String, String> get voiceConfig => {
    'voiceId': _voiceId,
    'engine': _engine,
    'languageCode': _languageCode,
  };

  /// Dispose service
  void dispose() {
    _audioPlayer.dispose();
    debugPrint(' AWS Polly Service disposed');
  }

  /// Get service status (for debugging)
  Map<String, dynamic> getStatus() {
    return {
      'service': 'AWS Polly',
      'voice': _voiceId,
      'engine': _engine,
      'region': _region,
      'isInitialized': _isInitialized,
      'isSpeaking': _isSpeaking,
      'outputFormat': _outputFormat,
      'sampleRate': _sampleRate,
      'languageCode': _languageCode,
      'hasCredentials': _accessKey.isNotEmpty && _secretKey.isNotEmpty,
    };
  }

  /// Test voice with a sample phrase
  Future<bool> testVoice({String? voiceId, String? engine}) async {
    final testPhrase = "Hello! This is a test of the AWS Polly text-to-speech service.";
    return await speak(
      text: testPhrase,
      voiceId: voiceId,
      engine: engine,
    );
  }
}