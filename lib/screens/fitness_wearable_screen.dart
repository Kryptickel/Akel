import 'package:flutter/material.dart';
import '../services/fitness_wearable_service.dart';
import 'package:intl/intl.dart';

class FitnessWearableScreen extends StatefulWidget {
  const FitnessWearableScreen({super.key});

  @override
  State<FitnessWearableScreen> createState() => _FitnessWearableScreenState();
}

class _FitnessWearableScreenState extends State<FitnessWearableScreen> {
  final FitnessWearableService _fitnessService = FitnessWearableService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _fitnessService.initialize();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E27),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
        ),
      );
    }

    final devices = _fitnessService.getDevices();
    final primaryDevice = _fitnessService.getPrimaryDevice();
    final stats = _fitnessService.getStatistics();
    final todayActivity = _fitnessService.getTodayActivity();
    final alerts = _fitnessService.getAlerts();
    final hrHistory = _fitnessService.getHeartRateHistory(hours: 24);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Fitness Wearables'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => _showSettings(),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fitnessService.syncWithDevice();
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Current Heart Rate Card
            _buildHeartRateCard(stats['currentHeartRate']),

            const SizedBox(height: 16),

            // Today's Activity Card
            if (todayActivity != null) _buildActivityCard(todayActivity),

            const SizedBox(height: 16),

            // Statistics Overview
            _buildStatisticsCard(stats),

            const SizedBox(height: 16),

            // Heart Rate Alerts
            if (alerts.isNotEmpty) ...[
              _buildSectionHeader('Heart Rate Alerts', Icons.warning),
              const SizedBox(height: 12),
              ...alerts.reversed.take(3).map((alert) => _buildAlertCard(alert)),
              const SizedBox(height: 16),
            ],

            // Connected Devices
            if (devices.isNotEmpty) ...[
              _buildSectionHeader('Connected Devices', Icons.fitness_center),
              const SizedBox(height: 12),
              ...devices.map((device) => _buildDeviceCard(device)),
              const SizedBox(height: 16),
            ],

            // Heart Rate Chart
            if (hrHistory.isNotEmpty) ...[
              _buildSectionHeader('Heart Rate History (24h)', Icons.show_chart),
              const SizedBox(height: 12),
              _buildHeartRateChart(hrHistory),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _connectNewDevice(),
        backgroundColor: const Color(0xFF00BFA5),
        icon: const Icon(Icons.add),
        label: const Text('Connect Device'),
      ),
    );
  }

  Widget _buildHeartRateCard(int currentHR) {
    Color hrColor;
    String hrStatus;

    if (currentHR < 60) {
      hrColor = Colors.blue;
      hrStatus = 'Low';
    } else if (currentHR < 100) {
      hrColor = Colors.green;
      hrStatus = 'Normal';
    } else if (currentHR < 140) {
      hrColor = Colors.orange;
      hrStatus = 'Elevated';
    } else {
      hrColor = Colors.red;
      hrStatus = 'High';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [hrColor.withValues(alpha: 0.3), hrColor.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hrColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: hrColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite, color: hrColor, size: 32),
              const SizedBox(width: 12),
              const Text(
                'Heart Rate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currentHR',
                style: TextStyle(
                  color: hrColor,
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'BPM',
                  style: TextStyle(
                    color: hrColor.withValues(alpha: 0.8),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: hrColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              hrStatus.toUpperCase(),
              style: TextStyle(
                color: hrColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(ActivityData activity) {
    final stepProgress = activity.steps / _fitnessService.getDailyStepGoal();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_walk, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Today\'s Activity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActivityStat(
                  '${activity.steps}',
                  'Steps',
                  Icons.directions_walk,
                ),
              ),
              Expanded(
                child: _buildActivityStat(
                  '${activity.distance.toStringAsFixed(1)} km',
                  'Distance',
                  Icons.straighten,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActivityStat(
                  '${activity.caloriesBurned}',
                  'Calories',
                  Icons.local_fire_department,
                ),
              ),
              Expanded(
                child: _buildActivityStat(
                  '${activity.activeMinutes} min',
                  'Active',
                  Icons.timer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daily Goal',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${(stepProgress * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: stepProgress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
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

  Widget _buildStatisticsCard(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Avg HR',
                '${stats['averageHeartRate']} BPM',
                Icons.favorite,
                Colors.red,
              ),
              _buildStatItem(
                'Devices',
                '${stats['connectedDevices']}',
                Icons.watch,
                const Color(0xFF00BFA5),
              ),
              _buildStatItem(
                'Alerts',
                '${stats['totalAlerts']}',
                Icons.warning,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
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

  Widget _buildAlertCard(HeartRateAlert alert) {
    Color alertColor;
    IconData alertIcon;

    switch (alert.alertType) {
      case 'high':
        alertColor = Colors.red;
        alertIcon = Icons.arrow_upward;
        break;
      case 'low':
        alertColor = Colors.blue;
        alertIcon = Icons.arrow_downward;
        break;
      default:
        alertColor = Colors.orange;
        alertIcon = Icons.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alertColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: alertColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(alertIcon, color: alertColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${alert.alertType.toUpperCase()} Heart Rate',
                  style: TextStyle(
                    color: alertColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${alert.bpm} BPM',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('MMM d, h:mm a').format(alert.timestamp),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (alert.emergencyContacted)
            const Icon(Icons.phone, color: Color(0xFF00BFA5), size: 20),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(FitnessDevice device) {
    final brandColor = _fitnessService.getBrandColor(device.brand);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _fitnessService.getBrandIcon(device.brand),
              color: brandColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  device.brand.name.toUpperCase(),
                  style: TextStyle(
                    color: brandColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.battery_full,
                      color: _getBatteryColor(device.batteryLevel),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${device.batteryLevel}%',
                      style: TextStyle(
                        color: _getBatteryColor(device.batteryLevel),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _disconnectDevice(device.id),
            icon: const Icon(Icons.close, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateChart(List<HeartRateReading> readings) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: HeartRateChartPainter(readings),
              child: Container(),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '24h ago',
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
              Text(
                'Now',
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00BFA5), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getBatteryColor(int level) {
    if (level > 50) return Colors.green;
    if (level > 20) return Colors.orange;
    return Colors.red;
  }

  void _connectNewDevice() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(
          'Connect Fitness Device',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBrandButton(FitnessBrand.fitbit, 'Fitbit'),
            const SizedBox(height: 12),
            _buildBrandButton(FitnessBrand.garmin, 'Garmin'),
            const SizedBox(height: 12),
            _buildBrandButton(FitnessBrand.whoop, 'Whoop'),
            const SizedBox(height: 12),
            _buildBrandButton(FitnessBrand.polar, 'Polar'),
            const SizedBox(height: 12),
            _buildBrandButton(FitnessBrand.suunto, 'Suunto'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandButton(FitnessBrand brand, String name) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          await _fitnessService.connectDevice(brand);
          if (mounted) {
            Navigator.pop(context);
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(' $name connected'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        icon: Icon(_fitnessService.getBrandIcon(brand)),
        label: Text(name),
        style: ElevatedButton.styleFrom(
          backgroundColor: _fitnessService.getBrandColor(brand),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _disconnectDevice(String deviceId) async {
    await _fitnessService.disconnectDevice(deviceId);
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(' Device disconnected')),
      );
    }
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(
          'Fitness Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text(
                  'Heart Rate Monitoring',
                  style: TextStyle(color: Colors.white),
                ),
                value: _fitnessService.isHeartRateMonitoringEnabled(),
                onChanged: (value) {
                  _fitnessService.updateSettings(heartRateMonitoring: value);
                  setState(() {});
                },
                activeColor: const Color(0xFF00BFA5),
              ),
              SwitchListTile(
                title: const Text(
                  'Activity Tracking',
                  style: TextStyle(color: Colors.white),
                ),
                value: _fitnessService.isActivityTrackingEnabled(),
                onChanged: (value) {
                  _fitnessService.updateSettings(activityTracking: value);
                  setState(() {});
                },
                activeColor: const Color(0xFF00BFA5),
              ),
              const Divider(color: Colors.white12),
              ListTile(
                title: const Text(
                  'High HR Threshold',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${_fitnessService.getHighHeartRateThreshold()} BPM',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF00BFA5)),
                  onPressed: () => _editThreshold('high'),
                ),
              ),
              ListTile(
                title: const Text(
                  'Low HR Threshold',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${_fitnessService.getLowHeartRateThreshold()} BPM',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF00BFA5)),
                  onPressed: () => _editThreshold('low'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editThreshold(String type) {
    // Would open threshold editor
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit $type threshold')),
    );
  }
}

// Custom painter for heart rate chart
class HeartRateChartPainter extends CustomPainter {
  final List<HeartRateReading> readings;

  HeartRateChartPainter(this.readings);

  @override
  void paint(Canvas canvas, Size size) {
    if (readings.isEmpty) return;

    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final maxHR = readings.map((r) => r.bpm).reduce((a, b) => a > b ? a : b);
    final minHR = readings.map((r) => r.bpm).reduce((a, b) => a < b ? a : b);

    for (int i = 0; i < readings.length; i++) {
      final x = (i / (readings.length - 1)) * size.width;
      final normalizedHR = (readings[i].bpm - minHR) / (maxHR - minHR);
      final y = size.height - (normalizedHR * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}