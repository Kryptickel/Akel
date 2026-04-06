import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetService {
  static const String _widgetName = 'PanicButtonWidget';
  static const String _actionKey = 'panic_action';

  // Initialize the widget service
  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId('group.com.kryptickel.akel');

      // Register callback for widget clicks
      HomeWidget.widgetClicked.listen((Uri? uri) {
        if (uri != null && uri.host == 'panic') {
          _handleWidgetClick();
        }
      });

      await updateWidget();
      debugPrint(' Widget service initialized');
    } catch (e) {
      debugPrint(' Widget initialization error: $e');
    }
  }

  // Update widget data
  static Future<void> updateWidget({
    bool isPanicActive = false,
    String? lastPanicTime,
  }) async {
    try {
      await HomeWidget.saveWidgetData<bool>('panic_active', isPanicActive);
      await HomeWidget.saveWidgetData<String>(
        'last_panic',
        lastPanicTime ?? 'Never',
      );
      await HomeWidget.saveWidgetData<String>(
        'app_name',
        'AKEL Panic',
      );

      // Update the widget UI
      await HomeWidget.updateWidget(
        name: _widgetName,
        iOSName: 'PanicButtonWidget',
        androidName: 'PanicButtonWidget',
      );

      debugPrint(' Widget updated');
    } catch (e) {
      debugPrint(' Widget update error: $e');
    }
  }

  // Handle widget click
  static Future<void> _handleWidgetClick() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('widget_panic_triggered', true);
      await prefs.setString(
        'widget_panic_time',
        DateTime.now().toIso8601String(),
      );

      debugPrint(' PANIC TRIGGERED FROM WIDGET');
    } catch (e) {
      debugPrint(' Widget click error: $e');
    }
  }

  // Check if panic was triggered from widget
  static Future<bool> wasTriggeredFromWidget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final triggered = prefs.getBool('widget_panic_triggered') ?? false;

      if (triggered) {
        await prefs.remove('widget_panic_triggered');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint(' Check widget trigger error: $e');
      return false;
    }
  }

  // Clear widget panic trigger
  static Future<void> clearWidgetTrigger() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('widget_panic_triggered');
      await prefs.remove('widget_panic_time');
    } catch (e) {
      debugPrint(' Clear widget trigger error: $e');
    }
  }
}