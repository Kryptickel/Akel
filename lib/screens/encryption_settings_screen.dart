import 'package:flutter/material.dart';
import '../services/encryption_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';

class EncryptionSettingsScreen extends StatefulWidget {
  const EncryptionSettingsScreen({super.key});

  @override
  State<EncryptionSettingsScreen> createState() => _EncryptionSettingsScreenState();
}

class _EncryptionSettingsScreenState extends State<EncryptionSettingsScreen> {
  final EncryptionService _encryptionService = EncryptionService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();

  bool _isLoading = true;
  bool _encryptionEnabled = false;
  bool _encryptContacts = false;
  bool _encryptMessages = false;
  bool _encryptLocation = false;
  bool _encryptHistory = false;
  bool _encryptMedical = false;
  String _encryptionLevel = 'standard';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final settings = await _encryptionService.getEncryptionSettings();

      if (mounted) {
        setState(() {
          _encryptionEnabled = settings['enabled'] ?? false;
          _encryptContacts = settings['encrypt_contacts'] ?? false;
          _encryptMessages = settings['encrypt_messages'] ?? false;
          _encryptLocation = settings['encrypt_location'] ?? false;
          _encryptHistory = settings['encrypt_history'] ?? false;
          _encryptMedical = settings['encrypt_medical'] ?? false;
          _encryptionLevel = settings['encryption_level'] ?? 'standard';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleEncryption(bool value) async {
    await _vibrationService.light();

    try {
      await _encryptionService.setEncryption(value);

      if (mounted) {
        setState(() => _encryptionEnabled = value);
        await _soundService.playSuccess();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? '🔐 Encryption enabled' : '🔓 Encryption disabled'),
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

  Future<void> _saveSetting(String key, dynamic value) async {
    await _vibrationService.light();
    try {
      await _encryptionService.saveEncryptionSetting(key, value);
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
        title: const Text('Encryption Settings'),
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
                colors: _encryptionEnabled
                    ? [Colors.blue.withValues(alpha: 0.2), Colors.cyan.withValues(alpha: 0.2)]
                    : [Colors.grey.withValues(alpha: 0.2), Colors.blueGrey.withValues(alpha: 0.2)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _encryptionEnabled
                    ? Colors.blue.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _encryptionEnabled ? Icons.enhanced_encryption : Icons.no_encryption,
                  size: 80,
                  color: _encryptionEnabled ? Colors.blue : Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _encryptionEnabled ? 'Data Encrypted' : 'Encryption Disabled',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _encryptionEnabled
                      ? 'Your data is securely encrypted'
                      : 'Enable to encrypt your data',
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
                    color: _encryptionEnabled
                        ? Colors.blue.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security,
                    color: _encryptionEnabled ? Colors.blue : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enable Encryption', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Protect your data with encryption', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Switch(value: _encryptionEnabled, onChanged: _toggleEncryption, activeColor: Colors.blue),
              ],
            ),
          ),

          if (_encryptionEnabled) ...[
            const SizedBox(height: 24),
            const Text('ENCRYPTION LEVEL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00BFA5), letterSpacing: 1)),
            const SizedBox(height: 12),

            ...EncryptionService.encryptionLevels.map((level) {
              final isSelected = _encryptionLevel == level['value'];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Card(
                  color: const Color(0xFF1E2740),
                  child: RadioListTile<String>(
                    value: level['value'] as String,
                    groupValue: _encryptionLevel,
                    onChanged: (value) {
                      setState(() => _encryptionLevel = value!);
                      _saveSetting('level', value!);
                    },
                    title: Text(
                      level['name'] as String,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      level['description'] as String,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    secondary: Icon(level['icon'] as IconData, color: Colors.blue),
                    activeColor: Colors.blue,
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),
            const Text('ENCRYPT DATA TYPES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00BFA5), letterSpacing: 1)),
            const SizedBox(height: 12),

            _buildEncryptOption(
              icon: Icons.contacts,
              title: 'Emergency Contacts',
              subtitle: 'Encrypt contact information',
              value: _encryptContacts,
              onChanged: (value) {
                setState(() => _encryptContacts = value);
                _saveSetting('contacts', value);
              },
            ),
            const SizedBox(height: 12),

            _buildEncryptOption(
              icon: Icons.message,
              title: 'Messages',
              subtitle: 'Encrypt emergency messages',
              value: _encryptMessages,
              onChanged: (value) {
                setState(() => _encryptMessages = value);
                _saveSetting('messages', value);
              },
            ),
            const SizedBox(height: 12),

            _buildEncryptOption(
              icon: Icons.location_on,
              title: 'Location Data',
              subtitle: 'Encrypt location history',
              value: _encryptLocation,
              onChanged: (value) {
                setState(() => _encryptLocation = value);
                _saveSetting('location', value);
              },
            ),
            const SizedBox(height: 12),

            _buildEncryptOption(
              icon: Icons.history,
              title: 'Panic History',
              subtitle: 'Encrypt event history',
              value: _encryptHistory,
              onChanged: (value) {
                setState(() => _encryptHistory = value);
                _saveSetting('history', value);
              },
            ),
            const SizedBox(height: 12),

            _buildEncryptOption(
              icon: Icons.medical_services,
              title: 'Medical Information',
              subtitle: 'Encrypt medical ID data',
              value: _encryptMedical,
              onChanged: (value) {
                setState(() => _encryptMedical = value);
                _saveSetting('medical', value);
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
                      Text('About Encryption', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '• AES-256 military-grade encryption\n'
                        '• Data encrypted at rest and in transit\n'
                        '• Only you can decrypt your data\n'
                        '• Keys stored securely on device\n'
                        '• Emergency functions work normally',
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

  Widget _buildEncryptOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      color: const Color(0xFF1E2740),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        value: value,
        activeColor: Colors.blue,
        onChanged: onChanged,
      ),
    );
  }
}