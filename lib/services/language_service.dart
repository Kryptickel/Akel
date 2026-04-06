import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SupportedLanguage {
  english,
  spanish,
  french,
  german,
  italian,
  portuguese,
  chinese,
  japanese,
  korean,
  arabic,
  hindi,
  russian,
}

class LanguageData {
  final SupportedLanguage language;
  final String name;
  final String nativeName;
  final String code;
  final String flag;
  final bool isRTL;

  LanguageData({
    required this.language,
    required this.name,
    required this.nativeName,
    required this.code,
    required this.flag,
    this.isRTL = false,
  });
}

class LanguageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _languageKey = 'selected_language';

// Supported languages
  static final List<LanguageData> supportedLanguages = [
    LanguageData(
      language: SupportedLanguage.english,
      name: 'English',
      nativeName: 'English',
      code: 'en',
      flag: '🇬🇧',
    ),
    LanguageData(
      language: SupportedLanguage.spanish,
      name: 'Spanish',
      nativeName: 'Español',
      code: 'es',
      flag: '🇪🇸',
    ),
    LanguageData(
      language: SupportedLanguage.french,
      name: 'French',
      nativeName: 'Français',
      code: 'fr',
      flag: '🇫🇷',
    ),
    LanguageData(
      language: SupportedLanguage.german,
      name: 'German',
      nativeName: 'Deutsch',
      code: 'de',
      flag: '🇩🇪',
    ),
    LanguageData(
      language: SupportedLanguage.italian,
      name: 'Italian',
      nativeName: 'Italiano',
      code: 'it',
      flag: '🇮🇹',
    ),
    LanguageData(
      language: SupportedLanguage.portuguese,
      name: 'Portuguese',
      nativeName: 'Português',
      code: 'pt',
      flag: '🇵🇹',
    ),
    LanguageData(
      language: SupportedLanguage.chinese,
      name: 'Chinese',
      nativeName: '中文',
      code: 'zh',
      flag: '🇨🇳',
    ),
    LanguageData(
      language: SupportedLanguage.japanese,
      name: 'Japanese',
      nativeName: '日本語',
      code: 'ja',
      flag: '🇯🇵',
    ),
    LanguageData(
      language: SupportedLanguage.korean,
      name: 'Korean',
      nativeName: '한국어',
      code: 'ko',
      flag: '🇰🇷',
    ),
    LanguageData(
      language: SupportedLanguage.arabic,
      name: 'Arabic',
      nativeName: 'العربية',
      code: 'ar',
      flag: '🇸🇦',
      isRTL: true,
    ),
    LanguageData(
      language: SupportedLanguage.hindi,
      name: 'Hindi',
      nativeName: 'हिन्दी',
      code: 'hi',
      flag: '🇮🇳',
    ),
    LanguageData(
      language: SupportedLanguage.russian,
      name: 'Russian',
      nativeName: 'Русский',
      code: 'ru',
      flag: '🇷🇺',
    ),
  ];

// Emergency message translations
  static final Map<SupportedLanguage, Map<String, String>> translations = {
    SupportedLanguage.english: {
      'emergency_alert': 'EMERGENCY ALERT!',
      'help_needed': 'I need help! This is an emergency.',
      'location': 'My location',
      'please_respond': 'Please respond immediately.',
      'sent_from': 'Sent from AKEL Panic Button',
    },
    SupportedLanguage.spanish: {
      'emergency_alert': '¡ALERTA DE EMERGENCIA!',
      'help_needed': '¡Necesito ayuda! Esta es una emergencia.',
      'location': 'Mi ubicación',
      'please_respond': 'Por favor responda inmediatamente.',
      'sent_from': 'Enviado desde AKEL Botón de Pánico',
    },
    SupportedLanguage.french: {
      'emergency_alert': 'ALERTE D\'URGENCE!',
      'help_needed': 'J\'ai besoin d\'aide! C\'est une urgence.',
      'location': 'Ma position',
      'please_respond': 'Veuillez répondre immédiatement.',
      'sent_from': 'Envoyé depuis AKEL Bouton Panique',
    },
    SupportedLanguage.german: {
      'emergency_alert': 'NOTFALL-ALARM!',
      'help_needed': 'Ich brauche Hilfe! Dies ist ein Notfall.',
      'location': 'Mein Standort',
      'please_respond': 'Bitte antworten Sie sofort.',
      'sent_from': 'Gesendet von AKEL Panik-Button',
    },
    SupportedLanguage.italian: {
      'emergency_alert': 'ALLARME DI EMERGENZA!',
      'help_needed': 'Ho bisogno di aiuto! Questa è un\'emergenza.',
      'location': 'La mia posizione',
      'please_respond': 'Si prega di rispondere immediatamente.',
      'sent_from': 'Inviato da AKEL Pulsante di Panico',
    },
    SupportedLanguage.portuguese: {
      'emergency_alert': 'ALERTA DE EMERGÊNCIA!',
      'help_needed': 'Preciso de ajuda! Esta é uma emergência.',
      'location': 'Minha localização',
      'please_respond': 'Por favor, responda imediatamente.',
      'sent_from': 'Enviado do AKEL Botão de Pânico',
    },
    SupportedLanguage.chinese: {
      'emergency_alert': '紧急警报！',
      'help_needed': '我需要帮助！这是紧急情况。',
      'location': '我的位置',
      'please_respond': '请立即回应。',
      'sent_from': '来自AKEL紧急按钮',
    },
    SupportedLanguage.japanese: {
      'emergency_alert': '緊急警報！',
      'help_needed': '助けが必要です！これは緊急事態です。',
      'location': '私の位置',
      'please_respond': 'すぐに応答してください。',
      'sent_from': 'AKELパニックボタンから送信',
    },
    SupportedLanguage.korean: {
      'emergency_alert': '긴급 경보!',
      'help_needed': '도움이 필요합니다! 이것은 긴급 상황입니다.',
      'location': '내 위치',
      'please_respond': '즉시 응답해 주세요.',
      'sent_from': 'AKEL 패닉 버튼에서 전송됨',
    },
    SupportedLanguage.arabic: {
      'emergency_alert': 'تنبيه طوارئ!',
      'help_needed': 'أحتاج المساعدة! هذه حالة طوارئ.',
      'location': 'موقعي',
      'please_respond': 'يرجى الرد فوراً.',
      'sent_from': 'مُرسل من زر الطوارئ AKEL',
    },
    SupportedLanguage.hindi: {
      'emergency_alert': 'आपातकालीन चेतावनी!',
      'help_needed': 'मुझे मदद चाहिए! यह एक आपातकाल है।',
      'location': 'मेरा स्थान',
      'please_respond': 'कृपया तुरंत जवाब दें।',
      'sent_from': 'AKEL पैनिक बटन से भेजा गया',
    },
    SupportedLanguage.russian: {
      'emergency_alert': 'ЭКСТРЕННОЕ ОПОВЕЩЕНИЕ!',
      'help_needed': 'Мне нужна помощь! Это чрезвычайная ситуация.',
      'location': 'Моё местоположение',
      'please_respond': 'Пожалуйста, ответьте немедленно.',
      'sent_from': 'Отправлено с кнопки паники AKEL',
    },
  };

