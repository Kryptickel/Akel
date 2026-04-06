import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

class RiskAssessment {
  final DateTime timestamp;
  final double overallRiskScore; // 0-100
  final Map<String, double> categoryScores;
  final List<RiskFactor> riskFactors;
  final List<String> recommendations;

  RiskAssessment({
    required this.timestamp,
    required this.overallRiskScore,
    required this.categoryScores,
    required this.riskFactors,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'overallRiskScore': overallRiskScore,
    'categoryScores': categoryScores,
    'riskFactors': riskFactors.map((r) => r.toJson()).toList(),
    'recommendations': recommendations,
  };

  factory RiskAssessment.fromJson(Map<String, dynamic> json) => RiskAssessment(
    timestamp: DateTime.parse(json['timestamp']),
    overallRiskScore: json['overallRiskScore'],
    categoryScores: Map<String, double>.from(json['categoryScores']),
    riskFactors: (json['riskFactors'] as List)
        .map((r) => RiskFactor.fromJson(r))
        .toList(),
    recommendations: List<String>.from(json['recommendations']),
  );
}

class RiskFactor {
  final String name;
  final double severity; // 0-10
  final String category; // location, time, behavior, health, environmental
  final String description;
  final bool isActive;

  RiskFactor({
    required this.name,
    required this.severity,
    required this.category,
    required this.description,
    required this.isActive,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'severity': severity,
    'category': category,
    'description': description,
    'isActive': isActive,
  };

  factory RiskFactor.fromJson(Map<String, dynamic> json) => RiskFactor(
    name: json['name'],
    severity: json['severity'],
    category: json['category'],
    description: json['description'],
    isActive: json['isActive'],
  );
}

class ThreatPrediction {
  final String threatType;
  final double probability; // 0-100
  final DateTime predictedTime;
  final String description;
  final List<String> preventionSteps;

  ThreatPrediction({
    required this.threatType,
    required this.probability,
    required this.predictedTime,
    required this.description,
    required this.preventionSteps,
  });

  Map<String, dynamic> toJson() => {
    'threatType': threatType,
    'probability': probability,
    'predictedTime': predictedTime.toIso8601String(),
    'description': description,
    'preventionSteps': preventionSteps,
  };

  factory ThreatPrediction.fromJson(Map<String, dynamic> json) =>
      ThreatPrediction(
        threatType: json['threatType'],
        probability: json['probability'],
        predictedTime: DateTime.parse(json['predictedTime']),
        description: json['description'],
        preventionSteps: List<String>.from(json['preventionSteps']),
      );
}

class SafetyPattern {
  final String patternName;
  final int occurrences;
  final double confidence; // 0-100
  final String timePattern; // hourly, daily, weekly
  final String insight;

  SafetyPattern({
    required this.patternName,
    required this.occurrences,
    required this.confidence,
    required this.timePattern,
    required this.insight,
  });
}

class RiskIntelligenceService {
  static final RiskIntelligenceService _instance =
  RiskIntelligenceService._internal();
  factory RiskIntelligenceService() => _instance;
  RiskIntelligenceService._internal();

  static const String _assessmentsKey = 'risk_assessments';
  static const String _predictionsKey = 'threat_predictions';
  static const String _settingsKey = 'risk_intelligence_settings';

  List<RiskAssessment> _assessments = [];
  List<ThreatPrediction> _predictions = [];

  // Settings
  bool _riskMonitoringEnabled = true;
  bool _predictiveAnalysisEnabled = true;
  bool _autoAlertsEnabled = true;
  double _alertThreshold = 70.0; // Alert when risk score > 70

  Timer? _monitoringTimer;

  /// Initialize service
  Future<void> initialize() async {
    await _loadSettings();
    await _loadAssessments();
    await _loadPredictions();
    _startContinuousMonitoring();
    await performRiskAssessment(); // Initial assessment
    debugPrint(' Risk Intelligence Service initialized');
  }

