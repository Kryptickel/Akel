import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/anonymous_mode_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';

class AnonymousModeScreen extends StatefulWidget {
  const AnonymousModeScreen({super.key});

  @override
  State<AnonymousModeScreen> createState() => _AnonymousModeScreenState();
}

class _AnonymousModeScreenState extends State<AnonymousModeScreen> {
  final AnonymousModeService _anonService = AnonymousModeService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();

  bool _isLoading = true;
  bool _anonymousEnabled = false;
  bool _hideIdentity = false;
  bool _maskLocation = false;
  bool _randomizeData = false;
  bool _useVpn = false;
  bool _clearCookies = false;
  bool _disableTracking = false;
  bool _anonymousMessaging = false;
  bool _privateBrowsing = false;
  String? _anonymousId;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final settings = await _anonService.getAnonymousSettings();
      final anonId = await _anonService.getAnonymousId();

      if (mounted) {
        setState(() {
          _anonymousEnabled = settings['enabled'] ?? false;
          _hideIdentity = settings['hide_identity'] ?? false;
          _maskLocation = settings['mask_location'] ?? false;
          _randomizeData = settings['randomize_data'] ?? false;
          _useVpn = settings['use_vpn'] ?? false;
          _clearCookies = settings['clear_cookies'] ?? false;
          _disableTracking = settings['disable_tracking'] ?? false;
          _anonymousMessaging = settings['anonymous_messaging'] ?? false;
          _privateBrowsing = settings['private_browsing'] ?? false;
          _anonymousId = anonId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleAnonymousMode(bool value) async {
    await _vibrationService.light();

    try {
      if (value && _anonymousId == null) {
// Generate anonymous ID when enabling for the first time
        final newId = await _anonService.generateAnonymousId();
        setState(() => _anonymousId = newId);
      }

      await _anonService.setAnonymousMode(value);

      if (mounted) {
        setState(() => _anonymousEnabled = value);
        await _soundService.playSuccess();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? '🥷 Anonymous mode enabled' : '👤 Anonymous mode disabled'),
            backgroundColor: value ? Colors.deepPurple : Colors.orange,
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
      await _anonService.saveAnonymousSetting(key, value);
      await _soundService.playClick();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _regenerateId() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text('Regenerate Anonymous ID?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will create a new anonymous ID. Your old ID will be lost.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _anonService.clearAnonymousId();
        final newId = await _anonService.generateAnonymousId();

        setState(() => _anonymousId = newId);
        await _vibrationService.success();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ New anonymous ID generated'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
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
        title: const Text('Anonymous Mode'),
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
                colors: _anonymousEnabled
                    ? [Colors.deepPurple.withValues(alpha: 0.2), Colors.purple.withValues(alpha: 0.2)]
                    : [Colors.grey.withValues(alpha: 0.2), Colors.blueGrey.withValues(alpha: 0.2)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _anonymousEnabled
                    ? Colors.deepPurple.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _anonymousEnabled ? Icons.person_off : Icons.person,
                  size: 80,
                  color: _anonymousEnabled ? Colors.deepPurple : Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _anonymousEnabled ? 'Anonymous' : 'Identified',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _anonymousEnabled
                      ? 'Your identity is protected'
                      : 'Enable to hide your identity',
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
                    color: _anonymousEnabled
                        ? Colors.deepPurple.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security,
                    color: _anonymousEnabled ? Colors.deepPurple : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enable Anonymous Mode', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Hide your identity in emergencies', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Switch(value: _anonymousEnabled, onChanged: _toggleAnonymousMode, activeColor: Colors.deepPurple),
              ],
            ),
          ),

          if (_anonymousEnabled) ...[
            const SizedBox(height: 24),

// Anonymous ID Card
            Card(
              color: const Color(0xFF1E2740),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.badge, color: Colors.deepPurple, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Your Anonymous ID',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0E27),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _anonymousId ?? 'Not generated',
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (_anonymousId != null) {
                                Clipboard.setData(ClipboardData(text: _anonymousId!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('📋 ID copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                            tooltip: 'Copy',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _regenerateId,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Regenerate ID'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepPurple,
                          side: const BorderSide(color: Colors.deepPurple),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text('PRIVACY FEATURES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00BFA5), letterSpacing: 1)),
            const SizedBox(height: 12),

            _buildAnonymousOption(
              icon: Icons.person_off,
              title: 'Hide Identity',
              subtitle: 'Don\'t share personal information',
              value: _hideIdentity,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _hideIdentity = value);
                  _saveSetting('hide_identity', value);
                }
              },
            ),
            const SizedBox(height: 12),

            _buildAnonymousOption(
              icon: Icons.location_off,
              title: 'Mask Location',
              subtitle: 'Send approximate location only',
              value: _maskLocation,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _maskLocation = value);
                  _saveSetting('mask_location', value);
                }
              },
            ),
            const SizedBox(height: 12),

            _buildAnonymousOption(
              icon: Icons.shuffle,
              title: 'Randomize Data',
              subtitle: 'Add random noise to your data',
              value: _randomizeData,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _randomizeData = value);
                  _saveSetting('randomize_data', value);
                }
              },
            ),
            const SizedBox(height: 12),

            _buildAnonymousOption(
              icon: Icons.vpn_lock,
              title: 'Use VPN',
              subtitle: 'Route traffic through VPN',
              value: _useVpn,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _useVpn = value);
                  _saveSetting('use_vpn', value);
                }
              },
            ),
            const SizedBox(height: 12),

            _buildAnonymousOption(
              icon: Icons.cookie,
              title: 'Clear Cookies',
              subtitle: 'Delete cookies after each session',
              value: _clearCookies,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _clearCookies = value);
                  _saveSetting('clear_cookies', value);
                }
              },
            ),
            const SizedBox(height: 12),

            _buildAnonymousOption(
              icon: Icons.track_changes,
              title: 'Disable Tracking',
              subtitle: 'Block all tracking attempts',
              value: _disableTracking,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _disableTracking = value);
                  _saveSetting('disable_tracking', value);
                }
              },
            ),
            const SizedBox(height: 12),

            _buildAnonymousOption(
              icon: Icons.message,
              title: 'Anonymous Messaging',
              subtitle: 'Send alerts without sender info',
              value: _anonymousMessaging,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _anonymousMessaging = value);
                  _saveSetting('anonymous_messaging', value);
                }
              },
            ),
            const SizedBox(height: 12),

            _buildAnonymousOption(
              icon: Icons.browser_not_supported,
              title: 'Private Browsing',
              subtitle: 'Don\'t save browsing history',
              value: _privateBrowsing,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _privateBrowsing = value);
                  _saveSetting('private_browsing', value);
                }
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
                      Text('About Anonymous Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '• Protects your identity during emergencies\n'
                        '• Uses anonymous ID instead of name\n'
                        '• Masks personal information\n'
                        '• Emergency responders still get help request\n'
                        '• Useful in sensitive situations',
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

  Widget _buildAnonymousOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Card(
      color: const Color(0xFF1E2740),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.deepPurple),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        value: value,
        activeColor: Colors.deepPurple,
        onChanged: onChanged,
      ),
    );
  }
}