// Get current language
  Future<SupportedLanguage> getCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);

      if (languageCode != null) {
        return supportedLanguages
            .firstWhere(
              (lang) => lang.code == languageCode,
          orElse: () => supportedLanguages[0],
        )
            .language;
      }

      return SupportedLanguage.english;
    } catch (e) {
      debugPrint('❌ Get current language error: $e');
      return SupportedLanguage.english;
    }
  }

// Set language
  Future<bool> setLanguage(SupportedLanguage language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageData = getLanguageData(language);

      await prefs.setString(_languageKey, languageData.code);

      debugPrint('✅ Language set to: ${languageData.name}');
      return true;
    } catch (e) {
      debugPrint('❌ Set language error: $e');
      return false;
    }
  }

// Get language data
  LanguageData getLanguageData(SupportedLanguage language) {
    return supportedLanguages.firstWhere((lang) => lang.language == language);
  }

// Get translation
  String getTranslation(SupportedLanguage language, String key) {
    final languageTranslations = translations[language];
    if (languageTranslations != null && languageTranslations.containsKey(key)) {
      return languageTranslations[key]!;
    }

// Fallback to English
    return translations[SupportedLanguage.english]![key] ?? key;
  }

// Get emergency message
  Future<String> getEmergencyMessage({
    required String userName,
    required String location,
    SupportedLanguage? language,
  }) async {
    final currentLanguage = language ?? await getCurrentLanguage();

    final alert = getTranslation(currentLanguage, 'emergency_alert');
    final helpNeeded = getTranslation(currentLanguage, 'help_needed');
    final locationLabel = getTranslation(currentLanguage, 'location');
    final pleaseRespond = getTranslation(currentLanguage, 'please_respond');
    final sentFrom = getTranslation(currentLanguage, 'sent_from');

    return '$alert\n\n'
        '$userName: $helpNeeded\n\n'
        '$locationLabel: $location\n\n'
        '$pleaseRespond\n\n'
        '$sentFrom';
  }

// Save user language preference
  Future<bool> saveUserLanguagePreference({
    required String userId,
    required SupportedLanguage language,
  }) async {
    try {
      final languageData = getLanguageData(language);

      await _firestore.collection('users').doc(userId).update({
        'language': languageData.code,
        'languageName': languageData.name,
        'languageNativeName': languageData.nativeName,
      });

      debugPrint('✅ User language preference saved');
      return true;
    } catch (e) {
      debugPrint('❌ Save user language preference error: $e');
      return false;
    }
  }

// Get user language preference
  Future<SupportedLanguage?> getUserLanguagePreference(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final data = doc.data();
        final languageCode = data?['language'] as String?;

        if (languageCode != null) {
          return supportedLanguages
              .firstWhere(
                (lang) => lang.code == languageCode,
            orElse: () => supportedLanguages[0],
          )
              .language;
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Get user language preference error: $e');
      return null;
    }
  }

// Get language statistics
  Future<Map<String, dynamic>> getLanguageStatistics(String userId) async {
    try {
      final currentLanguage = await getCurrentLanguage();
      final languageData = getLanguageData(currentLanguage);

// Get panic events count (as a proxy for language usage)
      final eventsSnapshot = await _firestore
          .collection('panic_events')
          .where('userId', isEqualTo: userId)
          .get();

      final totalEvents = eventsSnapshot.docs.length;

      return {
        'currentLanguage': languageData.name,
        'currentLanguageNative': languageData.nativeName,
        'currentLanguageFlag': languageData.flag,
        'isRTL': languageData.isRTL,
        'totalSupportedLanguages': supportedLanguages.length,
        'messagesWithTranslation': totalEvents,
      };
    } catch (e) {
      debugPrint('❌ Get language statistics error: $e');
      return {};
    }
  }

// Get all supported languages
  List<LanguageData> getAllLanguages() {
    return supportedLanguages;
  }

// Check if language is RTL
  bool isRTL(SupportedLanguage language) {
    return getLanguageData(language).isRTL;
  }

// Get language from code
  SupportedLanguage? getLanguageFromCode(String code) {
    try {
      return supportedLanguages
          .firstWhere((lang) => lang.code == code)
          .language;
    } catch (e) {
      return null;
    }
  }
}