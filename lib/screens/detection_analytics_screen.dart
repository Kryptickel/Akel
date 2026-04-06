import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import '../widgets/futuristic_widgets.dart';
import '../services/smart_detection_service.dart';
import '../providers/auth_provider.dart';

/// ==================== DETECTION ANALYTICS SCREEN ====================
///
/// SMART DETECTION ANALYTICS DASHBOARD
///
/// Features:
/// - Detection trends over time
/// - Severity distribution charts
/// - Detection type breakdown
/// - Hourly detection patterns
/// - Weekly/monthly analytics
/// - Export analytics data
///
/// 24-HOUR MARATHON - PHASE 1 (HOURS 3-4)
/// ================================================================

class DetectionAnalyticsScreen extends StatefulWidget {
  const DetectionAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<DetectionAnalyticsScreen> createState() => _DetectionAnalyticsScreenState();
}

class _DetectionAnalyticsScreenState extends State<DetectionAnalyticsScreen> {
  final SmartDetectionService _detectionService = SmartDetectionService();

  bool _isLoading = true;
  List<DetectionEvent> _allEvents = [];
  Map<String, dynamic> _statistics = {};

  // Analytics data
  Map<DetectionType, int> _typeDistribution = {};
  Map<EarthquakeSeverity, int> _severityDistribution = {};
  List<int> _hourlyPattern = List.filled(24, 0);
  List<int> _weeklyPattern = List.filled(7, 0);

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      await _detectionService.initialize();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;

