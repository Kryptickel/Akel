import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/weather_alerts_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';
import 'package:intl/intl.dart';

class WeatherAlertsScreen extends StatefulWidget {
  const WeatherAlertsScreen({super.key});

  @override
  State<WeatherAlertsScreen> createState() => _WeatherAlertsScreenState();
}

class _WeatherAlertsScreenState extends State<WeatherAlertsScreen> {
  final WeatherAlertService _weatherService = WeatherAlertService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();

  List<Map<String, dynamic>> _activeAlerts = [];
  List<Map<String, dynamic>> _alertHistory = [];
  bool _isLoadingActive = true;
  bool _isLoadingHistory = false;
  bool _isMonitoringEnabled = false;
  int _selectedTab = 0; // 0 = Active, 1 = History

  @override
  void initState() {
    super.initState();
    _loadAlerts();
    _checkMonitoringStatus();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoadingActive = true);

    try {
      final activeAlerts = await _weatherService.getActiveAlerts();

      if (mounted) {
        setState(() {
          _activeAlerts = activeAlerts;
          _isLoadingActive = false;
        });
      }
    } catch (e) {
      debugPrint(' Load alerts error: $e');
      if (mounted) {
        setState(() => _isLoadingActive = false);
      }
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);

    try {
      final history = await _weatherService.getAlertHistory(limit: 50);

      if (mounted) {
        setState(() {
          _alertHistory = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint(' Load history error: $e');
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _checkMonitoringStatus() async {
    final enabled = await _weatherService.isMonitoringEnabled();
    if (mounted) {
      setState(() {
        _isMonitoringEnabled = enabled;
      });
    }
  }

  Future<void> _toggleMonitoring(bool value) async {
    await _vibrationService.light();

    try {
      await _weatherService.setMonitoringEnabled(value);

      if (mounted) {
        setState(() {
          _isMonitoringEnabled = value;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? ' Weather monitoring enabled'
                  : ' Weather monitoring disabled',
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

  Future<void> _dismissAlert(String alertId) async {
    await _vibrationService.light();

    try {
      await _weatherService.dismissAlert(alertId);

      if (mounted) {
        await _soundService.playSuccess();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' Alert dismissed'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        _loadAlerts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAlertDetails(Map<String, dynamic> alert) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2740),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _buildAlertDetailsSheet(
          alert,
          scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Weather Alerts'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _selectedTab == 0 ? _loadAlerts : _loadHistory,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('Active', 0, _activeAlerts.length),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTabButton('History', 1, null),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Monitoring Toggle
          Container(
            margin: const EdgeInsets.all(16),
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
                    color: _isMonitoringEnabled
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud,
                    color: _isMonitoringEnabled ? Colors.green : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weather Monitoring',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Get real-time severe weather alerts',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isMonitoringEnabled,
                  onChanged: _toggleMonitoring,
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _selectedTab == 0 ? _buildActiveTab() : _buildHistoryTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, int? count) {
    final isSelected = _selectedTab == index;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedTab = index;
        });
        if (index == 1 && _alertHistory.isEmpty) {
          _loadHistory();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? const Color(0xFF00BFA5)
            : const Color(0xFF1E2740),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (count != null && count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? const Color(0xFF00BFA5) : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    if (_isLoadingActive) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
      );
    }

    if (_activeAlerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wb_sunny,
              size: 80,
              color: Colors.yellow[600],
            ),
            const SizedBox(height: 24),
            Text(
              'All Clear!',
              style: TextStyle(
                color: Colors.yellow[600],
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No active weather alerts in your area',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _activeAlerts.length,
      itemBuilder: (context, index) {
        final alert = _activeAlerts[index];
        return _buildAlertCard(alert, isActive: true);
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
      );
    }

    if (_alertHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 24),
            Text(
              'No Alert History',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Past weather alerts will appear here',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _alertHistory.length,
      itemBuilder: (context, index) {
        final alert = _alertHistory[index];
        return _buildAlertCard(alert, isActive: false);
      },
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert, {required bool isActive}) {
    final type = alert['type'] as String;
    final severity = alert['severity'] as String;
    final typeData = WeatherAlertService.getAlertTypeData(type);
    final severityColor = WeatherAlertService.getSeverityColor(severity);
    final severityIcon = WeatherAlertService.getSeverityIcon(severity);

    return Card(
      color: const Color(0xFF1E2740),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAlertDetails(alert),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    typeData['icon'] as String,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert['headline'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(severityIcon, size: 14, color: severityColor),
                            const SizedBox(width: 4),
                            Text(
                              alert['area'] as String,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: severityColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time, size: 12, color: severityColor),
                          const SizedBox(width: 4),
                          Text(
                            WeatherAlertService.formatTimeRemaining(
                              alert['expiresTime'] as String,
                            ),
                            style: TextStyle(
                              color: severityColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alert['description'] as String,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isActive) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showAlertDetails(alert),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00BFA5),
                          side: const BorderSide(color: Color(0xFF00BFA5)),
                        ),
                        child: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _dismissAlert(alert['id']),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text('Dismiss'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertDetailsSheet(
      Map<String, dynamic> alert,
      ScrollController scrollController,
      ) {
    final type = alert['type'] as String;
    final severity = alert['severity'] as String;
    final typeData = WeatherAlertService.getAlertTypeData(type);
    final severityData = WeatherAlertService.getSeverityLevelData(severity);
    final severityColor = Color(severityData['color'] as int);

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Alert Header
          Row(
            children: [
              Text(
                typeData['icon'] as String,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: severityColor),
                      ),
                      child: Text(
                        severityData['name'] as String,
                        style: TextStyle(
                          color: severityColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      typeData['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 24),

          // Description
          const Text(
            'DESCRIPTION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00BFA5),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            alert['description'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Safety Tips
          const Text(
            'SAFETY TIPS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00BFA5),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          ...(typeData['safetyTips'] as List<String>).map((tip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: severityColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Time Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Expires: ',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      WeatherAlertService.formatTimeRemaining(
                        alert['expiresTime'] as String,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}