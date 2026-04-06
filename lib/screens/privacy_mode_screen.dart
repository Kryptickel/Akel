import 'package:flutter/material.dart';
import '../services/privacy_mode_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';

class PrivacyModeScreen extends StatefulWidget {
  const PrivacyModeScreen({super.key});

  @override
  State<PrivacyModeScreen> createState() => _PrivacyModeScreenState();
}

class _PrivacyModeScreenState extends State<PrivacyModeScreen> {
  final PrivacyModeService _privacyService = PrivacyModeService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();

  bool _isLoading = true;
  bool _privacyEnabled = false;
  bool _disableAnalytics = false;
  bool _disableCrashReports = false;
  bool _disableLocationHistory = false;
  bool _disableContactSync = false;
  bool _disableUsageStats = false;
  bool _autoDeleteHistory = false;
  bool _encryptLocalData = false;
  bool _blockScreenshots = false;
  bool _incognitoMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final settings = await _privacyService.getPrivacySettings();

      if (mounted) {
        setState(() {
          _privacyEnabled = settings['enabled'] ?? false;
          _disableAnalytics = settings['disable_analytics'] ?? false;
          _disableCrashReports = settings['disable_crash_reports'] ?? false;
          _disableLocationHistory = settings['disable_location_history'] ?? false;
          _disableContactSync = settings['disable_contact_sync'] ?? false;
          _disableUsageStats = settings['disable_usage_stats'] ?? false;
          _autoDeleteHistory = settings['auto_delete_history'] ?? false;
          _encryptLocalData = settings['encrypt_local_data'] ?? false;
          _blockScreenshots = settings['block_screenshots'] ?? false;
          _incognitoMode = settings['incognito_mode'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _togglePrivacyMode(bool value) async {
    await _vibrationService.light();

    try {
      await _privacyService.setPrivacyMode(value);

      if (mounted) {
        setState(() => _privacyEnabled = value);
        await _soundService.playSuccess();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? '🔒 Privacy mode enabled' : '🔓 Privacy mode disabled'),
            backgroundColor: value ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    await _vibrationService.light();
    try {
      await _privacyService.savePrivacySetting(key, value);
      await _soundService.playClick();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E27),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00BFA5))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Privacy Mode'),
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
                colors: _privacyEnabled
                    ? [Colors.green.withValues(alpha: 0.2), Colors.teal.withValues(alpha: 0.2)]
                    : [Colors.grey.withValues(alpha: 0.2), Colors.blueGrey.withValues(alpha: 0.2)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _privacyEnabled
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _privacyEnabled ? Icons.lock : Icons.lock_open,
                  size: 80,
                  color: _privacyEnabled ? Colors.green : Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _privacyEnabled ? 'Privacy Protected' : 'Privacy Mode Off',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _privacyEnabled
                      ? 'Your data is protected'
                      : 'Enable to protect your privacy',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                    color: _privacyEnabled
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.privacy_tip,
                    color: _privacyEnabled ? Colors.green : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enable Privacy Mode', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Disable tracking and data collection', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Switch(value: _privacyEnabled, onChanged: _togglePrivacyMode, activeColor: Colors.green),
              ],
            ),
          ),

          if (_privacyEnabled) ...[
            const SizedBox(height: 24),
            const Text('PRIVACY FEATURES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00BFA5), letterSpacing: 1)),
            const SizedBox(height: 12),

            _buildPrivacyOption(
              icon: Icons.analytics_outlined,
              title: 'Disable Analytics',
              subtitle: 'Stop collecting usage data',
              value: _disableAnalytics,
              onChanged: (value) {
                setState(() => _disableAnalytics = value);
                _saveSetting('disable_analytics', value);
              },
            ),
            const SizedBox(height: 12),

            _buildPrivacyOption(
              icon: Icons.bug_report_outlined,
              title: 'Disable Crash Reports',
              subtitle: 'Don\'t send crash data',
              value: _disableCrashReports,
              onChanged: (value) {
                setState(() => _disableCrashReports = value);
                _saveSetting('disable_crash_reports', value);
              },
            ),
            const SizedBox(height: 12),

            _buildPrivacyOption(
              icon: Icons.location_off,
              title: 'Disable Location History',
              subtitle: 'Don\'t save location breadcrumbs',
              value: _disableLocationHistory,
              onChanged: (value) {
                setState(() => _disableLocationHistory = value);
                _saveSetting('disable_location_history', value);
              },
            ),
            const SizedBox(height: 12),

            _buildPrivacyOption(
              icon: Icons.cloud_off,
              title: 'Disable Contact Sync',
              subtitle: 'Keep contacts local only',
              value: _disableContactSync,
              onChanged: (value) {
                setState(() => _disableContactSync = value);
                _saveSetting('disable_contact_sync', value);
              },
            ),
            const SizedBox(height: 12),

            _buildPrivacyOption(
              icon: Icons.bar_chart_outlined,
              title: 'Disable Usage Statistics',
              subtitle: 'Don\'t track app usage',
              value: _disableUsageStats,
              onChanged: (value) {
                setState(() => _disableUsageStats = value);
                _saveSetting('disable_usage_stats', value);
              },
            ),
            const SizedBox(height: 12),

            _buildPrivacyOption(
              icon: Icons.delete_sweep,
              title: 'Auto-Delete History',
              subtitle: 'Clear panic history after 30 days',
              value: _autoDeleteHistory,
              onChanged: (value) {
                setState(() => _autoDeleteHistory = value);
                _saveSetting('auto_delete_history', value);
              },
            ),
            const SizedBox(height: 12),

            _buildPrivacyOption(
              icon: Icons.enhanced_encryption,
              title: 'Encrypt Local Data',
              subtitle: 'Encrypt data stored on device',
              value: _encryptLocalData,
              onChanged: (value) {
                setState(() => _encryptLocalData = value);
                _saveSetting('encrypt_local_data', value);
              },
            ),
            const SizedBox(height: 12),

            _buildPrivacyOption(
              icon: Icons.screenshot_outlined,
              title: 'Block Screenshots',
              subtitle: 'Prevent screenshots in app',
              value: _blockScreenshots,
              onChanged: (value) {
                setState(() => _blockScreenshots = value);
                _saveSetting('block_screenshots', value);
              },
            ),
            const SizedBox(height: 12),

            _buildPrivacyOption(
              icon: Icons.visibility_off,
              title: 'Incognito Mode',
              subtitle: 'Leave no trace of app usage',
              value: _incognitoMode,
              onChanged: (value) {
                setState(() => _incognitoMode = value);
                _saveSetting('incognito_mode', value);
              },
            ),

            const SizedBox(height: 24),

// Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text('About Privacy Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '• All data stays on your device\n'
                        '• No data is shared with third parties\n'
                        '• Emergency functions still work normally\n'
                        '• You control what data is collected\n'
                        '• Can be disabled anytime',
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrivacyOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      color: const Color(0xFF1E2740),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.green),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        value: value,
        activeColor: Colors.green,
        onChanged: onChanged,
      ),
    );
  }
}