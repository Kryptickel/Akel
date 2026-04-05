import 'package:flutter/material.dart';
import '../services/advanced_wearables_service.dart';
import 'package:intl/intl.dart';

class AdvancedWearablesScreen extends StatefulWidget {
  const AdvancedWearablesScreen({super.key});

  @override
  State<AdvancedWearablesScreen> createState() =>
      _AdvancedWearablesScreenState();
}

class _AdvancedWearablesScreenState extends State<AdvancedWearablesScreen> {
  final AdvancedWearablesService _wearablesService =
  AdvancedWearablesService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _wearablesService.initialize();
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

    final stats = _wearablesService.getStatistics();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Advanced Health'),
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
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Health Metrics Grid
            _buildHealthMetricsGrid(stats),

            const SizedBox(height: 16),

            // ECG Section
            _buildSectionHeader('ECG Monitoring', Icons.monitor_heart),
            const SizedBox(height: 12),
            _buildECGCard(),

            const SizedBox(height: 16),

            // SpO2 Section
            _buildSectionHeader('Blood Oxygen', Icons.bloodtype),
            const SizedBox(height: 12),
            _buildSpO2Card(stats),

            const SizedBox(height: 16),

            // Temperature Section
            _buildSectionHeader('Body Temperature', Icons.thermostat),
            const SizedBox(height: 12),
            _buildTemperatureCard(stats),

            const SizedBox(height: 16),

            // Stress Section
            _buildSectionHeader('Stress Level', Icons.psychology),
            const SizedBox(height: 12),
            _buildStressCard(stats),

            const SizedBox(height: 16),

