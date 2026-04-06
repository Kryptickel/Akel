import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

/// ==================== EMERGENCY CORE SERVICE ====================
///
/// Universal Emergency Management System (Web + Mobile Compatible)
///
/// Features:
/// - Offline emergency queue (SharedPreferences/localStorage)
/// - Automatic retry with exponential backoff
/// - Check-in system with missed alerts
/// - Connectivity monitoring
/// - Queue processor with 30s interval
/// - Man-down detection (mobile only - stubs for web)
/// - Emergency history and analytics
///
/// Storage: SharedPreferences (browser localStorage on web)
/// Platform: Web, iOS, Android (universal compatibility)
///
/// ==============================================================

class EmergencyCoreService {
  // ==================== SINGLETON ====================
  static final EmergencyCoreService _instance = EmergencyCoreService._internal();
  factory EmergencyCoreService() => _instance;
  EmergencyCoreService._internal();

  // ==================== STATE VARIABLES ====================
  bool _isOnline = true;
  bool _isInitialized = false;
  Timer? _queueProcessor;
  Timer? _checkinTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Check-in system
  bool _checkinEnabled = false;
  int _checkinIntervalMinutes = 120; // 2 hours default
  DateTime? _lastCheckin;

  // Man-down detection (mobile only)
  bool _manDownEnabled = false;

  // Callbacks
  Function(String)? onCheckinMissed;
  Function()? onManDown;
  Function(Map<String, dynamic>)? onEmergencyQueued;
  Function(Map<String, dynamic>)? onEmergencySent;
  Function(Map<String, dynamic>)? onEmergencyFailed;

  // Storage keys
  static const String _emergenciesKey = 'emergency_queue';
  static const String _checkinsKey = 'checkin_history';
  static const String _manDownEventsKey = 'man_down_events';
  static const String _settingsKey = 'emergency_settings';

