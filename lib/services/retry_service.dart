import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

enum RetryStatus {
  pending,
  retrying,
  success,
  failed,
  maxRetriesReached,
}

class RetryAttempt {
  final String id;
  final String userId;
  final String contactId;
  final String contactName;
  final String phoneNumber;
  final String message;
  int attemptNumber; // CHANGED: Removed 'final'
  final int maxAttempts;
  DateTime scheduledTime; // CHANGED: Removed 'final'
  final DateTime createdAt;
  RetryStatus status;
  String? errorMessage;

  RetryAttempt({
    required this.id,
    required this.userId,
    required this.contactId,
    required this.contactName,
    required this.phoneNumber,
    required this.message,
    required this.attemptNumber,
    required this.maxAttempts,
    required this.scheduledTime,
    required this.createdAt,
    this.status = RetryStatus.pending,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'contactId': contactId,
      'contactName': contactName,
      'phoneNumber': phoneNumber,
      'message': message,
      'attemptNumber': attemptNumber,
      'maxAttempts': maxAttempts,
      'scheduledTime': scheduledTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'status': status.toString(),
      'errorMessage': errorMessage,
    };
  }

  factory RetryAttempt.fromMap(Map<String, dynamic> map) {
    return RetryAttempt(
      id: map['id'],
      userId: map['userId'],
      contactId: map['contactId'],
      contactName: map['contactName'],
      phoneNumber: map['phoneNumber'],
      message: map['message'],
      attemptNumber: map['attemptNumber'],
      maxAttempts: map['maxAttempts'],
      scheduledTime: DateTime.parse(map['scheduledTime']),
      createdAt: DateTime.parse(map['createdAt']),
      status: RetryStatus.values.firstWhere(
            (e) => e.toString() == map['status'],
        orElse: () => RetryStatus.pending,
      ),
      errorMessage: map['errorMessage'],
    );
  }
}

class RetryService {
  static final RetryService _instance = RetryService._internal();
  factory RetryService() => _instance;
  RetryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<RetryAttempt> _retryQueue = [];
  Timer? _retryTimer;
  bool _isProcessing = false;

  // CHANGED: lowerCamelCase naming
  static const List<int> _backoffDelays = [
    30, // 30 seconds (attempt 1)
    60, // 1 minute (attempt 2)
    300, // 5 minutes (attempt 3)
    900, // 15 minutes (attempt 4)
    1800, // 30 minutes (attempt 5)
  ];

  static const int maxRetries = 5; // CHANGED: lowerCamelCase

  // Queue a failed alert for retry
  Future<String> queueRetry({
    required String userId,
    required String contactId,
    required String contactName,
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final retryId = DateTime.now().millisecondsSinceEpoch.toString();
      final scheduledTime = DateTime.now().add(Duration(seconds: _backoffDelays[0]));

      final retry = RetryAttempt(
        id: retryId,
        userId: userId,
        contactId: contactId,
        contactName: contactName,
        phoneNumber: phoneNumber,
        message: message,
        attemptNumber: 1,
        maxAttempts: maxRetries,
        scheduledTime: scheduledTime,
        createdAt: DateTime.now(),
        status: RetryStatus.pending,
      );

      _retryQueue.add(retry);

      await _firestore
          .collection('retry_queue')
          .doc(retryId)
          .set(retry.toMap());

      print(' Queued retry for $contactName - Scheduled at ${scheduledTime.toString()}');

      _startRetryProcessor();

      return retryId;
    } catch (e) {
      print(' Error queueing retry: $e');
      rethrow;
    }
  }

  // Calculate next retry delay with exponential backoff
  Duration _getNextRetryDelay(int attemptNumber) {
    if (attemptNumber >= _backoffDelays.length) {
      return Duration(seconds: _backoffDelays.last);
    }
    return Duration(seconds: _backoffDelays[attemptNumber]);
  }

