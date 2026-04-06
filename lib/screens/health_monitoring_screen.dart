import 'package:flutter/material.dart';
import '../services/health_monitoring_service.dart';
import 'package:intl/intl.dart';

class HealthMonitoringScreen extends StatefulWidget {
  const HealthMonitoringScreen({super.key});

  @override
  State<HealthMonitoringScreen> createState() => _HealthMonitoringScreenState();
}

class _HealthMonitoringScreenState extends State<HealthMonitoringScreen> {
  final HealthMonitoringService _healthService = HealthMonitoringService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _healthService.initialize();
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

    final report = _healthService.generateHealthReport();
    final vitals = _healthService.getCurrentVitals();
    final fitness = _healthService.getFitnessMetrics();
    final wellness = _healthService.getWellnessMetrics();
    final alerts = _healthService.getAlerts();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Health Dashboard'),
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
            // Overall Health Score
            _buildHealthScoreCard(report),

            const SizedBox(height: 16),

            // Active Alerts
            if (alerts.isNotEmpty) ...[
              _buildSectionHeader('Health Alerts', Icons.warning_amber),
              const SizedBox(height: 12),
              ...alerts.take(3).map((alert) => _buildAlertCard(alert)),
              const SizedBox(height: 16),
            ],

            // Vital Signs
            _buildSectionHeader('Vital Signs', Icons.favorite),
            const SizedBox(height: 12),
            _buildVitalsCard(vitals, report.summary['vitalScore']),

            const SizedBox(height: 16),

            // Fitness Metrics
            _buildSectionHeader('Fitness Activity', Icons.directions_run),
            const SizedBox(height: 12),
            _buildFitnessCard(fitness, report.summary['fitnessScore']),

            const SizedBox(height: 16),

            // Wellness Metrics
            _buildSectionHeader('Wellness', Icons.spa),
            const SizedBox(height: 12),
            _buildWellnessCard(wellness, report.summary['wellnessScore']),

            const SizedBox(height: 16),

