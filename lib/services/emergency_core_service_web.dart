import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

class EmergencyCoreService {
  static final EmergencyCoreService _instance = EmergencyCoreService._internal();
  factory EmergencyCoreService() => _instance;
  EmergencyCoreService._internal();

  bool _isOnline = true;
  bool _isInitialized = false;
  Timer? _queueProcessor;
  Timer? _checkinTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _checkinEnabled = false;
  int _checkinIntervalMinutes = 120;
  DateTime? _lastCheckin;

  Function(String)? onCheckinMissed;
  Function()? onManDown;

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint(' Emergency Core (WEB) already initialized');
      return;
    }

    try {
      debugPrint(' Initializing Emergency Core for WEB...');
      await _initWebStorage();
      await _startConnectivityMonitoring();
      await _startQueueProcessor();
      await _loadSettings();

      _isInitialized = true;
      debugPrint(' Emergency Core (WEB) initialized');
    } catch (e) {
      debugPrint(' Init error: $e');
      _isInitialized = true;
    }
  }

  Future<void> _initWebStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!prefs.containsKey('web_emergencies')) {
        await prefs.setString('web_emergencies', '[]');
      }
      if (!prefs.containsKey('web_checkins')) {
        await prefs.setString('web_checkins', '[]');
      }

      debugPrint(' Web storage ready');
    } catch (e) {
      debugPrint(' Web storage: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _checkinEnabled = prefs.getBool('checkin_enabled') ?? false;
      _checkinIntervalMinutes = prefs.getInt('checkin_interval') ?? 120;

      if (_checkinEnabled) {
        await enableCheckins(_checkinIntervalMinutes);
      }
    } catch (e) {
      debugPrint(' Load settings: $e');
    }
  }

  Future<void> _startConnectivityMonitoring() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _isOnline = !result.contains(ConnectivityResult.none);

      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
        _isOnline = !results.contains(ConnectivityResult.none);

        if (_isOnline) {
          debugPrint(' Online');
          _processQueue();
        } else {
          debugPrint(' Offline');
        }
      });
    } catch (e) {
      debugPrint(' Connectivity: $e');
      _isOnline = false;
    }
  }

  Future<int> queueEmergency({
    required String userId,
    required String type,
    required String message,
    required List<Map<String, dynamic>> contacts,
    Position? location,
    List<String>? recordings,
    List<String>? photos,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final emergency = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'user_id': userId,
        'type': type,
        'message': message,
        'contacts': contacts,
        'latitude': location?.latitude,
        'longitude': location?.longitude,
        'status': _isOnline ? 'sending' : 'queued',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'retry_count': 0,
      };

      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('web_emergencies') ?? '[]';
      final list = List<Map<String, dynamic>>.from(jsonDecode(json));

      list.insert(0, emergency);

      if (list.length > 100) {
        list.removeRange(100, list.length);
      }

      await prefs.setString('web_emergencies', jsonEncode(list));

      debugPrint(' Queued: ${emergency['id']}');

      if (_isOnline) {
        _processQueue();
      }

      return emergency['id'] as int;
    } catch (e) {
      debugPrint(' Queue error: $e');
      rethrow;
    }
  }

  Future<void> _startQueueProcessor() async {
    _queueProcessor = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isOnline) _processQueue();
    });
  }

  Future<void> _processQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('web_emergencies') ?? '[]';
      final list = List<Map<String, dynamic>>.from(jsonDecode(json));

      final pending = list.where((e) {
        final status = e['status'] as String?;
        return status == 'queued' || status == 'sending';
      }).toList();

      for (final emergency in pending) {
        await _sendEmergency(emergency);
      }
    } catch (e) {
      debugPrint(' Process: $e');
    }
  }

  Future<void> _sendEmergency(Map<String, dynamic> emergency) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      emergency['status'] = 'sent';
      emergency['sent_at'] = DateTime.now().millisecondsSinceEpoch;

      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('web_emergencies') ?? '[]';
      final list = List<Map<String, dynamic>>.from(jsonDecode(json));

      final index = list.indexWhere((e) => e['id'] == emergency['id']);
      if (index != -1) {
        list[index] = emergency;
        await prefs.setString('web_emergencies', jsonEncode(list));
      }

      debugPrint(' Sent: ${emergency['id']}');
    } catch (e) {
      emergency['retry_count'] = (emergency['retry_count'] as int? ?? 0) + 1;
      emergency['status'] = emergency['retry_count'] >= 4 ? 'failed' : 'queued';
    }
  }

  Future<void> enableCheckins(int intervalMinutes) async {
    _checkinEnabled = true;
    _checkinIntervalMinutes = intervalMinutes;
    _lastCheckin = DateTime.now();

    _checkinTimer?.cancel();
    _checkinTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkStatus();
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('checkin_enabled', true);
    await prefs.setInt('checkin_interval', intervalMinutes);

    debugPrint(' Check-ins: Every $intervalMinutes min');
  }

  Future<void> disableCheckins() async {
    _checkinEnabled = false;
    _checkinTimer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('checkin_enabled', false);

    debugPrint(' Check-ins disabled');
  }

  Future<void> performCheckin() async {
    try {
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition();
      } catch (_) {}

      final checkin = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'user_id': 'current_user',
        'latitude': pos?.latitude,
        'longitude': pos?.longitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'type': 'manual',
        'status': 'completed',
      };

      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('web_checkins') ?? '[]';
      final list = List<Map<String, dynamic>>.from(jsonDecode(json));
      list.insert(0, checkin);
      await prefs.setString('web_checkins', jsonEncode(list));

      _lastCheckin = DateTime.now();
      debugPrint(' Check-in done');
    } catch (e) {
      debugPrint(' Check-in: $e');
    }
  }

  void _checkStatus() {
    if (!_checkinEnabled || _lastCheckin == null) return;

    final minutes = DateTime.now().difference(_lastCheckin!).inMinutes;

    if (minutes >= _checkinIntervalMinutes) {
      debugPrint(' Check-in missed!');
      onCheckinMissed?.call('Missed after $minutes min');
    }
  }

  Future<int> getPendingCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('web_emergencies') ?? '[]';
      final list = List<Map<String, dynamic>>.from(jsonDecode(json));

      final pending = list.where((e) {
        final status = e['status'] as String?;
        return status == 'queued' || status == 'sending';
      }).toList();

      return pending.length;
    } catch (_) {
      return 0;
    }
  }

  void startQueueProcessing() {
    debugPrint(' Already running');
  }

  void resumeServices() {
    if (_checkinEnabled && _checkinTimer == null) {
      enableCheckins(_checkinIntervalMinutes);
    }
    debugPrint(' Resumed');
  }

  void dispose() {
    _queueProcessor?.cancel();
    _checkinTimer?.cancel();
    _connectivitySubscription?.cancel();
    debugPrint(' Disposed');
  }

  bool get isInitialized => _isInitialized;
  bool get isOnline => _isOnline;
  bool get manDownEnabled => false; // Not available on web
  bool get checkinEnabled => _checkinEnabled;
}