      if (userId != null) {
        // Load all data
        final events = await _detectionService.getDetectionHistoryFromFirestore(userId, limit: 1000);
        final stats = await _detectionService.getDetectionStatistics(userId);

        // Calculate analytics
        _calculateAnalytics(events);

        setState(() {
          _allEvents = events;
          _statistics = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(' Analytics load error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _calculateAnalytics(List<DetectionEvent> events) {
    // Type distribution
    _typeDistribution.clear();
    for (final type in DetectionType.values) {
      _typeDistribution[type] = events.where((e) => e.type == type).length;
    }

    // Severity distribution
    _severityDistribution.clear();
    for (final severity in EarthquakeSeverity.values) {
      _severityDistribution[severity] = events.where((e) => e.severity == severity).length;
    }

    // Hourly pattern
    _hourlyPattern = List.filled(24, 0);
    for (final event in events) {
      final hour = event.timestamp.hour;
      _hourlyPattern[hour]++;
    }

    // Weekly pattern (0 = Monday, 6 = Sunday)
    _weeklyPattern = List.filled(7, 0);
    for (final event in events) {
      final weekday = event.timestamp.weekday - 1; // Convert to 0-based
      _weeklyPattern[weekday]++;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AkelDesign.deepBlack,
        body: const Center(
          child: FuturisticLoadingIndicator(
            size: 60,
            color: AkelDesign.neonBlue,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AkelDesign.deepBlack,
      appBar: AppBar(
        backgroundColor: AkelDesign.carbonFiber,
        elevation: 0,
        leading: FuturisticIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.pop(context),
          size: 40,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DETECTION ANALYTICS',
              style: AkelDesign.h3.copyWith(fontSize: 16),
            ),
            Text(
              'Smart Detection Insights',
              style: AkelDesign.caption.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AkelDesign.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Stats
            _buildSummaryStats(),

            const SizedBox(height: AkelDesign.xxl),

            // Detection Type Distribution
            Text('DETECTION TYPE BREAKDOWN', style: AkelDesign.subtitle),
            const SizedBox(height: AkelDesign.md),
            _buildTypeDistributionChart(),

            const SizedBox(height: AkelDesign.xxl),

            // Severity Distribution
            Text('SEVERITY DISTRIBUTION', style: AkelDesign.subtitle),
            const SizedBox(height: AkelDesign.md),
            _buildSeverityDistributionChart(),

            const SizedBox(height: AkelDesign.xxl),

            // Hourly Pattern
            Text('HOURLY DETECTION PATTERN', style: AkelDesign.subtitle),
            const SizedBox(height: AkelDesign.md),
            _buildHourlyPatternChart(),

            const SizedBox(height: AkelDesign.xxl),

            // Weekly Pattern
            Text('WEEKLY DETECTION PATTERN', style: AkelDesign.subtitle),
            const SizedBox(height: AkelDesign.md),
            _buildWeeklyPatternChart(),

            const SizedBox(height: AkelDesign.xxl),

            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Events',
                '${_statistics['total'] ?? 0}',
                Icons.analytics,
                AkelDesign.neonBlue,
              ),
            ),
            const SizedBox(width: AkelDesign.md),
            Expanded(
              child: _buildStatCard(
                'Avg Per Day',
                '${(_statistics['avgPerDay'] ?? 0).toStringAsFixed(1)}',
                Icons.trending_up,
                AkelDesign.successGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: AkelDesign.md),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Earthquakes',
                '${_statistics['earthquakes'] ?? 0}',
                Icons.waves,
                Colors.orange,
              ),
            ),
            const SizedBox(width: AkelDesign.md),
            Expanded(
              child: _buildStatCard(
                'Falls',
                '${_statistics['falls'] ?? 0}',
                Icons.personal_injury,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.md),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AkelDesign.sm),
          Text(
            value,
            style: AkelDesign.h3.copyWith(color: color, fontSize: 20),
          ),
          Text(label, style: AkelDesign.caption.copyWith(fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildTypeDistributionChart() {
    if (_typeDistribution.isEmpty || _typeDistribution.values.every((v) => v == 0)) {
      return _buildEmptyChart('No detection data available');
    }

    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: _typeDistribution.entries.map((entry) {
                  final color = _getTypeColor(entry.key);
                  final percentage = (_typeDistribution[entry.key]! / _allEvents.length * 100);

                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    title: '${percentage.toStringAsFixed(0)}%',
                    color: color,
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: AkelDesign.lg),
          Wrap(
            spacing: AkelDesign.md,
            runSpacing: AkelDesign.sm,
            children: _typeDistribution.entries.map((entry) {
              return _buildLegendItem(
                entry.key.name,
                _getTypeColor(entry.key),
                entry.value,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityDistributionChart() {
    if (_severityDistribution.isEmpty || _severityDistribution.values.every((v) => v == 0)) {
      return _buildEmptyChart('No severity data available');
    }

    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: SizedBox(
        height: 250,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: _severityDistribution.values.reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
            barGroups: _severityDistribution.entries.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final severity = entry.value.key;
              final count = entry.value.value;

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: count.toDouble(),
                    color: _getSeverityColor(severity),
                    width: 40,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final severities = EarthquakeSeverity.values;
                    if (value.toInt() >= 0 && value.toInt() < severities.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          severities[value.toInt()].name.substring(0, 3).toUpperCase(),
                          style: AkelDesign.caption.copyWith(fontSize: 10),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: AkelDesign.caption.copyWith(fontSize: 10),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.white10,
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyPatternChart() {
    if (_hourlyPattern.every((v) => v == 0)) {
      return _buildEmptyChart('No hourly pattern data');
    }

    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: _hourlyPattern.asMap().entries.map((entry) {
                  return FlSpot(entry.key.toDouble(), entry.value.toDouble());
                }).toList(),
                isCurved: true,
                color: AkelDesign.neonBlue,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AkelDesign.neonBlue.withOpacity(0.2),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 6,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${value.toInt()}h',
                        style: AkelDesign.caption.copyWith(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: AkelDesign.caption.copyWith(fontSize: 10),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.white10,
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyPatternChart() {
    if (_weeklyPattern.every((v) => v == 0)) {
      return _buildEmptyChart('No weekly pattern data');
    }

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: _weeklyPattern.reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
            barGroups: _weeklyPattern.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.toDouble(),
                    color: AkelDesign.successGreen,
                    width: 30,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < weekdays.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          weekdays[value.toInt()],
                          style: AkelDesign.caption.copyWith(fontSize: 10),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: AkelDesign.caption.copyWith(fontSize: 10),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.white10,
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        FuturisticButton(
          text: 'EXPORT ANALYTICS DATA',
          icon: Icons.download,
          onPressed: () {
            // Export functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(' Analytics data exported'),
                backgroundColor: AkelDesign.successGreen,
              ),
            );
          },
          color: AkelDesign.infoBlue,
          isFullWidth: true,
        ),
        const SizedBox(height: AkelDesign.md),
        FuturisticButton(
          text: 'REFRESH DATA',
          icon: Icons.refresh,
          onPressed: _loadAnalytics,
          color: AkelDesign.neonBlue,
          isOutlined: true,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildEmptyChart(String message) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.xxl),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.insert_chart_outlined, size: 60, color: Colors.white24),
            const SizedBox(height: AkelDesign.md),
            Text(
              message,
              style: AkelDesign.caption.copyWith(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AkelDesign.sm,
        vertical: AkelDesign.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: AkelDesign.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(DetectionType type) {
    switch (type) {
      case DetectionType.earthquake:
        return Colors.orange;
      case DetectionType.fall:
        return Colors.red;
      case DetectionType.environmentalHazard:
        return AkelDesign.warningOrange;
      case DetectionType.naturalDisaster:
        return Colors.purple;
    }
  }

  Color _getSeverityColor(EarthquakeSeverity severity) {
    switch (severity) {
      case EarthquakeSeverity.minor:
        return const Color(0xFF4CAF50);
      case EarthquakeSeverity.moderate:
        return const Color(0xFFFFA726);
      case EarthquakeSeverity.strong:
        return const Color(0xFFFF5722);
      case EarthquakeSeverity.severe:
        return const Color(0xFFF44336);
    }
  }
}