import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/panic_service_v2.dart';
import '../services/biometric_service.dart';
import '../services/vibration_service.dart';
import '../services/shake_detection_service.dart' as shake_service;
import '../services/enhanced_aws_polly_service.dart';
import '../widgets/panic_widget_config.dart';
import '../widgets/glossy_3d_widgets.dart';
import '../widgets/futuristic_widgets.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import 'message_templates_screen.dart';
import 'export_data_screen.dart';
import 'help_support_screen.dart';
import 'app_diagnostics_screen.dart';
import 'emergency_info_screen.dart';
import 'shake_settings_screen.dart';
import 'contact_groups_screen.dart';
import 'safe_word_screen.dart';
import 'checkin_screen.dart';
import 'fake_call_screen.dart';
import 'voice_commands_screen.dart';
import 'sos_settings_screen.dart';
import 'biometric_settings_screen.dart';
import 'voice_settings_screen.dart';
import 'advanced_features_screen.dart';
import 'doctor_annie_customizer_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final PanicServiceV2 _panicServiceV2 = PanicServiceV2();
  final BiometricService _biometricService = BiometricService();
  final VibrationService _vibrationService = VibrationService();
  final shake_service.ShakeDetectionService _shakeService =
  shake_service.ShakeDetectionService();
  final EnhancedAWSPollyService _pollyService = EnhancedAWSPollyService();

  late AnimationController _backgroundController;

  // Emergency Settings
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _soundAlertsEnabled = true;
  bool _smsFallbackEnabled = true;
  bool _shareLocation = true;
  bool _countdownEnabled = true;
  bool _biometricLockEnabled = false;
  bool _vibrationEnabled = true;
  bool _fallDetectionEnabled = false;
  bool _locationTrackingEnabled = true;
  String _fallSensitivity = 'medium';

  // Hardware Triggers
  bool _volumeTriggerEnabled = true;
  bool _powerTriggerEnabled = true;
  bool _shakeTriggerEnabled = true;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _panicServiceV2.initialize();

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _loadSettings();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _panicServiceV2.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (mounted) {
      setState(() {
        // Emergency Settings
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _locationEnabled = prefs.getBool('location_enabled') ?? true;
        _soundAlertsEnabled = prefs.getBool('sound_alerts_enabled') ?? true;
        _smsFallbackEnabled = prefs.getBool('sms_fallback_enabled') ?? true;
        _shareLocation = prefs.getBool('share_location') ?? true;
        _countdownEnabled = prefs.getBool('countdown_enabled') ?? true;
        _biometricLockEnabled = prefs.getBool('biometric_lock_enabled') ?? false;
        _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
        _fallDetectionEnabled = prefs.getBool('fall_detection_enabled') ?? false;
        _locationTrackingEnabled = prefs.getBool('location_tracking_enabled') ?? true;
        _fallSensitivity = prefs.getString('fall_sensitivity') ?? 'medium';

        // Hardware Triggers
        _volumeTriggerEnabled = prefs.getBool('volume_trigger_enabled') ?? true;
        _powerTriggerEnabled = prefs.getBool('power_trigger_enabled') ?? true;
        _shakeTriggerEnabled = prefs.getBool('shake_trigger_enabled') ?? true;

        _isLoading = false;
      });
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Setting saved'),
          backgroundColor: AkelDesign.successGreen,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _saveAllSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Emergency Settings
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('location_enabled', _locationEnabled);
    await prefs.setBool('sound_alerts_enabled', _soundAlertsEnabled);
    await prefs.setBool('sms_fallback_enabled', _smsFallbackEnabled);
    await prefs.setBool('share_location', _shareLocation);
    await prefs.setBool('countdown_enabled', _countdownEnabled);
    await prefs.setBool('biometric_lock_enabled', _biometricLockEnabled);
    await prefs.setBool('vibration_enabled', _vibrationEnabled);
    await prefs.setBool('fall_detection_enabled', _fallDetectionEnabled);
    await prefs.setBool('location_tracking_enabled', _locationTrackingEnabled);
    await prefs.setString('fall_sensitivity', _fallSensitivity);

    // Hardware Triggers
    await prefs.setBool('volume_trigger_enabled', _volumeTriggerEnabled);
    await prefs.setBool('power_trigger_enabled', _powerTriggerEnabled);
    await prefs.setBool('shake_trigger_enabled', _shakeTriggerEnabled);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' All settings saved successfully!'),
          backgroundColor: AkelDesign.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToDoctorAnnie() async {
    await _vibrationService.heavy();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DoctorAnnieCustomizerScreen()),
    );
  }

  void _navigateToAdvancedFeatures() async {
    await _vibrationService.heavy();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdvancedFeaturesScreen()),
    );
  }

  Future<void> _showAboutDialog() async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
        ),
        title: Row(
          children: [
            Icon(Icons.shield, color: AkelDesign.neonBlue, size: 32),
            const SizedBox(width: 12),
            Text('About AKEL', style: AkelDesign.h3),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AKEL Panic Button',
                style: AkelDesign.h2.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text('Version 1.0.0 (Build 55)', style: AkelDesign.body),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  '80+ Features Active',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enterprise Emergency Response System',
                style: AkelDesign.body,
              ),
              const SizedBox(height: 16),
              Text(' Doctor Annie AI', style: AkelDesign.subtitle),
              const SizedBox(height: 8),
              Text(
                '• 3D Pixar-style avatar\n'
                    '• AWS Polly voice synthesis\n'
                    '• Customizable appearance & personality\n'
                    '• Lip sync & facial expressions',
                style: AkelDesign.caption,
              ),
              const SizedBox(height: 16),
              Text(' 3D Glossy UI', style: AkelDesign.subtitle),
              const SizedBox(height: 8),
              Text(
                '• Realistic glass morphism\n'
                    '• 3D depth and shadows\n'
                    '• Glossy shine effects\n'
                    '• Liquid animations',
                style: AkelDesign.caption,
              ),
              const SizedBox(height: 16),
              Text(' Marathon Features', style: AkelDesign.subtitle),
              const SizedBox(height: 8),
              Text(
                '• Offline emergency mode\n'
                    '• Man-down detection\n'
                    '• Worker safety check-ins\n'
                    '• Offline maps & routes\n'
                    '• Multi-agency dispatch\n'
                    '• Hazard reporter',
                style: AkelDesign.caption,
              ),
              const SizedBox(height: 16),
              Text(
                '© 2026 Kryptickel\nBuilt with Flutter, Firebase & AWS',
                style: AkelDesign.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AkelDesign.neonBlue)),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearDataDialog() async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
        ),
        title: Text('Clear All Data?', style: AkelDesign.h3),
        content: Text(
          'This will:\n'
              '• Reset all settings to default\n'
              '• Clear onboarding completion\n'
              '• Disable all triggers\n'
              '• Remove safe word\n'
              '• Reset voice preferences\n'
              '• Reset Doctor Annie customization\n\n'
              'Your emergency contacts will NOT be deleted.\n\n'
              'Continue?',
          style: AkelDesign.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AkelDesign.errorRed,
            ),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _loadSettings();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Settings cleared successfully'),
          backgroundColor: AkelDesign.successGreen,
        ),
      );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
      child: Text(
        title,
        style: AkelDesign.h3.copyWith(
          fontSize: 14,
          letterSpacing: 1.5,
          color: AkelDesign.neonBlue,
        ),
      ),
    );
  }

  Widget _buildGlossyCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Widget? badge,
  }) {
    return GestureDetector(
      onTap: () async {
        await _vibrationService.light();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
          border: Border.all(
            color: color.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Glossy overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AkelDesign.radiusMd),
                    topRight: Radius.circular(AkelDesign.radiusMd),
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (badge != null) ...[
                    badge,
                    const SizedBox(width: 8),
                  ],
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AkelDesign.deepBlack,
        body: Center(
          child: CircularProgressIndicator(color: AkelDesign.neonBlue),
        ),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.userProfile?['name'] ?? 'User';
    final userEmail = authProvider.user?.email ?? 'No email';
    final currentVoice = _pollyService.currentVoice;

    return Scaffold(
      backgroundColor: AkelDesign.deepBlack,
      appBar: AppBar(
        backgroundColor: AkelDesign.carbonFiber,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(' Settings', style: AkelDesign.h2.copyWith(fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: AkelDesign.successGreen),
            onPressed: _saveAllSettings,
            tooltip: 'Save All Settings',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showAboutDialog,
            tooltip: 'About',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0 + (_backgroundController.value * 0.2),
                colors: [
                  AkelDesign.carbonFiber,
                  AkelDesign.deepBlack,
                ],
              ),
            ),
            child: child,
          );
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // USER PROFILE CARD
            RealisticGlassCard(
              enable3D: true,
              elevation: 12,
              margin: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AkelDesign.neonBlue,
                          AkelDesign.neonBlue.withValues(alpha: 0.5),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // DOCTOR ANNIE - TOP PRIORITY
            _buildSectionHeader(' AI MEDICAL ASSISTANT'),

            _buildGlossyCard(
              title: 'Doctor Annie',
              subtitle: 'Customize your 3D AI medical assistant',
              icon: Icons.psychology,
              color: const Color(0xFF00BFA5),
              onTap: _navigateToDoctorAnnie,
              badge: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00BFA5), Color(0xFF00E5FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '3D',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),

            // MARATHON FEATURES - SECOND PRIORITY
            _buildSectionHeader(' MARATHON FEATURES'),

            _buildGlossyCard(
              title: 'Advanced Features',
              subtitle: '70+ premium emergency features',
              icon: Icons.science,
              color: const Color(0xFF7E57C2),
              onTap: _navigateToAdvancedFeatures,
              badge: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),

            // VOICE SETTINGS
            _buildSectionHeader(' VOICE ASSISTANT'),

            RealisticGlassCard(
              enable3D: true,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AkelDesign.neonBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.record_voice_over, color: AkelDesign.neonBlue),
                ),
                title: const Text(
                  'Voice Settings',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                subtitle: Text(
                  'Current: ${currentVoice.displayName} (${currentVoice.gender})',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                onTap: () async {
                  await _vibrationService.light();
                  if (mounted) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VoiceSettingsScreen()),
                    );
                    setState(() {});
                  }
                },
              ),
            ),

            // EMERGENCY SETTINGS
            _buildSectionHeader(' EMERGENCY SETTINGS'),

            LiquidGlassCard(
              gradientColors: const [Colors.red, Colors.orange, Colors.deepOrange],
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.medical_services, color: Colors.white),
                ),
                title: const Text(
                  'Emergency Medical Info',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                subtitle: const Text(
                  'Blood type, allergies, medical conditions',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                onTap: () async {
                  await _vibrationService.light();
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EmergencyInfoScreen()),
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 12),

            // EMERGENCY SWITCHES
            NeumorphicCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                secondary: const Icon(Icons.timer, color: AkelDesign.warningOrange),
                title: const Text('Countdown Timer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('10-second countdown before alert', style: TextStyle(color: Colors.white70, fontSize: 12)),
                value: _countdownEnabled,
                onChanged: (value) async {
                  await _vibrationService.light();
                  setState(() => _countdownEnabled = value);
                  _saveSetting('countdown_enabled', value);
                },
                activeColor: AkelDesign.warningOrange,
              ),
            ),

            NeumorphicCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                secondary: const Icon(Icons.volume_up, color: AkelDesign.neonBlue),
                title: const Text('Sound Alerts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Play sound when panic triggered', style: TextStyle(color: Colors.white70, fontSize: 12)),
                value: _soundAlertsEnabled,
                onChanged: (value) async {
                  await _vibrationService.light();
                  setState(() => _soundAlertsEnabled = value);
                  _saveSetting('sound_alerts_enabled', value);
                },
                activeColor: AkelDesign.neonBlue,
              ),
            ),

            NeumorphicCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                secondary: const Icon(Icons.vibration, color: Colors.purple),
                title: const Text('Haptic Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Vibrate on interactions', style: TextStyle(color: Colors.white70, fontSize: 12)),
                value: _vibrationEnabled,
                onChanged: (value) async {
                  if (value) await _vibrationService.medium();
                  setState(() => _vibrationEnabled = value);
                  _saveSetting('vibration_enabled', value);
                },
                activeColor: Colors.purple,
              ),
            ),

            NeumorphicCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                secondary: const Icon(Icons.location_on, color: AkelDesign.successGreen),
                title: const Text('Location Services', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Share GPS location in alerts', style: TextStyle(color: Colors.white70, fontSize: 12)),
                value: _locationEnabled,
                onChanged: (value) async {
                  await _vibrationService.light();
                  setState(() => _locationEnabled = value);
                  _saveSetting('location_enabled', value);
                },
                activeColor: AkelDesign.successGreen,
              ),
            ),

            NeumorphicCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                secondary: const Icon(Icons.sms, color: Colors.orange),
                title: const Text('SMS Fallback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Use SMS when internet unavailable', style: TextStyle(color: Colors.white70, fontSize: 12)),
                value: _smsFallbackEnabled,
                onChanged: (value) async {
                  await _vibrationService.light();
                  setState(() => _smsFallbackEnabled = value);
                  _saveSetting('sms_fallback_enabled', value);
                },
                activeColor: Colors.orange,
              ),
            ),

            // HARDWARE TRIGGERS
            _buildSectionHeader(' HARDWARE TRIGGERS'),

            NeumorphicCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                secondary: const Icon(Icons.volume_up, color: Colors.cyan),
                title: const Text('Volume Button Trigger', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Press volume buttons 5x quickly', style: TextStyle(color: Colors.white70, fontSize: 12)),
                value: _volumeTriggerEnabled,
                onChanged: (value) async {
                  await _vibrationService.light();
                  setState(() => _volumeTriggerEnabled = value);
                  _saveSetting('volume_trigger_enabled', value);
                },
                activeColor: Colors.cyan,
              ),
            ),

            NeumorphicCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                secondary: const Icon(Icons.power_settings_new, color: Colors.deepPurple),
                title: const Text('Power Button Trigger', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Press power button 3x quickly', style: TextStyle(color: Colors.white70, fontSize: 12)),
                value: _powerTriggerEnabled,
                onChanged: (value) async {
                  await _vibrationService.light();
                  setState(() => _powerTriggerEnabled = value);
                  _saveSetting('power_trigger_enabled', value);
                },
                activeColor: Colors.deepPurple,
              ),
            ),

            NeumorphicCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                secondary: const Icon(Icons.vibration, color: AkelDesign.infoBlue),
                title: const Text('Shake to Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Shake device vigorously to trigger', style: TextStyle(color: Colors.white70, fontSize: 12)),
                value: _shakeTriggerEnabled,
                onChanged: (value) async {
                  await _vibrationService.light();
                  setState(() => _shakeTriggerEnabled = value);
                  _saveSetting('shake_trigger_enabled', value);
                },
                activeColor: AkelDesign.infoBlue,
              ),
            ),

            // SECURITY SETTINGS
            _buildSectionHeader(' SECURITY'),

            MetallicCard(
              baseColor: Colors.purple,
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.security, color: Colors.white),
                    ),
                    title: const Text('Safe Word System', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: const Text('Silent panic with secret word', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                    onTap: () async {
                      await _vibrationService.light();
                      if (mounted) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SafeWordScreen()));
                      }
                    },
                  ),
                  const Divider(color: Colors.white24),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.fingerprint, color: Colors.white),
                    ),
                    title: const Text('Biometric Security', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: const Text('Fingerprint/Face ID', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                    onTap: () async {
                      await _vibrationService.light();
                      if (mounted) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const BiometricSettingsScreen()));
                      }
                    },
                  ),
                  const Divider(color: Colors.white24),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.widgets, color: Colors.white),
                    ),
                    title: const Text('Home Screen Widget', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: const Text('Configure panic button widget', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                    onTap: () async {
                      await _vibrationService.light();
                      if (mounted) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PanicWidgetConfig()));
                      }
                    },
                  ),
                ],
              ),
            ),

            // CONTACT ORGANIZATION
            _buildSectionHeader(' CONTACT ORGANIZATION'),

            FrostedGlassCard(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.group_work, color: Colors.blue),
                ),
                title: const Text('Contact Groups', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: const Text('Organize contacts into groups', style: TextStyle(color: Colors.white70, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                onTap: () async {
                  await _vibrationService.light();
                  if (mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactGroupsScreen()));
                  }
                },
              ),
            ),

            // APP INFORMATION
            _buildSectionHeader(' APP INFORMATION'),

            NeumorphicCard(
              child: ListTile(
                leading: const Icon(Icons.info_outline, color: AkelDesign.neonBlue),
                title: const Text('About AKEL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: const Text('Version 1.0.0 (Build 55) - 80+ Features', style: TextStyle(color: Colors.white70, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                onTap: () async {
                  await _vibrationService.light();
                  _showAboutDialog();
                },
              ),
            ),

            // DANGER ZONE
            _buildSectionHeader(' DANGER ZONE'),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Clear Settings Data',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Reset all settings to default', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _vibrationService.warning();
                      _showClearDataDialog();
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Clear Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AkelDesign.errorRed,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AkelDesign.radiusMd)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}