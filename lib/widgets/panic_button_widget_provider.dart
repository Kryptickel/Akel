import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';

class PanicButtonWidgetProvider {
  static const String _widgetName = 'PanicButtonWidget';
  static const String _androidWidgetName = 'PanicButtonWidgetProvider';
  static const String _iOSWidgetName = 'PanicButtonWidget';

  // Initialize widget
  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId('group.akel.panicbutton');
      debugPrint(' Widget initialized');
    } catch (e) {
      debugPrint(' Widget initialization error: $e');
    }
  }

  // Update widget data
  static Future<void> updateWidget({
    required String userName,
    required int batteryLevel,
    required bool isOnline,
    required bool fallDetectionActive,
    required bool shakeDetectionActive,
    required bool locationTrackingActive,
  }) async {
    try {
      // Save data to widget
      await HomeWidget.saveWidgetData<String>('userName', userName);
      await HomeWidget.saveWidgetData<int>('batteryLevel', batteryLevel);
      await HomeWidget.saveWidgetData<bool>('isOnline', isOnline);
      await HomeWidget.saveWidgetData<bool>('fallDetectionActive', fallDetectionActive);
      await HomeWidget.saveWidgetData<bool>('shakeDetectionActive', shakeDetectionActive);
      await HomeWidget.saveWidgetData<bool>('locationTrackingActive', locationTrackingActive);

      // Update widget
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        iOSName: _iOSWidgetName,
      );

      debugPrint(' Widget updated');
    } catch (e) {
      debugPrint(' Widget update error: $e');
    }
  }

  // Handle widget tap
  static Future<void> registerWidgetTapListener(Function(Uri?) callback) async {
    try {
      HomeWidget.widgetClicked.listen(callback);
      debugPrint(' Widget tap listener registered');
    } catch (e) {
      debugPrint(' Widget tap listener error: $e');
    }
  }

  // Get initial data from widget
  static Future<Uri?> getInitialData() async {
    try {
      return await HomeWidget.initiallyLaunchedFromHomeWidget();
    } catch (e) {
      debugPrint(' Get initial data error: $e');
      return null;
    }
  }

  // Set widget action URLs
  static Future<void> setActionUrls() async {
    try {
      // Panic button action
      await HomeWidget.saveWidgetData<String>(
        'panicAction',
        'akel://panic',
      );

      // Silent panic action
      await HomeWidget.saveWidgetData<String>(
        'silentPanicAction',
        'akel://silent_panic',
      );

      // Call 911 action
      await HomeWidget.saveWidgetData<String>(
        'call911Action',
        'akel://call_911',
      );

      debugPrint(' Widget action URLs set');
    } catch (e) {
      debugPrint(' Set action URLs error: $e');
    }
  }

  // Check if widget is available
  static Future<bool> isWidgetAvailable() async {
    try {
      // Widget is available on Android and iOS only
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint(' Check widget availability error: $e');
      return false;
    }
  }

  // Record widget usage
  static Future<void> recordWidgetUsage(String action) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      await HomeWidget.saveWidgetData<String>('lastAction', action);
      await HomeWidget.saveWidgetData<String>('lastActionTime', timestamp);

      debugPrint(' Widget usage recorded: $action at $timestamp');
    } catch (e) {
      debugPrint(' Record widget usage error: $e');
    }
  }
}