  // Start the retry processor
  void _startRetryProcessor() {
    if (_retryTimer != null && _retryTimer!.isActive) {
      return;
    }

    print(' Starting retry processor...');

    _retryTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _processRetryQueue();
    });
  }

  // Process retry queue
  Future<void> _processRetryQueue() async {
    if (_isProcessing) return;

    _isProcessing = true;

    try {
      final now = DateTime.now();
      final dueRetries = _retryQueue.where((retry) =>
      retry.status == RetryStatus.pending &&
          retry.scheduledTime.isBefore(now)
      ).toList();

      if (dueRetries.isEmpty) {
        print(' No retries due at this time');
        return;
      }

      print(' Processing ${dueRetries.length} due retries...');

      for (final retry in dueRetries) {
        await _executeRetry(retry);

        await Future.delayed(const Duration(milliseconds: 500));
      }

    } catch (e) {
      print(' Error processing retry queue: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // Execute a single retry attempt
  Future<void> _executeRetry(RetryAttempt retry) async {
    try {
      print(' Attempting retry ${retry.attemptNumber}/${retry.maxAttempts} for ${retry.contactName}');

      retry.status = RetryStatus.retrying;
      await _updateRetryInFirestore(retry);

      final success = await _attemptSend(retry);

      if (success) {
        print(' Retry successful for ${retry.contactName}');
        retry.status = RetryStatus.success;
        _retryQueue.remove(retry);
        await _updateRetryInFirestore(retry);

        await _logRetryResult(retry, true);

      } else {
        print(' Retry failed for ${retry.contactName}');

        if (retry.attemptNumber >= retry.maxAttempts) {
          print(' Max retries reached for ${retry.contactName}');
          retry.status = RetryStatus.maxRetriesReached;
          _retryQueue.remove(retry);
          await _updateRetryInFirestore(retry);

          await _logRetryResult(retry, false);

        } else {
          retry.attemptNumber++;
          retry.scheduledTime = DateTime.now().add(_getNextRetryDelay(retry.attemptNumber - 1));
          retry.status = RetryStatus.pending;

          await _updateRetryInFirestore(retry);

          print(' Next retry scheduled for ${retry.scheduledTime.toString()}');
        }
      }

    } catch (e) {
      print(' Error executing retry: $e');
      retry.errorMessage = e.toString();
      retry.status = RetryStatus.failed;
      await _updateRetryInFirestore(retry);
    }
  }

  // Simulate sending (replace with actual SMS/Call logic)
  Future<bool> _attemptSend(RetryAttempt retry) async {
    try {
      await Future.delayed(const Duration(milliseconds: 1000));

      // Simulate 70% success rate for testing
      final success = DateTime.now().millisecond % 10 < 7;

      return success;

    } catch (e) {
      print(' Send attempt error: $e');
      return false;
    }
  }

  // Update retry in Firestore
  Future<void> _updateRetryInFirestore(RetryAttempt retry) async {
    try {
      await _firestore
          .collection('retry_queue')
          .doc(retry.id)
          .update(retry.toMap());
    } catch (e) {
      print(' Error updating retry in Firestore: $e');
    }
  }

  // Log retry result
  Future<void> _logRetryResult(RetryAttempt retry, bool success) async {
    try {
      await _firestore.collection('retry_logs').add({
        'retryId': retry.id,
        'userId': retry.userId,
        'contactName': retry.contactName,
        'phoneNumber': retry.phoneNumber,
        'totalAttempts': retry.attemptNumber,
        'success': success,
        'finalStatus': retry.status.toString(),
        'createdAt': retry.createdAt.toIso8601String(),
        'completedAt': DateTime.now().toIso8601String(),
        'duration': DateTime.now().difference(retry.createdAt).inSeconds,
      });
    } catch (e) {
      print(' Error logging retry result: $e');
    }
  }

  // Load retry queue from Firestore
  Future<void> loadRetryQueue(String userId) async {
    try {
      print(' Loading retry queue from Firestore...');

      final snapshot = await _firestore
          .collection('retry_queue')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: RetryStatus.pending.toString())
          .get();

      _retryQueue.clear();

      for (final doc in snapshot.docs) {
        final retry = RetryAttempt.fromMap(doc.data());
        _retryQueue.add(retry);
      }

      print(' Loaded ${_retryQueue.length} pending retries');

      if (_retryQueue.isNotEmpty) {
        _startRetryProcessor();
      }

    } catch (e) {
      print(' Error loading retry queue: $e');
    }
  }

  // Get retry statistics
  Future<Map<String, dynamic>> getRetryStats(String userId) async {
    try {
      final logsSnapshot = await _firestore
          .collection('retry_logs')
          .where('userId', isEqualTo: userId)
          .get();

      int totalRetries = logsSnapshot.docs.length;
      int successful = 0;
      int failed = 0;
      int totalAttempts = 0;

      for (final doc in logsSnapshot.docs) {
        final data = doc.data();
        if (data['success'] == true) {
          successful++;
        } else {
          failed++;
        }
        totalAttempts += (data['totalAttempts'] as int?) ?? 0;
      }

      final currentPending = _retryQueue.where((r) => r.userId == userId).length;

      return {
        'totalRetries': totalRetries,
        'successful': successful,
        'failed': failed,
        'successRate': totalRetries > 0
            ? '${((successful / totalRetries) * 100).toStringAsFixed(1)}%'
            : 'N/A',
        'averageAttempts': totalRetries > 0
            ? (totalAttempts / totalRetries).toStringAsFixed(1)
            : 'N/A',
        'currentPending': currentPending,
      };
    } catch (e) {
      print(' Error getting retry stats: $e');
      return {
        'totalRetries': 0,
        'successful': 0,
        'failed': 0,
        'successRate': 'N/A',
        'averageAttempts': 'N/A',
        'currentPending': 0,
      };
    }
  }

  // Get pending retries for display
  List<RetryAttempt> getPendingRetries(String userId) {
    return _retryQueue.where((r) => r.userId == userId).toList();
  }

  // Cancel a specific retry
  Future<void> cancelRetry(String retryId) async {
    try {
      final retry = _retryQueue.firstWhere((r) => r.id == retryId);
      _retryQueue.remove(retry);

      await _firestore.collection('retry_queue').doc(retryId).delete();

      print(' Cancelled retry: $retryId');
    } catch (e) {
      print(' Error cancelling retry: $e');
    }
  }

  // Clear all retries for a user
  Future<void> clearRetries(String userId) async {
    try {
      _retryQueue.removeWhere((r) => r.userId == userId);

      final snapshot = await _firestore
          .collection('retry_queue')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      print(' Cleared all retries for user: $userId');
    } catch (e) {
      print(' Error clearing retries: $e');
    }
  }

  // Stop retry processor
  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }
}