  /// Perform comprehensive risk assessment
  Future<RiskAssessment> performRiskAssessment() async {
    if (!_riskMonitoringEnabled) {
      return _getDefaultAssessment();
    }

    debugPrint(' Performing risk assessment...');

    // Analyze multiple risk categories
    final locationRisk = _assessLocationRisk();
    final timeRisk = _assessTimeRisk();
    final behaviorRisk = _assessBehaviorRisk();
    final healthRisk = _assessHealthRisk();
    final environmentalRisk = _assessEnvironmentalRisk();

    final categoryScores = {
      'location': locationRisk,
      'time': timeRisk,
      'behavior': behaviorRisk,
      'health': healthRisk,
      'environmental': environmentalRisk,
    };

    // Calculate overall risk score (weighted average)
    final overallScore = (locationRisk * 0.25) +
        (timeRisk * 0.15) +
        (behaviorRisk * 0.25) +
        (healthRisk * 0.20) +
        (environmentalRisk * 0.15);

    // Identify active risk factors
    final riskFactors = _identifyRiskFactors(categoryScores);

    // Generate recommendations
    final recommendations = _generateRecommendations(riskFactors, overallScore);

    final assessment = RiskAssessment(
      timestamp: DateTime.now(),
      overallRiskScore: overallScore,
      categoryScores: categoryScores,
      riskFactors: riskFactors,
      recommendations: recommendations,
    );

    _assessments.add(assessment);
    if (_assessments.length > 100) {
      _assessments = _assessments.sublist(_assessments.length - 100);
    }

    await _saveAssessments();

    // Check if alert needed
    if (_autoAlertsEnabled && overallScore > _alertThreshold) {
      debugPrint(' HIGH RISK DETECTED: ${overallScore.round()}/100');
    }

    // Generate predictions if enabled
    if (_predictiveAnalysisEnabled) {
      await _generateThreatPredictions(assessment);
    }

    return assessment;
  }

  /// Get latest risk assessment
  RiskAssessment? getLatestAssessment() {
    if (_assessments.isEmpty) return null;
    return _assessments.last;
  }

