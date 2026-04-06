import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/voice_command_service.dart';
import '../services/vibration_service.dart';
import '../models/voice_command.dart';

class VoiceCommandsScreen extends StatefulWidget {
  const VoiceCommandsScreen({super.key});

  @override
  State<VoiceCommandsScreen> createState() => _VoiceCommandsScreenState();
}

class _VoiceCommandsScreenState extends State<VoiceCommandsScreen> {
  final VoiceCommandService _voiceService = VoiceCommandService();
  final VibrationService _vibrationService = VibrationService();

  bool _isEnabled = false;
  bool _isListening = false;
  bool _isInitializing = false;
  bool _hasPermission = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final enabled = await _voiceService.isVoiceCommandsEnabled();
    final permission = await _voiceService.hasMicrophonePermission();

    if (mounted) {
      setState(() {
        _isEnabled = enabled;
        _hasPermission = permission;
      });
    }
  }

  Future<void> _toggleVoiceCommands(bool value) async {
    await _vibrationService.light();

    if (value) {
      // Request permission and initialize
      setState(() => _isInitializing = true);

      final initialized = await _voiceService.initialize();

      if (initialized) {
        final hasPermission = await _voiceService.hasMicrophonePermission();

        if (hasPermission) {
          await _voiceService.setVoiceCommandsEnabled(true);

          setState(() {
            _isEnabled = true;
            _hasPermission = true;
            _isInitializing = false;
          });

          if (mounted) {
            _showVoiceCommandInfoDialog();
          }
        } else {
          setState(() => _isInitializing = false);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(' Microphone permission denied'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        setState(() => _isInitializing = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(' Failed to initialize voice recognition'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      await _voiceService.stopListening();
      await _voiceService.setVoiceCommandsEnabled(false);

      setState(() {
        _isEnabled = false;
        _isListening = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' Voice commands disabled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showVoiceCommandInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            const Icon(Icons.mic, color: Colors.blue, size: 28),
            const SizedBox(width: 12),
            Text(
              'Voice Commands Enabled',
              style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to use:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoBullet(' ', 'Tap "Start Listening" button'),
            _buildInfoBullet(' ', 'Say: "Hey AKEL, emergency!"'),
            _buildInfoBullet(' ', 'Panic alert triggers automatically'),
            _buildInfoBullet(' ', 'Tap "Stop" to end listening'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Works best in quiet environments. Keep phone close when speaking.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBullet(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleListening() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    final userName = authProvider.user?.displayName ?? 'User';

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(' Not logged in')),
      );
      return;
    }

    if (_isListening) {
      await _voiceService.stopListening();
      await _vibrationService.light();

      setState(() => _isListening = false);
    } else {
      await _voiceService.startListening(
        userId: userId,
        userName: userName,
      );
      await _vibrationService.success();

      setState(() => _isListening = true);

      // Update last words periodically
      _updateLastWords();
    }
  }

  void _updateLastWords() {
    if (!_isListening) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isListening) {
        setState(() {
          _lastWords = _voiceService.lastWords;
        });
        _updateLastWords();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Commands'),
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Text(
                  _isEnabled ? 'ON' : 'OFF',
                  style: TextStyle(
                    color: _isEnabled ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Switch(
                  value: _isEnabled,
                  onChanged: _isInitializing ? null : _toggleVoiceCommands,
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Card
          if (_isEnabled) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isListening
                      ? [Colors.blue.withValues(alpha: 0.3), Colors.purple.withValues(alpha: 0.3)]
                      : [Colors.grey.withValues(alpha: 0.2), Colors.grey.withValues(alpha: 0.1)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isListening ? Colors.blue : Colors.grey.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _isListening ? Icons.mic : Icons.mic_off,
                    size: 80,
                    color: _isListening ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isListening ? 'Listening...' : 'Not Listening',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _isListening ? Colors.blue : Colors.grey,
                    ),
                  ),
                  if (_isListening && _lastWords.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '"$_lastWords"',
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _toggleListening,
                      icon: Icon(_isListening ? Icons.stop : Icons.mic, size: 28),
                      label: Text(
                        _isListening ? 'Stop Listening' : 'Start Listening',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isListening ? Colors.red : Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Wake Words
          const Text(
            'WAKE WORDS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00BFA5),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.record_voice_over, color: Colors.blue, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Start your command with:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...VoiceCommandService.defaultWakeWords.map((word) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.chevron_right, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '"$word"',
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Emergency Commands
          const Text(
            'EMERGENCY COMMANDS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00BFA5),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Trigger panic with:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: VoiceCommandService.defaultEmergencyCommands
                        .map((command) => Chip(
                      label: Text(command),
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                    ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Examples
          const Text(
            'EXAMPLES',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00BFA5),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExampleCommand('Hey AKEL, emergency!', true),
                  _buildExampleCommand('Akel, help me!', true),
                  _buildExampleCommand('Hey AKEL, I need help!', true),
                  _buildExampleCommand('Okay AKEL, danger!', true),
                  const Divider(height: 24),
                  _buildExampleCommand('Hey AKEL, what\'s up?', false),
                  _buildExampleCommand('Akel, hello', false),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Command History
          if (userId != null && _isEnabled) ...[
            const Text(
              'RECENT COMMANDS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00BFA5),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<VoiceCommand>>(
              stream: _voiceService.getVoiceCommandHistory(userId, limit: 10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error loading history',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final commands = snapshot.data ?? [];

                if (commands.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.history, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No commands yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start listening to see your voice commands here',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    itemCount: commands.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final command = commands[index];
                      return ListTile(
                        leading: Icon(
                          command.triggered ? Icons.check_circle : Icons.mic,
                          color: command.triggered ? Colors.green : Colors.grey,
                        ),
                        title: Text(
                          command.command,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(command.timestamp),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: command.triggered
                            ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Text(
                            'TRIGGERED',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 24),

          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'Privacy & Battery',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• Voice commands only work when actively listening\n'
                      '• Audio is processed locally on your device\n'
                      '• No audio is recorded or stored\n'
                      '• Only command text is logged\n'
                      '• Minimal battery impact when listening',
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
    );
  }

  Widget _buildExampleCommand(String command, bool willTrigger) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            willTrigger ? Icons.check_circle : Icons.cancel,
            color: willTrigger ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '"$command"',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            willTrigger ? 'Will trigger' : 'Won\'t trigger',
            style: TextStyle(
              fontSize: 11,
              color: willTrigger ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}