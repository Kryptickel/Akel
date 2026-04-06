import 'package:flutter/material.dart';
import '../services/safety_analytics_service.dart';
import 'package:intl/intl.dart';

class SafetyAnalyticsScreen extends StatefulWidget {
  const SafetyAnalyticsScreen({super.key});

  @override
  State<SafetyAnalyticsScreen> createState() => _SafetyAnalyticsScreenState();
}

class _SafetyAnalyticsScreenState extends State<SafetyAnalyticsScreen> {
  final SafetyAnalyticsService _analyticsService = SafetyAnalyticsService();
  bool _isLoading = true;
  int _selectedPeriod = 30; // days

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _analyticsService.initialize();
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

    final stats = _analyticsService.getComprehensiveStats();
    final eventsByType = _analyticsService.getEventsByType(days: _selectedPeriod);
    final eventsBySeverity = _analyticsService.getEventsBySeverity(days: _selectedPeriod);
    final dailyTrend = _analyticsService.getDailyTrend(days: 7);
    final usagePatterns = _analyticsService.getUsagePatterns();
    final insights = _analyticsService.generateInsights();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Safety Analytics'),
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
// Period Selector
            _buildPeriodSelector(),

            const SizedBox(height: 16),

// Safety Score Card
            _buildSafetyScoreCard(stats['safetyScore']),

            const SizedBox(height: 16),

// Key Statistics Grid
            _buildKeyStatsGrid(stats),

            const SizedBox(height: 16),

// Daily Trend
            _buildSectionHeader('7-Day Activity Trend', Icons.trending_up),
            const SizedBox(height: 12),
            _buildDailyTrendChart(dailyTrend),

            const SizedBox(height: 16),

// Events by Type
            _buildSectionHeader('Events by Type', Icons.category),
            const SizedBox(height: 12),
            _buildEventsByTypeChart(eventsByType),

            const SizedBox(height: 16),

// Events by Severity
            _buildSectionHeader('Events by Severity', Icons.priority_high),
            const SizedBox(height: 12),
            _buildEventsBySeverityChart(eventsBySeverity),

            const SizedBox(height: 16),

// Usage Patterns
            _buildSectionHeader('Feature Usage', Icons.star),
            const SizedBox(height: 12),
            _buildUsagePatternsCard(usagePatterns),

