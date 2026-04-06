import 'package:flutter/material.dart';
import '../services/risk_intelligence_service.dart';
import 'package:intl/intl.dart';

class RiskIntelligenceScreen extends StatefulWidget {
  const RiskIntelligenceScreen({super.key});

  @override
  State<RiskIntelligenceScreen> createState() => _RiskIntelligenceScreenState();
}

class _RiskIntelligenceScreenState extends State<RiskIntelligenceScreen> {
  final RiskIntelligenceService _riskService = RiskIntelligenceService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _riskService.initialize();
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

    final latestAssessment = _riskService.getLatestAssessment();
    final predictions = _riskService.getThreatPredictions();
    final patterns = _riskService.detectPatterns();
    final stats = _riskService.getStatistics();
    final riskTrend = _riskService.getRiskTrend(days: 7);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Risk Intelligence'),
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
          await _riskService.performRiskAssessment();
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
// Current Risk Score
            if (latestAssessment != null)
              _buildRiskScoreCard(latestAssessment),

            const SizedBox(height: 16),

// Statistics Grid
            _buildStatisticsGrid(stats),

            const SizedBox(height: 16),

// Risk Trend
            if (riskTrend.isNotEmpty) ...[
              _buildSectionHeader('7-Day Risk Trend', Icons.show_chart),
              const SizedBox(height: 12),
              _buildRiskTrendChart(riskTrend),
              const SizedBox(height: 16),
            ],

// Category Breakdown
            if (latestAssessment != null) ...[
              _buildSectionHeader('Risk Categories', Icons.category),
              const SizedBox(height: 12),
              _buildCategoryBreakdown(latestAssessment.categoryScores),
              const SizedBox(height: 16),
            ],

// Active Risk Factors
            if (latestAssessment != null && latestAssessment.riskFactors.isNotEmpty) ...[
              _buildSectionHeader('Active Risk Factors', Icons.warning),
              const SizedBox(height: 12),
              ...latestAssessment.riskFactors.map((factor) => _buildRiskFactorCard(factor)),
              const SizedBox(height: 16),
            ],

// Threat Predictions
            if (predictions.isNotEmpty) ...[
              _buildSectionHeader('Threat Predictions', Icons.psychology),
              const SizedBox(height: 12),
              ...predictions.map((prediction) => _buildPredictionCard(prediction)),
              const SizedBox(height: 16),
            ],

// Safety Patterns
            if (patterns.isNotEmpty) ...[
              _buildSectionHeader('Detected Patterns', Icons.pattern),
              const SizedBox(height: 12),
              ...patterns.map((pattern) => _buildPatternCard(pattern)),
              const SizedBox(height: 16),
            ],

// Recommendations
            if (latestAssessment != null && latestAssessment.recommendations.isNotEmpty) ...[
              _buildSectionHeader('AI Recommendations', Icons.lightbulb),
              const SizedBox(height: 12),
              _buildRecommendationsCard(latestAssessment.recommendations),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _performNewAssessment(),
        backgroundColor: const Color(0xFF00BFA5),
        icon: const Icon(Icons.refresh),
        label: const Text('New Assessment'),
      ),
    );
  }

  Widget _buildRiskScoreCard(RiskAssessment assessment) {
    final score = assessment.overallRiskScore;
    Color scoreColor;
    String scoreLabel;
    IconData scoreIcon;

    if (score < 30) {
      scoreColor = Colors.green;
      scoreLabel = 'Low Risk';
      scoreIcon = Icons.check_circle;
    } else if (score < 60) {
      scoreColor = Colors.lightGreen;
      scoreLabel = 'Moderate Risk';
      scoreIcon = Icons.info;
    } else if (score < 80) {
      scoreColor = Colors.orange;
      scoreLabel = 'High Risk';
      scoreIcon = Icons.warning;
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Critical Risk';
      scoreIcon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor, scoreColor.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 12),
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
                    'Current Risk Level',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'AI-Powered Assessment',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Icon(scoreIcon, color: Colors.white, size: 48),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${score.round()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 88,
                  fontWeight: FontWeight.bold,
                  height: 1,
                  letterSpacing: -2,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  '/100',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 28,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              scoreLabel.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Updated: ${DateFormat('MMM d, h:mm a').format(assessment.timestamp)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid(Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          'Assessments',
          '${stats['totalAssessments']}',
          Icons.assessment,
          const Color(0xFF00BFA5),
        ),
        _buildStatCard(
          'Avg Risk',
          '${stats['averageRisk'].round()}',
          Icons.trending_up,
          Colors.blue,
        ),
        _buildStatCard(
          'High Risk',
          '${stats['highRiskCount']}',
          Icons.warning,
          Colors.orange,
        ),
        _buildStatCard(
          'Predictions',
          '${stats['activePredictions']}',
          Icons.psychology,
          Colors.purple,
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
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 10),
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

  Widget _buildRiskTrendChart(List<double> trend) {
    if (trend.isEmpty) return const SizedBox();

    final maxValue = trend.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Risk Trend Analysis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              painter: RiskTrendPainter(trend, maxValue),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(Map<String, double> categories) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: categories.entries.map((entry) {
          final color = _getCategoryColor(entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(_getCategoryIcon(entry.key), color: color, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          entry.key.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${entry.value.round()}',
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: entry.value / 100,
                    backgroundColor: Colors.white12,
                    color: color,
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRiskFactorCard(RiskFactor factor) {
    final color = _getSeverityColor(factor.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(factor.category),
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      factor.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${factor.severity.toStringAsFixed(1)}/10',
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  factor.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(ThreatPrediction prediction) {
    final color = _getProbabilityColor(prediction.probability);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  prediction.threatType,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${prediction.probability.round()}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            prediction.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Prevention Steps:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...prediction.preventionSteps.map((step) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: color, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
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

  Widget _buildPatternCard(SafetyPattern pattern) {
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA5).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pattern,
              color: Color(0xFF00BFA5),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pattern.patternName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  pattern.insight,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pattern.occurrences} occurrences • ${pattern.confidence.round()}% confidence',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(List<String> recommendations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'AI Recommendations',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
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
                const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rec,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'location':
        return Colors.blue;
      case 'time':
        return Colors.purple;
      case 'behavior':
        return Colors.orange;
      case 'health':
        return Colors.red;
      case 'environmental':
        return Colors.green;
      default:
        return const Color(0xFF00BFA5);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'location':
        return Icons.place;
      case 'time':
        return Icons.schedule;
      case 'behavior':
        return Icons.person;
      case 'health':
        return Icons.favorite;
      case 'environmental':
        return Icons.wb_sunny;
      default:
        return Icons.info;
    }
  }

  Color _getSeverityColor(double severity) {
    if (severity >= 8) return Colors.red;
    if (severity >= 6) return Colors.orange;
    if (severity >= 4) return Colors.yellow;
    return Colors.green;
  }

  Color _getProbabilityColor(double probability) {
    if (probability >= 75) return Colors.red;
    if (probability >= 50) return Colors.orange;
    if (probability >= 25) return Colors.yellow;
    return Colors.green;
  }

  void _performNewAssessment() async {
    setState(() => _isLoading = true);
    await _riskService.performRiskAssessment();
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Risk assessment complete'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(
          'Risk Intelligence Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text(
                'Risk Monitoring',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Continuous risk assessment',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              value: _riskService.isRiskMonitoringEnabled(),
              onChanged: (value) {
                _riskService.updateSettings(riskMonitoring: value);
                setState(() {});
              },
              activeColor: const Color(0xFF00BFA5),
            ),
            SwitchListTile(
              title: const Text(
                'Predictive Analysis',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'AI threat predictions',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              value: _riskService.isPredictiveAnalysisEnabled(),
              onChanged: (value) {
                _riskService.updateSettings(predictiveAnalysis: value);
                setState(() {});
              },
              activeColor: const Color(0xFF00BFA5),
            ),
            SwitchListTile(
              title: const Text(
                'Auto Alerts',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Automatic high-risk notifications',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              value: _riskService.isAutoAlertsEnabled(),
              onChanged: (value) {
                _riskService.updateSettings(autoAlerts: value);
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

// Custom painter for risk trend chart
class RiskTrendPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;

  RiskTrendPainter(this.values, this.maxValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final normalizedValue = values[i] / maxValue;
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

// Draw points
    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final normalizedValue = values[i] / maxValue;
      final y = size.height - (normalizedValue * size.height);
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}