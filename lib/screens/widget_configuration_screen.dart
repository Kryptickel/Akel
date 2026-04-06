import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../widgets/panic_button_widget_provider.dart';
import '../services/vibration_service.dart';

class WidgetConfigurationScreen extends StatefulWidget {
  const WidgetConfigurationScreen({super.key});

  @override
  State<WidgetConfigurationScreen> createState() => _WidgetConfigurationScreenState();
}

class _WidgetConfigurationScreenState extends State<WidgetConfigurationScreen> {
  final VibrationService _vibrationService = VibrationService();

  bool _isLoading = true;
  bool _widgetAvailable = false;
  bool _showUserName = true;
  bool _showBattery = true;
  bool _showConnectivity = true;
  bool _showActiveFeatures = true;
  String _widgetTheme = 'red';
  String _widgetSize = 'medium';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkWidgetAvailability();
  }

  Future<void> _checkWidgetAvailability() async {
    final available = await PanicButtonWidgetProvider.isWidgetAvailable();
    if (mounted) {
      setState(() {
        _widgetAvailable = available;
      });
    }
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();

    if (mounted) {
      setState(() {
        _showUserName = prefs.getBool('widget_show_username') ?? true;
        _showBattery = prefs.getBool('widget_show_battery') ?? true;
        _showConnectivity = prefs.getBool('widget_show_connectivity') ?? true;
        _showActiveFeatures = prefs.getBool('widget_show_active_features') ?? true;
        _widgetTheme = prefs.getString('widget_theme') ?? 'red';
        _widgetSize = prefs.getString('widget_size') ?? 'medium';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('widget_show_username', _showUserName);
    await prefs.setBool('widget_show_battery', _showBattery);
    await prefs.setBool('widget_show_connectivity', _showConnectivity);
    await prefs.setBool('widget_show_active_features', _showActiveFeatures);
    await prefs.setString('widget_theme', _widgetTheme);
    await prefs.setString('widget_size', _widgetSize);

    await _updateWidget();

    if (mounted) {
      await _vibrationService.success();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Widget settings saved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _updateWidget() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userName = authProvider.userProfile?['name'] ?? 'User';

    await PanicButtonWidgetProvider.updateWidget(
      userName: userName,
      batteryLevel: 85,
      isOnline: true,
      fallDetectionActive: false,
      shakeDetectionActive: false,
      locationTrackingActive: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Configuration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Widget',
            onPressed: () async {
              await _vibrationService.light();
              await _updateWidget();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Widget refreshed'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_widgetAvailable
          ? _buildUnavailableState()
          : _buildConfigurationForm(),
    );
  }

  Widget _buildUnavailableState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.widgets_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Widget Not Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Widgets are only available on mobile devices',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
// Info Card
        _buildInfoCard(),

        const SizedBox(height: 24),

// Display Settings
        _buildSectionHeader('Display Settings'),
        _buildSettingTile(
          title: 'Show User Name',
          subtitle: 'Display your name on the widget',
          value: _showUserName,
          onChanged: (value) => setState(() => _showUserName = value),
        ),
        _buildSettingTile(
          title: 'Show Battery Level',
          subtitle: 'Display battery percentage',
          value: _showBattery,
          onChanged: (value) => setState(() => _showBattery = value),
        ),
        _buildSettingTile(
          title: 'Show Connectivity',
          subtitle: 'Display online/offline status',
          value: _showConnectivity,
          onChanged: (value) => setState(() => _showConnectivity = value),
        ),
        _buildSettingTile(
          title: 'Show Active Features',
          subtitle: 'Display active protection features',
          value: _showActiveFeatures,
          onChanged: (value) => setState(() => _showActiveFeatures = value),
        ),

        const SizedBox(height: 24),

// Theme Settings
        _buildSectionHeader('Widget Theme'),
        _buildThemeSelector(),

        const SizedBox(height: 24),

// Size Settings
        _buildSectionHeader('Widget Size'),
        _buildSizeSelector(),

        const SizedBox(height: 24),

// Widget Preview
        _buildSectionHeader('Widget Preview'),
        _buildWidgetPreview(),

        const SizedBox(height: 24),

// Save Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),

        const SizedBox(height: 16),

// Instructions Card
        _buildInstructionsCard(),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Panic Button Widget',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a panic button to your home screen for instant access.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: (newValue) {
          _vibrationService.light();
          onChanged(newValue);
        },
      ),
    );
  }

  Widget _buildThemeSelector() {
    final themes = {
      'red': {'name': 'Red Alert', 'color': Colors.red},
      'orange': {'name': 'Orange Warning', 'color': Colors.orange},
      'purple': {'name': 'Purple Silent', 'color': Colors.purple},
      'blue': {'name': 'Blue Classic', 'color': Colors.blue},
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: themes.entries.map((entry) {
            return RadioListTile<String>(
              title: Text(entry.value['name'] as String),
              value: entry.key,
              groupValue: _widgetTheme,
              onChanged: (value) {
                _vibrationService.light();
                setState(() => _widgetTheme = value!);
              },
              secondary: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: entry.value['color'] as Color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSizeSelector() {
    final sizes = {
      'small': 'Small (2x2)',
      'medium': 'Medium (4x2)',
      'large': 'Large (4x4)',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sizes.entries.map((entry) {
            return RadioListTile<String>(
              title: Text(entry.value),
              value: entry.key,
              groupValue: _widgetSize,
              onChanged: (value) {
                _vibrationService.light();
                setState(() => _widgetSize = value!);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWidgetPreview() {
    final themeColor = _getThemeColor();

    return Card(
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              themeColor,
              themeColor.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (_showUserName) ...[
              const Text(
                'John Doe',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (_showBattery)
                  _buildPreviewIndicator('85%', Icons.battery_5_bar),
                if (_showConnectivity)
                  _buildPreviewIndicator('Online', Icons.wifi),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.warning_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'PANIC',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            if (_showActiveFeatures) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _buildFeatureChip('Fall Detection'),
                  _buildFeatureChip('Shake Alert'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewIndicator(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      color: Colors.grey.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.help_outline, size: 20),
                SizedBox(width: 8),
                Text(
                  'How to Add Widget',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Android:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              '1. Long-press on home screen\n'
                  '2. Tap "Widgets"\n'
                  '3. Find "AKEL Panic Button"\n'
                  '4. Drag to home screen',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'iOS:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              '1. Long-press on home screen\n'
                  '2. Tap "+" button (top left)\n'
                  '3. Search "AKEL"\n'
                  '4. Select widget size and add',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Color _getThemeColor() {
    switch (_widgetTheme) {
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'blue':
        return Colors.blue;
      default:
        return Colors.red;
    }
  }
}