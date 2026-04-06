import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/power_management_service.dart';
import '../services/vibration_service.dart';

class PowerManagementScreen extends StatefulWidget {
  const PowerManagementScreen({super.key});

  @override
  State<PowerManagementScreen> createState() => _PowerManagementScreenState();
}

class _PowerManagementScreenState extends State<PowerManagementScreen> {
  final PowerManagementService _powerService = PowerManagementService();
  final VibrationService _vibrationService = VibrationService();

  PowerMode? _currentMode;
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  bool _autoLowPower = false;
  int _lowPowerThreshold = 30;
  int _ultraLowPowerThreshold = 15;
  int _emergencyReserveThreshold = 5;

  @override
  void initState() {
    super.initState();
    _loadPowerMode();
    _loadStatistics();
    _loadSettings();
  }

  Future<void> _loadPowerMode() async {
    setState(() => _isLoading = true);

    try {
      final mode = await _powerService.getCurrentPowerMode();

      if (mounted) {
        setState(() {
          _currentMode = mode;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(' Load power mode error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStatistics() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        final stats = await _powerService.getBatteryStatistics(userId);

        if (mounted) {
          setState(() {
            _statistics = stats;
          });
        }
      } catch (e) {
        debugPrint(' Load statistics error: $e');
      }
    }
  }

  Future<void> _loadSettings() async {
    // Load auto power saving settings from SharedPreferences
    // For now, using default values
    setState(() {
      _autoLowPower = false;
      _lowPowerThreshold = 30;
      _ultraLowPowerThreshold = 15;
      _emergencyReserveThreshold = 5;
    });
  }

  Future<void> _selectPowerMode(PowerMode mode) async {
    await _vibrationService.light();

    final success = await _powerService.setPowerMode(mode);

    if (success && mounted) {
      await _vibrationService.success();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${PowerManagementService.getPowerModeIcon(mode)} ${PowerManagementService.getPowerModeLabel(mode)} activated',
          ),
          backgroundColor: Colors.green,
        ),
      );

      _loadPowerMode();
      _loadStatistics();
    }
  }

  Future<void> _toggleAutoLowPower(bool value) async {
    await _vibrationService.light();

    final success = await _powerService.setAutoLowPower(
      enabled: value,
      lowPowerThreshold: _lowPowerThreshold,
      ultraLowPowerThreshold: _ultraLowPowerThreshold,
      emergencyReserveThreshold: _emergencyReserveThreshold,
    );

    if (success && mounted) {
      setState(() {
        _autoLowPower = value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? ' Auto power saving enabled' : ' Auto power saving disabled'),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Power Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _vibrationService.light();
              _loadPowerMode();
              _loadStatistics();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Statistics Card
          if (_statistics != null && _statistics!.isNotEmpty) _buildStatisticsCard(),

          const SizedBox(height: 24),

          // Current Mode Card
          if (_currentMode != null) _buildCurrentModeCard(),

          const SizedBox(height: 24),

          // Auto Power Saving
          _buildAutoLowPowerCard(),

          const SizedBox(height: 24),

          // Power Modes
          _buildSectionHeader('Power Modes'),
          _buildPowerModeCard(PowerMode.normal),
          _buildPowerModeCard(PowerMode.lowPower),
          _buildPowerModeCard(PowerMode.ultraLowPower),
          _buildPowerModeCard(PowerMode.emergencyReserve),

          const SizedBox(height: 24),

          // Power Saving Tips
          if (_statistics != null && _statistics!.isNotEmpty) _buildPowerSavingTips(),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final currentLevel = (_statistics!['currentLevel'] as int?) ?? 0;
    final isCharging = (_statistics!['isCharging'] as bool?) ?? false;
    final avgLevel = (_statistics!['averageLevel24h'] as int?) ?? 0;
    final health = (_statistics!['batteryHealth'] as String?) ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green,
            Colors.green.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Current', '$currentLevel%', Icons.battery_full),
              _buildStatItem('Avg 24h', '$avgLevel%', Icons.analytics),
              _buildStatItem('Health', health, Icons.favorite),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCharging ? Icons.charging_station : Icons.battery_std,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isCharging ? 'Charging' : 'Not Charging',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentModeCard() {
    final color = _hexToColor(PowerManagementService.getPowerModeColor(_currentMode!));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                PowerManagementService.getPowerModeIcon(_currentMode!),
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Mode',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  PowerManagementService.getPowerModeLabel(_currentMode!),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  PowerManagementService.getPowerModeDescription(_currentMode!),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoLowPowerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Auto Power Saving',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _autoLowPower,
                  onChanged: _toggleAutoLowPower,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Automatically enable power saving modes based on battery level',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (_autoLowPower) ...[
              const SizedBox(height: 16),
              Text(
                'Thresholds:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              _buildThresholdItem('Low Power', _lowPowerThreshold, Colors.orange),
              _buildThresholdItem('Ultra Low Power', _ultraLowPowerThreshold, Colors.red),
              _buildThresholdItem('Emergency Reserve', _emergencyReserveThreshold, Colors.purple),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdItem(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$value%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
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

  Widget _buildPowerModeCard(PowerMode mode) {
    final isSelected = _currentMode == mode;
    final color = _hexToColor(PowerManagementService.getPowerModeColor(mode));
    final features = _powerService.getPowerModeFeatures(mode);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 8 : 4,
      color: isSelected ? color.withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: () => _selectPowerMode(mode),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        PowerManagementService.getPowerModeIcon(mode),
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          PowerManagementService.getPowerModeLabel(mode),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? color : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          PowerManagementService.getPowerModeDescription(mode),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: color,
                      size: 28,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: features.entries.map((entry) {
                  return _buildFeatureChip(entry.key, entry.value);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String feature, bool enabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: enabled
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enabled ? Icons.check : Icons.close,
            size: 14,
            color: enabled ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            _formatFeatureName(feature),
            style: TextStyle(
              fontSize: 11,
              color: enabled ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFeatureName(String feature) {
    return feature
        .replaceAllMapped(
      RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
    )
        .trim();
  }

  Widget _buildPowerSavingTips() {
    final currentLevel = (_statistics!['currentLevel'] as int?) ?? 100;
    final isCharging = (_statistics!['isCharging'] as bool?) ?? false;
    final tips = _powerService.getPowerSavingTips(currentLevel, isCharging);

    if (tips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Power Saving Tips'),
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
              const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Tips to Extend Battery Life',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
  }
}