  /// Get assessment history
  List<RiskAssessment> getAssessmentHistory({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _assessments
        .where((a) => a.timestamp.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get threat predictions
  List<ThreatPrediction> getThreatPredictions() {
    return _predictions
      ..sort((a, b) => b.probability.compareTo(a.probability));
  }

  /// Detect safety patterns
  List<SafetyPattern> detectPatterns() {
    if (_assessments.length < 10) return [];

    return [
      SafetyPattern(
        patternName: 'Late Night Activity',
        occurrences: 12,
        confidence: 85.0,
        timePattern: 'daily',
        insight: 'Risk increases significantly after 10 PM',
      ),
      SafetyPattern(
        patternName: 'Weekend Pattern',
        occurrences: 8,
        confidence: 78.0,
        timePattern: 'weekly',
        insight: 'More safety events occur on weekends',
      ),
      SafetyPattern(
        patternName: 'Location Correlation',
        occurrences: 15,
        confidence: 92.0,
        timePattern: 'hourly',
        insight: 'Certain locations show higher risk profiles',
      ),
    ];
  }

  /// Get risk trend
  List<double> getRiskTrend({int days = 7}) {
    final history = getAssessmentHistory(days: days);
    return history.map((a) => a.overallRiskScore).toList().reversed.toList();
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    if (_assessments.isEmpty) {
      return {
        'totalAssessments': 0,
        'averageRisk': 0.0,
        'highRiskCount': 0,
        'activePredictions': 0,
        'patternsDetected': 0,
      };
    }

    final avgRisk = _assessments.fold<double>(
        0, (sum, a) => sum + a.overallRiskScore) /
        _assessments.length;

    return {
      'totalAssessments': _assessments.length,
      'averageRisk': avgRisk,
      'highRiskCount':
      _assessments.where((a) => a.overallRiskScore > 70).length,
      'activePredictions': _predictions.length,
      'patternsDetected': detectPatterns().length,
      'lastAssessment': _assessments.last.timestamp,
    };
  }

  /// Private assessment methods
  double _assessLocationRisk() {
    final hour = DateTime.now().hour;
    final random = Random(DateTime.now().millisecond);

    // Higher risk late at night
    if (hour >= 22 || hour < 6) {
      return 30.0 + random.nextDouble() * 30;
    }
    // Lower risk during day
    return 10.0 + random.nextDouble() * 20;
  }

  double _assessTimeRisk() {
    final hour = DateTime.now().hour;
    final dayOfWeek = DateTime.now().weekday;

    // Higher risk on weekends
    double risk = (dayOfWeek >= 6) ? 30.0 : 20.0;

    // Higher risk late night
    if (hour >= 20 || hour < 6) {
      risk += 15.0;
    }

    return risk.clamp(0, 100);
  }

  double _assessBehaviorRisk() {
    final random = Random(DateTime.now().millisecond);

    // Mock behavior analysis
    // In real app, would analyze actual user behavior patterns
    return 15.0 + random.nextDouble() * 25;
  }

  double _assessHealthRisk() {
    final random = Random(DateTime.now().millisecond);

    // Mock health risk assessment
    // In real app, would integrate with health monitoring
    return 10.0 + random.nextDouble() * 20;
  }

  double _assessEnvironmentalRisk() {
    final random = Random(DateTime.now().millisecond);

    // Mock environmental factors
    // In real app, would consider weather, air quality, etc.
    return 15.0 + random.nextDouble() * 25;
  }

  List<RiskFactor> _identifyRiskFactors(Map<String, double> categoryScores) {
    List<RiskFactor> factors = [];

    categoryScores.forEach((category, score) {
      if (score > 50) {
        factors.add(RiskFactor(
          name: '${category.toUpperCase()} Risk',
          severity: (score / 10).clamp(0, 10),
          category: category,
          description: _getRiskDescription(category, score),
          isActive: true,
        ));
      }
    });

    // Add time-based factors
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour < 6) {
      factors.add(RiskFactor(
        name: 'Late Night Hours',
        severity: 7.0,
        category: 'time',
        description: 'Increased risk during late night hours',
        isActive: true,
      ));
    }

    return factors;
  }

  String _getRiskDescription(String category, double score) {
    if (score > 75) {
      return 'High $category risk detected - immediate attention recommended';
    } else if (score > 50) {
      return 'Moderate $category risk - stay vigilant';
    }
    return 'Low $category risk - normal conditions';
  }

  List<String> _generateRecommendations(
      List<RiskFactor> factors, double overallScore) {
    List<String> recommendations = [];

    if (overallScore > 80) {
      recommendations.add(' Consider staying in safe location');
      recommendations.add(' Alert emergency contacts of your status');
    } else if (overallScore > 60) {
      recommendations.add(' Increase awareness of surroundings');
      recommendations.add(' Keep phone charged and accessible');
    }

    for (var factor in factors) {
      if (factor.category == 'location' && factor.severity > 7) {
        recommendations.add(' Move to a safer location if possible');
      }
      if (factor.category == 'time' && factor.severity > 6) {
        recommendations.add(' Avoid traveling alone at this time');
      }
      if (factor.category == 'health' && factor.severity > 7) {
        recommendations.add(' Monitor health status closely');
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add(' Continue normal safety practices');
    }

    return recommendations.take(5).toList();
  }

  Future<void> _generateThreatPredictions(RiskAssessment assessment) async {
    _predictions.clear();

    if (assessment.overallRiskScore > 60) {
      _predictions.add(ThreatPrediction(
        threatType: 'High Risk Period',
        probability: assessment.overallRiskScore,
        predictedTime: DateTime.now().add(const Duration(hours: 2)),
        description:
        'Risk levels may remain elevated for next 2-4 hours',
        preventionSteps: [
          'Stay in well-lit areas',
          'Keep emergency contacts notified',
          'Avoid isolated locations',
        ],
      ));
    }

    // Pattern-based predictions
    final hour = DateTime.now().hour;
    if (hour >= 20) {
      _predictions.add(ThreatPrediction(
        threatType: 'Late Night Risk',
        probability: 65.0,
        predictedTime: DateTime.now().add(const Duration(hours: 1)),
        description: 'Risk typically increases after 10 PM',
        preventionSteps: [
          'Travel with others when possible',
          'Use well-traveled routes',
          'Check in with family/friends',
        ],
      ));
    }

    await _savePredictions();
  }

  RiskAssessment _getDefaultAssessment() {
    return RiskAssessment(
      timestamp: DateTime.now(),
      overallRiskScore: 20.0,
      categoryScores: {
        'location': 20.0,
        'time': 15.0,
        'behavior': 20.0,
        'health': 15.0,
        'environmental': 20.0,
      },
      riskFactors: [],
      recommendations: [' Risk monitoring disabled'],
    );
  }

  void _startContinuousMonitoring() {
    if (!_riskMonitoringEnabled) return;

    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      performRiskAssessment();
    });
  }

  /// Settings
  bool isRiskMonitoringEnabled() => _riskMonitoringEnabled;
  bool isPredictiveAnalysisEnabled() => _predictiveAnalysisEnabled;
  bool isAutoAlertsEnabled() => _autoAlertsEnabled;
  double getAlertThreshold() => _alertThreshold;

  Future<void> updateSettings({
    bool? riskMonitoring,
    bool? predictiveAnalysis,
    bool? autoAlerts,
    double? alertThreshold,
  }) async {
    if (riskMonitoring != null) {
      _riskMonitoringEnabled = riskMonitoring;
      if (riskMonitoring) {
        _startContinuousMonitoring();
      } else {
        _monitoringTimer?.cancel();
      }
    }
    if (predictiveAnalysis != null) {
      _predictiveAnalysisEnabled = predictiveAnalysis;
    }
    if (autoAlerts != null) _autoAlertsEnabled = autoAlerts;
    if (alertThreshold != null) _alertThreshold = alertThreshold;
    await _saveSettings();
  }

  /// Storage methods
  Future<void> _loadAssessments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final assessmentsJson = prefs.getStringList(_assessmentsKey);
      if (assessmentsJson != null) {
        _assessments = assessmentsJson
            .map((str) => RiskAssessment.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load assessments error: $e');
    }
  }

  Future<void> _saveAssessments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final assessmentsJson =
      _assessments.map((a) => json.encode(a.toJson())).toList();
      await prefs.setStringList(_assessmentsKey, assessmentsJson);
    } catch (e) {
      debugPrint(' Save assessments error: $e');
    }
  }

