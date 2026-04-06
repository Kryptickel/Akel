import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class PanicHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get panic events for a user (simplified - no index needed)
  Future<List<Map<String, dynamic>>> getPanicHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('panic_events')
          .where('userId', isEqualTo: userId)
          .get();

      // Sort in memory instead of Firestore
      final events = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort by timestamp descending
      events.sort((a, b) {
        final aTime = (a['timestamp'] as Timestamp).toDate();
        final bTime = (b['timestamp'] as Timestamp).toDate();
        return bTime.compareTo(aTime); // Descending order
      });

      return events;
    } catch (e) {
      debugPrint(' Get panic history error: $e');
      return [];
    }
  }

  // Get panic events with date filter (simplified - no index needed)
  Future<List<Map<String, dynamic>>> getPanicHistoryByDateRange(
      String userId,
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      final snapshot = await _firestore
          .collection('panic_events')
          .where('userId', isEqualTo: userId)
          .get();

      // Filter and sort in memory
      final events = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).where((event) {
        final timestamp = (event['timestamp'] as Timestamp).toDate();
        return timestamp.isAfter(startDate) && timestamp.isBefore(endDate);
      }).toList();

      // Sort by timestamp descending
      events.sort((a, b) {
        final aTime = (a['timestamp'] as Timestamp).toDate();
        final bTime = (b['timestamp'] as Timestamp).toDate();
        return bTime.compareTo(aTime);
      });

      return events;
    } catch (e) {
      debugPrint(' Get panic history by date error: $e');
      return [];
    }
  }

  // Get location trail for a specific panic event
  Future<List<Map<String, dynamic>>> getLocationTrail(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('panic_events')
          .doc(eventId)
          .collection('location_trail')
          .get();

      final trail = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort by timestamp ascending
      trail.sort((a, b) {
        final aTime = (a['timestamp'] as Timestamp).toDate();
        final bTime = (b['timestamp'] as Timestamp).toDate();
        return aTime.compareTo(bTime);
      });

      return trail;
    } catch (e) {
      debugPrint(' Get location trail error: $e');
      return [];
    }
  }

  // Get panic statistics
  Future<Map<String, dynamic>> getPanicStatistics(String userId) async {
    try {
      final events = await getPanicHistory(userId);

      if (events.isEmpty) {
        return {
          'totalEvents': 0,
          'thisMonth': 0,
          'thisWeek': 0,
          'averageResponseTime': 0,
          'mostCommonHour': 0,
          'silentModeUsage': 0,
        };
      }

      final now = DateTime.now();
      final thisMonth = events.where((e) {
        final timestamp = (e['timestamp'] as Timestamp).toDate();
        return timestamp.year == now.year && timestamp.month == now.month;
      }).length;

      final thisWeek = events.where((e) {
        final timestamp = (e['timestamp'] as Timestamp).toDate();
        final diff = now.difference(timestamp).inDays;
        return diff <= 7;
      }).length;

      // Calculate most common hour
      final hourCounts = <int, int>{};
      for (var event in events) {
        final timestamp = (event['timestamp'] as Timestamp).toDate();
        final hour = timestamp.hour;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }

      int mostCommonHour = 0;
      int maxCount = 0;
      hourCounts.forEach((hour, count) {
        if (count > maxCount) {
          maxCount = count;
          mostCommonHour = hour;
        }
      });

      // Calculate silent mode usage
      final silentEvents = events.where((e) => e['silentMode'] == true).length;
      final silentPercentage = (silentEvents / events.length * 100).round();

      return {
        'totalEvents': events.length,
        'thisMonth': thisMonth,
        'thisWeek': thisWeek,
        'mostCommonHour': mostCommonHour,
        'silentModeUsage': silentPercentage,
        'lastEvent': events.first['timestamp'],
      };
    } catch (e) {
      debugPrint(' Get panic statistics error: $e');
      return {
        'totalEvents': 0,
        'thisMonth': 0,
        'thisWeek': 0,
        'mostCommonHour': 0,
        'silentModeUsage': 0,
      };
    }
  }

  // Generate shareable panic report
  String generatePanicReport(Map<String, dynamic> event) {
    final timestamp = (event['timestamp'] as Timestamp).toDate();
    final dateStr = DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp);

    final report = StringBuffer();
    report.writeln(' AKEL PANIC ALERT REPORT');
    report.writeln('═══════════════════════════════════');
    report.writeln('');
    report.writeln(' Date & Time: $dateStr');
    report.writeln(' User: ${event['userName'] ?? 'Unknown'}');
    report.writeln('');
    report.writeln(' LOCATION:');
    if (event['latitude'] != null && event['longitude'] != null) {
      report.writeln(' Coordinates: ${event['latitude']}, ${event['longitude']}');
      report.writeln(' Google Maps: https://maps.google.com/?q=${event['latitude']},${event['longitude']}');
    } else {
      report.writeln(' Location unavailable');
    }
    report.writeln('');
    report.writeln(' ALERT DETAILS:');
    report.writeln(' Mode: ${event['silentMode'] == true ? 'Silent' : 'Normal'}');
    report.writeln(' Contacts Notified: ${event['contactsNotified'] ?? 0}');
    report.writeln(' Status: ${event['status'] ?? 'Unknown'}');
    report.writeln('');
    if (event['locationTrackingActive'] == true) {
      report.writeln(' LOCATION TRACKING:');
      report.writeln(' Status: Active during event');
      report.writeln(' Trail: Available in app');
      report.writeln('');
    }
    report.writeln('═══════════════════════════════════');
    report.writeln('Generated by AKEL Panic Button');
    report.writeln('For emergency use only');

    return report.toString();
  }

  // Delete panic event
  Future<bool> deletePanicEvent(String eventId) async {
    try {
      await _firestore.collection('panic_events').doc(eventId).delete();
      debugPrint(' Panic event deleted: $eventId');
      return true;
    } catch (e) {
      debugPrint(' Delete panic event error: $e');
      return false;
    }
  }

  // Clear all panic history for user
  Future<bool> clearAllHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('panic_events')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint(' All panic history cleared for user: $userId');
      return true;
    } catch (e) {
      debugPrint(' Clear panic history error: $e');
      return false;
    }
  }
}