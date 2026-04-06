import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';

class VoiceCommandScreen extends StatefulWidget {
  const VoiceCommandScreen({super.key});

  @override
  State<VoiceCommandScreen> createState() => _VoiceCommandScreenState();
}

class _VoiceCommandScreenState extends State<VoiceCommandScreen> {
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();

  bool _isEnabled = false;
  bool _isLoading = true;

  final List<String> _defaultCommands = [
    'Help me',
    'Emergency',
    'Call for help',
    'I need help',
    'Nine one one',
    'SOS',
    'Panic',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('voice_commands_enabled') ?? false;

      if (mounted) {
        setState(() {
          _isEnabled = enabled;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Load voice command settings error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleVoiceCommands(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('voice_commands_enabled', value);

      await _vibrationService.success();
      await _soundService.playSuccess();

      setState(() {
        _isEnabled = value;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? '✅ Voice commands enabled'
                  : '⚠️ Voice commands disabled',
            ),
            backgroundColor: value ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Toggle voice commands error: $e');
      await _vibrationService.error();
      await _soundService.playError();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('🎤 Voice Commands'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎤 Voice Commands'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
// Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.mic, color: Colors.deepPurple, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Voice-Activated Emergency',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Trigger emergency alerts hands-free using voice commands.',
                ),
                SizedBox(height: 8),
                Text(
                  '• Works in background\n'
                      '• No need to touch phone\n'
                      '• Perfect for dangerous situations\n'
                      '• Multiple command phrases',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

// Enable/Disable Toggle
          Card(
            child: SwitchListTile(
              title: const Text(
                'Voice Commands',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _isEnabled
                    ? 'Active - Say a command to trigger alert'
                    : 'Disabled - Enable to use voice activation',
              ),
              value: _isEnabled,
              onChanged: _toggleVoiceCommands,
              activeColor: Colors.deepPurple,
              secondary: Icon(
                _isEnabled ? Icons.mic : Icons.mic_off,
                color: _isEnabled ? Colors.deepPurple : Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 24),

// Available Commands
          const Text(
            'Available Voice Commands',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._defaultCommands.map((command) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.record_voice_over,
                    color: Colors.deepPurple),
                title: Text(
                  '"$command"',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: const Text('Say this to trigger emergency alert'),
                trailing: Icon(
                  _isEnabled ? Icons.check_circle : Icons.circle_outlined,
                  color: _isEnabled ? Colors.green : Colors.grey,
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 24),

// How It Works
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'How It Works',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStep('1', 'Enable voice commands'),
                _buildStep('2', 'Keep app running in background'),
                _buildStep('3', 'Say any command phrase clearly'),
                _buildStep('4', 'Emergency alert triggers automatically'),
              ],
            ),
          ),

          const SizedBox(height: 24),

// Privacy Note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.privacy_tip, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Privacy & Battery',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '• Voice data processed locally\n'
                      '• Nothing recorded or stored\n'
                      '• Minimal battery usage\n'
                      '• Only listens for specific commands\n'
                      '• Disable anytime',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

// Test Button
          if (_isEnabled)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _vibrationService.light();
                  await _soundService.playClick();

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('🎤 Test Voice Command'),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic, size: 64, color: Colors.deepPurple),
                          SizedBox(height: 16),
                          Text(
                            'Say one of the command phrases to test',
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Example: "Help me"',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
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
                },
                icon: const Icon(Icons.mic, size: 24),
                label: const Text(
                  'TEST VOICE COMMAND',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }
}