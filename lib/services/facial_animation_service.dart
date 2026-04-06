import 'dart:async';
import 'package:flutter/foundation.dart';

/// Facial Expression Types for Doctor Annie
enum FacialExpression {
  neutral,
  smile,
  concerned,
  thinking,
  explaining,
  listening,
  surprised,
  empathetic,
  encouraging,
  serious,
}

/// Lip Sync Phoneme Mapping
enum Phoneme {
  silence, // Mouth closed
  ah, // Open mouth
  eh, // Medium open
  oh, // Rounded
  ee, // Wide smile
  oo, // Pursed lips
  m, // Closed lips
  f, // Teeth on lip
  th, // Tongue visible
}

/// Facial Animation Service - Controls Doctor Annie's expressions and lip sync
class FacialAnimationService {
  static final FacialAnimationService _instance = FacialAnimationService._internal();
  factory FacialAnimationService() => _instance;
  FacialAnimationService._internal();

  // Current state
  FacialExpression _currentExpression = FacialExpression.neutral;
  Phoneme _currentPhoneme = Phoneme.silence;
  bool _isBlinking = false;
  bool _isSpeaking = false;

  // Animation streams
  final _expressionController = StreamController<FacialExpression>.broadcast();
  final _phonemeController = StreamController<Phoneme>.broadcast();
  final _blinkController = StreamController<bool>.broadcast();

  Stream<FacialExpression> get expressionStream => _expressionController.stream;
  Stream<Phoneme> get phonemeStream => _phonemeController.stream;
  Stream<bool> get blinkStream => _blinkController.stream;

  FacialExpression get currentExpression => _currentExpression;
  Phoneme get currentPhoneme => _currentPhoneme;
  bool get isSpeaking => _isSpeaking;

  // Timers
  Timer? _blinkTimer;
  Timer? _lipSyncTimer;

  void initialize() {
    _startBlinking();
    debugPrint(' FacialAnimationService initialized');
  }

  // ==================== EXPRESSION CONTROL ====================

  void setExpression(FacialExpression expression) {
    _currentExpression = expression;
    _expressionController.add(expression);
    debugPrint(' Expression changed to: $expression');
  }

  void expressEmotionBasedOnText(String text) {
    final lowerText = text.toLowerCase();

    if (lowerText.contains('?')) {
      setExpression(FacialExpression.thinking);
    } else if (lowerText.contains('sorry') || lowerText.contains('unfortunately')) {
      setExpression(FacialExpression.concerned);
    } else if (lowerText.contains('great') || lowerText.contains('excellent') || lowerText.contains('wonderful')) {
      setExpression(FacialExpression.encouraging);
    } else if (lowerText.contains('understand') || lowerText.contains('i see')) {
      setExpression(FacialExpression.empathetic);
    } else if (lowerText.contains('important') || lowerText.contains('serious')) {
      setExpression(FacialExpression.serious);
    } else {
      setExpression(FacialExpression.neutral);
    }
  }

  // ==================== LIP SYNC ====================

  void startLipSync(String text, {Duration? duration}) {
    _isSpeaking = true;

    // Convert text to phonemes
    final phonemes = _textToPhonemes(text);

    // Calculate timing
    final totalDuration = duration ?? Duration(milliseconds: text.length * 80);
    final phonemeDuration = Duration(
      milliseconds: totalDuration.inMilliseconds ~/ phonemes.length,
    );

    // Animate through phonemes
    int index = 0;
    _lipSyncTimer?.cancel();
    _lipSyncTimer = Timer.periodic(phonemeDuration, (timer) {
      if (index >= phonemes.length) {
        timer.cancel();
        stopLipSync();
        return;
      }

      _currentPhoneme = phonemes[index];
      _phonemeController.add(phonemes[index]);
      index++;
    });

    // Set appropriate expression while speaking
    expressEmotionBasedOnText(text);
  }

  void stopLipSync() {
    _isSpeaking = false;
    _lipSyncTimer?.cancel();
    _currentPhoneme = Phoneme.silence;
    _phonemeController.add(Phoneme.silence);

    // Return to neutral expression
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isSpeaking) {
        setExpression(FacialExpression.neutral);
      }
    });
  }

  List<Phoneme> _textToPhonemes(String text) {
    final phonemes = <Phoneme>[];
    final words = text.toLowerCase().split(' ');

    for (final word in words) {
      for (int i = 0; i < word.length; i++) {
        final char = word[i];

        if ('aeiou'.contains(char)) {
          if (char == 'a' || char == 'e') {
            phonemes.add(Phoneme.ah);
          } else if (char == 'i') {
            phonemes.add(Phoneme.ee);
          } else if (char == 'o') {
            phonemes.add(Phoneme.oh);
          } else if (char == 'u') {
            phonemes.add(Phoneme.oo);
          }
        } else if ('mn'.contains(char)) {
          phonemes.add(Phoneme.m);
        } else if ('fv'.contains(char)) {
          phonemes.add(Phoneme.f);
        } else if (char == 'th') {
          phonemes.add(Phoneme.th);
        } else {
          phonemes.add(Phoneme.eh);
        }
      }
      phonemes.add(Phoneme.silence); // Pause between words
    }

    return phonemes;
  }

  // ==================== BLINKING ====================

  void _startBlinking() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _blink();
    });
  }

  void _blink() {
    if (_isBlinking) return;

    _isBlinking = true;
    _blinkController.add(true);

    Future.delayed(const Duration(milliseconds: 150), () {
      _isBlinking = false;
      _blinkController.add(false);
    });
  }

  // ==================== GESTURES ====================

  void performGesture(String gesture) {
    switch (gesture) {
      case 'nod':
        _nod();
        break;
      case 'shake':
        _shake();
        break;
      case 'tilt':
        _tilt();
        break;
    }
  }

  void _nod() {
    // Head nod animation (can be implemented in widget)
    debugPrint(' Nodding gesture');
  }

  void _shake() {
    // Head shake animation
    debugPrint(' Shaking gesture');
  }

  void _tilt() {
    // Head tilt animation
    debugPrint(' Tilting gesture');
  }

  // ==================== CLEANUP ====================

  void dispose() {
    _blinkTimer?.cancel();
    _lipSyncTimer?.cancel();
    _expressionController.close();
    _phonemeController.close();
    _blinkController.close();
  }
}