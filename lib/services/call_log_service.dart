import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum CallOutcome { answered, missed, failed, busy, noAnswer }
enum CallType { manual, autoCall, emergency }

class CallLogEntry {
  final String id;
  final String userId;
  final String contactName;
  final String contactPhone;
  final DateTime timestamp;
  final CallOutcome outcome;
  final CallType type;
  final int durationSeconds;
  final String? panicEventId;
  final String? notes;

  CallLogEntry({
    required this.id,
    required this.userId,
    required this.contactName,
    required this.contactPhone,
    required this.timestamp,
    required this.outcome,
    required this.type,
    this.durationSeconds = 0,
    this.panicEventId,
    this.notes,
  });

  factory CallLogEntry.fromMap(Map<String, dynamic> map, String id) {
    return CallLogEntry(
      id: id,
      userId: map['userId'] ?? '',
      contactName: map['contactName'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      outcome: _outcomeFromString(map['outcome'] ?? 'failed'),
      type: _typeFromString(map['type'] ?? 'manual'),
      durationSeconds: map['durationSeconds'] ?? 0,
      panicEventId: map['panicEventId'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'timestamp': FieldValue.serverTimestamp(),
      'outcome': _outcomeToString(outcome),
      'type': _typeToString(type),
      'durationSeconds': durationSeconds,
      'panicEventId': panicEventId,
      'notes': notes,
    };
  }

  static CallOutcome _outcomeFromString(String outcome) {
    switch (outcome.toLowerCase()) {
      case 'answered':
        return CallOutcome.answered;
      case 'missed':
        return CallOutcome.missed;
      case 'busy':
        return CallOutcome.busy;
      case 'noanswer':
        return CallOutcome.noAnswer;
      default:
        return CallOutcome.failed;
    }
  }

  static String _outcomeToString(CallOutcome outcome) {
    switch (outcome) {
      case CallOutcome.answered:
        return 'answered';
      case CallOutcome.missed:
        return 'missed';
      case CallOutcome.busy:
        return 'busy';
      case CallOutcome.noAnswer:
        return 'noAnswer';
      case CallOutcome.failed:
        return 'failed';
    }
  }

  static CallType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'autocall':
        return CallType.autoCall;
      case 'emergency':
        return CallType.emergency;
      default:
        return CallType.manual;
    }
  }

  static String _typeToString(CallType type) {
    switch (type) {
      case CallType.autoCall:
        return 'autoCall';
      case CallType.emergency:
        return 'emergency';
      case CallType.manual:
        return 'manual';
    }
  }
}

class CallLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// Log a call
  Future<String> logCall({
    required String userId,
    required String contactName,
    required String contactPhone,
    required CallOutcome outcome,
    required CallType type,
    int durationSeconds = 0,
    String? panicEventId,
    String? notes,
  }) async {
    try {
      final entry = CallLogEntry(
        id: '',
        userId: userId,
        contactName: contactName,
        contactPhone: contactPhone,
        timestamp: DateTime.now(),
        outcome: outcome,
        type: type,
        durationSeconds: durationSeconds,
        panicEventId: panicEventId,
        notes: notes,
      );

      final docRef = await _firestore.collection('call_logs').add(entry.toMap());

      debugPrint('✅ Call logged: $contactName ($outcome)');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Log call error: $e');
      rethrow;
    }
  }

// Get all call logs for user
  Future<List<CallLogEntry>> getCallLogs(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('call_logs')
          .where('userId', isEqualTo: userId)
          .get();

      final logs = snapshot.docs.map((doc) {
        return CallLogEntry.fromMap(doc.data(), doc.id);
      }).toList();

// Sort by timestamp descending
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return logs;
    } catch (e) {
      debugPrint('❌ Get call logs error: $e');
      return [];
    }
  }

// Get call logs by date range
  Future<List<CallLogEntry>> getCallLogsByDateRange(
      String userId,
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      final snapshot = await _firestore
          .collection('call_logs')
          .where('userId', isEqualTo: userId)
          .get();

      final logs = snapshot.docs.map((doc) {
        return CallLogEntry.fromMap(doc.data(), doc.id);
      }).where((log) {
        return log.timestamp.isAfter(startDate) &&
            log.timestamp.isBefore(endDate);
      }).toList();

      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return logs;
    } catch (e) {
      debugPrint('❌ Get call logs by date error: $e');
      return [];
    }
  }

// Get call logs for specific panic event
  Future<List<CallLogEntry>> getCallLogsForEvent(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('call_logs')
          .where('panicEventId', isEqualTo: eventId)
          .get();

      final logs = snapshot.docs.map((doc) {
        return CallLogEntry.fromMap(doc.data(), doc.id);
      }).toList();

      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return logs;
    } catch (e) {
      debugPrint('❌ Get call logs for event error: $e');
      return [];
    }
  }