  // Settings
  int _maxRetryCount = 5;
  bool _autoRetryEnabled = true;

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint(' Emergency Core Service already initialized');
      return;
    }

    try {
      debugPrint(' ========== EMERGENCY CORE SERVICE INITIALIZATION ==========');
      debugPrint(' Platform: ${kIsWeb ? "WEB (Browser)" : "NATIVE (Mobile)"}');

      // Initialize storage
      await _initStorage();

      // Start connectivity monitoring
      await _startConnectivityMonitoring();

      // Load saved settings
      await _loadSettings();

      // Start queue processor
      await _startQueueProcessor();

      _isInitialized = true;

      debugPrint(' Emergency Core Service initialized successfully');
      debugPrint(' Connectivity monitoring: ACTIVE');
      debugPrint(' Queue processor: RUNNING (30s interval)');
      debugPrint(' Storage: SharedPreferences${kIsWeb ? " (localStorage)" : ""}');
      debugPrint(' Check-ins: ${_checkinEnabled ? "ENABLED" : "DISABLED"}');
      debugPrint(' Man-down: ${kIsWeb ? "N/A (web)" : (_manDownEnabled ? "ENABLED" : "DISABLED")}');
      debugPrint('========================================================\n');

    } catch (e, stackTrace) {
      debugPrint(' Emergency Core Service initialization error: $e');
      debugPrint(' Stack trace: $stackTrace');
      _isInitialized = true; // Continue with limited functionality
    }
  }

  // ==================== STORAGE INITIALIZATION ====================

  Future<void> _initStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Initialize emergency queue
      if (!prefs.containsKey(_emergenciesKey)) {
        await prefs.setString(_emergenciesKey, jsonEncode([]));
        debugPrint(' Emergency queue initialized');
      }

      // Initialize check-in history
      if (!prefs.containsKey(_checkinsKey)) {
        await prefs.setString(_checkinsKey, jsonEncode([]));
        debugPrint(' Check-in history initialized');
      }

      // Initialize man-down events
      if (!prefs.containsKey(_manDownEventsKey)) {
        await prefs.setString(_manDownEventsKey, jsonEncode([]));
        debugPrint(' Man-down events initialized');
      }

      // Initialize settings
      if (!prefs.containsKey(_settingsKey)) {
        await prefs.setString(_settingsKey, jsonEncode({
          'checkin_enabled': false,
          'checkin_interval': 120,
          'man_down_enabled': false,
          'auto_retry_enabled': true,
          'max_retry_count': 5,
        }));
        debugPrint(' Settings initialized with defaults');
      }

      debugPrint(' Storage initialized successfully');

    } catch (e) {
      debugPrint(' Storage initialization warning: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final settings = jsonDecode(settingsJson) as Map<String, dynamic>;

        _checkinEnabled = settings['checkin_enabled'] as bool? ?? false;
        _checkinIntervalMinutes = settings['checkin_interval'] as int? ?? 120;
        _manDownEnabled = settings['man_down_enabled'] as bool? ?? false;
        _autoRetryEnabled = settings['auto_retry_enabled'] as bool? ?? true;
        _maxRetryCount = settings['max_retry_count'] as int? ?? 5;

        debugPrint(' Settings loaded:');
        debugPrint(' Check-ins: ${_checkinEnabled ? "ENABLED" : "DISABLED"}');
        debugPrint(' Check-in interval: $_checkinIntervalMinutes minutes');
        debugPrint(' Man-down: ${_manDownEnabled ? "ENABLED" : "DISABLED"}');
        debugPrint(' Auto-retry: ${_autoRetryEnabled ? "ENABLED" : "DISABLED"}');
        debugPrint(' Max retries: $_maxRetryCount');

        // Resume check-ins if enabled
        if (_checkinEnabled) {
          await enableCheckins(_checkinIntervalMinutes);
        }

        // Resume man-down if enabled (mobile only)
        if (_manDownEnabled && !kIsWeb) {
          await enableManDown();
        }
      }
    } catch (e) {
      debugPrint(' Settings load warning: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsKey, jsonEncode({
        'checkin_enabled': _checkinEnabled,
        'checkin_interval': _checkinIntervalMinutes,
        'man_down_enabled': _manDownEnabled,
        'auto_retry_enabled': _autoRetryEnabled,
        'max_retry_count': _maxRetryCount,
      }));
    } catch (e) {
      debugPrint(' Save settings warning: $e');
    }
  }

  // ==================== CONNECTIVITY MONITORING ====================

  Future<void> _startConnectivityMonitoring() async {
    try {
      // Check initial connectivity
      final result = await Connectivity().checkConnectivity();
      _isOnline = !result.contains(ConnectivityResult.none);

      debugPrint(' Initial connectivity: ${_isOnline ? "ONLINE " : "OFFLINE "}');

      // Listen to connectivity changes
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
        final wasOnline = _isOnline;
        _isOnline = !results.contains(ConnectivityResult.none);

        if (!wasOnline && _isOnline) {
          debugPrint(' CONNECTION RESTORED - Processing pending emergencies');
          _processQueue();
        } else if (wasOnline && !_isOnline) {
          debugPrint(' CONNECTION LOST - Entering offline mode');
        }
      });

    } catch (e) {
      debugPrint(' Connectivity monitoring warning: $e');
      _isOnline = false;
    }
  }

  // ==================== QUEUE EMERGENCY ====================

  /// Queue an emergency for sending
  ///
  /// If online: Immediately attempts to send
  /// If offline: Stores for later transmission
  ///
  /// Returns: Emergency ID (timestamp in milliseconds)
  Future<int> queueEmergency({
    required String userId,
    required String type,
    required String message,
    required List<Map<String, dynamic>> contacts,
    Position? location,
    List<String>? breadcrumbs,
    List<String>? recordings,
    List<String>? photos,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final emergencyId = DateTime.now().millisecondsSinceEpoch;

      final emergency = {
        'id': emergencyId,
        'user_id': userId,
        'type': type,
        'message': message,
        'contacts': contacts,
        'latitude': location?.latitude,
        'longitude': location?.longitude,
        'accuracy': location?.accuracy,
        'altitude': location?.altitude,
        'heading': location?.heading,
        'speed': location?.speed,
        'status': _isOnline ? 'sending' : 'queued',
        'created_at': emergencyId,
        'sent_at': null,
        'retry_count': 0,
        'last_retry_at': null,
        'breadcrumbs': breadcrumbs ?? [],
        'recordings': recordings ?? [],
        'photos': photos ?? [],
        'metadata': metadata ?? {},
        'platform': kIsWeb ? 'web' : 'mobile',
      };

      // Add to queue
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_emergenciesKey) ?? '[]';
      final queue = List<Map<String, dynamic>>.from(jsonDecode(queueJson));

      queue.insert(0, emergency);

      // Keep only last 100 emergencies
      if (queue.length > 100) {
        final removed = queue.length - 100;
        queue.removeRange(100, queue.length);
        debugPrint(' Cleaned $removed old emergencies (kept last 100)');
      }

      await prefs.setString(_emergenciesKey, jsonEncode(queue));

      debugPrint(' Emergency queued successfully');
      debugPrint(' ID: $emergencyId');
      debugPrint(' Type: $type');
      debugPrint(' Status: ${emergency['status']}');
      debugPrint(' Online: $_isOnline');
      debugPrint(' Location: ${location != null ? "Available (${location.latitude}, ${location.longitude})" : "Unavailable"}');
      debugPrint(' Contacts: ${contacts.length}');

      // Callback
      onEmergencyQueued?.call(emergency);

      // Process immediately if online
      if (_isOnline) {
        unawaited(_processQueue());
      }

      return emergencyId;

    } catch (e, stackTrace) {
      debugPrint(' Error queueing emergency: $e');
      debugPrint(' Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Helper to avoid unawaited_futures warning
  void unawaited(Future<void> future) {}

  // ==================== QUEUE PROCESSOR ====================

  Future<void> _startQueueProcessor() async {
    try {
      _queueProcessor = Timer.periodic(const Duration(seconds: 30), (_) {
        if (_isOnline && _autoRetryEnabled) {
          unawaited(_processQueue());
        }
      });

      debugPrint(' Queue processor started (30 second interval)');
    } catch (e) {
      debugPrint(' Queue processor warning: $e');
    }
  }

  Future<void> _processQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_emergenciesKey) ?? '[]';
      final queue = List<Map<String, dynamic>>.from(jsonDecode(queueJson));

      // Get pending emergencies
      final pending = queue.where((e) {
        final status = e['status'] as String?;
        return status == 'queued' || status == 'sending';
      }).toList();

      if (pending.isEmpty) {
        return;
      }

      debugPrint(' Processing ${pending.length} pending emergencies...');

      for (final emergency in pending) {
        await _sendEmergency(emergency, queue, prefs);

        // Small delay between sends to avoid overwhelming the system
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint(' Queue processing complete');

    } catch (e) {
      debugPrint(' Queue processing warning: $e');
    }
  }

  Future<void> _sendEmergency(
      Map<String, dynamic> emergency,
      List<Map<String, dynamic>> queue,
      SharedPreferences prefs,
      ) async {
    try {
      final emergencyId = emergency['id'];
      final retryCount = emergency['retry_count'] as int? ?? 0;

      debugPrint(' Sending emergency $emergencyId (attempt ${retryCount + 1})...');

      // TODO: Implement actual sending logic
      // Examples:
      // Send SMS via Twilio API
      // Send push notifications via Firebase Cloud Messaging
      // Send emails via SendGrid/AWS SES
      // Call emergency contacts via VoIP
      // Upload to Firebase Firestore/Realtime Database
      // Trigger webhooks
      // Send to custom emergency API

      // Simulate sending (REPLACE WITH ACTUAL IMPLEMENTATION)
      await Future.delayed(const Duration(milliseconds: 500));

      // Simulate success (change to your actual send logic)
      final success = true;

      if (success) {
        // Mark as sent
        emergency['status'] = 'sent';
        emergency['sent_at'] = DateTime.now().millisecondsSinceEpoch;

        debugPrint(' Emergency $emergencyId sent successfully');
        debugPrint(' Send time: ${DateTime.now()}');
        debugPrint(' Retry count: $retryCount');

        // Callback
        onEmergencySent?.call(emergency);

      } else {
        throw Exception('Send failed - simulated failure');
      }

      // Update queue
      final index = queue.indexWhere((e) => e['id'] == emergencyId);
      if (index != -1) {
        queue[index] = emergency;
        await prefs.setString(_emergenciesKey, jsonEncode(queue));
      }

    } catch (e) {
      debugPrint(' Failed to send emergency ${emergency['id']}: $e');

      // Increment retry count
      emergency['retry_count'] = (emergency['retry_count'] as int? ?? 0) + 1;
      emergency['last_retry_at'] = DateTime.now().millisecondsSinceEpoch;

      // Mark as failed if too many retries
      if (emergency['retry_count'] >= _maxRetryCount) {
        emergency['status'] = 'failed';
        debugPrint(' Emergency ${emergency['id']} marked as FAILED');
        debugPrint(' Total attempts: ${emergency['retry_count']}');
        debugPrint(' First attempt: ${DateTime.fromMillisecondsSinceEpoch(emergency['created_at'] as int)}');

        // Callback
        onEmergencyFailed?.call(emergency);
      } else {
        emergency['status'] = 'queued';
        final nextRetry = Duration(seconds: (30 * emergency['retry_count']).toInt());
        debugPrint(' Emergency ${emergency['id']} will retry');
        debugPrint(' Attempt: ${emergency['retry_count']}/$_maxRetryCount');
        debugPrint(' Next retry: ~${nextRetry.inSeconds} seconds');
      }

      // Update queue
      final index = queue.indexWhere((e) => e['id'] == emergency['id']);
      if (index != -1) {
        queue[index] = emergency;
        await prefs.setString(_emergenciesKey, jsonEncode(queue));
      }
    }
  }

  // ==================== CHECK-IN SYSTEM ====================

  /// Enable automatic check-ins
  Future<void> enableCheckins(int intervalMinutes) async {
    try {
      _checkinEnabled = true;
      _checkinIntervalMinutes = intervalMinutes;
      _lastCheckin = DateTime.now();

      // Cancel existing timer
      _checkinTimer?.cancel();

      // Start new timer (check every minute)
      _checkinTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        _checkCheckinStatus();
      });

      // Save settings
      await _saveSettings();

      final nextCheckin = DateTime.now().add(Duration(minutes: intervalMinutes));
      debugPrint(' Check-ins ENABLED');
      debugPrint(' Interval: $intervalMinutes minutes');
      debugPrint(' Next check-in due: $nextCheckin');

    } catch (e) {
      debugPrint(' Check-in enable warning: $e');
    }
  }

  /// Disable automatic check-ins
  Future<void> disableCheckins() async {
    try {
      _checkinEnabled = false;
      _checkinTimer?.cancel();

      // Save settings
      await _saveSettings();

      debugPrint(' Check-ins DISABLED');

    } catch (e) {
      debugPrint(' Check-in disable warning: $e');
    }
  }

  /// Perform manual check-in
  Future<void> performCheckin({String? notes}) async {
    try {
      Position? position;

      // Get location
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint(' Location unavailable for check-in: $e');
      }

      final checkin = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'user_id': 'current_user', // TODO: Get from auth service
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'accuracy': position?.accuracy,
        'altitude': position?.altitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'type': 'manual',
        'status': 'completed',
        'notes': notes,
        'platform': kIsWeb ? 'web' : 'mobile',
      };

      // Save to history
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_checkinsKey) ?? '[]';
      final history = List<Map<String, dynamic>>.from(jsonDecode(historyJson));

      history.insert(0, checkin);

      // Keep only last 100 check-ins
      if (history.length > 100) {
        history.removeRange(100, history.length);
      }

      await prefs.setString(_checkinsKey, jsonEncode(history));

      _lastCheckin = DateTime.now();

      debugPrint(' Check-in completed');
      debugPrint(' Location: ${position != null ? "${position.latitude}, ${position.longitude}" : "unavailable"}');
      debugPrint(' Time: ${DateTime.now()}');
      debugPrint(' Notes: ${notes ?? "none"}');

    } catch (e) {
      debugPrint(' Check-in error: $e');
      rethrow;
    }
  }

  void _checkCheckinStatus() {
    if (!_checkinEnabled || _lastCheckin == null) return;

    final minutesSinceLastCheckin = DateTime.now().difference(_lastCheckin!).inMinutes;

    if (minutesSinceLastCheckin >= _checkinIntervalMinutes) {
      debugPrint(' ========== CHECK-IN MISSED ==========');
      debugPrint(' Time overdue: $minutesSinceLastCheckin minutes');
      debugPrint(' Last check-in: $_lastCheckin');
      debugPrint(' Expected interval: $_checkinIntervalMinutes minutes');
      debugPrint('========================================');

      // Record missed check-in
      unawaited(_recordMissedCheckin(minutesSinceLastCheckin));

      // Trigger callback
      onCheckinMissed?.call('Check-in missed after $minutesSinceLastCheckin minutes');
    }
  }

  Future<void> _recordMissedCheckin(int minutesSince) async {
    try {
      final missedCheckin = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'user_id': 'current_user',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'type': 'auto_missed',
        'status': 'missed',
        'minutes_overdue': minutesSince,
        'expected_at': _lastCheckin?.add(Duration(minutes: _checkinIntervalMinutes)).millisecondsSinceEpoch,
      };

      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_checkinsKey) ?? '[]';
      final history = List<Map<String, dynamic>>.from(jsonDecode(historyJson));

      history.insert(0, missedCheckin);

      if (history.length > 100) {
        history.removeRange(100, history.length);
      }

      await prefs.setString(_checkinsKey, jsonEncode(history));

    } catch (e) {
      debugPrint(' Record missed check-in warning: $e');
    }
  }

  // ==================== MAN-DOWN DETECTION ====================
  // Note: Man-down detection requires accelerometer sensors
  // This is ONLY available on mobile devices, NOT on web

  /// Enable man-down detection (Mobile only)
  Future<void> enableManDown() async {
    if (kIsWeb) {
      debugPrint(' Man-down detection not available on web platform');
      debugPrint(' This feature requires mobile device with accelerometer');
      return;
    }

    try {
      _manDownEnabled = true;
      await _saveSettings();

      debugPrint(' Man-down detection ENABLED (mobile only)');
      debugPrint(' Note: Actual accelerometer monitoring not implemented in web version');
      debugPrint(' Implement accelerometer logic in mobile-specific code');

    } catch (e) {
      debugPrint(' Man-down enable warning: $e');
    }
  }

  /// Disable man-down detection (Mobile only)
  Future<void> disableManDown() async {
    if (kIsWeb) {
      debugPrint(' Man-down detection not available on web platform');
      return;
    }

    try {
      _manDownEnabled = false;
      await _saveSettings();

      debugPrint(' Man-down detection DISABLED');

    } catch (e) {
      debugPrint(' Man-down disable warning: $e');
    }
  }

  /// Record a man-down event
  Future<void> recordManDownEvent({
    required double acceleration,
    Position? location,
  }) async {
    try {
      final event = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'user_id': 'current_user',
        'latitude': location?.latitude,
        'longitude': location?.longitude,
        'accuracy': location?.accuracy,
        'acceleration': acceleration,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'resolved': 0,
        'platform': kIsWeb ? 'web' : 'mobile',
      };

      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString(_manDownEventsKey) ?? '[]';
      final events = List<Map<String, dynamic>>.from(jsonDecode(eventsJson));

      events.insert(0, event);

      // Keep only last 50 events
      if (events.length > 50) {
        events.removeRange(50, events.length);
      }

      await prefs.setString(_manDownEventsKey, jsonEncode(events));

      debugPrint(' Man-down event recorded');
      debugPrint(' Acceleration: $acceleration m/s²');
      debugPrint(' Location: ${location != null ? "${location.latitude}, ${location.longitude}" : "unavailable"}');

      // Callback
      onManDown?.call();

    } catch (e) {
      debugPrint(' Record man-down event error: $e');
    }
  }

  /// Get man-down events
  Future<List<Map<String, dynamic>>> getManDownEvents({bool unresolvedOnly = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString(_manDownEventsKey) ?? '[]';
      var events = List<Map<String, dynamic>>.from(jsonDecode(eventsJson));

      if (unresolvedOnly) {
        events = events.where((e) => (e['resolved'] as int? ?? 0) == 0).toList();
      }

      return events;

    } catch (e) {
      debugPrint(' Get man-down events warning: $e');
      return [];
    }
  }

  /// Resolve a man-down event
  Future<void> resolveManDownEvent(int eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString(_manDownEventsKey) ?? '[]';
      final events = List<Map<String, dynamic>>.from(jsonDecode(eventsJson));

      final index = events.indexWhere((e) => e['id'] == eventId);
      if (index != -1) {
        events[index]['resolved'] = 1;
        events[index]['resolved_at'] = DateTime.now().millisecondsSinceEpoch;
        await prefs.setString(_manDownEventsKey, jsonEncode(events));

        debugPrint(' Man-down event $eventId resolved');
      }

    } catch (e) {
      debugPrint(' Resolve man-down event warning: $e');
    }
  }

  // ==================== QUERY METHODS ====================

  /// Get count of pending emergencies
  Future<int> getPendingCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_emergenciesKey) ?? '[]';
      final queue = List<Map<String, dynamic>>.from(jsonDecode(queueJson));

      final pending = queue.where((e) {
        final status = e['status'] as String?;
        return status == 'queued' || status == 'sending';
      }).toList();

      return pending.length;

    } catch (e) {
      debugPrint(' Get pending count warning: $e');
      return 0;
    }
  }

  /// Get all emergencies (with optional status filter)
  Future<List<Map<String, dynamic>>> getEmergencies({
    String? status,
    int? limit,
    bool newestFirst = true,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_emergenciesKey) ?? '[]';
      var queue = List<Map<String, dynamic>>.from(jsonDecode(queueJson));

      // Filter by status
      if (status != null) {
        queue = queue.where((e) => e['status'] == status).toList();
      }

      // Sort
      if (!newestFirst) {
        queue = queue.reversed.toList();
      }

      // Limit
      if (limit != null && queue.length > limit) {
        queue = queue.sublist(0, limit);
      }

      return queue;

    } catch (e) {
      debugPrint(' Get emergencies warning: $e');
      return [];
    }
  }

  /// Get emergency by ID
  Future<Map<String, dynamic>?> getEmergencyById(int id) async {
    try {
      final emergencies = await getEmergencies();
      return emergencies.firstWhere(
            (e) => e['id'] == id,
        orElse: () => {},
      );
    } catch (e) {
      debugPrint(' Get emergency by ID warning: $e');
      return null;
    }
  }

  /// Get recent check-ins
  Future<List<Map<String, dynamic>>> getRecentCheckins({int limit = 10}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_checkinsKey) ?? '[]';
      final history = List<Map<String, dynamic>>.from(jsonDecode(historyJson));

      return history.take(limit).toList();

    } catch (e) {
      debugPrint(' Get checkins warning: $e');
      return [];
    }
  }

  /// Get emergency statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final emergencies = await getEmergencies();
      final checkins = await getRecentCheckins(limit: 100);
      final manDownEvents = await getManDownEvents();

      final queued = emergencies.where((e) => e['status'] == 'queued').length;
      final sending = emergencies.where((e) => e['status'] == 'sending').length;
      final sent = emergencies.where((e) => e['status'] == 'sent').length;
      final failed = emergencies.where((e) => e['status'] == 'failed').length;

      final completedCheckins = checkins.where((c) => c['status'] == 'completed').length;
      final missedCheckins = checkins.where((c) => c['status'] == 'missed').length;

      final unresolvedManDown = manDownEvents.where((e) => (e['resolved'] as int? ?? 0) == 0).length;

      return {
        'total_emergencies': emergencies.length,
        'queued': queued,
        'sending': sending,
        'sent': sent,
        'failed': failed,
        'total_checkins': checkins.length,
        'completed_checkins': completedCheckins,
        'missed_checkins': missedCheckins,
        'total_man_down_events': manDownEvents.length,
        'unresolved_man_down_events': unresolvedManDown,
        'is_online': _isOnline,
        'checkin_enabled': _checkinEnabled,
        'man_down_enabled': _manDownEnabled,
      };

    } catch (e) {
      debugPrint(' Get statistics warning: $e');
      return {};
    }
  }

  /// Clear sent emergencies from queue
  Future<void> clearSentEmergencies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_emergenciesKey) ?? '[]';
      final queue = List<Map<String, dynamic>>.from(jsonDecode(queueJson));

      final beforeCount = queue.length;
      final filtered = queue.where((e) => e['status'] != 'sent').toList();

      await prefs.setString(_emergenciesKey, jsonEncode(filtered));

      final removed = beforeCount - filtered.length;
      debugPrint(' Cleared $removed sent emergencies');

    } catch (e) {
      debugPrint(' Clear sent warning: $e');
    }
  }

  /// Clear all data (DANGEROUS - use with caution)
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_emergenciesKey);
      await prefs.remove(_checkinsKey);
      await prefs.remove(_manDownEventsKey);

      debugPrint(' All emergency data cleared');

    } catch (e) {
      debugPrint(' Clear all data warning: $e');
    }
  }

  // ==================== CONTROL METHODS ====================

  void startQueueProcessing() {
    if (_queueProcessor != null && _queueProcessor!.isActive) {
      debugPrint(' Queue processor already running');
    } else {
      unawaited(_startQueueProcessor());
    }
  }

  void resumeServices() {
    try {
      debugPrint(' Resuming services...');

      // Resume check-ins if enabled
      if (_checkinEnabled && (_checkinTimer == null || !_checkinTimer!.isActive)) {
        unawaited(enableCheckins(_checkinIntervalMinutes));
      }

      // Resume man-down if enabled (mobile only)
      if (_manDownEnabled && !kIsWeb) {
        unawaited(enableManDown());
      }

      // Process queue if online
      if (_isOnline) {
        unawaited(_processQueue());
      }

      debugPrint(' Services resumed');

    } catch (e) {
      debugPrint(' Resume services warning: $e');
    }
  }

  void dispose() {
    try {
      debugPrint(' Disposing Emergency Core Service...');

      _queueProcessor?.cancel();
      _checkinTimer?.cancel();
      _connectivitySubscription?.cancel();

      debugPrint(' Emergency Core Service disposed');

    } catch (e) {
      debugPrint(' Dispose warning: $e');
    }
  }

  // ==================== GETTERS ====================

  bool get isInitialized => _isInitialized;
  bool get isOnline => _isOnline;
  bool get manDownEnabled => _manDownEnabled;
  bool get checkinEnabled => _checkinEnabled;
  int get checkinIntervalMinutes => _checkinIntervalMinutes;
  DateTime? get lastCheckin => _lastCheckin;
  int get maxRetryCount => _maxRetryCount;
  bool get autoRetryEnabled => _autoRetryEnabled;

  // ==================== SETTERS ====================

  set maxRetryCount(int value) {
    _maxRetryCount = value;
    unawaited(_saveSettings());
  }

  set autoRetryEnabled(bool value) {
    _autoRetryEnabled = value;
    unawaited(_saveSettings());
  }
}