            // Recommendations
            if (report.recommendations.isNotEmpty) ...[
              _buildSectionHeader('Recommendations', Icons.lightbulb),
              const SizedBox(height: 12),
              _buildRecommendationsCard(report.recommendations),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _generateFullReport(),
        backgroundColor: const Color(0xFF00BFA5),
        icon: const Icon(Icons.assessment),
        label: const Text('Full Report'),
      ),
    );
  }

  Widget _buildHealthScoreCard(HealthReport report) {
    final score = report.overallScore;
    Color scoreColor;
    String scoreText;
    IconData scoreIcon;

    if (score >= 80) {
      scoreColor = Colors.green;
      scoreText = 'Excellent';
      scoreIcon = Icons.emoji_emotions;
    } else if (score >= 60) {
      scoreColor = Colors.lightGreen;
      scoreText = 'Good';
      scoreIcon = Icons.sentiment_satisfied;
    } else if (score >= 40) {
      scoreColor = Colors.orange;
      scoreText = 'Fair';
      scoreIcon = Icons.sentiment_neutral;
    } else {
      scoreColor = Colors.red;
      scoreText = 'Needs Attention';
      scoreIcon = Icons.sentiment_dissatisfied;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor, scoreColor.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
                    'Overall Health',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Comprehensive Score',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Icon(scoreIcon, color: Colors.white, size: 40),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${score.round()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  '/100',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            scoreText.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildScoreBreakdown(
                  'Vitals',
                  report.summary['vitalScore'],
                  Icons.favorite,
                ),
              ),
              Expanded(
                child: _buildScoreBreakdown(
                  'Fitness',
                  report.summary['fitnessScore'],
                  Icons.directions_run,
                ),
              ),
              Expanded(
                child: _buildScoreBreakdown(
                  'Wellness',
                  report.summary['wellnessScore'],
                  Icons.spa,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown(String label, double score, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          '${score.round()}',
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

  Widget _buildAlertCard(HealthAlert alert) {
    Color alertColor;
    IconData alertIcon;

    switch (alert.severity) {
      case 'critical':
        alertColor = Colors.red;
        alertIcon = Icons.error;
        break;
      case 'warning':
        alertColor = Colors.orange;
        alertIcon = Icons.warning;
        break;
      default:
        alertColor = Colors.blue;
        alertIcon = Icons.info;
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
            padding: const EdgeInsets.all(10),
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
                  alert.metricName,
                  style: TextStyle(
                    color: alertColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  alert.message,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                Text(
                  DateFormat('h:mm a').format(alert.timestamp),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              await _healthService.acknowledgeAlert(alert.id);
              setState(() {});
            },
            icon: const Icon(Icons.check_circle_outline, color: Color(0xFF00BFA5)),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsCard(Map<String, dynamic> vitals, double score) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDC143C), Color(0xFFFF6B6B)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vital Signs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Score: ${score.round()}',
                  style: const TextStyle(
                    color: Colors.white,
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
              Expanded(
                child: _buildVitalMetric(
                  'Heart Rate',
                  '${vitals['heartRate'].round()}',
                  'BPM',
                  Icons.favorite,
                ),
              ),
              Expanded(
                child: _buildVitalMetric(
                  'Blood Pressure',
                  '${vitals['bloodPressureSystolic'].round()}/${vitals['bloodPressureDiastolic'].round()}',
                  'mmHg',
                  Icons.monitor_heart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildVitalMetric(
                  'Temperature',
                  vitals['temperature'].toStringAsFixed(1),
                  '°C',
                  Icons.thermostat,
                ),
              ),
              Expanded(
                child: _buildVitalMetric(
                  'SpO₂',
                  '${vitals['spO2'].round()}',
                  '%',
                  Icons.bloodtype,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalMetric(
      String label, String value, String unit, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFitnessCard(Map<String, dynamic> fitness, double score) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fitness Activity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Score: ${score.round()}',
                  style: const TextStyle(
                    color: Colors.white,
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
              Expanded(
                child: _buildFitnessMetric(
                  '${fitness['steps'].round()}',
                  'Steps',
                  Icons.directions_walk,
                ),
              ),
              Expanded(
                child: _buildFitnessMetric(
                  '${fitness['calories'].round()}',
                  'Calories',
                  Icons.local_fire_department,
                ),
              ),
              Expanded(
                child: _buildFitnessMetric(
                  '${fitness['activeMinutes'].round()}',
                  'Minutes',
                  Icons.timer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFitnessMetric(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
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

  Widget _buildWellnessCard(Map<String, dynamic> wellness, double score) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Wellness',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Score: ${score.round()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildWellnessItem('Sleep Score', wellness['sleepScore'].round(), Icons.bedtime),
          const SizedBox(height: 12),
          _buildWellnessItem('Stress Level', wellness['stressLevel'].round(), Icons.psychology),
          const SizedBox(height: 12),
          _buildWellnessItem('HRV Score', wellness['hrvScore'].round(), Icons.favorite),
        ],
      ),
    );
  }

  Widget _buildWellnessItem(String label, int value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: value / 100,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsCard(List<String> recommendations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00BFA5).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Color(0xFFFFD700), size: 24),
              SizedBox(width: 12),
              Text(
                'Health Recommendations',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF00BFA5),
                  size: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rec,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          )),
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

  void _generateFullReport() {
    final report = _healthService.generateHealthReport();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(
          'Health Report',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generated: ${DateFormat('MMM d, y h:mm a').format(report.generatedAt)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Text(
                'Overall Score: ${report.overallScore.round()}/100',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Summary:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• Vitals Score: ${report.summary['vitalScore'].round()}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                '• Fitness Score: ${report.summary['fitnessScore'].round()}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                '• Wellness Score: ${report.summary['wellnessScore'].round()}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(' Report exported'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Export'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(
          'Monitoring Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text(
                'Continuous Monitoring',
                style: TextStyle(color: Colors.white),
              ),
              value: _healthService.isContinuousMonitoringEnabled(),
              onChanged: (value) {
                _healthService.updateSettings(continuousMonitoring: value);
                setState(() {});
              },
              activeColor: const Color(0xFF00BFA5),
            ),
            SwitchListTile(
              title: const Text(
                'Alert Notifications',
                style: TextStyle(color: Colors.white),
              ),
              value: _healthService.isAlertNotificationsEnabled(),
              onChanged: (value) {
                _healthService.updateSettings(alertNotifications: value);
                setState(() {});
              },
              activeColor: const Color(0xFF00BFA5),
            ),
            SwitchListTile(
              title: const Text(
                'Daily Reports',
                style: TextStyle(color: Colors.white),
              ),
              value: _healthService.isDailyReportEnabled(),
              onChanged: (value) {
                _healthService.updateSettings(dailyReport: value);
                setState(() {});
              },
              activeColor: const Color(0xFF00BFA5),
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
  }
}