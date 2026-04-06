import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum BroadcastType { fire, medical, police, danger, safe, custom }
enum DeliveryStatus { pending, sent, failed }

class BroadcastMessage {
  final String id;
  final String userId;
  final String userName;
  final BroadcastType type;
  final String message;
  final DateTime timestamp;
  final bool includeLocation;
  final double? latitude;
  final double? longitude;
  final List<String> recipients;
  final Map<String, DeliveryStatus> deliveryStatus;
  final int totalRecipients;
  final int successfulDeliveries;
  final int failedDeliveries;

  BroadcastMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.message,
    required this.timestamp,
    this.includeLocation = true,
    this.latitude,
    this.longitude,
    required this.recipients,
    required this.deliveryStatus,
    required this.totalRecipients,
    required this.successfulDeliveries,
    required this.failedDeliveries,
  });

  factory BroadcastMessage.fromMap(Map<String, dynamic> map, String id) {
    final deliveryStatusMap = (map['deliveryStatus'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, _statusFromString(value as String)),
    ) ??
        {};

    return BroadcastMessage(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      type: _typeFromString(map['type'] ?? 'custom'),
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      includeLocation: map['includeLocation'] ?? false,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      recipients: List<String>.from(map['recipients'] ?? []),
      deliveryStatus: deliveryStatusMap,
      totalRecipients: map['totalRecipients'] ?? 0,
      successfulDeliveries: map['successfulDeliveries'] ?? 0,
      failedDeliveries: map['failedDeliveries'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'type': _typeToString(type),
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'includeLocation': includeLocation,
      'latitude': latitude,
      'longitude': longitude,
      'recipients': recipients,
      'deliveryStatus': deliveryStatus.map(
            (key, value) => MapEntry(key, _statusToString(value)),
      ),
      'totalRecipients': totalRecipients,
      'successfulDeliveries': successfulDeliveries,
      'failedDeliveries': failedDeliveries,
    };
  }

  static BroadcastType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return BroadcastType.fire;
      case 'medical':
        return BroadcastType.medical;
      case 'police':
        return BroadcastType.police;
      case 'danger':
        return BroadcastType.danger;
      case 'safe':
        return BroadcastType.safe;
      default:
        return BroadcastType.custom;
    }
  }

  static String _typeToString(BroadcastType type) {
    switch (type) {
      case BroadcastType.fire:
        return 'fire';
      case BroadcastType.medical:
        return 'medical';
      case BroadcastType.police:
        return 'police';
      case BroadcastType.danger:
        return 'danger';
      case BroadcastType.safe:
        return 'safe';
      case BroadcastType.custom:
        return 'custom';
    }
  }

  static DeliveryStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return DeliveryStatus.sent;
      case 'failed':
        return DeliveryStatus.failed;
      default:
        return DeliveryStatus.pending;
    }
  }

  static String _statusToString(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'pending';
      case DeliveryStatus.sent:
        return 'sent';
      case DeliveryStatus.failed:
        return 'failed';
    }
  }
}

