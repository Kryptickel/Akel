import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/quick_settings_service.dart';
import '../services/vibration_service.dart';
import '../services/shake_detection_service.dart';
import '../services/sos_button_service.dart';

class QuickSettingsDrawer extends StatefulWidget {
  const QuickSettingsDrawer({super.key});

  @override
  State<QuickSettingsDrawer> createState() => _QuickSettingsDrawerState();
}

class _QuickSettingsDrawerState extends State<QuickSettingsDrawer> {
  final QuickSettingsService _settingsService = QuickSettingsService();
  final VibrationService _vibrationService = VibrationService();
  final ShakeDetectionService _shakeService = ShakeDetectionService();
  final SosButtonService _sosButtonService = SosButtonService();

  Map<String, bool> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.getAllSettings();
    if (mounted) {
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSetting(String key, bool value) async {
    await _vibrationService.light();

// Handle special cases
    if (key == 'dark_mode') {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      themeProvider.toggleTheme();
    } else if (key == 'shake_detection_enabled') {
      if (value) {
        await _shakeService.enable();
      } else {
        await _shakeService.disable();
      }
    } else if (key == 'sos_button_visible') {
      await _sosButtonService.setSosButtonVisible(value);
    }

    await _settingsService.toggleSetting(key, value);

    setState(() {
      _settings[key] = value;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${_getSettingName(key)} ${value ? 'enabled' : 'disabled'}'),
          duration: const Duration(seconds: 1),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  String _getSettingName(String key) {
    switch (key) {
      case 'dark_mode':
        return 'Dark Mode';
      case 'silent_mode':
        return 'Silent Mode';
      case 'share_location':
        return 'Location Sharing';
      case 'sound_alerts_enabled':
        return 'Sound Alerts';
      case 'vibration_enabled':
        return 'Haptic Feedback';
      case 'fall_detection_enabled':
        return 'Fall Detection';
      case 'shake_detection_enabled':
        return 'Shake Detection';
      case 'sos_button_visible':
        return 'SOS Button';
      case 'notifications_enabled':
        return 'Notifications';
      case 'location_enabled':
        return 'Location Services';
      default:
        return key;
    }
  }

  IconData _getSettingIcon(String key) {
    switch (key) {
      case 'dark_mode':
        return Icons.dark_mode;
      case 'silent_mode':
        return Icons.notifications_off;
      case 'share_location':
        return Icons.share_location;
      case 'sound_alerts_enabled':
        return Icons.volume_up;
      case 'vibration_enabled':
        return Icons.vibration;
      case 'fall_detection_enabled':
        return Icons.accessibility_new;
      case 'shake_detection_enabled':
        return Icons.vibration;
      case 'sos_button_visible':
        return Icons.sos;
      case 'notifications_enabled':
        return Icons.notifications_active;
      case 'location_enabled':
        return Icons.location_on;
      default:
        return Icons.settings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Column(
          children: [
// Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.tune,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Quick Settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toggle settings instantly',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

// Settings List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSettingToggle('dark_mode'),
                  const SizedBox(height: 8),
                  _buildSettingToggle('sos_button_visible'),
                  const SizedBox(height: 8),
                  _buildSettingToggle('shake_detection_enabled'),
                  const SizedBox(height: 8),
                  _buildSettingToggle('fall_detection_enabled'),
                  const SizedBox(height: 8),
                  _buildSettingToggle('share_location'),
                  const SizedBox(height: 8),
                  _buildSettingToggle('sound_alerts_enabled'),
                  const SizedBox(height: 8),
                  _buildSettingToggle('vibration_enabled'),
                  const SizedBox(height: 8),
                  _buildSettingToggle('notifications_enabled'),
                  const SizedBox(height: 8),
                  _buildSettingToggle('location_enabled'),
                ],
              ),
            ),

// Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Settings save automatically',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingToggle(String key) {
    final isEnabled = _settings[key] ?? false;
    final name = _getSettingName(key);
    final icon = _getSettingIcon(key);

    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isEnabled
              ? LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
              Theme.of(context).primaryColor.withValues(alpha: 0.05),
            ],
          )
              : null,
        ),
        child: SwitchListTile(
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEnabled
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isEnabled ? Theme.of(context).primaryColor : Colors.grey,
              size: 24,
            ),
          ),
          title: Text(
            name,
            style: TextStyle(
              fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            isEnabled ? 'Enabled' : 'Disabled',
            style: TextStyle(
              fontSize: 12,
              color: isEnabled ? Colors.green : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          value: isEnabled,
          activeColor: Theme.of(context).primaryColor,
          onChanged: (value) => _toggleSetting(key, value),
        ),
      ),
    );
  }
}