import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:battery_plus/battery_plus.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/vibration_service.dart';

class FamilyDeviceLinkingScreen extends StatefulWidget {
  const FamilyDeviceLinkingScreen({super.key});

  @override
  State<FamilyDeviceLinkingScreen> createState() => _FamilyDeviceLinkingScreenState();
}

class _FamilyDeviceLinkingScreenState extends State<FamilyDeviceLinkingScreen>
    with SingleTickerProviderStateMixin {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final VibrationService _vibrationService = VibrationService();
  final Battery _battery = Battery();

  late TabController _tabController;
  final TextEditingController _emailController = TextEditingController();

  bool _isSending = false;
  StreamSubscription<Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _startSharingMyLocation();
    _updateMyStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _locationSubscription?.cancel();
    _stopSharingMyLocation();
    super.dispose();
  }

  // ==================== MY STATUS ====================

  Future<void> _updateMyStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final batteryLevel = await _battery.batteryLevel;

      await _firestore.collection('users').doc(user.uid).update({
        'familyStatus': {
          'isOnline': true,
          'batteryLevel': batteryLevel,
          'lastSeen': FieldValue.serverTimestamp(),
          'displayName': user.displayName ?? user.email ?? 'Unknown',
          'email': user.email ?? '',
        },
      });
    } catch (e) {
      debugPrint('Update status error: ' + e.toString());
    }
  }

  Future<void> _startSharingMyLocation() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      ).listen((position) async {
        await _firestore.collection('users').doc(user.uid).update({
          'familyStatus.location': {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': FieldValue.serverTimestamp(),
            'accuracy': position.accuracy,
          },
          'familyStatus.lastSeen': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('Start sharing location error: ' + e.toString());
    }
  }

  Future<void> _stopSharingMyLocation() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _locationSubscription?.cancel();

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'familyStatus.isOnline': false,
        'familyStatus.lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Stop sharing location error: ' + e.toString());
    }
  }

  // ==================== INVITATIONS ====================

  Future<void> _sendInvitation(String currentUserId) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Please enter an email address', Colors.orange);
      return;
    }

    if (email == _auth.currentUser?.email) {
      _showSnackBar('You cannot link to yourself', Colors.orange);
      return;
    }

    setState(() => _isSending = true);

    try {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        _showSnackBar('No user found with that email', Colors.red);
        setState(() => _isSending = false);
        return;
      }

      final targetUserId = userQuery.docs.first.id;
      final targetUserData = userQuery.docs.first.data();

      final existingLink = await _firestore
          .collection('family_links')
          .where('requesterId', isEqualTo: currentUserId)
          .where('targetId', isEqualTo: targetUserId)
          .limit(1)
          .get();

      if (existingLink.docs.isNotEmpty) {
        _showSnackBar('Invitation already sent to this user', Colors.orange);
        setState(() => _isSending = false);
        return;
      }

      final currentUserData = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      final requesterName = currentUserData.data()?['name'] ??
          _auth.currentUser?.displayName ??
          _auth.currentUser?.email ??
          'Unknown';

      await _firestore.collection('family_links').add({
        'requesterId': currentUserId,
        'requesterName': requesterName,
        'requesterEmail': _auth.currentUser?.email ?? '',
        'targetId': targetUserId,
        'targetName': targetUserData['name'] ?? email,
        'targetEmail': email,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'permissions': {
          'canSeeLocation': true,
          'canSendAlerts': true,
          'canSeeBattery': true,
          'canRequestLocation': true,
          'canReceiveAlerts': true,
          'canSeeHealthRecords': false,
        },
      });

      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('notifications')
          .add({
        'type': 'family_link_request',
        'fromUserId': currentUserId,
        'fromUserName': requesterName,
        'fromUserEmail': _auth.currentUser?.email ?? '',
        'message': requesterName + ' wants to link their device with yours',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      _emailController.clear();
      _showSnackBar('Invitation sent to ' + email, Colors.green);
      await _vibrationService.light();
    } catch (e) {
      _showSnackBar('Failed to send invitation: ' + e.toString(), Colors.red);
    }

    setState(() => _isSending = false);
  }

  Future<void> _acceptInvitation(String linkId, String requesterId) async {
    try {
      await _vibrationService.light();

      final permissions = await _showPermissionDialog();
      if (permissions == null) return;

      await _firestore.collection('family_links').doc(linkId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'permissions': permissions,
      });

      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final currentUserData = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final requesterData = await _firestore
          .collection('users')
          .doc(requesterId)
          .get();

      await _firestore.collection('family_links').add({
        'requesterId': currentUser.uid,
        'requesterName': currentUserData.data()?['name'] ?? currentUser.email ?? 'Unknown',
        'requesterEmail': currentUser.email ?? '',
        'targetId': requesterId,
        'targetName': requesterData.data()?['name'] ?? 'Unknown',
        'targetEmail': requesterData.data()?['email'] ?? '',
        'status': 'accepted',
        'createdAt': FieldValue.serverTimestamp(),
        'acceptedAt': FieldValue.serverTimestamp(),
        'permissions': permissions,
      });

      await _firestore
          .collection('users')
          .doc(requesterId)
          .collection('notifications')
          .add({
        'type': 'family_link_accepted',
        'fromUserId': currentUser.uid,
        'fromUserName': currentUserData.data()?['name'] ?? currentUser.email ?? 'Unknown',
        'message': (currentUserData.data()?['name'] ?? currentUser.email ?? 'Someone') + ' accepted your family link request',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      _showSnackBar('Family link accepted', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to accept invitation: ' + e.toString(), Colors.red);
    }
  }

  Future<void> _declineInvitation(String linkId) async {
    try {
      await _vibrationService.light();
      await _firestore.collection('family_links').doc(linkId).update({
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
      });
      _showSnackBar('Invitation declined', Colors.orange);
    } catch (e) {
      _showSnackBar('Failed to decline invitation: ' + e.toString(), Colors.red);
    }
  }

  Future<void> _removeLink(String linkId, String memberName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Remove ' + memberName + '?',
          style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color),
        ),
        content: Text(
          'This will remove the family link with ' + memberName + '. They will no longer be able to see your location or send you alerts.',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _vibrationService.warning();
        await _firestore.collection('family_links').doc(linkId).delete();
        _showSnackBar(memberName + ' removed from family links', Colors.green);
      } catch (e) {
        _showSnackBar('Failed to remove link: ' + e.toString(), Colors.red);
      }
    }
  }

  // ==================== ALERTS ====================

  Future<void> _sendAlertToMember(
      String targetUserId,
      String targetName,
      String currentUserId,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Alert ' + targetName + '?',
          style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color),
        ),
        content: Text(
          'This will send an emergency alert to ' + targetName + '.',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _vibrationService.heavy();

        Position? position;
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
        } catch (e) {
          debugPrint('Location error: ' + e.toString());
        }

        final currentUserData = await _firestore
            .collection('users')
            .doc(currentUserId)
            .get();

        final senderName = currentUserData.data()?['name'] ??
            _auth.currentUser?.email ??
            'A family member';

        await _firestore
            .collection('users')
            .doc(targetUserId)
            .collection('notifications')
            .add({
          'type': 'family_panic_alert',
          'fromUserId': currentUserId,
          'fromUserName': senderName,
          'message': 'EMERGENCY: ' + senderName + ' needs help!',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'location': position != null
              ? {
            'latitude': position.latitude,
            'longitude': position.longitude,
          }
              : null,
        });

        _showSnackBar('Alert sent to ' + targetName, Colors.green);
      } catch (e) {
        _showSnackBar('Failed to send alert: ' + e.toString(), Colors.red);
      }
    }
  }

  Future<void> _requestLocation(String targetUserId, String targetName) async {
    try {
      await _vibrationService.light();

      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('notifications')
          .add({
        'type': 'location_request',
        'fromUserId': currentUser.uid,
        'fromUserEmail': currentUser.email ?? '',
        'message': (currentUser.displayName ?? currentUser.email ?? 'A family member') + ' is requesting your current location',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      _showSnackBar('Location request sent to ' + targetName, Colors.green);
    } catch (e) {
      _showSnackBar('Failed to request location: ' + e.toString(), Colors.red);
    }
  }

  // ==================== HEALTH RECORDS ====================

  Future<void> _viewHealthRecords(String targetUserId, String targetName) async {
    try {
      final healthDoc = await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('medical_info')
          .doc('emergency')
          .get();

      if (!mounted) return;

      if (!healthDoc.exists || healthDoc.data() == null) {
        _showSnackBar(targetName + ' has not set up health records yet', Colors.orange);
        return;
      }

      final data = healthDoc.data()!;

      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).cardColor,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.medical_services, color: Colors.red, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            targetName + ' - Health Records',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Shared with your permission',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _buildHealthSection('Blood Type', Icons.bloodtype, Colors.red,
                    data['bloodType']?.toString() ?? 'Not set'),

                _buildHealthSection('Allergies', Icons.warning_amber, Colors.orange,
                    data['allergies']?.toString() ?? 'None listed'),

                _buildHealthSection('Medical Conditions', Icons.monitor_heart, Colors.purple,
                    data['conditions']?.toString() ?? 'None listed'),

                _buildHealthSection('Current Medications', Icons.medication, Colors.blue,
                    data['medications']?.toString() ?? 'None listed'),

                _buildHealthSection('Emergency Notes', Icons.note_alt, Colors.teal,
                    data['emergencyNotes']?.toString() ?? 'None'),

                _buildHealthSection('Doctor Name', Icons.person, Colors.green,
                    data['doctorName']?.toString() ?? 'Not set'),

                _buildHealthSection('Doctor Phone', Icons.phone, Colors.green,
                    data['doctorPhone']?.toString() ?? 'Not set'),

                _buildHealthSection('Hospital', Icons.local_hospital, Colors.red,
                    data['hospital']?.toString() ?? 'Not set'),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This information is confidential. Only use it in an emergency.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      _showSnackBar('Failed to load health records: ' + e.toString(), Colors.red);
    }
  }

  Widget _buildHealthSection(String label, IconData icon, Color color, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PERMISSION DIALOG ====================

  Future<Map<String, dynamic>?> _showPermissionDialog() async {
    bool canSeeLocation = true;
    bool canSendAlerts = true;
    bool canSeeBattery = true;
    bool canRequestLocation = true;
    bool canReceiveAlerts = true;
    bool canSeeHealthRecords = false;

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            'Set Permissions',
            style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose what this family member can do:',
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 16),
                _buildPermissionTile(
                  'See my location',
                  Icons.location_on,
                  canSeeLocation,
                      (val) => setDialogState(() => canSeeLocation = val),
                ),
                _buildPermissionTile(
                  'Send me alerts',
                  Icons.warning_amber,
                  canSendAlerts,
                      (val) => setDialogState(() => canSendAlerts = val),
                ),
                _buildPermissionTile(
                  'See my battery level',
                  Icons.battery_full,
                  canSeeBattery,
                      (val) => setDialogState(() => canSeeBattery = val),
                ),
                _buildPermissionTile(
                  'Request my location',
                  Icons.my_location,
                  canRequestLocation,
                      (val) => setDialogState(() => canRequestLocation = val),
                ),
                _buildPermissionTile(
                  'Receive my alerts',
                  Icons.notifications_active,
                  canReceiveAlerts,
                      (val) => setDialogState(() => canReceiveAlerts = val),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.medical_services, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Health Records Access',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'This grants access to sensitive medical information including blood type, allergies, medications and conditions. Only enable for trusted family members.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPermissionTile(
                  'See my health records',
                  Icons.health_and_safety,
                  canSeeHealthRecords,
                      (val) => setDialogState(() => canSeeHealthRecords = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'canSeeLocation': canSeeLocation,
                'canSendAlerts': canSendAlerts,
                'canSeeBattery': canSeeBattery,
                'canRequestLocation': canRequestLocation,
                'canReceiveAlerts': canReceiveAlerts,
                'canSeeHealthRecords': canSeeHealthRecords,
              }),
              child: const Text('Accept'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile(
      String label,
      IconData icon,
      bool value,
      ValueChanged<bool> onChanged,
      ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).primaryColor,
        ),
      ],
    );
  }

  // ==================== HELPERS ====================

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  String _timeSince(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    final now = DateTime.now();
    final time = timestamp.toDate();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return diff.inMinutes.toString() + 'm ago';
    if (diff.inHours < 24) return diff.inHours.toString() + 'h ago';
    return diff.inDays.toString() + 'd ago';
  }

  Color _batteryColor(int level) {
    if (level >= 60) return Colors.green;
    if (level >= 30) return Colors.orange;
    return Colors.red;
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Family Linking')),
        body: const Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Device Linking'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Family'),
            Tab(icon: Icon(Icons.mail_outline), text: 'Requests'),
            Tab(icon: Icon(Icons.person_add), text: 'Invite'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFamilyTab(userId),
          _buildRequestsTab(userId),
          _buildInviteTab(userId),
        ],
      ),
    );
  }

  // ==================== FAMILY TAB ====================

  Widget _buildFamilyTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('family_links')
          .where('requesterId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
          );
        }

        final links = snapshot.data?.docs ?? [];

        if (links.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Theme.of(context).textTheme.bodySmall?.color),
                const SizedBox(height: 16),
                Text(
                  'No Family Members Linked',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Go to Invite tab to add family members',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: links.length,
          itemBuilder: (context, index) {
            final link = links[index].data() as Map<String, dynamic>;
            final linkId = links[index].id;
            final targetId = link['targetId'] as String;
            final targetName = link['targetName'] as String? ?? 'Unknown';
            final permissions = link['permissions'] as Map<String, dynamic>? ?? {};

            return StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(targetId).snapshots(),
              builder: (context, userSnapshot) {
                final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                final familyStatus = userData?['familyStatus'] as Map<String, dynamic>?;
                final isOnline = familyStatus?['isOnline'] as bool? ?? false;
                final batteryLevel = familyStatus?['batteryLevel'] as int? ?? 0;
                final lastSeen = familyStatus?['lastSeen'] as Timestamp?;
                final location = familyStatus?['location'] as Map<String, dynamic>?;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isOnline
                              ? Colors.green.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                          child: Icon(
                            Icons.person,
                            color: isOnline ? Colors.green : Colors.grey,
                          ),
                        ),
                        title: Text(
                          targetName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.headlineMedium?.color,
                          ),
                        ),
                        subtitle: Text(
                          isOnline ? 'Online' : 'Last seen ' + _timeSince(lastSeen),
                          style: TextStyle(
                            color: isOnline ? Colors.green : Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                        trailing: permissions['canSeeBattery'] == true
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.battery_full,
                              color: _batteryColor(batteryLevel),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              batteryLevel.toString() + '%',
                              style: TextStyle(
                                color: _batteryColor(batteryLevel),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                            : null,
                      ),

                      if (location != null && permissions['canSeeLocation'] == true)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                'Lat: ' + (location['latitude'] as double).toStringAsFixed(4) +
                                    ', Lng: ' + (location['longitude'] as double).toStringAsFixed(4),
                                style: const TextStyle(fontSize: 11, color: Colors.blue),
                              ),
                            ],
                          ),
                        ),

                      const Divider(height: 1),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          children: [
                            if (permissions['canSendAlerts'] == true)
                              TextButton.icon(
                                icon: const Icon(Icons.warning_amber, color: Colors.red, size: 18),
                                label: const Text('Alert', style: TextStyle(color: Colors.red, fontSize: 12)),
                                onPressed: () => _sendAlertToMember(targetId, targetName, userId),
                              ),
                            if (permissions['canRequestLocation'] == true)
                              TextButton.icon(
                                icon: Icon(Icons.my_location, color: Theme.of(context).primaryColor, size: 18),
                                label: Text('Location', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12)),
                                onPressed: () => _requestLocation(targetId, targetName),
                              ),
                            if (permissions['canSeeHealthRecords'] == true)
                              TextButton.icon(
                                icon: const Icon(Icons.medical_services, color: Colors.red, size: 18),
                                label: const Text('Health', style: TextStyle(color: Colors.red, fontSize: 12)),
                                onPressed: () => _viewHealthRecords(targetId, targetName),
                              ),
                            TextButton.icon(
                              icon: const Icon(Icons.link_off, color: Colors.grey, size: 18),
                              label: const Text('Remove', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              onPressed: () => _removeLink(linkId, targetName),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ==================== REQUESTS TAB ====================

  Widget _buildRequestsTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('family_links')
          .where('targetId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
          );
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 64, color: Theme.of(context).textTheme.bodySmall?.color),
                const SizedBox(height: 16),
                Text(
                  'No Pending Requests',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Family link requests will appear here',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index].data() as Map<String, dynamic>;
            final requestId = requests[index].id;
            final requesterName = request['requesterName'] as String? ?? 'Unknown';
            final requesterEmail = request['requesterEmail'] as String? ?? '';
            final createdAt = request['createdAt'] as Timestamp?;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.2),
                          child: const Icon(Icons.person, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                requesterName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.headlineMedium?.color,
                                ),
                              ),
                              Text(
                                requesterEmail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                              Text(
                                'Sent ' + _timeSince(createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      requesterName + ' wants to link their device with yours. You can choose what permissions to grant.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _declineInvitation(requestId),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Decline'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _acceptInvitation(requestId, request['requesterId']),
                            child: const Text('Accept'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== INVITE TAB ====================

  Widget _buildInviteTab(String userId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INVITE A FAMILY MEMBER',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enter the email address of the family member you want to link with. They must have an AKEL account.',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'family@example.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isSending
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Icon(Icons.send),
                      label: Text(_isSending ? 'Sending...' : 'Send Invitation'),
                      onPressed: _isSending ? null : () => _sendInvitation(userId),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'HOW IT WORKS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          _buildHowItWorksStep('1', 'Send an invitation to a family member using their email', Icons.mail_outline, Colors.blue),
          _buildHowItWorksStep('2', 'They receive a request and choose what permissions to grant', Icons.security, Colors.orange),
          _buildHowItWorksStep('3', 'Once accepted you can see their location and battery level', Icons.location_on, Colors.green),
          _buildHowItWorksStep('4', 'Either of you can send panic alerts to the other', Icons.warning_amber, Colors.red),
          _buildHowItWorksStep('5', 'With permission you can view their health records in an emergency', Icons.medical_services, Colors.purple),
          _buildHowItWorksStep('6', 'You can remove the link at any time from the Family tab', Icons.link_off, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildHowItWorksStep(String step, String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
            child: Center(
              child: Text(
                step,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}