            const SizedBox(height: 16),

// Insights
            if (insights.isNotEmpty) ...[
              _buildSectionHeader('AI Insights', Icons.psychology),
              const SizedBox(height: 12),
              _buildInsightsCard(insights),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPeriodButton('7 Days', 7),
          ),
          Expanded(
            child: _buildPeriodButton('30 Days', 30),
          ),
          Expanded(
            child: _buildPeriodButton('90 Days', 90),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, int days) {
    final isSelected = _selectedPeriod == days;
    return Material(
      color: isSelected ? const Color(0xFF00BFA5) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => setState(() => _selectedPeriod = days),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyScoreCard(double score) {
    Color scoreColor;
    String scoreLabel;
    IconData scoreIcon;

    if (score >= 90) {
      scoreColor = Colors.green;
      scoreLabel = 'Excellent';
      scoreIcon = Icons.shield;
    } else if (score >= 75) {
      scoreColor = Colors.lightGreen;
      scoreLabel = 'Very Good';
      scoreIcon = Icons.verified;
    } else if (score >= 60) {
      scoreColor = Colors.orange;
      scoreLabel = 'Good';
      scoreIcon = Icons.check_circle;
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Needs Improvement';
      scoreIcon = Icons.warning;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor, scoreColor.withValues(alpha: 0.7)],
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
                    'Safety Score',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Overall Protection Rating',
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
            scoreLabel.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyStatsGrid(Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Events',
          '${stats['totalEvents']}',
          Icons.event,
          const Color(0xFF00BFA5),
        ),
        _buildStatCard(
          'Panic Used',
          '${stats['panicButtonUsed']}',
          Icons.emergency,
          Colors.red,
        ),
        _buildStatCard(
          'Check-Ins',
          '${stats['checkInsCompleted']}',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Avg Response',
          '${stats['averageResponseTime'].round()}s',
          Icons.timer,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTrendChart(Map<String, int> trend) {
    if (trend.isEmpty) {
      return _buildEmptyChart('No trend data available');
    }

    final maxValue = trend.values.reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: trend.entries.map((entry) {
                final height = (entry.value / maxValue) * 100;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (entry.value > 0)
                          Text(
                            '${entry.value}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          height: height.clamp(10, 100),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00BFA5), Color(0xFF1DE9B6)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: trend.keys.map((key) {
              return Expanded(
                child: Text(
                  key,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsByTypeChart(Map<String, int> events) {
    if (events.isEmpty) {
      return _buildEmptyChart('No events in this period');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: events.entries.map((entry) {
          final percentage = (entry.value / events.values.reduce((a, b) => a + b)) * 100;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    entry.key.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.white12,
                      color: _getEventTypeColor(entry.key),
                      minHeight: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${entry.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEventsBySeverityChart(Map<String, int> events) {
    if (events.isEmpty) {
      return _buildEmptyChart('No severity data available');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: events.entries.map((entry) {
          final percentage = (entry.value / events.values.reduce((a, b) => a + b)) * 100;
          return Expanded(
            child: Column(
              children: [
                Text(
                  '${entry.value}',
                  style: TextStyle(
                    color: _getSeverityColor(entry.key),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: _getSeverityColor(entry.key).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getSeverityColor(entry.key),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${percentage.round()}%',
                      style: TextStyle(
                        color: _getSeverityColor(entry.key),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.key.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUsagePatternsCard(List<UsagePattern> patterns) {
    if (patterns.isEmpty) {
      return _buildEmptyChart('No usage data available');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: patterns.take(5).map((pattern) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BFA5).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Color(0xFF00BFA5),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pattern.featureName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${pattern.usageCount} times • ${pattern.averageSessionMinutes.toStringAsFixed(1)} min avg',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${pattern.usageCount}',
                  style: const TextStyle(
                    color: Color(0xFF00BFA5),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsightsCard(List<String> insights) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber, size: 28),
              SizedBox(width: 12),
              Text(
                'AI-Powered Insights',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.arrow_forward,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight,
                    style: const TextStyle(
                      color: Colors.white,
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

  Widget _buildEmptyChart(String message) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
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

  Color _getEventTypeColor(String type) {
    switch (type) {
      case 'panic':
        return Colors.red;
      case 'alert':
        return Colors.orange;
      case 'check-in':
        return Colors.green;
      case 'location-update':
        return Colors.blue;
      default:
        return const Color(0xFF00BFA5);
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(
          'Analytics Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text(
                'Analytics Enabled',
                style: TextStyle(color: Colors.white),
              ),
              value: _analyticsService.isAnalyticsEnabled(),
              onChanged: (value) {
                _analyticsService.updateSettings(analytics: value);
                setState(() {});
              },
              activeColor: const Color(0xFF00BFA5),
            ),
            SwitchListTile(
              title: const Text(
                'Location Tracking',
                style: TextStyle(color: Colors.white),
              ),
              value: _analyticsService.isLocationTrackingEnabled(),
              onChanged: (value) {
                _analyticsService.updateSettings(locationTracking: value);
                setState(() {});
              },
              activeColor: const Color(0xFF00BFA5),
            ),
            const Divider(color: Colors.white12),
            ListTile(
              title: const Text(
                'Clear Old Data',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Remove data older than ${_analyticsService.getDataRetentionDays()} days',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                onPressed: () async {
                  await _analyticsService.clearOldData();
                  if (mounted) {
                    Navigator.pop(context);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🗑️ Old data cleared'),
                      ),
                    );
                  }
                },
              ),
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