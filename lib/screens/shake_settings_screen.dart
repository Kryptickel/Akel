import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/shake_detection_service.dart';
import '../services/vibration_service.dart';

class ShakeSettingsScreen extends StatefulWidget {
  const ShakeSettingsScreen({super.key});

  @override
  State<ShakeSettingsScreen> createState() => _ShakeSettingsScreenState();
}

class _ShakeSettingsScreenState extends State<ShakeSettingsScreen> {
  final ShakeDetectionService _shakeService = ShakeDetectionService();
  final VibrationService _vibrationService = VibrationService();

  bool _shakeEnabled = false;
  double _shakeSensitivity = 2.7;
  int _shakeCount = 3;
  int _shakeTimeWindow = 500; // milliseconds
  bool _vibrationFeedback = true;
  bool _countdownEnabled = true;
  int _countdownDuration = 10;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _shakeEnabled = prefs.getBool('shake_enabled') ?? false;
        _shakeSensitivity = prefs.getDouble('shake_sensitivity') ?? 2.7;
        _shakeCount = prefs.getInt('shake_count') ?? 3;
        _shakeTimeWindow = prefs.getInt('shake_time_window') ?? 500;
        _vibrationFeedback = prefs.getBool('shake_vibration_feedback') ?? true;
        _countdownEnabled = prefs.getBool('shake_countdown_enabled') ?? true;
        _countdownDuration = prefs.getInt('shake_countdown_duration') ?? 10;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  Future<void> _toggleShakeDetection(bool value) async {
    setState(() => _shakeEnabled = value);
    await _saveSetting('shake_enabled', value);

    if (value) {
      await _shakeService.enable();
      if (mounted) {
        _showShakeEnabledDialog();
      }
    } else {
      await _shakeService.disable();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shake detection disabled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showShakeEnabledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            const Icon(Icons.vibration, color: Colors.blue, size: 28),
            const SizedBox(width: 12),
            Text(
              'Shake Detection Enabled',
              style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shake-to-Alert is now active!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How it works:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoBullet('Shake your phone $_shakeCount times firmly'),
            _buildInfoBullet('Must be within ${_shakeTimeWindow}ms'),
            if (_countdownEnabled)
              _buildInfoBullet('$_countdownDuration-second countdown to cancel'),
            _buildInfoBullet('Works even when screen is off'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Try it now! Shake your phone to test.',
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

  Widget _buildInfoBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.blue),
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

  String _getSensitivityLabel() {
    if (_shakeSensitivity < 2.0) return 'Very Low';
    if (_shakeSensitivity < 2.5) return 'Low';
    if (_shakeSensitivity < 3.0) return 'Medium';
    if (_shakeSensitivity < 3.5) return 'High';
    return 'Very High';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shake-to-Alert')),
        body: Center(
          child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🤳 Shake-to-Alert'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _shakeEnabled
                  ? Colors.green.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _shakeEnabled ? Colors.green : Colors.grey,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _shakeEnabled ? Icons.check_circle : Icons.cancel,
                  color: _shakeEnabled ? Colors.green : Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _shakeEnabled ? 'ACTIVE' : 'OFF',
                  style: TextStyle(
                    color: _shakeEnabled ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
// Enable/Disable Card
          Card(
            elevation: 4,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    Icons.vibration,
                    color: _shakeEnabled ? Colors.blue : Colors.grey,
                    size: 32,
                  ),
                  title: Text(
                    'Enable Shake Detection',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    _shakeEnabled
                        ? 'Shake your phone to activate panic mode'
                        : 'Tap to enable shake detection',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 13,
                    ),
                  ),
                  value: _shakeEnabled,
                  thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(WidgetState.selected)) return Colors.blue;
                    return null;
                  }),
                  onChanged: (value) async {
                    await _vibrationService.light();
                    await _toggleShakeDetection(value);
                  },
                ),

                if (_shakeEnabled) ...[
                  const Divider(height: 1),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: isDark ? Colors.blue[300] : Colors.blue[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Shake detection works even when your screen is off or the app is in the background.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.blue[200] : Colors.blue[900],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (_shakeEnabled) ...[
            const SizedBox(height: 32),

// Sensitivity Section
            _buildSectionHeader('DETECTION SENSITIVITY'),
            const SizedBox(height: 8),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sensitivity',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue),
                          ),
                          child: Text(
                            _getSensitivityLabel(),
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Less Sensitive',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        Text(
                          _shakeSensitivity.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          'More Sensitive',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _shakeSensitivity,
                      min: 1.5,
                      max: 4.0,
                      divisions: 25,
                      activeColor: Colors.blue,
                      onChanged: (value) {
                        setState(() => _shakeSensitivity = value);
                      },
                      onChangeEnd: (value) async {
                        await _vibrationService.light();
                        await _saveSetting('shake_sensitivity', value);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lower values require stronger shakes. Higher values are more sensitive but may trigger accidentally.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

// Shake Count
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Number of Shakes Required',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildShakeCountOption(2),
                        _buildShakeCountOption(3),
                        _buildShakeCountOption(4),
                        _buildShakeCountOption(5),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Currently set to $_shakeCount shakes. More shakes = less accidental triggers.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

// Time Window
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detection Time Window',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Shakes must occur within ${_shakeTimeWindow}ms',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Slider(
                      value: _shakeTimeWindow.toDouble(),
                      min: 300,
                      max: 1000,
                      divisions: 14,
                      activeColor: Colors.blue,
                      label: '${_shakeTimeWindow}ms',
                      onChanged: (value) {
                        setState(() => _shakeTimeWindow = value.toInt());
                      },
                      onChangeEnd: (value) async {
                        await _vibrationService.light();
                        await _saveSetting('shake_time_window', value.toInt());
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

// Feedback Section
            _buildSectionHeader('FEEDBACK'),
            const SizedBox(height: 8),

            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.vibration, color: Colors.orange),
                title: const Text('Vibration Feedback'),
                subtitle: const Text('Vibrate when shake is detected'),
                value: _vibrationFeedback,
                onChanged: (value) async {
                  if (value) await _vibrationService.medium();
                  setState(() => _vibrationFeedback = value);
                  await _saveSetting('shake_vibration_feedback', value);
                },
              ),
            ),

            const SizedBox(height: 32),

// Countdown Section
            _buildSectionHeader('SAFETY COUNTDOWN'),
            const SizedBox(height: 8),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.timer, color: Colors.green),
                    title: const Text('Enable Countdown'),
                    subtitle: const Text('Time to cancel before alert sent'),
                    value: _countdownEnabled,
                    onChanged: (value) async {
                      await _vibrationService.light();
                      setState(() => _countdownEnabled = value);
                      await _saveSetting('shake_countdown_enabled', value);
                    },
                  ),
                  if (_countdownEnabled) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Countdown Duration: $_countdownDuration seconds',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Slider(
                            value: _countdownDuration.toDouble(),
                            min: 3,
                            max: 30,
                            divisions: 27,
                            activeColor: Colors.green,
                            label: '$_countdownDuration sec',
                            onChanged: (value) {
                              setState(() => _countdownDuration = value.toInt());
                            },
                            onChangeEnd: (value) async {
                              await _vibrationService.light();
                              await _saveSetting('shake_countdown_duration', value.toInt());
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

// Test Button
            ElevatedButton.icon(
              onPressed: () async {
                await _vibrationService.medium();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Shake your phone $_shakeCount times within ${_shakeTimeWindow}ms to test!',
                      ),
                      backgroundColor: Colors.blue,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text(
                'Test Shake Detection',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 16),

// Info Card
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
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tips for Best Results',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.blue[200] : Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTip('Shake firmly but not violently'),
                  _buildTip('Keep phone in hand or pocket'),
                  _buildTip('Works best with medium sensitivity'),
                  _buildTip('Test before relying on in emergency'),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildShakeCountOption(int count) {
    final isSelected = _shakeCount == count;
    return GestureDetector(
      onTap: () async {
        await _vibrationService.light();
        setState(() => _shakeCount = count);
        await _saveSetting('shake_count', count);
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              'shakes',
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.blue)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}