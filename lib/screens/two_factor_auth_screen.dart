import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/two_factor_auth_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';

class TwoFactorAuthScreen extends StatefulWidget {
  const TwoFactorAuthScreen({super.key});

  @override
  State<TwoFactorAuthScreen> createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends State<TwoFactorAuthScreen> {
  final TwoFactorAuthService _twoFactorService = TwoFactorAuthService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = true;
  bool _twoFactorEnabled = false;
  bool _smsMethod = true;
  bool _emailMethod = false;
  bool _appMethod = false;
  String _phoneNumber = '';
  String _email = '';
  List<String> _backupCodes = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final settings = await _twoFactorService.getTwoFactorSettings();
      final backupCodes = await _twoFactorService.getBackupCodes();

      if (mounted) {
        setState(() {
          _twoFactorEnabled = settings['enabled'] ?? false;
          _smsMethod = settings['sms_method'] ?? true;
          _emailMethod = settings['email_method'] ?? false;
          _appMethod = settings['app_method'] ?? false;
          _phoneNumber = settings['phone_number'] ?? '';
          _email = settings['email'] ?? '';
          _phoneController.text = _phoneNumber;
          _emailController.text = _email;
          _backupCodes = backupCodes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleTwoFactor(bool value) async {
    await _vibrationService.light();

    if (value) {
      // Verify user wants to enable 2FA
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E2740),
          title: const Text('Enable Two-Factor Authentication?', style: TextStyle(color: Colors.white)),
          content: const Text(
            'This adds an extra layer of security. You\'ll need to enter a code each time you access sensitive features.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Enable'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    try {
      await _twoFactorService.setTwoFactor(value);

      if (mounted) {
        setState(() => _twoFactorEnabled = value);
        await _soundService.playSuccess();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? ' 2FA enabled' : ' 2FA disabled'),
            backgroundColor: value ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(' Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    await _vibrationService.light();
    try {
      await _twoFactorService.saveTwoFactorSetting(key, value);
      await _soundService.playClick();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(' Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _testTwoFactor() async {
    if (!_smsMethod && !_emailMethod && !_appMethod) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Please enable at least one 2FA method'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final method = _smsMethod ? 'SMS' : (_emailMethod ? 'Email' : 'App');
    final destination = _smsMethod ? _phoneNumber : _email;

    if (destination.isEmpty && (method == 'SMS' || method == 'Email')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(' Please enter your ${method == 'SMS' ? 'phone number' : 'email'}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final code = await _twoFactorService.sendVerificationCode(method, destination);

      if (mounted) {
        await _vibrationService.success();

        // Show dialog with code (in production, code would be sent via SMS/Email)
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E2740),
            title: const Text('Test Code Sent', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'A verification code has been sent to your $method.',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0E27),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Test Code: $code',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '(In production, you would receive this via SMS/Email)',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(' Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _generateBackupCodes() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text('Generate Backup Codes?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will generate 10 backup codes. Save them in a secure place. Each code can only be used once.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final codes = await _twoFactorService.generateBackupCodes();

        setState(() => _backupCodes = codes);
        await _vibrationService.success();

        _showBackupCodesDialog(codes);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(' Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showBackupCodesDialog(List<String> codes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(' Save These Backup Codes', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Store these codes in a safe place. Each can only be used once.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E27),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: codes.map((code) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: codes.join('\n')));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(' Codes copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Copy All'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('I\'ve Saved Them'),
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
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00BFA5))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
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
                colors: _twoFactorEnabled
                    ? [Colors.green.withValues(alpha: 0.2), Colors.teal.withValues(alpha: 0.2)]
                    : [Colors.grey.withValues(alpha: 0.2), Colors.blueGrey.withValues(alpha: 0.2)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _twoFactorEnabled
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _twoFactorEnabled ? Icons.verified_user : Icons.security,
                  size: 80,
                  color: _twoFactorEnabled ? Colors.green : Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _twoFactorEnabled ? '2FA Enabled' : '2FA Disabled',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _twoFactorEnabled
                      ? 'Your account is protected with 2FA'
                      : 'Enable for extra security',
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
                    color: _twoFactorEnabled
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock,
                    color: _twoFactorEnabled ? Colors.green : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enable 2FA', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Require code for sensitive actions', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Switch(value: _twoFactorEnabled, onChanged: _toggleTwoFactor, activeColor: Colors.green),
              ],
            ),
          ),

          if (_twoFactorEnabled) ...[
            const SizedBox(height: 24),
            const Text('AUTHENTICATION METHODS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00BFA5), letterSpacing: 1)),
            const SizedBox(height: 12),

            Card(
              color: const Color(0xFF1E2740),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.sms, color: Colors.green),
                    title: const Text('SMS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                    subtitle: const Text('Receive codes via text message', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    value: _smsMethod,
                    activeColor: Colors.green,
                    onChanged: (value) {
                      setState(() => _smsMethod = value);
                      _saveSetting('sms_method', value);
                    },
                  ),
                  if (_smsMethod) ...[
                    const Divider(height: 1, color: Colors.white24),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintText: '+1 (555) 123-4567',
                          hintStyle: TextStyle(color: Colors.white38),
                          prefixIcon: Icon(Icons.phone, color: Colors.green),
                        ),
                        onChanged: (value) {
                          _phoneNumber = value;
                          _saveSetting('phone_number', value);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            Card(
              color: const Color(0xFF1E2740),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.email, color: Colors.blue),
                    title: const Text('Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                    subtitle: const Text('Receive codes via email', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    value: _emailMethod,
                    activeColor: Colors.blue,
                    onChanged: (value) {
                      setState(() => _emailMethod = value);
                      _saveSetting('email_method', value);
                    },
                  ),
                  if (_emailMethod) ...[
                    const Divider(height: 1, color: Colors.white24),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintText: 'you@example.com',
                          hintStyle: TextStyle(color: Colors.white38),
                          prefixIcon: Icon(Icons.email, color: Colors.blue),
                        ),
                        onChanged: (value) {
                          _email = value;
                          _saveSetting('email', value);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            Card(
              color: const Color(0xFF1E2740),
              child: SwitchListTile(
                secondary: const Icon(Icons.phonelink_lock, color: Colors.purple),
                title: const Text('Authenticator App', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                subtitle: const Text('Use Google Authenticator or similar', style: TextStyle(color: Colors.white70, fontSize: 12)),
                value: _appMethod,
                activeColor: Colors.purple,
                onChanged: (value) {
                  setState(() => _appMethod = value);
                  _saveSetting('app_method', value);
                },
              ),
            ),

            const SizedBox(height: 24),

            // Test 2FA Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _testTwoFactor,
                icon: const Icon(Icons.send),
                label: const Text('Test 2FA'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text('BACKUP CODES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00BFA5), letterSpacing: 1)),
            const SizedBox(height: 12),

            Card(
              color: const Color(0xFF1E2740),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.vpn_key, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Emergency Backup Codes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _backupCodes.isEmpty
                          ? 'No backup codes generated yet'
                          : '${_backupCodes.length} backup codes generated',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _generateBackupCodes,
                        icon: const Icon(Icons.refresh),
                        label: Text(_backupCodes.isEmpty ? 'Generate Codes' : 'Regenerate Codes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                      Text('About Two-Factor Authentication', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '• Adds extra security layer to your account\n'
                        '• Requires code for sensitive actions\n'
                        '• Codes expire after 5 minutes\n'
                        '• Save backup codes in secure location\n'
                        '• Can use SMS, Email, or Authenticator App',
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
}