            // Sleep Section
            _buildSectionHeader('Sleep Analysis', Icons.bedtime),
            const SizedBox(height: 12),
            _buildSleepCard(stats),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetricsGrid(Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildMetricCard(
          'SpO₂',
          '${stats['currentSpO2']}%',
          Icons.bloodtype,
          Colors.red,
        ),
        _buildMetricCard(
          'Temperature',
          '${stats['currentTemp'].toStringAsFixed(1)}°C',
          Icons.thermostat,
          Colors.orange,
        ),
        _buildMetricCard(
          'Stress',
          '${stats['currentStress']}',
          Icons.psychology,
          Colors.purple,
        ),
        _buildMetricCard(
          'Sleep Score',
          '${stats['lastSleepScore'].round()}',
          Icons.bedtime,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildECGCard() {
    final latestECG = _wearablesService.getLatestECG();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFF48FB1)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Electrocardiogram',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Heart Rhythm Analysis',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (latestECG != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    latestECG.rhythm.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (latestECG != null) ...[
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomPaint(
                painter: ECGWaveformPainter(latestECG.waveform),
                child: Container(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${latestECG.heartRate} BPM',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              DateFormat('MMM d, h:mm a').format(latestECG.timestamp),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ] else
            const Text(
              'No ECG readings yet',
              style: TextStyle(color: Colors.white70),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await _wearablesService.takeECGReading();
                setState(() {});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(' ECG reading complete'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.favorite),
              label: const Text('Take ECG Reading'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFE91E63),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpO2Card(Map<String, dynamic> stats) {
    final currentSpO2 = stats['currentSpO2'];
    final avgSpO2 = stats['averageSpO2'];

    Color spo2Color;
    String status;

    if (currentSpO2 >= 95) {
      spo2Color = Colors.green;
      status = 'Normal';
    } else if (currentSpO2 >= 90) {
      spo2Color = Colors.orange;
      status = 'Low';
    } else {
      spo2Color = Colors.red;
      status = 'Critical';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: spo2Color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bloodtype, color: spo2Color, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          '$currentSpO2%',
                          style: TextStyle(
                            color: spo2Color,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: spo2Color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: spo2Color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '24h Average',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$avgSpO2%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white54, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Normal range: 95-100%. Values below 90% require medical attention.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureCard(Map<String, dynamic> stats) {
    final currentTemp = stats['currentTemp'];
    final avgTemp = stats['averageTemp'];

    Color tempColor;
    String status;

    if (currentTemp < 37.5) {
      tempColor = Colors.green;
      status = 'Normal';
    } else if (currentTemp < 38.0) {
      tempColor = Colors.orange;
      status = 'Elevated';
    } else {
      tempColor = Colors.red;
      status = 'Fever';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tempColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.thermostat, color: tempColor, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          '${currentTemp.toStringAsFixed(1)}°C',
                          style: TextStyle(
                            color: tempColor,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: tempColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: tempColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    '24h Average',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${avgTemp.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStressCard(Map<String, dynamic> stats) {
    final currentStress = stats['currentStress'];
    final avgStress = stats['averageStress'];

    Color stressColor;
    String status;

    if (currentStress < 30) {
      stressColor = Colors.green;
      status = 'Low';
    } else if (currentStress < 70) {
      stressColor = Colors.orange;
      status = 'Medium';
    } else {
      stressColor = Colors.red;
      status = 'High';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            stressColor.withValues(alpha: 0.3),
            stressColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: stressColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: stressColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stress Level',
                      style: TextStyle(
                        color: stressColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        color: stressColor.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$currentStress',
                style: TextStyle(
                  color: stressColor,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: currentStress / 100,
              backgroundColor: Colors.white12,
              color: stressColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '24h Average',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                '$avgStress',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSleepCard(Map<String, dynamic> stats) {
    final lastSleep = _wearablesService.getLastNightSleep();
    final sleepScore = stats['lastSleepScore'];

    Color scoreColor;
    if (sleepScore >= 80) {
      scoreColor = Colors.green;
    } else if (sleepScore >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sleep Quality',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Last Night',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '${sleepScore.round()}',
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Score',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (lastSleep != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSleepStat(
                    'Total',
                    '${(lastSleep.totalMinutes / 60).toStringAsFixed(1)}h',
                    Icons.bedtime,
                  ),
                ),
                Expanded(
                  child: _buildSleepStat(
                    'Deep',
                    '${(lastSleep.deepSleepMinutes / 60).toStringAsFixed(1)}h',
                    Icons.airline_seat_flat,
                  ),
                ),
                Expanded(
                  child: _buildSleepStat(
                    'REM',
                    '${(lastSleep.remSleepMinutes / 60).toStringAsFixed(1)}h',
                    Icons.nightlight,
                  ),
                ),
              ],
            ),
          ] else
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'No sleep data available',
                style: TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSleepStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
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

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(
          'Health Monitoring Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text(
                  'ECG Monitoring',
                  style: TextStyle(color: Colors.white),
                ),
                value: _wearablesService.isECGMonitoringEnabled(),
                onChanged: (value) {
                  _wearablesService.updateSettings(ecgMonitoring: value);
                  setState(() {});
                },
                activeColor: const Color(0xFF00BFA5),
              ),
              SwitchListTile(
                title: const Text(
                  'SpO₂ Monitoring',
                  style: TextStyle(color: Colors.white),
                ),
                value: _wearablesService.isSpO2MonitoringEnabled(),
                onChanged: (value) {
                  _wearablesService.updateSettings(spo2Monitoring: value);
                  setState(() {});
                },
                activeColor: const Color(0xFF00BFA5),
              ),
              SwitchListTile(
                title: const Text(
                  'Temperature Monitoring',
                  style: TextStyle(color: Colors.white),
                ),
                value: _wearablesService.isTemperatureMonitoringEnabled(),
                onChanged: (value) {
                  _wearablesService.updateSettings(
                      temperatureMonitoring: value);
                  setState(() {});
                },
                activeColor: const Color(0xFF00BFA5),
              ),
              SwitchListTile(
                title: const Text(
                  'Stress Monitoring',
                  style: TextStyle(color: Colors.white),
                ),
                value: _wearablesService.isStressMonitoringEnabled(),
                onChanged: (value) {
                  _wearablesService.updateSettings(stressMonitoring: value);
                  setState(() {});
                },
                activeColor: const Color(0xFF00BFA5),
              ),
              SwitchListTile(
                title: const Text(
                  'Sleep Tracking',
                  style: TextStyle(color: Colors.white),
                ),
                value: _wearablesService.isSleepTrackingEnabled(),
                onChanged: (value) {
                  _wearablesService.updateSettings(sleepTracking: value);
                  setState(() {});
                },
                activeColor: const Color(0xFF00BFA5),
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
}

// Custom painter for ECG waveform
class ECGWaveformPainter extends CustomPainter {
  final List<double> waveform;

  ECGWaveformPainter(this.waveform);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (int i = 0; i < waveform.length; i++) {
      final x = (i / (waveform.length - 1)) * size.width;
      final y = size.height - (waveform[i] * size.height);

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