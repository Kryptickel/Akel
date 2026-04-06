import 'package:flutter/material.dart';
import '../services/sos_button_service.dart';
import '../services/vibration_service.dart';

class SosSettingsScreen extends StatefulWidget {
  const SosSettingsScreen({super.key});

  @override
  State<SosSettingsScreen> createState() => _SosSettingsScreenState();
}

class _SosSettingsScreenState extends State<SosSettingsScreen> {
  final SosButtonService _sosButtonService = SosButtonService();
  final VibrationService _vibrationService = VibrationService();

  bool _isVisible = true;
  String _position = 'right';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final visible = await _sosButtonService.isSosButtonVisible();
    final position = await _sosButtonService.getSosButtonPosition();

    if (mounted) {
      setState(() {
        _isVisible = visible;
        _position = position;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleVisibility(bool value) async {
    await _vibrationService.light();
    await _sosButtonService.setSosButtonVisible(value);
    setState(() => _isVisible = value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? ' SOS button enabled' : ' SOS button hidden'),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _changePosition(String position) async {
    await _vibrationService.light();
    await _sosButtonService.setSosButtonPosition(position);
    setState(() => _position = position);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(' SOS button position: $position'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('SOS Button'),
          backgroundColor: Colors.transparent,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Button Settings'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red,
                  Colors.red.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.white,
                          size: 36,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'SOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Quick-Access Emergency Button',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Always available for instant emergency alerts',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Preview Card
          _buildSectionHeader('BUTTON PREVIEW'),
          const SizedBox(height: 12),

          Container(
            height: 200,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[900]
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.grey[800]!
                    : Colors.grey[300]!,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone_android,
                        size: 80,
                        color: isDark
                            ? Colors.grey[700]
                            : Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your Screen',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? Colors.grey[600]
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isVisible)
                  Positioned(
                    bottom: 16,
                    left: _position == 'left' ? 16 : null,
                    right: _position == 'right' ? 16 : null,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Colors.red, Color(0xFFB71C1C)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning, color: Colors.white, size: 24),
                            Text(
                              'SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Visibility Toggle
          _buildSectionHeader('BUTTON VISIBILITY'),
          const SizedBox(height: 12),

          Card(
            child: SwitchListTile(
              secondary: Icon(
                _isVisible ? Icons.visibility : Icons.visibility_off,
                color: _isVisible ? Colors.green : Colors.grey,
              ),
              title: Text(
                'Show SOS Button',
                style: TextStyle(
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                _isVisible
                    ? 'SOS button is visible on all screens'
                    : 'SOS button is hidden',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              value: _isVisible,
              thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.green;
                }
                return null;
              }),
              onChanged: _toggleVisibility,
            ),
          ),

          const SizedBox(height: 24),

          // Position Selection
          _buildSectionHeader('BUTTON POSITION'),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text(
                    'Right Side',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Default position (bottom-right corner)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  value: 'right',
                  groupValue: _position,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: _isVisible
                      ? (value) => _changePosition(value!)
                      : null,
                  secondary: Icon(
                    Icons.arrow_forward,
                    color: _position == 'right'
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                ),
                RadioListTile<String>(
                  title: Text(
                    'Left Side',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Alternative position (bottom-left corner)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  value: 'left',
                  groupValue: _position,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: _isVisible
                      ? (value) => _changePosition(value!)
                      : null,
                  secondary: Icon(
                    Icons.arrow_back,
                    color: _position == 'left'
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Features Info Card
          _buildSectionHeader('FEATURES'),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'SOS Button Features',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).textTheme.headlineMedium?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFeatureBullet(' ', 'Instant panic alert (no countdown)'),
                _buildFeatureBullet(' ', 'Pulsing red button for visibility'),
                _buildFeatureBullet(' ', 'Available on all screens'),
                _buildFeatureBullet(' ', 'One-tap emergency activation'),
                _buildFeatureBullet(' ', 'Always accessible for quick response'),
                _buildFeatureBullet(' ', 'Silent alert option'),
                _buildFeatureBullet(' ', 'Usage statistics tracking'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Usage Instructions Card
          _buildSectionHeader('HOW TO USE'),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Usage Instructions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).textTheme.headlineMedium?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInstructionStep(
                  '1',
                  'Tap the red SOS button',
                  'The button appears in the bottom corner of your screen',
                ),
                const SizedBox(height: 12),
                _buildInstructionStep(
                  '2',
                  'Instant alert sent',
                  'Emergency alert is immediately sent to your contacts',
                ),
                const SizedBox(height: 12),
                _buildInstructionStep(
                  '3',
                  'No countdown delay',
                  'Unlike the main panic button, SOS sends instantly',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Important Notice Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Important Notice',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).textTheme.headlineMedium?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  ' The SOS button sends alerts INSTANTLY without a countdown timer.\n\n'
                      ' Only use in genuine emergency situations.\n\n'
                      ' Your emergency contacts will be notified immediately.\n\n'
                      ' Location and alert details will be shared automatically.',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Statistics Card (if usage data exists)
          FutureBuilder<int>(
            future: _sosButtonService.getSosCount(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data! > 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('USAGE STATISTICS'),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.analytics,
                                    color: Colors.blue,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total SOS Alerts',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${snapshot.data} times',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).textTheme.headlineMedium?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            FutureBuilder<DateTime?>(
                              future: _sosButtonService.getLastSosTime(),
                              builder: (context, timeSnapshot) {
                                if (timeSnapshot.hasData && timeSnapshot.data != null) {
                                  final lastUsed = timeSnapshot.data!;
                                  final timeAgo = _formatDateTime(lastUsed);

                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.grey[800]
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.schedule,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Last used: $timeAgo',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).textTheme.bodySmall?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Comparison Card
          _buildSectionHeader('SOS VS MAIN PANIC BUTTON'),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feature Comparison',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildComparisonRow(
                    'Activation Speed',
                    'Instant',
                    '10-second countdown',
                  ),
                  const Divider(height: 24),
                  _buildComparisonRow(
                    'Availability',
                    'All screens',
                    'Home screen only',
                  ),
                  const Divider(height: 24),
                  _buildComparisonRow(
                    'Button Size',
                    'Small floating',
                    'Large center button',
                  ),
                  const Divider(height: 24),
                  _buildComparisonRow(
                    'Cancelable',
                    'No',
                    'Yes (10 seconds)',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
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

  Widget _buildFeatureBullet(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonRow(String feature, String sosValue, String mainValue) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            feature,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: Theme.of(context).textTheme.headlineMedium?.color,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SOS',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sosValue,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Main',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                mainValue,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}