import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/vibration_service.dart';

class RemoteFamilyMonitoringScreen extends StatefulWidget {
  const RemoteFamilyMonitoringScreen({super.key});

  @override
  State<RemoteFamilyMonitoringScreen> createState() =>
      _RemoteFamilyMonitoringScreenState();
}

class _RemoteFamilyMonitoringScreenState
    extends State<RemoteFamilyMonitoringScreen>
    with SingleTickerProviderStateMixin {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final VibrationService _vibrationService = VibrationService();

  late TabController _tabController;
  StreamSubscription<QuerySnapshot>? _alertSubscription;
  List<Map<String, dynamic>> _liveAlerts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _listenForFamilyAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _alertSubscription?.cancel();
    super.dispose();
  }

// ==================== LIVE ALERTS LISTENER ====================

  void _listenForFamilyAlerts() {
    final user = _auth.currentUser;
    if (user == null) return;

    _alertSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('type', isEqualTo: 'family_panic_alert')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty && mounted) {
        setState(() {
          _liveAlerts = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });

        _vibrationService.heavy();
        _showLiveAlertBanner(_liveAlerts.first);
      }
    });
  }

  void _showLiveAlertBanner(Map<String, dynamic> alert) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 8),
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'EMERGENCY: ' + (alert['fromUserName'] ?? 'Family member') + ' needs help!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.yellow,
          onPressed: () => _tabController.animateTo(1),
        ),
      ),
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
    final diff = DateTime.now().difference(timestamp.toDate());
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

  IconData _batteryIcon(int level) {
    if (level >= 80) return Icons.battery_full;
    if (level >= 60) return Icons.battery_5_bar;
    if (level >= 40) return Icons.battery_3_bar;
    if (level >= 20) return Icons.battery_1_bar;
    return Icons.battery_0_bar;
  }

  Future<List<Map<String, dynamic>>> _getFamilyMembers(String userId) async {
    final snapshot = await _firestore
        .collection('family_links')
        .where('requesterId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['linkId'] = doc.id;
      return data;
    }).toList();
  }

// ==================== ACTIONS ====================

  Future<void> _sendCheckInRequest(String targetUserId, String targetName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _vibrationService.light();

      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('notifications')
          .add({
        'type': 'checkin_request',
        'fromUserId': user.uid,
        'fromUserEmail': user.email ?? '',
        'fromUserName': user.displayName ?? user.email ?? 'A family member',
        'message': (user.displayName ?? user.email ?? 'A family member') + ' is asking you to confirm you are safe',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'requiresResponse': true,
      });

      _showSnackBar('Check-in request sent to ' + targetName, Colors.green);
    } catch (e) {
      _showSnackBar('Failed to send check-in request: ' + e.toString(), Colors.red);
    }
  }

  Future<void> _triggerSOSOnBehalf(
      String targetUserId,
      String targetName,
      String currentUserId,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Trigger SOS for ' + targetName + '?',
          style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color),
        ),
        content: Text(
          'This will create an emergency alert on behalf of ' + targetName + ' and notify their emergency contacts.',
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
            child: const Text('Trigger SOS'),
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

        final triggeredBy = currentUserData.data()?['name'] ??
            _auth.currentUser?.email ??
            'A family member';

        await _firestore.collection('panic_alerts').add({
          'userId': targetUserId,
          'triggeredBy': triggeredBy,
          'triggeredByUserId': currentUserId,
          'type': 'remote_sos',
          'timestamp': FieldValue.serverTimestamp(),
          'location': position != null
              ? {
            'latitude': position.latitude,
            'longitude': position.longitude,
          }
              : null,
          'message': 'EMERGENCY: Remote SOS triggered for ' + targetName + ' by ' + triggeredBy,
        });

        await _firestore
            .collection('users')
            .doc(targetUserId)
            .collection('notifications')
            .add({
          'type': 'remote_sos_triggered',
          'fromUserId': currentUserId,
          'fromUserName': triggeredBy,
          'message': triggeredBy + ' triggered an SOS on your behalf',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });

        _showSnackBar('SOS triggered for ' + targetName, Colors.green);
      } catch (e) {
        _showSnackBar('Failed to trigger SOS: ' + e.toString(), Colors.red);
      }
    }
  }

  Future<void> _markAlertAsRead(String alertId, String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(alertId)
          .update({'read': true});
    } catch (e) {
      debugPrint('Mark alert read error: ' + e.toString());
    }
  }

