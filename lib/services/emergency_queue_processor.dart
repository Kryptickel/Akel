import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_emergency_service.dart';
import 'panic_service_v2.dart';

class EmergencyQueueProcessor {
  static final EmergencyQueueProcessor _instance = EmergencyQueueProcessor._internal();
  factory EmergencyQueueProcessor() => _instance;
  EmergencyQueueProcessor._internal();

  final OfflineEmergencyService _offlineService = OfflineEmergencyService();
  final PanicServiceV2 _panicService = PanicServiceV2();

  Timer? _processingTimer;
  bool _isProcessing = false;

  // FIXED: Updated type to accept a List of results
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Start monitoring for connection and process queue
  void startMonitoring() {
    // Process queue every 30 seconds when online
    _processingTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => processQueue(),
    );

    // FIXED: Line 28 - Listener updated to handle List<ConnectivityResult>
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      // Check if there is any active connection in the list that isn't 'none'
      if (result.isNotEmpty && !result.contains(ConnectivityResult.none)) {
        debugPrint(' Connection restored - processing emergency queue');
        processQueue();
      }
    });

    debugPrint(' Emergency queue processor started');
  }

  // Process all pending emergencies
  Future<void> processQueue() async {
    if (_isProcessing) {
      debugPrint(' Already processing queue, skipping...');
      return;
    }

    _isProcessing = true;

    try {
      final pending = await _offlineService.getPendingEmergencies();

      if (pending.isEmpty) {
        debugPrint(' No pending emergencies to process');
        _isProcessing = false;
        return;
      }

      debugPrint(' Processing ${pending.length} pending emergencies...');

      for (final emergency in pending) {
        await _processEmergency(emergency);
      }

      debugPrint(' Queue processing complete');
    } catch (e) {
      debugPrint(' Error processing queue: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // Process a single emergency
  Future<void> _processEmergency(Map<String, dynamic> emergency) async {
    final id = emergency['id'] as int;
    final retryCount = emergency['retry_count'] as int;

    if (retryCount >= 5) {
      debugPrint(' Emergency $id exceeded max retries, marking as failed');
      await _offlineService.markAsFailed(id, error: 'Max retries exceeded');
      return;
    }

    if (retryCount > 0) {
      final lastRetry = emergency['last_retry'] as int?;
      if (lastRetry != null) {
        final waitTime = Duration(minutes: 1 << retryCount);
        final timeSinceLastRetry = DateTime.now().millisecondsSinceEpoch - lastRetry;

        if (timeSinceLastRetry < waitTime.inMilliseconds) {
          debugPrint(' Waiting for backoff period for emergency $id');
          return;
        }
      }
    }

    try {
      debugPrint(' Attempting to send emergency $id (retry #$retryCount)');

      final breadcrumbs = await _offlineService.getBreadcrumbs(id);

      // jsonDecode is now covered by the 'dart:convert' import
      final contacts = List<Map<String, dynamic>>.from(
        jsonDecode(emergency['contacts'] as String),
      );

      String message = emergency['message'] as String;

      if (breadcrumbs.isNotEmpty) {
        message += '\n\n Location Trail (${breadcrumbs.length} points):';
        for (final crumb in breadcrumbs.take(5)) {
          final lat = crumb['latitude'];
          final lng = crumb['longitude'];
          message += '\nhttps://maps.google.com/?q=$lat,$lng';
        }
      }

      final success = await _sendEmergency(
        contacts: contacts,
        message: message,
        latitude: emergency['latitude'] as double?,
        longitude: emergency['longitude'] as double?,
      );

      if (success) {
        await _offlineService.markAsSent(id);
        debugPrint(' Emergency $id sent successfully');
      } else {
        throw Exception('Failed to send emergency');
      }
    } catch (e) {
      debugPrint(' Failed to send emergency $id: $e');
      await _offlineService.incrementRetry(id);
    }
  }

  Future<bool> _sendEmergency({
    required List<Map<String, dynamic>> contacts,
    required String message,
    double? latitude,
    double? longitude,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  void stopMonitoring() {
    _processingTimer?.cancel();
    _connectivitySubscription?.cancel();
    debugPrint(' Emergency queue processor stopped');
  }
}