// Get call statistics
  Future<Map<String, dynamic>> getCallStatistics(String userId) async {
    try {
      final logs = await getCallLogs(userId);

      if (logs.isEmpty) {
        return {
          'totalCalls': 0,
          'answeredCalls': 0,
          'missedCalls': 0,
          'failedCalls': 0,
          'successRate': 0.0,
          'totalDuration': 0,
          'averageDuration': 0.0,
          'autoCallCount': 0,
          'manualCallCount': 0,
          'emergencyCallCount': 0,
        };
      }

      final totalCalls = logs.length;
      final answeredCalls = logs.where((l) => l.outcome == CallOutcome.answered).length;
      final missedCalls = logs.where((l) => l.outcome == CallOutcome.missed).length;
      final failedCalls = logs.where((l) => l.outcome == CallOutcome.failed).length;
      final busyCalls = logs.where((l) => l.outcome == CallOutcome.busy).length;
      final noAnswerCalls = logs.where((l) => l.outcome == CallOutcome.noAnswer).length;

      final successRate = (answeredCalls / totalCalls * 100);

      final totalDuration = logs.fold<int>(0, (sum, log) => sum + log.durationSeconds);
      final averageDuration = answeredCalls > 0
          ? totalDuration / answeredCalls
          : 0.0;

      final autoCallCount = logs.where((l) => l.type == CallType.autoCall).length;
      final manualCallCount = logs.where((l) => l.type == CallType.manual).length;
      final emergencyCallCount = logs.where((l) => l.type == CallType.emergency).length;

// This week stats
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final thisWeekCalls = logs.where((l) => l.timestamp.isAfter(weekAgo)).length;

// This month stats
      final monthStart = DateTime(now.year, now.month, 1);
      final thisMonthCalls = logs.where((l) => l.timestamp.isAfter(monthStart)).length;

      return {
        'totalCalls': totalCalls,
        'answeredCalls': answeredCalls,
        'missedCalls': missedCalls,
        'failedCalls': failedCalls,
        'busyCalls': busyCalls,
        'noAnswerCalls': noAnswerCalls,
        'successRate': successRate,
        'totalDuration': totalDuration,
        'averageDuration': averageDuration,
        'autoCallCount': autoCallCount,
        'manualCallCount': manualCallCount,
        'emergencyCallCount': emergencyCallCount,
        'thisWeekCalls': thisWeekCalls,
        'thisMonthCalls': thisMonthCalls,
      };
    } catch (e) {
      debugPrint('❌ Get call statistics error: $e');
      return {};
    }
  }

// Export call logs as CSV
  String exportCallLogsAsCSV(List<CallLogEntry> logs) {
    final buffer = StringBuffer();

// Header
    buffer.writeln('Date,Time,Contact,Phone,Outcome,Type,Duration (seconds),Notes');

// Data
    for (final log in logs) {
      final date = '${log.timestamp.year}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')}';
      final time = '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}';
      final contact = _escapeCsv(log.contactName);
      final phone = _escapeCsv(log.contactPhone);
      final outcome = _formatOutcome(log.outcome);
      final type = _formatType(log.type);
      final duration = log.durationSeconds.toString();
      final notes = _escapeCsv(log.notes ?? '');

      buffer.writeln('$date,$time,$contact,$phone,$outcome,$type,$duration,$notes');
    }

    return buffer.toString();
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _formatOutcome(CallOutcome outcome) {
    switch (outcome) {
      case CallOutcome.answered:
        return 'Answered';
      case CallOutcome.missed:
        return 'Missed';
      case CallOutcome.busy:
        return 'Busy';
      case CallOutcome.noAnswer:
        return 'No Answer';
      case CallOutcome.failed:
        return 'Failed';
    }
  }

  String _formatType(CallType type) {
    switch (type) {
      case CallType.autoCall:
        return 'Auto-Call';
      case CallType.emergency:
        return 'Emergency';
      case CallType.manual:
        return 'Manual';
    }
  }

// Get outcome icon
  static String getOutcomeIcon(CallOutcome outcome) {
    switch (outcome) {
      case CallOutcome.answered:
        return '✅';
      case CallOutcome.missed:
        return '⚠️';
      case CallOutcome.busy:
        return '📵';
      case CallOutcome.noAnswer:
        return '🔇';
      case CallOutcome.failed:
        return '❌';
    }
  }

// Get outcome color
  static String getOutcomeColor(CallOutcome outcome) {
    switch (outcome) {
      case CallOutcome.answered:
        return '#4CAF50'; // Green
      case CallOutcome.missed:
        return '#FF9800'; // Orange
      case CallOutcome.busy:
        return '#FFC107'; // Amber
      case CallOutcome.noAnswer:
        return '#9E9E9E'; // Grey
      case CallOutcome.failed:
        return '#F44336'; // Red
    }
  }

// Get type icon
  static String getTypeIcon(CallType type) {
    switch (type) {
      case CallType.autoCall:
        return '🤖';
      case CallType.emergency:
        return '🚨';
      case CallType.manual:
        return '📞';
    }
  }

// Delete call log
  Future<bool> deleteCallLog(String logId) async {
    try {
      await _firestore.collection('call_logs').doc(logId).delete();
      debugPrint('✅ Call log deleted: $logId');
      return true;
    } catch (e) {
      debugPrint('❌ Delete call log error: $e');
      return false;
    }
  }

// Clear all call logs for user
  Future<bool> clearAllCallLogs(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('call_logs')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint('✅ All call logs cleared for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Clear call logs error: $e');
      return false;
    }
  }

// Format duration for display
  String formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }
}