// ==================== GEOFENCE ====================

  Future<void> _showAddGeofenceDialog(
      String targetUserId,
      String targetName,
      ) async {
    final nameController = TextEditingController();
    double radius = 500;

    Position? currentPosition;
    try {
      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Location error: ' + e.toString());
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            'Add Geofence for ' + targetName,
            style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A geofence will alert you when ' + targetName + ' leaves the defined area.',
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Zone Name (e.g. Home, School)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Radius: ' + radius.toInt().toString() + ' meters',
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              Slider(
                value: radius,
                min: 100,
                max: 5000,
                divisions: 49,
                label: radius.toInt().toString() + 'm',
                onChanged: (val) => setDialogState(() => radius = val),
              ),
              if (currentPosition != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Center: ' + currentPosition.latitude.toStringAsFixed(4) + ', ' + currentPosition.longitude.toStringAsFixed(4),
                        style: const TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(context);

                try {
                  await _firestore.collection('geofences').add({
                    'ownerId': _auth.currentUser?.uid,
                    'targetUserId': targetUserId,
                    'targetName': targetName,
                    'zoneName': nameController.text.trim(),
                    'radius': radius,
                    'centerLat': currentPosition?.latitude ?? 0.0,
                    'centerLng': currentPosition?.longitude ?? 0.0,
                    'active': true,
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  _showSnackBar('Geofence added for ' + targetName, Colors.green);
                } catch (e) {
                  _showSnackBar('Failed to add geofence: ' + e.toString(), Colors.red);
                }
              },
              child: const Text('Add Geofence'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteGeofence(String geofenceId, String zoneName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Remove ' + zoneName + '?',
          style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color),
        ),
        content: Text(
          'This geofence will no longer monitor this area.',
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
        await _firestore.collection('geofences').doc(geofenceId).delete();
        _showSnackBar(zoneName + ' geofence removed', Colors.green);
      } catch (e) {
        _showSnackBar('Failed to remove geofence: ' + e.toString(), Colors.red);
      }
    }
  }

// ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Family Monitoring')),
        body: const Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Family Monitoring'),
        actions: [
          if (_liveAlerts.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_active, color: Colors.red),
                  onPressed: () => _tabController.animateTo(1),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _liveAlerts.length.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              icon: const Icon(Icons.dashboard),
              text: 'Dashboard',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: _liveAlerts.isNotEmpty,
                label: Text(_liveAlerts.length.toString()),
                child: const Icon(Icons.warning_amber),
              ),
              text: 'Alerts',
            ),
            const Tab(icon: Icon(Icons.map), text: 'Map'),
            const Tab(icon: Icon(Icons.fence), text: 'Geofences'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(userId),
          _buildAlertsTab(userId),
          _buildMapTab(userId),
          _buildGeofencesTab(userId),
        ],
      ),
    );
  }

// ==================== DASHBOARD TAB ====================

  Widget _buildDashboardTab(String userId) {
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
                  'Link family members from the Family Device Linking screen',
                  textAlign: TextAlign.center,
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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOnline ? 'Online' : 'Last seen ' + _timeSince(lastSeen),
                              style: TextStyle(
                                color: isOnline ? Colors.green : Theme.of(context).textTheme.bodySmall?.color,
                                fontSize: 12,
                              ),
                            ),
                            if (location != null && permissions['canSeeLocation'] == true)
                              Text(
                                'Lat: ' + (location['latitude'] as double).toStringAsFixed(4) +
                                    ', Lng: ' + (location['longitude'] as double).toStringAsFixed(4),
                                style: const TextStyle(fontSize: 11, color: Colors.blue),
                              ),
                          ],
                        ),
                        trailing: permissions['canSeeBattery'] == true
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _batteryIcon(batteryLevel),
                              color: _batteryColor(batteryLevel),
                              size: 20,
                            ),
                            Text(
                              batteryLevel.toString() + '%',
                              style: TextStyle(
                                color: _batteryColor(batteryLevel),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                            : null,
                      ),

                      const Divider(height: 1),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                              label: const Text('Check In', style: TextStyle(color: Colors.green, fontSize: 12)),
                              onPressed: () => _sendCheckInRequest(targetId, targetName),
                            ),
                            if (permissions['canSendAlerts'] == true)
                              TextButton.icon(
                                icon: const Icon(Icons.sos, color: Colors.red, size: 18),
                                label: const Text('SOS', style: TextStyle(color: Colors.red, fontSize: 12)),
                                onPressed: () => _triggerSOSOnBehalf(targetId, targetName, userId),
                              ),
                            TextButton.icon(
                              icon: const Icon(Icons.fence, color: Colors.orange, size: 18),
                              label: const Text('Geofence', style: TextStyle(color: Colors.orange, fontSize: 12)),
                              onPressed: () => _showAddGeofenceDialog(targetId, targetName),
                            ),
                            TextButton.icon(
                              icon: Icon(Icons.history, color: Theme.of(context).primaryColor, size: 18),
                              label: Text('History', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12)),
                              onPressed: () => _showPanicHistory(targetId, targetName),
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

