import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum SyncStatus {
  pending,
  syncing,
  synced,
  failed,
}

class OfflineData {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final SyncStatus status;
  final int retryCount;

  OfflineData({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.status = SyncStatus.pending,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString(),
      'retryCount': retryCount,
    };
  }

  factory OfflineData.fromMap(Map<String, dynamic> map) {
    return OfflineData(
      id: map['id'] as String,
      type: map['type'] as String,
      data: Map<String, dynamic>.from(map['data'] as Map),
      timestamp: DateTime.parse(map['timestamp'] as String),
      status: _parseStatus(map['status'] as String),
      retryCount: (map['retryCount'] as int?) ?? 0,
    );
  }

  static SyncStatus _parseStatus(String status) {
    switch (status.split('.').last) {
      case 'syncing':
        return SyncStatus.syncing;
      case 'synced':
        return SyncStatus.synced;
      case 'failed':
        return SyncStatus.failed;
      default:
        return SyncStatus.pending;
    }
  }

  OfflineData copyWith({
    SyncStatus? status,
    int? retryCount,
  }) {
    return OfflineData(
      id: id,
      type: type,
      data: data,
      timestamp: timestamp,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

class OfflineSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _offlineQueueKey = 'offline_queue';
  static const String _syncEnabledKey = 'sync_enabled';
  static const String _lastSyncKey = 'last_sync';
  static const int maxRetries = 3;

  // Check if sync is enabled
  Future<bool> isSyncEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_syncEnabledKey) ?? true;
    } catch (e) {
      debugPrint(' Check sync enabled error: $e');
      return true;
    }
  }

  // Enable/disable sync
  Future<bool> setSyncEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_syncEnabledKey, enabled);
      debugPrint(' Sync ${enabled ? "enabled" : "disabled"}');
      return true;
    } catch (e) {
      debugPrint(' Set sync enabled error: $e');
      return false;
    }
  }

  // Queue data for offline sync
  Future<bool> queueData({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = await _getQueue();

      final offlineData = OfflineData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        data: data,
        timestamp: DateTime.now(),
      );

      queue.add(offlineData);
      await _saveQueue(queue);

      debugPrint(' Data queued for sync: ${offlineData.id}');
      return true;
    } catch (e) {
      debugPrint(' Queue data error: $e');
      return false;
    }
  }

  // Get pending queue items
  Future<List<OfflineData>> getPendingQueue() async {
    try {
      final queue = await _getQueue();
      return queue.where((item) => item.status == SyncStatus.pending).toList();
    } catch (e) {
      debugPrint(' Get pending queue error: $e');
      return [];
    }
  }

  // Get all queue items
  Future<List<OfflineData>> getAllQueue() async {
    try {
      return await _getQueue();
    } catch (e) {
      debugPrint(' Get all queue error: $e');
      return [];
    }
  }

  // Sync all pending data
  Future<Map<String, dynamic>> syncAll() async {
    final syncEnabled = await isSyncEnabled();
    if (!syncEnabled) {
      return {
        'success': false,
        'message': 'Sync is disabled',
      };
    }

    try {
      final queue = await _getQueue();
      final pendingItems = queue.where((item) =>
      item.status == SyncStatus.pending ||
          (item.status == SyncStatus.failed && item.retryCount < maxRetries)
      ).toList();

      if (pendingItems.isEmpty) {
        return {
          'success': true,
          'synced': 0,
          'failed': 0,
          'message': 'No items to sync',
        };
      }

      int syncedCount = 0;
      int failedCount = 0;

      for (final item in pendingItems) {
        final success = await _syncItem(item);

        if (success) {
          syncedCount++;
          // Update item status to synced
          final index = queue.indexWhere((q) => q.id == item.id);
          if (index != -1) {
            queue[index] = item.copyWith(status: SyncStatus.synced);
          }
        } else {
          failedCount++;
          // Increment retry count
          final index = queue.indexWhere((q) => q.id == item.id);
          if (index != -1) {
            queue[index] = item.copyWith(
              status: SyncStatus.failed,
              retryCount: item.retryCount + 1,
            );
          }
        }
      }

      await _saveQueue(queue);
      await _updateLastSync();

      debugPrint(' Sync completed: $syncedCount synced, $failedCount failed');

      return {
        'success': true,
        'synced': syncedCount,
        'failed': failedCount,
        'total': pendingItems.length,
      };
    } catch (e) {
      debugPrint(' Sync all error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Sync individual item
  Future<bool> _syncItem(OfflineData item) async {
    try {
      switch (item.type) {
        case 'panic_event':
          await _firestore.collection('panic_events').add({
            ...item.data,
            'syncedAt': FieldValue.serverTimestamp(),
            'wasOffline': true,
          });
          break;

        case 'contact':
          final userId = item.data['userId'] as String;
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('contacts')
              .add(item.data);
          break;

        case 'battery_log':
          await _firestore.collection('battery_history').add(item.data);
          break;

        case 'location_log':
          await _firestore.collection('location_history').add(item.data);
          break;

        default:
          debugPrint(' Unknown sync type: ${item.type}');
          return false;
      }

      return true;
    } catch (e) {
      debugPrint(' Sync item error: $e');
      return false;
    }
  }

  // Clear synced items from queue
  Future<bool> clearSyncedItems() async {
    try {
      final queue = await _getQueue();
      final filteredQueue = queue.where((item) =>
      item.status != SyncStatus.synced
      ).toList();

      await _saveQueue(filteredQueue);
      debugPrint(' Cleared synced items');
      return true;
    } catch (e) {
      debugPrint(' Clear synced items error: $e');
      return false;
    }
  }

  // Get sync statistics
  Future<Map<String, dynamic>> getSyncStatistics() async {
    try {
      final queue = await _getQueue();
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString(_lastSyncKey);

      final pending = queue.where((item) => item.status == SyncStatus.pending).length;
      final synced = queue.where((item) => item.status == SyncStatus.synced).length;
      final failed = queue.where((item) => item.status == SyncStatus.failed).length;

      return {
        'totalItems': queue.length,
        'pending': pending,
        'synced': synced,
        'failed': failed,
        'lastSync': lastSync,
        'syncEnabled': await isSyncEnabled(),
      };
    } catch (e) {
      debugPrint(' Get sync statistics error: $e');
      return {};
    }
  }

  // Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_lastSyncKey);
      if (lastSyncStr != null) {
        return DateTime.parse(lastSyncStr);
      }
      return null;
    } catch (e) {
      debugPrint(' Get last sync time error: $e');
      return null;
    }
  }

  // Delete queue item
  Future<bool> deleteQueueItem(String id) async {
    try {
      final queue = await _getQueue();
      queue.removeWhere((item) => item.id == id);
      await _saveQueue(queue);
      debugPrint(' Queue item deleted: $id');
      return true;
    } catch (e) {
      debugPrint(' Delete queue item error: $e');
      return false;
    }
  }

  // Retry failed item
  Future<bool> retryFailedItem(String id) async {
    try {
      final queue = await _getQueue();
      final index = queue.indexWhere((item) => item.id == id);

      if (index == -1) return false;

      final item = queue[index];
      if (item.retryCount >= maxRetries) {
        debugPrint(' Max retries reached for item: $id');
        return false;
      }

      final success = await _syncItem(item);

      if (success) {
        queue[index] = item.copyWith(status: SyncStatus.synced);
      } else {
        queue[index] = item.copyWith(
          status: SyncStatus.failed,
          retryCount: item.retryCount + 1,
        );
      }

      await _saveQueue(queue);
      return success;
    } catch (e) {
      debugPrint(' Retry failed item error: $e');
      return false;
    }
  }

  // Private helper methods
  Future<List<OfflineData>> _getQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_offlineQueueKey);

      if (queueJson == null) return [];

      final List<dynamic> queueList = json.decode(queueJson);
      return queueList.map((item) => OfflineData.fromMap(item)).toList();
    } catch (e) {
      debugPrint(' Get queue error: $e');
      return [];
    }
  }

  Future<void> _saveQueue(List<OfflineData> queue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = json.encode(queue.map((item) => item.toMap()).toList());
      await prefs.setString(_offlineQueueKey, queueJson);
    } catch (e) {
      debugPrint(' Save queue error: $e');
    }
  }

  Future<void> _updateLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint(' Update last sync error: $e');
    }
  }

  // Get sync status icon
  static String getSyncStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.pending:
        return ' ';
      case SyncStatus.syncing:
        return ' ';
      case SyncStatus.synced:
        return ' ';
      case SyncStatus.failed:
        return ' ';
    }
  }

  // Get sync status label
  static String getSyncStatusLabel(SyncStatus status) {
    switch (status) {
      case SyncStatus.pending:
        return 'Pending';
      case SyncStatus.syncing:
        return 'Syncing';
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.failed:
        return 'Failed';
    }
  }

  // Get sync status color
  static String getSyncStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.pending:
        return '#FF9800'; // Orange
      case SyncStatus.syncing:
        return '#2196F3'; // Blue
      case SyncStatus.synced:
        return '#4CAF50'; // Green
      case SyncStatus.failed:
        return '#F44336'; // Red
    }
  }
}