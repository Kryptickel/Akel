import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code') ?? 'en';
      _locale = Locale(languageCode);
      notifyListeners();
      debugPrint('✅ Locale loaded: $languageCode');
    } catch (e) {
      debugPrint('❌ Load locale error: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    try {
      if (_locale == locale) return;

      _locale = locale;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);

      debugPrint('✅ Locale set to: ${locale.languageCode}');
    } catch (e) {
      debugPrint('❌ Set locale error: $e');
    }
  }

  void clearLocale() {
    _locale = const Locale('en');
    notifyListeners();
  }
}