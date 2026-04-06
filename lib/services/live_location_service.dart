import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

enum ShareDuration { fifteenMin, oneHour, eightHours, untilStopped }

class LiveLocationShare {
  final String id;
  final String userId;
  final String userName;
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime startTime;
  final DateTime? endTime;
  final ShareDuration duration;
  final bool isActive;
  final List<String> sharedWith;
  final String shareCode;
  final DateTime lastUpdate;
  final List<LocationPoint> trail;

  LiveLocationShare({
    required this.id,
    required this.userId,
    required this.userName,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.startTime,
    this.endTime,
    required this.duration,
    this.isActive = true,
    required this.sharedWith,
    required this.shareCode,
    required this.lastUpdate,
    this.trail = const [],
  });

  factory LiveLocationShare.fromMap(Map<String, dynamic> map, String id) {
    return LiveLocationShare(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      accuracy: (map['accuracy'] ?? 0.0).toDouble(),
      startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (map['endTime'] as Timestamp?)?.toDate(),
      duration: _durationFromString(map['duration'] ?? 'untilStopped'),
      isActive: map['isActive'] ?? false,
      sharedWith: List<String>.from(map['sharedWith'] ?? []),
      shareCode: map['shareCode'] ?? '',
      lastUpdate: (map['lastUpdate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      trail: (map['trail'] as List<dynamic>?)
          ?.map((point) => LocationPoint.fromMap(point))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'startTime': FieldValue.serverTimestamp(),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'duration': _durationToString(duration),
      'isActive': isActive,
      'sharedWith': sharedWith,
      'shareCode': shareCode,
      'lastUpdate': FieldValue.serverTimestamp(),
      'trail': trail.map((point) => point.toMap()).toList(),
    };
  }

  static ShareDuration _durationFromString(String duration) {
    switch (duration.toLowerCase()) {
      case 'fifteenmin':
        return ShareDuration.fifteenMin;
      case 'onehour':
        return ShareDuration.oneHour;
      case 'eighthours':
        return ShareDuration.eightHours;
      default:
        return ShareDuration.untilStopped;
    }
  }

  static String _durationToString(ShareDuration duration) {
    switch (duration) {
      case ShareDuration.fifteenMin:
        return 'fifteenMin';
      case ShareDuration.oneHour:
        return 'oneHour';
      case ShareDuration.eightHours:
        return 'eightHours';
      case ShareDuration.untilStopped:
        return 'untilStopped';
    }
  }
}

class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracy;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracy,
  });

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      accuracy: (map['accuracy'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
      'accuracy': accuracy,
    };
  }
}

class LiveLocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _locationStream;
  String? _currentShareId;
  Timer? _expirationTimer;

  bool get isSharing => _currentShareId != null;
  String? get currentShareId => _currentShareId;

// Generate random share code
  String _generateShareCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
      8,
          (index) => chars[(random + index) % chars.length],
    ).join();
  }

// Start live location sharing
  Future<LiveLocationShare?> startSharing({
    required String userId,
    required String userName,
    required ShareDuration duration,
    List<String> sharedWith = const [],
  }) async {
    try {
// Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final shareCode = _generateShareCode();
      final now = DateTime.now();

      DateTime? endTime;
      switch (duration) {
        case ShareDuration.fifteenMin:
          endTime = now.add(const Duration(minutes: 15));
          break;
        case ShareDuration.oneHour:
          endTime = now.add(const Duration(hours: 1));
          break;
        case ShareDuration.eightHours:
          endTime = now.add(const Duration(hours: 8));
          break;
        case ShareDuration.untilStopped:
          endTime = null;
          break;
      }

      final share = LiveLocationShare(
        id: '',
        userId: userId,
        userName: userName,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        startTime: now,
        endTime: endTime,
        duration: duration,
        sharedWith: sharedWith,
        shareCode: shareCode,
        lastUpdate: now,
        trail: [
          LocationPoint(
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: now,
            accuracy: position.accuracy,
          )
        ],
      );

      final docRef = await _firestore.collection('live_locations').add(share.toMap());

      _currentShareId = docRef.id;

// Start location tracking
      _startLocationTracking(docRef.id);

// Set expiration timer if needed
      if (endTime != null) {
        _setExpirationTimer(docRef.id, endTime);
      }

      debugPrint('✅ Live location sharing started: $shareCode');

      return LiveLocationShare(
        id: docRef.id,
        userId: userId,
        userName: userName,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        startTime: now,
        endTime: endTime,
        duration: duration,
        sharedWith: sharedWith,
        shareCode: shareCode,
        lastUpdate: now,
      );
    } catch (e) {
      debugPrint('❌ Start sharing error: $e');
      return null;
    }
  }

// Start continuous location tracking
  void _startLocationTracking(String shareId) {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _locationStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) async {
      await _updateLocation(shareId, position);
    });

    debugPrint('📍 Location tracking started');
  }

