import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/widget_service.dart';

class PanicWidgetConfig extends StatefulWidget {
  const PanicWidgetConfig({super.key});

  @override
  State<PanicWidgetConfig> createState() => _PanicWidgetConfigState();
}

class _PanicWidgetConfigState extends State<PanicWidgetConfig> {
  bool _widgetEnabled = true;
  bool _requireUnlock = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _widgetEnabled = prefs.getBool('widget_enabled') ?? true;
      _requireUnlock = prefs.getBool('widget_require_unlock') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('widget_enabled', _widgetEnabled);
    await prefs.setBool('widget_require_unlock', _requireUnlock);

    if (_widgetEnabled) {
      await WidgetService.updateWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Settings'),
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: const Color(0xFF0A0E27),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFF1E2740),
            child: SwitchListTile(
              secondary: const Icon(Icons.widgets, color: Color(0xFF00BFA5)),
              title: const Text(
                'Enable Home Screen Widget',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Quick access panic button from home screen',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              value: _widgetEnabled,
              thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF00BFA5);
                }
                return null;
              }),
              onChanged: (value) {
                setState(() => _widgetEnabled = value);
                _saveSettings();
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF1E2740),
            child: SwitchListTile(
              secondary: const Icon(Icons.lock, color: Colors.orange),
              title: const Text(
                'Require Device Unlock',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Unlock device before triggering from widget',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              value: _requireUnlock,
              thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.orange;
                }
                return null;
              }),
              onChanged: _widgetEnabled
                  ? (value) {
                setState(() => _requireUnlock = value);
                _saveSettings();
              }
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00BFA5).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF00BFA5),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'How to Add Widget',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Android:\n'
                      '1. Long press on home screen\n'
                      '2. Tap "Widgets"\n'
                      '3. Find "AKEL Panic Button"\n'
                      '4. Drag to home screen\n\n'
                      'iOS:\n'
                      '1. Long press on home screen\n'
                      '2. Tap "+" in top corner\n'
                      '3. Search "AKEL"\n'
                      '4. Select widget size\n'
                      '5. Tap "Add Widget"',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Widget triggers panic immediately when tapped. Use with caution.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}