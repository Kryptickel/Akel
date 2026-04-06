import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class AIThreatAssessmentService {
  static final AIThreatAssessmentService _instance = AIThreatAssessmentService._internal();
  factory AIThreatAssessmentService() => _instance;
  AIThreatAssessmentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// Threat levels
  static const Map<String, Map<String, dynamic>> threatLevels = {
    'minimal': {
      'level': 0,
      'name': 'Minimal',
      'color': 0xFF4CAF50, // Green
      'icon': Icons.check_circle,
      'description': 'Low risk situation',
    },
    'low': {
      'level': 1,
      'name': 'Low',
      'color': 0xFF8BC34A, // Light Green
      'icon': Icons.info,
      'description': 'Some caution advised',
    },
    'moderate': {
      'level': 2,
      'name': 'Moderate',
      'color': 0xFFFFEB3B, // Yellow
      'icon': Icons.warning,
      'description': 'Increased vigilance needed',
    },
    'elevated': {
      'level': 3,
      'name': 'Elevated',
      'color': 0xFFFF9800, // Orange
      'icon': Icons.priority_high,
      'description': 'Significant risk present',
    },
    'high': {
      'level': 4,
      'name': 'High',
      'color': 0xFFFF5722, // Deep Orange
      'icon': Icons.warning_amber,
      'description': 'Dangerous situation',
    },
    'critical': {
      'level': 5,
      'name': 'Critical',
      'color': 0xFFF44336, // Red
      'icon': Icons.emergency,
      'description': 'Immediate danger - act now',
    },
  };

// Threat categories
  static const List<String> threatCategories = [
    'Personal Safety',
    'Medical Emergency',
    'Natural Disaster',
    'Crime/Violence',
    'Accident',
    'Fire',
    'Environmental Hazard',
    'Suspicious Activity',
    'Other',
  ];

  /// Assess threat level based on multiple factors
  Future<Map<String, dynamic>> assessThreat({
    required String category,
    required String description,
    required Position? location,
    Map<String, dynamic>? additionalFactors,
  }) async {
    try {
      debugPrint('🤖 AI: Assessing threat...');

// Simulate AI processing delay
      await Future.delayed(const Duration(milliseconds: 1500));

// Calculate threat score based on multiple factors
      int threatScore = 0;
      final List<String> factors = [];
      final List<String> recommendations = [];

// 1. Category-based scoring
      threatScore += _getCategoryScore(category);
      factors.add('Category: $category');

// 2. Description analysis (keyword detection)
      final descriptionScore = _analyzeDescription(description);
      threatScore += descriptionScore['score'] as int;
      if (descriptionScore['keywords'] != null) {
        factors.addAll(descriptionScore['keywords'] as List<String>);
      }

// 3. Location-based factors
      if (location != null) {
        final locationScore = await _analyzeLocation(location);
        threatScore += locationScore['score'] as int;
        if (locationScore['factors'] != null) {
          factors.addAll(locationScore['factors'] as List<String>);
        }
      }

// 4. Time-based factors
      final timeScore = _analyzeTimeOfDay();
      threatScore += timeScore['score'] as int;
      factors.add(timeScore['factor'] as String);

// 5. Additional factors
      if (additionalFactors != null) {
        threatScore += _analyzeAdditionalFactors(additionalFactors);
      }

// Determine threat level (0-100 scale mapped to levels)
      final threatLevel = _calculateThreatLevel(threatScore);

// Generate recommendations
      recommendations.addAll(_generateRecommendations(
        threatLevel: threatLevel,
        category: category,
        factors: factors,
      ));

// Generate emergency contacts recommendation
      final shouldContactEmergency = threatScore >= 60;

      final assessment = {
        'threatLevel': threatLevel,
        'threatScore': threatScore,
        'category': category,
        'factors': factors,
        'recommendations': recommendations,
        'shouldContactEmergency': shouldContactEmergency,
        'emergencyServices': _getRecommendedEmergencyServices(category, threatScore),
        'assessedAt': DateTime.now().toIso8601String(),
        'confidence': _calculateConfidence(factors.length),
      };

      debugPrint('✅ AI: Threat assessed - Level: $threatLevel, Score: $threatScore');

// Save assessment to history
      await _saveAssessment(assessment);

      return assessment;
    } catch (e) {
      debugPrint('❌ AI: Assessment error: $e');

// Return safe default assessment
      return {
        'threatLevel': 'moderate',
        'threatScore': 50,
        'category': category,
        'factors': ['Unable to complete full assessment'],
        'recommendations': ['Stay alert', 'Seek help if needed'],
        'shouldContactEmergency': false,
        'emergencyServices': [],
        'assessedAt': DateTime.now().toIso8601String(),
        'confidence': 'low',
      };
    }
  }

  /// Get category base score
  int _getCategoryScore(String category) {
    switch (category) {
      case 'Medical Emergency':
        return 40;
      case 'Crime/Violence':
        return 45;
      case 'Natural Disaster':
        return 50;
      case 'Fire':
        return 45;
      case 'Accident':
        return 35;
      case 'Environmental Hazard':
        return 30;
      case 'Suspicious Activity':
        return 25;
      case 'Personal Safety':
        return 30;
      default:
        return 20;
    }
  }

  /// Analyze description for keywords
  Map<String, dynamic> _analyzeDescription(String description) {
    final lowerDesc = description.toLowerCase();
    int score = 0;
    final List<String> keywords = [];

// High-risk keywords
    final highRiskWords = [
      'weapon', 'gun', 'knife', 'attack', 'assault', 'blood', 'unconscious',
      'fire', 'explosion', 'shooting', 'stabbing', 'robbery', 'kidnap',
      'earthquake', 'flood', 'tornado', 'hurricane', 'emergency'
    ];

// Medium-risk keywords
    final mediumRiskWords = [
      'threatening', 'suspicious', 'following', 'scared', 'injured', 'hurt',
      'accident', 'crash', 'danger', 'help', 'chase', 'yelling', 'fight'
    ];

// Low-risk keywords
    final lowRiskWords = [
      'lost', 'confused', 'uncomfortable', 'worried', 'concern', 'unsure'
    ];

    for (final word in highRiskWords) {
      if (lowerDesc.contains(word)) {
        score += 15;
        keywords.add('High-risk: $word detected');
      }
    }

    for (final word in mediumRiskWords) {
      if (lowerDesc.contains(word)) {
        score += 8;
        keywords.add('Medium-risk: $word detected');
      }
    }

    for (final word in lowRiskWords) {
      if (lowerDesc.contains(word)) {
        score += 3;
        keywords.add('Low-risk: $word detected');
      }
    }

    return {
      'score': score,
      'keywords': keywords.isEmpty ? null : keywords,
    };
  }

  /// Analyze location factors
  Future<Map<String, dynamic>> _analyzeLocation(Position location) async {
    int score = 0;
    final List<String> factors = [];

// Check accuracy (poor accuracy might indicate remote area)
    if (location.accuracy > 50) {
      score += 5;
      factors.add('Remote or uncertain location');
    }

// Check altitude (extreme altitudes can be risky)
    if (location.altitude < -100 || location.altitude > 2000) {
      score += 5;
      factors.add('Unusual altitude detected');
    }

// In a real implementation, you would:
// - Check against crime databases
// - Analyze neighborhood safety ratings
// - Check for recent incidents nearby
// - Consider population density

    return {
      'score': score,
      'factors': factors.isEmpty ? null : factors,
    };
  }

  /// Analyze time of day
  Map<String, dynamic> _analyzeTimeOfDay() {
    final hour = DateTime.now().hour;
    int score = 0;
    String factor;

    if (hour >= 22 || hour < 6) {
// Late night/early morning - higher risk
      score = 10;
      factor = 'Late night/early morning period';
    } else if (hour >= 18 && hour < 22) {
// Evening - moderate risk
      score = 5;
      factor = 'Evening hours';
    } else {
// Daytime - lower risk
      score = 0;
      factor = 'Daytime hours';
    }

    return {
      'score': score,
      'factor': factor,
    };
  }

  /// Analyze additional factors
  int _analyzeAdditionalFactors(Map<String, dynamic> factors) {
    int score = 0;

    if (factors['isAlone'] == true) score += 10;
    if (factors['hasNoPhone'] == true) score += 15;
    if (factors['unfamiliarArea'] == true) score += 8;
    if (factors['feelingUnsafe'] == true) score += 12;
    if (factors['cannotLeave'] == true) score += 20;

    return score;
  }

  /// Calculate threat level from score
  String _calculateThreatLevel(int score) {
    if (score >= 80) return 'critical';
    if (score >= 65) return 'high';
    if (score >= 50) return 'elevated';
    if (score >= 35) return 'moderate';
    if (score >= 20) return 'low';
    return 'minimal';
  }

  /// Generate recommendations
  List<String> _generateRecommendations({
    required String threatLevel,
    required String category,
    required List<String> factors,
  }) {
    final recommendations = <String>[];

// Critical level recommendations
    if (threatLevel == 'critical') {
      recommendations.add('🚨 Call emergency services immediately (911)');
      recommendations.add('Leave the area if safe to do so');
      recommendations.add('Alert emergency contacts now');
      recommendations.add('Find a safe location');
      recommendations.add('Do not confront the threat');
    }
// High level recommendations
    else if (threatLevel == 'high') {
      recommendations.add('⚠️ Strongly consider calling emergency services');
      recommendations.add('Alert trusted contacts immediately');
      recommendations.add('Move to a safer location');
      recommendations.add('Stay in public/well-lit areas');
      recommendations.add('Keep your phone accessible');
    }
// Elevated level recommendations
    else if (threatLevel == 'elevated') {
      recommendations.add('Stay alert and aware of surroundings');
      recommendations.add('Keep emergency contacts ready');
      recommendations.add('Avoid isolated areas');
      recommendations.add('Trust your instincts');
      recommendations.add('Have an exit plan ready');
    }
// Moderate level recommendations
    else if (threatLevel == 'moderate') {
      recommendations.add('Maintain situational awareness');
      recommendations.add('Share your location with contacts');
      recommendations.add('Stay in populated areas if possible');
      recommendations.add('Keep communication device charged');
    }
// Low level recommendations
    else {
      recommendations.add('Continue normal precautions');
      recommendations.add('Stay aware of your environment');
      recommendations.add('Keep emergency app accessible');
    }

// Category-specific recommendations
    if (category == 'Medical Emergency') {
      recommendations.add('💊 Seek immediate medical attention');
      recommendations.add('Do not drive yourself if serious');
    } else if (category == 'Natural Disaster') {
      recommendations.add('🌪️ Follow official emergency guidelines');
      recommendations.add('Seek shelter immediately');
    } else if (category == 'Fire') {
      recommendations.add('🔥 Evacuate immediately');
      recommendations.add('Do not use elevators');
      recommendations.add('Stay low if there is smoke');
    }

    return recommendations;
  }

  /// Get recommended emergency services
  List<String> _getRecommendedEmergencyServices(String category, int score) {
    final services = <String>[];

    if (score >= 60) {
      services.add('911 Emergency');
    }

    switch (category) {
      case 'Medical Emergency':
        services.addAll(['Ambulance', 'Hospital']);
        break;
      case 'Crime/Violence':
        services.addAll(['Police', '911']);
        break;
      case 'Fire':
        services.addAll(['Fire Department', '911']);
        break;
      case 'Natural Disaster':
        services.addAll(['Emergency Management', '911']);
        break;
      case 'Accident':
        services.addAll(['Police', 'Ambulance']);
        break;
    }

    return services.toSet().toList(); // Remove duplicates
  }

  /// Calculate confidence level
  String _calculateConfidence(int factorCount) {
    if (factorCount >= 5) return 'high';
    if (factorCount >= 3) return 'medium';
    return 'low';
  }

  /// Save assessment to history
  Future<void> _saveAssessment(Map<String, dynamic> assessment) async {
    try {
      await _firestore.collection('threat_assessments').add({
        ...assessment,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Save assessment error: $e');
    }
  }

  /// Get assessment history
  Future<List<Map<String, dynamic>>> getAssessmentHistory({
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('threat_assessments')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Get assessment history error: $e');
      return [];
    }
  }

  /// Get threat level data
  static Map<String, dynamic> getThreatLevelData(String level) {
    return threatLevels[level] ?? threatLevels['moderate']!;
  }

  /// Get threat level color
  static Color getThreatLevelColor(String level) {
    final data = getThreatLevelData(level);
    return Color(data['color'] as int);
  }

  /// Get threat level icon
  static IconData getThreatLevelIcon(String level) {
    final data = getThreatLevelData(level);
    return data['icon'] as IconData;
  }

  /// Quick assess (simplified version)
  Future<Map<String, dynamic>> quickAssess(String situation) async {
    return await assessThreat(
      category: 'Personal Safety',
      description: situation,
      location: null,
    );
  }
}