// ==================== ALERTS TAB ====================

  Widget _buildAlertsTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('type', whereIn: ['family_panic_alert', 'remote_sos_triggered', 'checkin_request'])
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
          );
        }

        final alerts = snapshot.data?.docs ?? [];

        if (alerts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Theme.of(context).textTheme.bodySmall?.color),
                const SizedBox(height: 16),
                Text(
                  'No Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Family alerts and check-ins will appear here',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index].data() as Map<String, dynamic>;
            final alertId = alerts[index].id;
            final isRead = alert['read'] as bool? ?? false;
            final type = alert['type'] as String? ?? '';
            final fromName = alert['fromUserName'] as String? ?? 'Unknown';
            final message = alert['message'] as String? ?? '';
            final timestamp = alert['timestamp'] as Timestamp?;
            final location = alert['location'] as Map<String, dynamic>?;

            Color alertColor = Colors.blue;
            IconData alertIcon = Icons.notifications;

            if (type == 'family_panic_alert') {
              alertColor = Colors.red;
              alertIcon = Icons.warning_amber;
            } else if (type == 'remote_sos_triggered') {
              alertColor = Colors.orange;
              alertIcon = Icons.sos;
            } else if (type == 'checkin_request') {
              alertColor = Colors.green;
              alertIcon = Icons.check_circle_outline;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isRead
                  ? Theme.of(context).cardColor
                  : alertColor.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isRead ? Colors.transparent : alertColor,
                  width: 1,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: alertColor.withOpacity(0.2),
                  child: Icon(alertIcon, color: alertColor, size: 20),
                ),
                title: Text(
                  fromName,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 12,
                      ),
                    ),
                    if (location != null)
                      Text(
                        'Location: ' + (location['latitude'] as double).toStringAsFixed(4) +
                            ', ' + (location['longitude'] as double).toStringAsFixed(4),
                        style: const TextStyle(fontSize: 11, color: Colors.blue),
                      ),
                    Text(
                      _timeSince(timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
                trailing: isRead
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.mark_email_read, color: Colors.grey),
                  onPressed: () => _markAlertAsRead(alertId, userId),
                ),
              ),
            );
          },
        );
      },
    );
  }

