import 'package:flutter/material.dart';
import '../services/biometric_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricSettingsScreen extends StatefulWidget {
  const BiometricSettingsScreen({super.key});

  @override
  State<BiometricSettingsScreen> createState() => _BiometricSettingsScreenState();
}

class _BiometricSettingsScreenState extends State<BiometricSettingsScreen> {
  final BiometricService _biometricService = BiometricService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();

  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  String _biometricType = 'Biometric';
  bool _isLoading = true;
  bool _isTesting = false;

  // Lock timeout options
  int _lockTimeout = 0; // 0 = immediate
  final List<Map<String, dynamic>> _timeoutOptions = [
    {'value': 0, 'label': 'Immediately'},
    {'value': 30, 'label': '30 seconds'},
    {'value': 60, 'label': '1 minute'},
    {'value': 300, 'label': '5 minutes'},
    {'value': 600, 'label': '10 minutes'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final isAvailable = await _biometricService.isBiometricAvailable();
      final isEnabled = await _biometricService.isBiometricEnabled();
      final type = await _biometricService.getBiometricTypeName();

      final prefs = await SharedPreferences.getInstance();
      final timeout = prefs.getInt('biometric_lock_timeout') ?? 0;

      if (mounted) {
        setState(() {
          _isBiometricAvailable = isAvailable;
          _isBiometricEnabled = isEnabled;
          _biometricType = type;
          _lockTimeout = timeout;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!_isBiometricAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Biometric authentication not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (value) {
      // Authenticate before enabling
      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to enable biometric lock',
      );

      if (!authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' Authentication failed'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    try {
      await _biometricService.setBiometricEnabled(value);
      await _vibrationService.success();
      await _soundService.playSuccess();

      if (mounted) {
        setState(() => _isBiometricEnabled = value);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? ' Biometric lock enabled'
                  : ' Biometric lock disabled',
            ),
            backgroundColor: value ? Colors.green : Colors.orange,
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

  Future<void> _setLockTimeout(int seconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('biometric_lock_timeout', seconds);

      await _vibrationService.light();

      setState(() => _lockTimeout = seconds);

      final label = _timeoutOptions.firstWhere((o) => o['value'] == seconds)['label'];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(' Lock timeout set to $label'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(' Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testBiometric() async {
    setState(() => _isTesting = true);

    final authenticated = await _biometricService.authenticate(
      reason: 'Test biometric authentication',
    );

    if (mounted) {
      setState(() => _isTesting = false);

      if (authenticated) {
        await _vibrationService.success();
        await _soundService.playSuccess();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' Authentication successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _vibrationService.error();
        await _soundService.playError();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' Authentication failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Biometric Security'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _loadSettings,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isBiometricAvailable
                      ? [
                    Colors.green.withValues(alpha: 0.2),
                    Colors.teal.withValues(alpha: 0.2),
                  ]
                      : [
                    Colors.grey.withValues(alpha: 0.2),
                    Colors.blueGrey.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isBiometricAvailable
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _isBiometricAvailable
                        ? Icons.fingerprint
                        : Icons.fingerprint_outlined,
                    size: 80,
                    color: _isBiometricAvailable
                        ? Colors.green
                        : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isBiometricAvailable
                        ? '$_biometricType Available'
                        : 'Biometric Not Available',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isBiometricAvailable
                        ? 'Your device supports biometric authentication'
                        : 'This device does not support biometric authentication',
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

            // Enable Biometric Lock
            if (_isBiometricAvailable) ...[
              const Text(
                'SECURITY SETTINGS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00BFA5),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

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
                        color: _isBiometricEnabled
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock,
                        color: _isBiometricEnabled
                            ? Colors.green
                            : Colors.grey,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Biometric Lock',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Require authentication to open app',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isBiometricEnabled,
                      onChanged: _toggleBiometric,
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Lock Timeout
              if (_isBiometricEnabled) ...[
                const Text(
                  'LOCK TIMEOUT',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00BFA5),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),

                ..._timeoutOptions.map((option) {
                  final isSelected = _lockTimeout == option['value'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: RadioListTile<int>(
                      value: option['value'] as int,
                      groupValue: _lockTimeout,
                      onChanged: (value) {
                        if (value != null) {
                          _setLockTimeout(value);
                        }
                      },
                      title: Text(
                        option['label'] as String,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      activeColor: const Color(0xFF00BFA5),
                      tileColor: const Color(0xFF1E2740),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),
              ],

              // Test Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isTesting ? null : _testBiometric,
                  icon: _isTesting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.fingerprint, size: 24),
                  label: Text(
                    _isTesting ? 'Testing...' : 'Test $_biometricType',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],

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
                        'About Biometric Security',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '• Biometric data never leaves your device\n'
                        '• Your fingerprint/face data is encrypted\n'
                        '• Adds an extra layer of security\n'
                        '• Fallback to PIN/Pattern if biometric fails\n'
                        '• Can be disabled anytime\n'
                        '• Lock timeout controls when authentication is required',
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.5,
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
}