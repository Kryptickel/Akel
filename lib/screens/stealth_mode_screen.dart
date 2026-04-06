import 'package:flutter/material.dart';
import '../services/stealth_mode_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';

class StealthModeScreen extends StatefulWidget {
  const StealthModeScreen({super.key});

  @override
  State<StealthModeScreen> createState() => _StealthModeScreenState();
}

class _StealthModeScreenState extends State<StealthModeScreen> {
  final StealthModeService _stealthService = StealthModeService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();

  bool _isLoading = true;
  bool _stealthEnabled = false;
  bool _hideAppName = false;
  bool _hidePanicButton = false;
  bool _hideNotifications = false;
  bool _hideEmergencyContacts = false;
  bool _hideLocationSharing = false;
  bool _disguiseAppIcon = false;
  bool _silentAlerts = false;
  bool _noCountdown = false;
  bool _hideRecentActivity = false;
  String _disguisedName = 'Calculator';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final settings = await _stealthService.getStealthSettings();
      final disguisedName = await _stealthService.getDisguisedAppName();

      if (mounted) {
        setState(() {
          _stealthEnabled = settings['enabled'] ?? false;
          _hideAppName = settings['hide_app_name'] ?? false;
          _hidePanicButton = settings['hide_panic_button'] ?? false;
          _hideNotifications = settings['hide_notifications'] ?? false;
          _hideEmergencyContacts = settings['hide_emergency_contacts'] ?? false;
          _hideLocationSharing = settings['hide_location_sharing'] ?? false;
          _disguiseAppIcon = settings['disguise_app_icon'] ?? false;
          _silentAlerts = settings['silent_alerts'] ?? false;
          _noCountdown = settings['no_countdown'] ?? false;
          _hideRecentActivity = settings['hide_recent_activity'] ?? false;
          _disguisedName = disguisedName;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Error loading settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleStealthMode(bool value) async {
    await _vibrationService.light();

    try {
      await _stealthService.setStealthMode(value);

      if (mounted) {
        setState(() => _stealthEnabled = value);

        await _soundService.playSuccess();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? ' Stealth mode enabled'
                  : ' Stealth mode disabled',
            ),
            backgroundColor: value ? Colors.purple : Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(' Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    await _vibrationService.light();

    try {
      await _stealthService.setFeatureHidden(key, value);
      await _soundService.playClick();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(' Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDisguiseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(
          'Choose Disguise',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: StealthModeService.disguiseOptions.length,
            itemBuilder: (context, index) {
              final option = StealthModeService.disguiseOptions[index];
              final isSelected = _disguisedName == option['name'];

              return Card(
                color: const Color(0xFF0A0E27),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(option['color'] as int).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      option['icon'] as IconData,
                      color: Color(option['color'] as int),
                    ),
                  ),
                  title: Text(
                    option['name'] as String,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () async {
                    await _vibrationService.light();
                    await _stealthService.setDisguisedAppName(option['name'] as String);

                    setState(() => _disguisedName = option['name'] as String);

                    if (mounted) {
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(' App will appear as ${option['name']}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E27),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Stealth Mode'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _stealthEnabled
                    ? [
                  Colors.purple.withValues(alpha: 0.2),
                  Colors.deepPurple.withValues(alpha: 0.2),
                ]
                    : [
                  Colors.grey.withValues(alpha: 0.2),
                  Colors.blueGrey.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _stealthEnabled
                    ? Colors.purple.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _stealthEnabled ? Icons.visibility_off : Icons.visibility,
                  size: 80,
                  color: _stealthEnabled ? Colors.purple : Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _stealthEnabled ? 'Stealth Mode Active' : 'Stealth Mode Disabled',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _stealthEnabled
                      ? 'App features are hidden for privacy'
                      : 'Enable to hide sensitive features',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Master Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2740),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _stealthEnabled
                        ? Colors.purple.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shield,
                    color: _stealthEnabled ? Colors.purple : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable Stealth Mode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Hide emergency features from others',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _stealthEnabled,
                  onChanged: _toggleStealthMode,
                  activeColor: Colors.purple,
                ),
              ],
            ),
          ),

          if (_stealthEnabled) ...[
            const SizedBox(height: 24),

            const Text(
              'STEALTH FEATURES',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00BFA5),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            _buildStealthOption(
              icon: Icons.text_fields,
              title: 'Hide App Name',
              subtitle: 'Show disguised name instead of AKEL',
              value: _hideAppName,
              onChanged: (value) {
                setState(() => _hideAppName = value);
                _saveSetting('hide_app_name', value);
              },
            ),

            const SizedBox(height: 12),

            _buildStealthOption(
              icon: Icons.error_outline,
              title: 'Hide Panic Button',
              subtitle: 'Remove panic button from home screen',
              value: _hidePanicButton,
              onChanged: (value) {
                setState(() => _hidePanicButton = value);
                _saveSetting('hide_panic_button', value);
              },
            ),

            const SizedBox(height: 12),

            _buildStealthOption(
              icon: Icons.notifications_off,
              title: 'Hide Notifications',
              subtitle: 'Suppress emergency notifications',
              value: _hideNotifications,
              onChanged: (value) {
                setState(() => _hideNotifications = value);
                _saveSetting('hide_notifications', value);
              },
            ),

            const SizedBox(height: 12),

            _buildStealthOption(
              icon: Icons.contacts_outlined,
              title: 'Hide Emergency Contacts',
              subtitle: 'Conceal contact list',
              value: _hideEmergencyContacts,
              onChanged: (value) {
                setState(() => _hideEmergencyContacts = value);
                _saveSetting('hide_emergency_contacts', value);
              },
            ),

            const SizedBox(height: 12),

            _buildStealthOption(
              icon: Icons.location_off,
              title: 'Hide Location Sharing',
              subtitle: 'Conceal location tracking features',
              value: _hideLocationSharing,
              onChanged: (value) {
                setState(() => _hideLocationSharing = value);
                _saveSetting('hide_location_sharing', value);
              },
            ),

            const SizedBox(height: 12),

            _buildStealthOption(
              icon: Icons.volume_off,
              title: 'Silent Alerts',
              subtitle: 'Send alerts without sound or vibration',
              value: _silentAlerts,
              onChanged: (value) {
                setState(() => _silentAlerts = value);
                _saveSetting('silent_alerts', value);
              },
            ),

            const SizedBox(height: 12),

            _buildStealthOption(
              icon: Icons.timer_off,
              title: 'No Countdown',
              subtitle: 'Skip countdown timer for instant alerts',
              value: _noCountdown,
              onChanged: (value) {
                setState(() => _noCountdown = value);
                _saveSetting('no_countdown', value);
              },
            ),

            const SizedBox(height: 12),

            _buildStealthOption(
              icon: Icons.history_toggle_off,
              title: 'Hide Recent Activity',
              subtitle: 'Conceal panic history and statistics',
              value: _hideRecentActivity,
              onChanged: (value) {
                setState(() => _hideRecentActivity = value);
                _saveSetting('hide_recent_activity', value);
              },
            ),

            const SizedBox(height: 24),

            const Text(
              'APP DISGUISE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00BFA5),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              color: const Color(0xFF1E2740),
              child: ListTile(
                leading: Icon(
                  StealthModeService.disguiseOptions
                      .firstWhere((o) => o['name'] == _disguisedName)['icon'] as IconData,
                  color: Colors.purple,
                ),
                title: const Text(
                  'Disguised As',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  _disguisedName,
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
                onTap: _showDisguiseDialog,
              ),
            ),

            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'About Stealth Mode',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '• Hides emergency features from prying eyes\n'
                        '• App appears as regular utility app\n'
                        '• Emergency functions still work silently\n'
                        '• You can still activate panic alerts\n'
                        '• Contacts are notified discreetly\n'
                        '• Perfect for abusive situations',
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStealthOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      color: const Color(0xFF1E2740),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.purple),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        value: value,
        activeColor: Colors.purple,
        onChanged: onChanged,
      ),
    );
  }
}