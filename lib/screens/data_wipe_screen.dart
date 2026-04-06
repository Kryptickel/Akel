import 'package:flutter/material.dart';
import '../services/data_wipe_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';

class DataWipeScreen extends StatefulWidget {
  const DataWipeScreen({super.key});

  @override
  State<DataWipeScreen> createState() => _DataWipeScreenState();
}

class _DataWipeScreenState extends State<DataWipeScreen> {
  final DataWipeService _wipeService = DataWipeService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();

  bool _wipeContacts = true;
  bool _wipeHistory = true;
  bool _wipeLocation = true;
  bool _wipeMedical = true;
  bool _wipeSettings = true;
  bool _wipeMessages = true;
  bool _isWiping = false;

  Future<void> _performWipe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text(' Confirm Data Wipe', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'This will PERMANENTLY delete selected data.\n\n'
              'This action CANNOT be undone!\n\n'
              'Are you absolutely sure?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('WIPE DATA'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isWiping = true);
    await _vibrationService.warning();

    try {
      final result = await _wipeService.emergencyWipe(
        wipeContacts: _wipeContacts,
        wipeHistory: _wipeHistory,
        wipeLocation: _wipeLocation,
        wipeMedical: _wipeMedical,
        wipeSettings: _wipeSettings,
        wipeMessages: _wipeMessages,
      );

      if (mounted) {
        setState(() => _isWiping = false);

        if (result['success'] == true) {
          await _soundService.playSuccess();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ' Data wiped successfully (${result['successCount']}/${result['totalCount']})',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          await _soundService.playError();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(' Data wipe failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isWiping = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Error: $e'),
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
        title: const Text('Emergency Data Wipe'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Warning Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: const Column(
              children: [
                Icon(Icons.warning_amber, size: 60, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'DANGER ZONE',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This will PERMANENTLY delete your data.\nThis action CANNOT be undone!',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'SELECT DATA TO WIPE',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00BFA5),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          _buildWipeOption(
            icon: Icons.contacts,
            title: 'Emergency Contacts',
            subtitle: 'Delete all saved contacts',
            value: _wipeContacts,
            onChanged: (value) {
              if (value != null) setState(() => _wipeContacts = value);
            },
          ),
          const SizedBox(height: 12),

          _buildWipeOption(
            icon: Icons.history,
            title: 'Panic History',
            subtitle: 'Delete all panic event records',
            value: _wipeHistory,
            onChanged: (value) {
              if (value != null) setState(() => _wipeHistory = value);
            },
          ),
          const SizedBox(height: 12),

          _buildWipeOption(
            icon: Icons.location_on,
            title: 'Location Data',
            subtitle: 'Delete location history',
            value: _wipeLocation,
            onChanged: (value) {
              if (value != null) setState(() => _wipeLocation = value);
            },
          ),
          const SizedBox(height: 12),

          _buildWipeOption(
            icon: Icons.medical_services,
            title: 'Medical Information',
            subtitle: 'Delete medical ID data',
            value: _wipeMedical,
            onChanged: (value) {
              if (value != null) setState(() => _wipeMedical = value);
            },
          ),
          const SizedBox(height: 12),

          _buildWipeOption(
            icon: Icons.settings,
            title: 'App Settings',
            subtitle: 'Reset all preferences',
            value: _wipeSettings,
            onChanged: (value) {
              if (value != null) setState(() => _wipeSettings = value);
            },
          ),
          const SizedBox(height: 12),

          _buildWipeOption(
            icon: Icons.message,
            title: 'Message Templates',
            subtitle: 'Delete custom messages',
            value: _wipeMessages,
            onChanged: (value) {
              if (value != null) setState(() => _wipeMessages = value);
            },
          ),

          const SizedBox(height: 32),

          // Wipe Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isWiping ? null : _performWipe,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isWiping
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Wiping Data...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.delete_forever, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'WIPE SELECTED DATA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                    Text(
                      'When to Use',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '• Device has been compromised\n'
                      '• You need to quickly erase sensitive data\n'
                      '• Before selling or giving away device\n'
                      '• In abusive situations requiring data removal\n'
                      '• When ordered by authorities',
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWipeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Card(
      color: const Color(0xFF1E2740),
      child: CheckboxListTile(
        secondary: Icon(icon, color: Colors.red),
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
        activeColor: Colors.red,
        onChanged: onChanged,
      ),
    );
  }
}