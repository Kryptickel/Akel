import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SosButtonService {
// SOS button visibility
  Future<void> setSosButtonVisible(bool visible) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sos_button_visible', visible);
      debugPrint('✅ SOS button visibility: $visible');
    } catch (e) {
      debugPrint('❌ Set SOS button visibility error: $e');
    }
  }

  Future<bool> isSosButtonVisible() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('sos_button_visible') ?? true; // Default: visible
    } catch (e) {
      debugPrint('❌ Get SOS button visibility error: $e');
      return true;
    }
  }

// SOS button position (left or right)
  Future<void> setSosButtonPosition(String position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sos_button_position', position);
      debugPrint('✅ SOS button position: $position');
    } catch (e) {
      debugPrint('❌ Set SOS button position error: $e');
    }
  }

  Future<String> getSosButtonPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('sos_button_position') ?? 'right'; // Default: right
    } catch (e) {
      debugPrint('❌ Get SOS button position error: $e');
      return 'right';
    }
  }

// SOS statistics
  Future<void> incrementSosCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt('sos_button_count') ?? 0;
      await prefs.setInt('sos_button_count', currentCount + 1);
      await prefs.setString('last_sos_button_time', DateTime.now().toIso8601String());
      debugPrint('✅ SOS button count incremented: ${currentCount + 1}');
    } catch (e) {
      debugPrint('❌ Increment SOS button count error: $e');
    }
  }

  Future<int> getSosCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('sos_button_count') ?? 0;
    } catch (e) {
      debugPrint('❌ Get SOS button count error: $e');
      return 0;
    }
  }

  Future<DateTime?> getLastSosTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString('last_sos_button_time');
      if (timeString != null) {
        return DateTime.parse(timeString);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get last SOS button time error: $e');
      return null;
    }
  }
}