// ==================== MAP TAB ====================

  Widget _buildMapTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('family_links')
          .where('requesterId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .snapshots(),
      builder: (context, snapshot) {
        final links = snapshot.data?.docs ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Live location map requires Google Maps integration. Below are the current coordinates of your family members.',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (links.isEmpty)
              Center(
                child: Text(
                  'No family members linked yet',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              )
            else
              ...links.map((linkDoc) {
                final link = linkDoc.data() as Map<String, dynamic>;
                final targetId = link['targetId'] as String;
                final targetName = link['targetName'] as String? ?? 'Unknown';
                final permissions = link['permissions'] as Map<String, dynamic>? ?? {};

                if (permissions['canSeeLocation'] != true) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.location_off, color: Colors.grey),
                      title: Text(targetName),
                      subtitle: const Text('Location permission not granted'),
                    ),
                  );
                }

                return StreamBuilder<DocumentSnapshot>(
                  stream: _firestore.collection('users').doc(targetId).snapshots(),
                  builder: (context, userSnapshot) {
                    final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                    final familyStatus = userData?['familyStatus'] as Map<String, dynamic>?;
                    final location = familyStatus?['location'] as Map<String, dynamic>?;
                    final isOnline = familyStatus?['isOnline'] as bool? ?? false;
                    final lastSeen = familyStatus?['lastSeen'] as Timestamp?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isOnline
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                              child: Icon(Icons.person, color: isOnline ? Colors.green : Colors.grey),
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
                          ),
                          if (location != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                children: [
                                  _buildLocationRow('Latitude', (location['latitude'] as double).toStringAsFixed(6)),
                                  const SizedBox(height: 4),
                                  _buildLocationRow('Longitude', (location['longitude'] as double).toStringAsFixed(6)),
                                  const SizedBox(height: 4),
                                  _buildLocationRow('Updated', _timeSince(location['timestamp'] as Timestamp?)),
                                ],
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_searching, color: Colors.grey, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Location not available yet',
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildLocationRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

// ==================== GEOFENCES TAB ====================

  Widget _buildGeofencesTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('geofences')
          .where('ownerId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
          );
        }

        final geofences = snapshot.data?.docs ?? [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fence, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Geofences alert you when a family member leaves a defined safe zone.',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (geofences.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fence, size: 64, color: Theme.of(context).textTheme.bodySmall?.color),
                      const SizedBox(height: 16),
                      Text(
                        'No Geofences Set',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add geofences from the Dashboard tab',
                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: geofences.length,
                  itemBuilder: (context, index) {
                    final geofence = geofences[index].data() as Map<String, dynamic>;
                    final geofenceId = geofences[index].id;
                    final zoneName = geofence['zoneName'] as String? ?? 'Unknown Zone';
                    final targetName = geofence['targetName'] as String? ?? 'Unknown';
                    final radius = (geofence['radius'] as num?)?.toDouble() ?? 500;
                    final active = geofence['active'] as bool? ?? true;
                    final centerLat = (geofence['centerLat'] as num?)?.toDouble() ?? 0.0;
                    final centerLng = (geofence['centerLng'] as num?)?.toDouble() ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: active
                              ? Colors.orange.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                          child: Icon(
                            Icons.fence,
                            color: active ? Colors.orange : Colors.grey,
                          ),
                        ),
                        title: Text(
                          zoneName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.headlineMedium?.color,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monitoring: ' + targetName,
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Radius: ' + radius.toInt().toString() + 'm',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              'Center: ' + centerLat.toStringAsFixed(4) + ', ' + centerLng.toStringAsFixed(4),
                              style: const TextStyle(fontSize: 11, color: Colors.blue),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: active,
                              onChanged: (val) async {
                                await _firestore
                                    .collection('geofences')
                                    .doc(geofenceId)
                                    .update({'active': val});
                              },
                              activeColor: Colors.orange,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _deleteGeofence(geofenceId, zoneName),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

// ==================== PANIC HISTORY ====================

  void _showPanicHistory(String targetUserId, String targetName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        minChildSize: 0.3,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.red),
                  const SizedBox(width: 12),
                  Text(
                    targetName + ' - Panic History',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('panic_alerts')
                    .where('userId', isEqualTo: targetUserId)
                    .orderBy('timestamp', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
                    );
                  }

                  final alerts = snapshot.data?.docs ?? [];

                  if (alerts.isEmpty) {
                    return Center(
                      child: Text(
                        'No panic history for ' + targetName,
                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index].data() as Map<String, dynamic>;
                      final timestamp = alert['timestamp'] as Timestamp?;
                      final type = alert['type'] as String? ?? 'panic';
                      final location = alert['location'] as Map<String, dynamic>?;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.withOpacity(0.2),
                            child: const Icon(Icons.warning_amber, color: Colors.red, size: 20),
                          ),
                          title: Text(
                            type == 'remote_sos' ? 'Remote SOS' : 'Panic Alert',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.headlineMedium?.color,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_timeSince(timestamp)),
                              if (location != null)
                                Text(
                                  'Lat: ' + (location['latitude'] as double).toStringAsFixed(4) +
                                      ', Lng: ' + (location['longitude'] as double).toStringAsFixed(4),
                                  style: const TextStyle(fontSize: 11, color: Colors.blue),
                                ),
                            ],
                          ),
                          trailing: Text(
                            timestamp?.toDate().toString().substring(0, 16) ?? '',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
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
    );
  }
}