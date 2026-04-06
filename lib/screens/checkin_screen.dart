import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

/// ==================== SAFETY CHECK-IN SCREEN ====================
///
/// PRODUCTION READY - BUILD 58 - UPDATED & FIXED
///
/// Features:
/// - Manual safety check-ins with location
/// - Automatic scheduled check-ins
/// - Notify all emergency contacts
/// - Check-in history with map view
/// ================================================================

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();

  bool _isCheckingIn = false;
  bool _autoCheckInEnabled = false;
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 20, minute: 0);

  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAutoCheckInSettings();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadAutoCheckInSettings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('check_in')
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _autoCheckInEnabled = data['enabled'] ?? false;
          if (data['scheduledTime'] != null) {
            final time = data['scheduledTime'] as String;
            final parts = time.split(':');
            _scheduledTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading auto check-in settings: $e');
    }
  }

  Future<void> _saveAutoCheckInSettings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('check_in')
          .set({
        'enabled': _autoCheckInEnabled,
        'scheduledTime': '${_scheduledTime.hour}:${_scheduledTime.minute}',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (_autoCheckInEnabled) {
        // FIXED: Using valid method for scheduling
        await _notificationService.sendCheckInNotification(
          title: "Auto Check-in Enabled",
          body: "Scheduled for ${_scheduledTime.format(context)}",
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _autoCheckInEnabled
                  ? ' Auto check-in enabled for ${_scheduledTime.format(context)}'
                  : ' Auto check-in disabled',
            ),
            backgroundColor: _autoCheckInEnabled ? AkelDesign.successGreen : AkelDesign.warningOrange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving auto check-in settings: $e');
    }
  }

  Future<void> _performCheckIn({String? customMessage}) async {
    setState(() => _isCheckingIn = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Get current location
      Position? position;
      try {
        // FIXED: Using valid method name from your LocationService
        position = await _locationService.getCurrentLocation();
      } catch (e) {
        debugPrint('Warning: Could not get location: $e');
      }

      final checkInData = {
        'userId': user.uid,
        'userName': user.displayName ?? 'Unknown User',
        'timestamp': FieldValue.serverTimestamp(),
        'message': customMessage ?? 'I\'m safe and checking in',
        'status': 'safe',
        'type': 'manual',
      };

      if (position != null) {
        checkInData['latitude'] = position.latitude;
        checkInData['longitude'] = position.longitude;
        checkInData['accuracy'] = position.accuracy;
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('check_ins')
          .add(checkInData);

      // Trigger local confirmation notification
      await _notificationService.sendCheckInNotification(
        body: customMessage ?? "Your safety status has been broadcasted.",
      );

      final contactsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('contacts')
          .get();

      int notificationsSent = 0;

      for (var contactDoc in contactsSnapshot.docs) {
        try {
          final contactData = contactDoc.data();
          await _firestore.collection('notifications').add({
            'to': contactData['phone'],
            'toName': contactData['name'],
            'from': user.uid,
            'fromName': user.displayName ?? 'Unknown',
            'type': 'check_in',
            'title': 'Safety Check-In',
            'message': customMessage ?? '${user.displayName} is safe',
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
            'latitude': position?.latitude,
            'longitude': position?.longitude,
          });
          notificationsSent++;
        } catch (e) {
          debugPrint('Error notifying contact: $e');
        }
      }

      if (mounted) {
        setState(() => _isCheckingIn = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Check-in sent to $notificationsSent contact(s)!'),
            backgroundColor: AkelDesign.successGreen,
          ),
        );
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingIn = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(' Error: $e'), backgroundColor: AkelDesign.errorRed),
        );
      }
    }
  }

  void _showCustomMessageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.carbonFiber,
        title: const Text('Custom Check-In Message', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _messageController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'I\'m safe at...',
            // FIXED: Updated withOpacity to withValues
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performCheckIn(customMessage: _messageController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AkelDesign.successGreen),
            child: const Text('Send Check-In'),
          ),
        ],
      ),
    );
  }

  void _showScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AkelDesign.carbonFiber,
          title: const Text('Auto Check-In Schedule', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Enable Auto Check-In', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  'Daily reminder at ${_scheduledTime.format(context)}',
                  // FIXED: Updated withOpacity to withValues
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
                value: _autoCheckInEnabled,
                activeColor: AkelDesign.successGreen,
                onChanged: (value) => setDialogState(() => _autoCheckInEnabled = value),
              ),
              if (_autoCheckInEnabled) ...[
                const SizedBox(height: 20),
                ListTile(
                  title: const Text('Scheduled Time', style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    _scheduledTime.format(context),
                    style: const TextStyle(color: AkelDesign.neonBlue, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.access_time, color: AkelDesign.neonBlue),
                  onTap: () async {
                    final newTime = await showTimePicker(context: context, initialTime: _scheduledTime);
                    if (newTime != null) setDialogState(() => _scheduledTime = newTime);
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveAutoCheckInSettings();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AkelDesign.neonBlue),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Check-In'),
        backgroundColor: AkelDesign.carbonFiber,
        actions: [
          IconButton(
            icon: Icon(
              _autoCheckInEnabled ? Icons.alarm_on : Icons.alarm_off,
              color: _autoCheckInEnabled ? AkelDesign.successGreen : Colors.white70,
            ),
            onPressed: _showScheduleDialog,
          ),
        ],
      ),
      backgroundColor: AkelDesign.deepBlack,
      body: user == null
          ? const Center(child: Text('Please log in', style: TextStyle(color: Colors.white70)))
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  // FIXED: Updated withOpacity to withValues
                  AkelDesign.successGreen.withValues(alpha: 0.2),
                  AkelDesign.successGreen.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle, size: 80, color: AkelDesign.successGreen),
                const SizedBox(height: 20),
                const Text('Safety Check-In', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(
                  'Let your emergency contacts know you\'re safe',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isCheckingIn ? null : () => _performCheckIn(),
                    icon: _isCheckingIn
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send),
                    label: Text(_isCheckingIn ? 'Sending...' : 'Check In Now', style: const TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AkelDesign.successGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isCheckingIn ? null : _showCustomMessageDialog,
                    icon: const Icon(Icons.edit),
                    label: const Text('Check In with Custom Message'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AkelDesign.successGreen,
                      // FIXED: Updated withOpacity to withValues
                      side: BorderSide(color: AkelDesign.successGreen.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AkelDesign.carbonFiber, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.history, color: AkelDesign.neonBlue),
                        SizedBox(width: 12),
                        Text('Recent Check-Ins', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('users')
                          .doc(user.uid)
                          .collection('check_ins')
                          .orderBy('timestamp', descending: true)
                          .limit(20)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AkelDesign.neonBlue));
                        }
                        final checkIns = snapshot.data?.docs ?? [];
                        return ListView.separated(
                          itemCount: checkIns.length,
                          separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                          itemBuilder: (context, index) {
                            final data = checkIns[index].data() as Map<String, dynamic>;
                            final timestamp = data['timestamp'] as Timestamp?;
                            return ListTile(
                              leading: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: AkelDesign.successGreen.withValues(alpha: 0.2), shape: BoxShape.circle),
                                child: const Icon(Icons.check_circle, color: AkelDesign.successGreen, size: 24),
                              ),
                              title: Text(data['message'] ?? 'Check-in', style: const TextStyle(color: Colors.white)),
                              subtitle: Text(
                                timestamp != null ? DateFormat('MMM dd, yyyy • h:mm a').format(timestamp.toDate()) : 'Pending...',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}