class BroadcastService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send broadcast message
  Future<BroadcastMessage?> sendBroadcast({
    required String userId,
    required String userName,
    required BroadcastType type,
    required String message,
    required List<Map<String, dynamic>> contacts,
    bool includeLocation = true,
  }) async {
    try {
      double? latitude;
      double? longitude;

      // Get location if requested
      if (includeLocation) {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          latitude = position.latitude;
          longitude = position.longitude;
        } catch (e) {
          debugPrint(' Could not get location: $e');
        }
      }

      // Build recipient list
      final recipients = contacts.map((c) => c['phone'] as String).toList();

      // Initialize delivery status
      final deliveryStatus = <String, DeliveryStatus>{};
      for (final phone in recipients) {
        deliveryStatus[phone] = DeliveryStatus.pending;
      }

      final broadcast = BroadcastMessage(
        id: '',
        userId: userId,
        userName: userName,
        type: type,
        message: message,
        timestamp: DateTime.now(),
        includeLocation: includeLocation,
        latitude: latitude,
        longitude: longitude,
        recipients: recipients,
        deliveryStatus: deliveryStatus,
        totalRecipients: recipients.length,
        successfulDeliveries: 0,
        failedDeliveries: 0,
      );

      // Save to Firestore
      final docRef = await _firestore.collection('broadcasts').add(broadcast.toMap());

      // Send messages to all contacts
      int successCount = 0;
      int failCount = 0;

      for (final contact in contacts) {
        final phone = contact['phone'] as String;
        final name = contact['name'] as String;

        try {
          // Build message with location if available
          String finalMessage = _buildMessage(type, message, userName);

          if (latitude != null && longitude != null) {
            finalMessage += '\n\n Location: https://maps.google.com/?q=$latitude,$longitude';
          }

          // Simulate SMS sending (in production, use actual SMS service)
          debugPrint(' Sending broadcast to $name ($phone): $finalMessage');

          // Update delivery status
          deliveryStatus[phone] = DeliveryStatus.sent;
          successCount++;
        } catch (e) {
          debugPrint(' Failed to send to $phone: $e');
          deliveryStatus[phone] = DeliveryStatus.failed;
          failCount++;
        }
      }

      // Update broadcast with delivery results
      await _firestore.collection('broadcasts').doc(docRef.id).update({
        'deliveryStatus': deliveryStatus.map(
              (key, value) => MapEntry(key, BroadcastMessage._statusToString(value)),
        ),
        'successfulDeliveries': successCount,
        'failedDeliveries': failCount,
      });

      debugPrint(' Broadcast sent: $successCount successful, $failCount failed');

      return BroadcastMessage(
        id: docRef.id,
        userId: userId,
        userName: userName,
        type: type,
        message: message,
        timestamp: DateTime.now(),
        includeLocation: includeLocation,
        latitude: latitude,
        longitude: longitude,
        recipients: recipients,
        deliveryStatus: deliveryStatus,
        totalRecipients: recipients.length,
        successfulDeliveries: successCount,
        failedDeliveries: failCount,
      );
    } catch (e) {
      debugPrint(' Send broadcast error: $e');
      return null;
    }
  }

  // Build message based on type
  String _buildMessage(BroadcastType type, String customMessage, String userName) {
    final baseMessage = getTemplateMessage(type, userName);

    if (type == BroadcastType.custom) {
      return customMessage;
    }

    return baseMessage;
  }

  // Get template message
  static String getTemplateMessage(BroadcastType type, String userName) {
    switch (type) {
      case BroadcastType.fire:
        return ' EMERGENCY: $userName is reporting a FIRE emergency!\n\n'
            'Immediate assistance needed. Please respond ASAP.';
      case BroadcastType.medical:
        return ' MEDICAL EMERGENCY: $userName needs immediate medical assistance!\n\n'
            'This is a critical situation. Please help or call emergency services.';
      case BroadcastType.police:
        return ' POLICE EMERGENCY: $userName is in danger and needs police assistance!\n\n'
            'Please call 911 or respond immediately.';
      case BroadcastType.danger:
        return ' DANGER ALERT: $userName is in a dangerous situation!\n\n'
            'Immediate help needed. Please respond or alert authorities.';
      case BroadcastType.safe:
        return ' SAFE: $userName is now safe.\n\n'
            'Emergency situation has been resolved. Thank you for your concern.';
      case BroadcastType.custom:
        return '';
    }
  }

  // Get all broadcasts for user
  Future<List<BroadcastMessage>> getBroadcasts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('broadcasts')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return BroadcastMessage.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint(' Get broadcasts error: $e');
      return [];
    }
  }

  // Delete broadcast
  Future<bool> deleteBroadcast(String broadcastId) async {
    try {
      await _firestore.collection('broadcasts').doc(broadcastId).delete();
      debugPrint(' Broadcast deleted: $broadcastId');
      return true;
    } catch (e) {
      debugPrint(' Delete broadcast error: $e');
      return false;
    }
  }

  // Get broadcast statistics
  Future<Map<String, dynamic>> getBroadcastStatistics(String userId) async {
    try {
      final broadcasts = await getBroadcasts(userId);

      final totalBroadcasts = broadcasts.length;
      final totalRecipients = broadcasts.fold<int>(
        0,
            (sum, b) => sum + b.totalRecipients,
      );
      final successfulDeliveries = broadcasts.fold<int>(
        0,
            (sum, b) => sum + b.successfulDeliveries,
      );
      final failedDeliveries = broadcasts.fold<int>(
        0,
            (sum, b) => sum + b.failedDeliveries,
      );

      final fireBroadcasts = broadcasts.where((b) => b.type == BroadcastType.fire).length;
      final medicalBroadcasts = broadcasts.where((b) => b.type == BroadcastType.medical).length;
      final policeBroadcasts = broadcasts.where((b) => b.type == BroadcastType.police).length;

      return {
        'totalBroadcasts': totalBroadcasts,
        'totalRecipients': totalRecipients,
        'successfulDeliveries': successfulDeliveries,
        'failedDeliveries': failedDeliveries,
        'successRate': totalRecipients > 0
            ? ((successfulDeliveries / totalRecipients) * 100).toStringAsFixed(1)
            : '0.0',
        'fireBroadcasts': fireBroadcasts,
        'medicalBroadcasts': medicalBroadcasts,
        'policeBroadcasts': policeBroadcasts,
      };
    } catch (e) {
      debugPrint(' Get broadcast statistics error: $e');
      return {};
    }
  }

  // Get type icon
  static String getTypeIcon(BroadcastType type) {
    switch (type) {
      case BroadcastType.fire:
        return ' ';
      case BroadcastType.medical:
        return ' ';
      case BroadcastType.police:
        return ' ';
      case BroadcastType.danger:
        return ' ';
      case BroadcastType.safe:
        return ' ';
      case BroadcastType.custom:
        return ' ';
    }
  }

  // Get type label
  static String getTypeLabel(BroadcastType type) {
    switch (type) {
      case BroadcastType.fire:
        return 'Fire Emergency';
      case BroadcastType.medical:
        return 'Medical Emergency';
      case BroadcastType.police:
        return 'Police Emergency';
      case BroadcastType.danger:
        return 'Danger Alert';
      case BroadcastType.safe:
        return 'Safe';
      case BroadcastType.custom:
        return 'Custom';
    }
  }

  // Get type color
  static String getTypeColor(BroadcastType type) {
    switch (type) {
      case BroadcastType.fire:
        return '#FF5722'; // Deep Orange
      case BroadcastType.medical:
        return '#F44336'; // Red
      case BroadcastType.police:
        return '#2196F3'; // Blue
      case BroadcastType.danger:
        return '#FF9800'; // Orange
      case BroadcastType.safe:
        return '#4CAF50'; // Green
      case BroadcastType.custom:
        return '#9C27B0'; // Purple
    }
  }

  // Get status icon
  static String getStatusIcon(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return ' ';
      case DeliveryStatus.sent:
        return ' ';
      case DeliveryStatus.failed:
        return ' ';
    }
  }

  // Get status label
  static String getStatusLabel(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'Pending';
      case DeliveryStatus.sent:
        return 'Sent';
      case DeliveryStatus.failed:
        return 'Failed';
    }
  }
}