// Update location in Firestore
  Future<void> _updateLocation(String shareId, Position position) async {
    try {
      final locationPoint = LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
      );

      await _firestore.collection('live_locations').doc(shareId).update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'lastUpdate': FieldValue.serverTimestamp(),
        'trail': FieldValue.arrayUnion([locationPoint.toMap()]),
      });

      debugPrint('📍 Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('❌ Update location error: $e');
    }
  }

// Set expiration timer
  void _setExpirationTimer(String shareId, DateTime endTime) {
    final duration = endTime.difference(DateTime.now());

    _expirationTimer = Timer(duration, () async {
      await stopSharing(shareId);
      debugPrint('⏱️ Location sharing expired');
    });
  }

// Stop sharing
  Future<bool> stopSharing(String? shareId) async {
    try {
      if (shareId == null) shareId = _currentShareId;
      if (shareId == null) return false;

      await _firestore.collection('live_locations').doc(shareId).update({
        'isActive': false,
        'endTime': FieldValue.serverTimestamp(),
      });

      _locationStream?.cancel();
      _locationStream = null;
      _expirationTimer?.cancel();
      _expirationTimer = null;
      _currentShareId = null;

      debugPrint('🛑 Location sharing stopped');
      return true;
    } catch (e) {
      debugPrint('❌ Stop sharing error: $e');
      return false;
    }
  }

// Get live location by share code
  Future<LiveLocationShare?> getLocationByShareCode(String shareCode) async {
    try {
      final snapshot = await _firestore
          .collection('live_locations')
          .where('shareCode', isEqualTo: shareCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return LiveLocationShare.fromMap(doc.data(), doc.id);
    } catch (e) {
      debugPrint('❌ Get location by code error: $e');
      return null;
    }
  }

// Get active shares for user
  Future<List<LiveLocationShare>> getActiveShares(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('live_locations')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        return LiveLocationShare.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint('❌ Get active shares error: $e');
      return [];
    }
  }

// Get all shares for user
  Future<List<LiveLocationShare>> getAllShares(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('live_locations')
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return LiveLocationShare.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint('❌ Get all shares error: $e');
      return [];
    }
  }

// Stream live location updates
  Stream<LiveLocationShare?> streamLocation(String shareId) {
    return _firestore
        .collection('live_locations')
        .doc(shareId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return LiveLocationShare.fromMap(snapshot.data()!, snapshot.id);
    });
  }

// Get share statistics
  Future<Map<String, dynamic>> getShareStatistics(String userId) async {
    try {
      final shares = await getAllShares(userId);

      final totalShares = shares.length;
      final activeShares = shares.where((s) => s.isActive).length;
      final expiredShares = shares.where((s) => !s.isActive && s.endTime != null).length;

      final totalDuration = shares.fold<int>(0, (sum, share) {
        if (share.endTime != null) {
          return sum + share.endTime!.difference(share.startTime).inMinutes;
        }
        return sum;
      });

      return {
        'totalShares': totalShares,
        'activeShares': activeShares,
        'expiredShares': expiredShares,
        'totalDuration': totalDuration,
      };
    } catch (e) {
      debugPrint('❌ Get share statistics error: $e');
      return {};
    }
  }

// Generate shareable link
  String generateShareLink(String shareCode) {
    return 'https://akel.app/live/$shareCode';
  }

// Generate share message
  String generateShareMessage(String userName, String shareCode, ShareDuration duration) {
    final link = generateShareLink(shareCode);
    final durationText = getDurationLabel(duration);

    return '🚨 EMERGENCY - $userName is sharing their live location with you.\n\n'
        '📍 View Location: $link\n'
        '🔑 Share Code: $shareCode\n'
        '⏱️ Duration: $durationText\n\n'
        'This is an automated emergency alert from AKEL.';
  }

// Get duration label
  static String getDurationLabel(ShareDuration duration) {
    switch (duration) {
      case ShareDuration.fifteenMin:
        return '15 Minutes';
      case ShareDuration.oneHour:
        return '1 Hour';
      case ShareDuration.eightHours:
        return '8 Hours';
      case ShareDuration.untilStopped:
        return 'Until Stopped';
    }
  }

// Get duration icon
  static String getDurationIcon(ShareDuration duration) {
    switch (duration) {
      case ShareDuration.fifteenMin:
        return '⏱️';
      case ShareDuration.oneHour:
        return '⏰';
      case ShareDuration.eightHours:
        return '🕐';
      case ShareDuration.untilStopped:
        return '♾️';
    }
  }

// Format accuracy
  String formatAccuracy(double accuracy) {
    if (accuracy < 10) return 'Excellent (${accuracy.toInt()}m)';
    if (accuracy < 50) return 'Good (${accuracy.toInt()}m)';
    if (accuracy < 100) return 'Fair (${accuracy.toInt()}m)';
    return 'Poor (${accuracy.toInt()}m)';
  }

// Dispose
  void dispose() {
    _locationStream?.cancel();
    _expirationTimer?.cancel();
  }
}