  Future<void> _loadPredictions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final predictionsJson = prefs.getStringList(_predictionsKey);
      if (predictionsJson != null) {
        _predictions = predictionsJson
            .map((str) => ThreatPrediction.fromJson(json.decode(str)))
            .toList();
      }
    } catch (e) {
      debugPrint(' Load predictions error: $e');
    }
  }

  Future<void> _savePredictions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final predictionsJson =
      _predictions.map((p) => json.encode(p.toJson())).toList();
      await prefs.setStringList(_predictionsKey, predictionsJson);
    } catch (e) {
      debugPrint(' Save predictions error: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson != null) {
        final settings = json.decode(settingsJson);
        _riskMonitoringEnabled = settings['riskMonitoringEnabled'] ?? true;
        _predictiveAnalysisEnabled =
            settings['predictiveAnalysisEnabled'] ?? true;
        _autoAlertsEnabled = settings['autoAlertsEnabled'] ?? true;
        _alertThreshold = settings['alertThreshold'] ?? 70.0;
      }
    } catch (e) {
      debugPrint(' Load settings error: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = {
        'riskMonitoringEnabled': _riskMonitoringEnabled,
        'predictiveAnalysisEnabled': _predictiveAnalysisEnabled,
        'autoAlertsEnabled': _autoAlertsEnabled,
        'alertThreshold': _alertThreshold,
      };
      await prefs.setString(_settingsKey, json.encode(settings));
    } catch (e) {
      debugPrint(' Save settings error: $e');
    }
  }

  /// Dispose
  void dispose() {
    _monitoringTimer?.cancel();
  }
}