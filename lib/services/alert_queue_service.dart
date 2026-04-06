import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// ==================== ALERT QUEUE SERVICE ====================
///
/// Queue and store emergency alerts when offline
///
/// FEATURES:
/// - Offline alert storage
/// - Auto-send when online
/// - Queue management
/// - Priority handling
/// - Persistent storage
///
/// =============================================================

class AlertQueueService {
  bool _isInitialized = false;
  final List<QueuedAlert> _queue = [];
  static const String _queueKey = 'emergency_alert_queue';

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      await _loadQueue();

      _isInitialized = true;
      debugPrint(' Alert Queue Service initialized');
      debugPrint(' Queued alerts: ${_queue.length}');
    } catch (e) {
      debugPrint(' Alert Queue init error: $e');
    }
  }

  // ==================== QUEUE MANAGEMENT ====================

  Future<void> addToQueue(Map<String, dynamic> alertData, {bool priority = false}) async {
    try {
      final alert = QueuedAlert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        data: alertData,
        queuedAt: DateTime.now(),
        priority: priority,
        retryCount: 0,
      );

      if (priority) {
        _queue.insert(0, alert);
      } else {
        _queue.add(alert);
      }

      await _saveQueue();

      debugPrint(' Alert added to queue (Priority: $priority)');
      debugPrint(' Queue size: ${_queue.length}');
    } catch (e) {
      debugPrint(' Add to queue error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getQueuedAlerts() async {
    try {
      return _queue.map((alert) => alert.data).toList();
    } catch (e) {
      debugPrint(' Get queued alerts error: $e');
      return [];
    }
  }

  Future<int> getQueuedAlertsCount() async {
    return _queue.length;
  }

  Future<void> removeFromQueue(String alertId) async {
    try {
      _queue.removeWhere((alert) => alert.id == alertId);
      await _saveQueue();

      debugPrint(' Alert removed from queue: $alertId');
      debugPrint(' Queue size: ${_queue.length}');
    } catch (e) {
      debugPrint(' Remove from queue error: $e');
    }
  }

  Future<void> clearQueue() async {
    try {
      _queue.clear();
      await _saveQueue();

      debugPrint(' Alert queue cleared');
    } catch (e) {
      debugPrint(' Clear queue error: $e');
    }
  }

  // ==================== RETRY MANAGEMENT ====================

  Future<void> incrementRetryCount(String alertId) async {
    try {
      final alert = _queue.firstWhere((a) => a.id == alertId);
      alert.retryCount++;
      alert.lastRetryAt = DateTime.now();

      await _saveQueue();

      debugPrint(' Retry count incremented for alert: $alertId (${alert.retryCount})');
    } catch (e) {
      debugPrint(' Increment retry error: $e');
    }
  }

  Future<List<QueuedAlert>> getAlertsForRetry({int maxRetries = 5}) async {
    try {
      return _queue.where((alert) => alert.retryCount < maxRetries).toList();
    } catch (e) {
      debugPrint(' Get retry alerts error: $e');
      return [];
    }
  }

  // ==================== PERSISTENCE ====================

  Future<void> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);

      if (queueJson != null) {
        final List<dynamic> queueList = jsonDecode(queueJson);
        _queue.clear();

        for (final alertData in queueList) {
          _queue.add(QueuedAlert.fromJson(alertData));
        }

        debugPrint(' Loaded ${_queue.length} queued alerts');
      }
    } catch (e) {
      debugPrint(' Load queue error: $e');
    }
  }

  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = jsonEncode(
          _queue.map((alert) => alert.toJson()).toList()
      );

      await prefs.setString(_queueKey, queueJson);
    } catch (e) {
      debugPrint(' Save queue error: $e');
    }
  }

  // ==================== QUEUE STATISTICS ====================

  int get totalQueued => _queue.length;

  int get priorityQueued => _queue.where((alert) => alert.priority).length;

  DateTime? get oldestAlert => _queue.isEmpty
      ? null
      : _queue.map((a) => a.queuedAt).reduce((a, b) => a.isBefore(b) ? a : b);

  DateTime? get newestAlert => _queue.isEmpty
      ? null
      : _queue.map((a) => a.queuedAt).reduce((a, b) => a.isAfter(b) ? a : b);

  // ==================== STATUS ====================

  bool get isInitialized => _isInitialized;
  bool get hasQueuedAlerts => _queue.isNotEmpty;

  // ==================== DISPOSE ====================

  void dispose() {
    _isInitialized = false;
    debugPrint(' Alert Queue Service disposed');
  }
}

// ==================== QUEUED ALERT MODEL ====================

class QueuedAlert {
  final String id;
  final Map<String, dynamic> data;
  final DateTime queuedAt;
  final bool priority;
  int retryCount;
  DateTime? lastRetryAt;

  QueuedAlert({
    required this.id,
    required this.data,
    required this.queuedAt,
    this.priority = false,
    this.retryCount = 0,
    this.lastRetryAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'data': data,
    'queuedAt': queuedAt.toIso8601String(),
    'priority': priority,
    'retryCount': retryCount,
    'lastRetryAt': lastRetryAt?.toIso8601String(),
  };

  factory QueuedAlert.fromJson(Map<String, dynamic> json) => QueuedAlert(
    id: json['id'],
    data: Map<String, dynamic>.from(json['data']),
    queuedAt: DateTime.parse(json['queuedAt']),
    priority: json['priority'] ?? false,
    retryCount: json['retryCount'] ?? 0,
    lastRetryAt: json['lastRetryAt'] != null
        ? DateTime.parse(json['lastRetryAt'])
        : null,
  );
}