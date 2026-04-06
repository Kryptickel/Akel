import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AWSService {
  // AWS Configuration
  static const String region = 'us-east-1';
  static const String accessKey = 'AKIA2EM7JUJDU7O7DWO4';
  static const String secretKey = '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';

  // Lex Bot Configuration
  static const String botId = 'LTDFCALG00';
  static const String botAliasId = 'TSTALIASID';
  static const String localeId = 'en_US';

  // Service instances
  late final http.Client _httpClient;
  late final stt.SpeechToText _speechToText;

  bool _speechInitialized = false;
  bool _isListening = false;

  AWSService() {
    _httpClient = http.Client();
    _speechToText = stt.SpeechToText();
  }

  Future<bool> initializeSpeechRecognition() async {
    if (_speechInitialized) return true;

    try {
      _speechInitialized = await _speechToText.initialize(
        onError: (error) => print('Speech error: ${error.errorMsg}'),
        onStatus: (status) => print('Speech status: $status'),
      );
      return _speechInitialized;
    } catch (e) {
      print('Failed to initialize speech recognition: $e');
      return false;
    }
  }

  bool get isSpeechAvailable => _speechInitialized;
  bool get isListening => _isListening;

  Future<bool> startVoiceToText({
    required Function(String text) onResult,
    Function(String finalText)? onComplete,
    String language = 'en-US',
  }) async {
    if (!_speechInitialized) {
      final initialized = await initializeSpeechRecognition();
      if (!initialized) {
        print('Speech recognition not available');
        return false;
      }
    }

    if (_isListening) {
      print('Already listening');
      return false;
    }

    try {
      _isListening = true;

      await _speechToText.listen(
        onResult: (result) {
          final recognizedText = result.recognizedWords;
          onResult(recognizedText);

          if (result.finalResult && onComplete != null) {
            onComplete(recognizedText);
          }
        },
        localeId: language,
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
      );

      return true;
    } catch (e) {
      print('Error starting voice recognition: $e');
      _isListening = false;
      return false;
    }
  }

  Future<void> stopVoiceToText() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
    } catch (e) {
      print('Error stopping voice recognition: $e');
    }
  }

  Future<void> cancelVoiceToText() async {
    if (!_isListening) return;

    try {
      await _speechToText.cancel();
      _isListening = false;
    } catch (e) {
      print('Error canceling voice recognition: $e');
    }
  }

  void dispose() {
    _httpClient.close();
    if (_isListening) {
      _speechToText.stop();
    }
  }

  Future<Map<String, dynamic>> sendTextToBot(
      String text, {
        String? sessionId,
      }) async {
    if (text.trim().isEmpty) {
      return {
        'success': false,
        'error': 'Message text cannot be empty',
      };
    }

    try {
      sessionId ??= _generateSessionId();

      final host = 'runtime-v2-lex.$region.amazonaws.com';
      final path = '/bots/$botId/botAliases/$botAliasId/botLocales/$localeId/sessions/$sessionId/text';

      final requestBody = jsonEncode({'text': text});
      final now = DateTime.now().toUtc();

      final response = await _makeSignedRequest(
        host: host,
        path: path,
        body: requestBody,
        now: now,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out after 30 seconds');
        },
      );

      return _handleLexResponse(response, sessionId);
    } on TimeoutException catch (e) {
      return {
        'success': false,
        'error': 'Request timeout: ${e.message}',
        'sessionId': sessionId,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Unexpected error: ${e.toString()}',
        'sessionId': sessionId,
      };
    }
  }

  Map<String, dynamic> _handleLexResponse(
      http.Response response,
      String sessionId,
      ) {
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        return {
          'success': true,
          'message': _extractMessage(data),
          'sessionId': sessionId,
          'sessionState': data['sessionState'],
          'interpretations': data['interpretations'],
          'rawResponse': data,
        };
      } catch (e) {
        return {
          'success': false,
          'error': 'Failed to parse response: ${e.toString()}',
          'sessionId': sessionId,
        };
      }
    } else {
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}: ${response.body}',
        'sessionId': sessionId,
      };
    }
  }

  String _extractMessage(Map<String, dynamic> data) {
    if (data['messages'] == null) return 'No response';

    final messagesList = data['messages'] as List<dynamic>;
    if (messagesList.isEmpty) return 'No response';

    final messages = messagesList
        .whereType<Map<String, dynamic>>()
        .map((m) => m['content'] as String?)
        .where((c) => c != null && c.trim().isNotEmpty)
        .cast<String>()
        .toList();

    return messages.isEmpty ? 'No response' : messages.join('\n');
  }

  /// Convert text to speech using AWS Polly via HTTP API
  Future<Uint8List?> textToSpeech(
      String text, {
        String voiceId = 'Joanna',
        String outputFormat = 'mp3',
      }) async {
    if (text.trim().isEmpty) {
      print('Polly error: Empty text provided');
      return null;
    }

    if (text.length > 3000) {
      print('Polly error: Text exceeds 3000 character limit');
      return null;
    }

    try {
      final host = 'polly.$region.amazonaws.com';
      final path = '/v1/speech';

      final requestBody = jsonEncode({
        'Text': text,
        'OutputFormat': outputFormat,
        'VoiceId': voiceId,
        'Engine': 'standard',
      });

      final now = DateTime.now().toUtc();

      final response = await _makePollySignedRequest(
        host: host,
        path: path,
        body: requestBody,
        now: now,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Polly request timed out');
        },
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('Polly error: HTTP ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Polly error: ${e.toString()}');
      return null;
    }
  }

  Future<http.Response> _makeSignedRequest({
    required String host,
    required String path,
    required String body,
    required DateTime now,
  }) async {
    final dateStamp = _formatDate(now);
    final amzDate = _formatDateTime(now);
    final payloadHash = sha256.convert(utf8.encode(body)).toString();

    final canonicalHeaders = 'host:$host\nx-amz-date:$amzDate\n';
    final signedHeaders = 'host;x-amz-date';
    final canonicalRequest =
        'POST\n$path\n\n$canonicalHeaders\n$signedHeaders\n$payloadHash';

    final credentialScope = '$dateStamp/$region/lex/aws4_request';
    final hashedRequest =
    sha256.convert(utf8.encode(canonicalRequest)).toString();
    final stringToSign =
        'AWS4-HMAC-SHA256\n$amzDate\n$credentialScope\n$hashedRequest';

    final signature = _calculateSignature(dateStamp, stringToSign, 'lex');
    final authorization =
        'AWS4-HMAC-SHA256 Credential=$accessKey/$credentialScope, '
        'SignedHeaders=$signedHeaders, Signature=$signature';

    final uri = Uri.https(host, path);
    final headers = {
      'Content-Type': 'application/json',
      'X-Amz-Date': amzDate,
      'Authorization': authorization,
    };

    return await _httpClient.post(uri, headers: headers, body: body);
  }

  Future<http.Response> _makePollySignedRequest({
    required String host,
    required String path,
    required String body,
    required DateTime now,
  }) async {
    final dateStamp = _formatDate(now);
    final amzDate = _formatDateTime(now);
    final payloadHash = sha256.convert(utf8.encode(body)).toString();

    final canonicalHeaders = 'content-type:application/json\nhost:$host\nx-amz-date:$amzDate\n';
    final signedHeaders = 'content-type;host;x-amz-date';
    final canonicalRequest =
        'POST\n$path\n\n$canonicalHeaders\n$signedHeaders\n$payloadHash';

    final credentialScope = '$dateStamp/$region/polly/aws4_request';
    final hashedRequest =
    sha256.convert(utf8.encode(canonicalRequest)).toString();
    final stringToSign =
        'AWS4-HMAC-SHA256\n$amzDate\n$credentialScope\n$hashedRequest';

    final signature = _calculateSignature(dateStamp, stringToSign, 'polly');
    final authorization =
        'AWS4-HMAC-SHA256 Credential=$accessKey/$credentialScope, '
        'SignedHeaders=$signedHeaders, Signature=$signature';

    final uri = Uri.https(host, path);
    final headers = {
      'Content-Type': 'application/json',
      'X-Amz-Date': amzDate,
      'Authorization': authorization,
    };

    return await _httpClient.post(uri, headers: headers, body: body);
  }

  String _calculateSignature(String dateStamp, String stringToSign, String service) {
    final kDate = _hmac(utf8.encode('AWS4$secretKey'), utf8.encode(dateStamp));
    final kRegion = _hmac(kDate, utf8.encode(region));
    final kService = _hmac(kRegion, utf8.encode(service));
    final kSigning = _hmac(kService, utf8.encode('aws4_request'));

    return _hmac(kSigning, utf8.encode(stringToSign))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  List<int> _hmac(List<int> key, List<int> data) {
    return Hmac(sha256, key).convert(data).bytes;
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}${_pad(dt.month)}${_pad(dt.day)}'
        'T${_pad(dt.hour)}${_pad(dt.minute)}${_pad(dt.second)}Z';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}${_pad(dt.month)}${_pad(dt.day)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String _generateSessionId() {
    return 'session-${DateTime.now().millisecondsSinceEpoch}';
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}