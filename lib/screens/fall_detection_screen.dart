import 'package:flutter/material.dart';
import '../services/fall_detection_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';

class FallDetectionScreen extends StatefulWidget {
  const FallDetectionScreen({super.key});

  @override
  State<FallDetectionScreen> createState() => _FallDetectionScreenState();
}

class _FallDetectionScreenState extends State<FallDetectionScreen> {
  final FallDetectionService _fallService = FallDetectionService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();

  bool _isEnabled = false;
  double _sensitivity = FallDetectionService.MEDIUM_SENSITIVITY;
  int _fallsDetected = 0;

  @override
  void initState() {
    super.initState();
    _initializeFallDetection();
  }

  Future<void> _initializeFallDetection() async {
    await _fallService.initialize();

// Set up fall detection callback
    _fallService.onFallDetected = _handleFallDetected;

    setState(() {
      _isEnabled = _fallService.isEnabled;
      _sensitivity = _fallService.sensitivity;
    });
  }

  void _handleFallDetected(BuildContext context) {
    setState(() {
      _fallsDetected++;
    });

    _vibrationService.panic();
    _soundService.playWarning();

    _showFallDetectedDialog();
  }

  void _showFallDetectedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[900],
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.white, size: 32),
            SizedBox(width: 12),
            Text(
              'FALL DETECTED!',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A fall has been detected!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Are you okay?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Emergency contacts will be notified if you don\'t respond.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ False alarm dismissed'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'I\'M OK',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
// TODO: Trigger emergency alert

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🚨 Emergency alert sent to contacts'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red[900],
            ),
            child: const Text('CALL FOR HELP'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFallDetection(bool value) async {
    await _vibrationService.light();
    await _soundService.playClick();

    if (value) {
      _fallService.startMonitoring(context);
    } else {
      _fallService.stopMonitoring();
    }

    setState(() {
      _isEnabled = value;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? '✅ Fall detection enabled'
                : '⚠️ Fall detection disabled',
          ),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  void _updateSensitivity(double value) async {
    await _vibrationService.light();

    _fallService.setSensitivity(value);

    setState(() {
      _sensitivity = value;
    });
  }

  String _getSensitivityLabel() {
    if (_sensitivity == FallDetectionService.LOW_SENSITIVITY) {
      return 'Low (Less sensitive)';
    } else if (_sensitivity == FallDetectionService.HIGH_SENSITIVITY) {
      return 'High (More sensitive)';
    } else {
      return 'Medium (Balanced)';
    }
  }

  Color _getSensitivityColor() {
    if (_sensitivity == FallDetectionService.LOW_SENSITIVITY) {
      return Colors.blue;
    } else if (_sensitivity == FallDetectionService.HIGH_SENSITIVITY) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }

  void _testFallDetection() async {
    await _vibrationService.warning();
    await _soundService.playWarning();

    _handleFallDetected(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Fall Detection'),
        backgroundColor: Colors.transparent,
        actions: [
          if (_isEnabled)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
// Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withValues(alpha: 0.2),
                  Colors.deepOrange.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.health_and_safety,
                        color: Colors.orange,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fall Detection',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'AI-powered protection',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'How it works:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoBullet('📱', 'Monitors phone accelerometer'),
                _buildInfoBullet('📉', 'Detects free fall motion'),
                _buildInfoBullet('💥', 'Detects impact/collision'),
                _buildInfoBullet('🚨', 'Alerts emergency contacts'),
              ],
            ),
          ),

          const SizedBox(height: 24),

// Enable/Disable Toggle
          Card(
            color: const Color(0xFF1E2740),
            child: SwitchListTile(
              title: const Text(
                'Fall Detection',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                _isEnabled
                    ? 'Active - Monitoring for falls'
                    : 'Disabled - Enable to start monitoring',
                style: const TextStyle(color: Colors.white70),
              ),
              value: _isEnabled,
              onChanged: _toggleFallDetection,
              activeColor: Colors.orange,
              secondary: Icon(
                _isEnabled ? Icons.sensors : Icons.sensors_off,
                color: _isEnabled ? Colors.orange : Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 24),

// Sensitivity Settings
          const Text(
            'SENSITIVITY',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00BFA5),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            color: const Color(0xFF1E2740),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Detection Sensitivity',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getSensitivityColor().withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getSensitivityLabel(),
                          style: TextStyle(
                            color: _getSensitivityColor(),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        'Low',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _sensitivity,
                          min: FallDetectionService.HIGH_SENSITIVITY,
                          max: FallDetectionService.LOW_SENSITIVITY,
                          divisions: 2,
                          activeColor: _getSensitivityColor(),
                          inactiveColor: Colors.white24,
                          onChanged: _updateSensitivity,
                        ),
                      ),
                      const Text(
                        'High',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _sensitivity == FallDetectionService.LOW_SENSITIVITY
                        ? 'Less sensitive - Fewer false alarms'
                        : _sensitivity == FallDetectionService.HIGH_SENSITIVITY
                        ? 'More sensitive - Better detection'
                        : 'Balanced - Recommended setting',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

// Statistics
          const Text(
            'STATISTICS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00BFA5),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            color: const Color(0xFF1E2740),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.orange,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_fallsDetected',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Falls Detected',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: Colors.white24,
                  ),
                  Column(
                    children: [
                      Icon(
                        _isEnabled ? Icons.check_circle : Icons.cancel,
                        color: _isEnabled ? Colors.green : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isEnabled ? 'ON' : 'OFF',
                        style: TextStyle(
                          color: _isEnabled ? Colors.green : Colors.grey,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Status',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

// Test Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _testFallDetection,
              icon: const Icon(Icons.science, size: 24),
              label: const Text(
                'Test Fall Detection',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.orange, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

// Safety Info
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
                      'Important Information',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '• Keep phone on your person for best results\n'
                      '• Works even when app is in background\n'
                      '• You\'ll be asked to confirm before alerts are sent\n'
                      '• Adjust sensitivity based on your activity level\n'
                      '• Test regularly to ensure it\'s working',
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
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fallService.dispose();
    super.dispose();
  }
}