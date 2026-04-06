import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/contact_group_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';
import '../models/contact_group.dart';
import 'group_editor_screen.dart';

class ContactGroupsScreen extends StatefulWidget {
  const ContactGroupsScreen({super.key});

  @override
  State<ContactGroupsScreen> createState() => _ContactGroupsScreenState();
}

class _ContactGroupsScreenState extends State<ContactGroupsScreen> {
  final ContactGroupService _groupService = ContactGroupService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();

  bool _isAlerting = false;

  Future<void> _createGroupFromTemplate(
      String userId,
      Map<String, String> template,
      ) async {
    try {
      await _vibrationService.light();
      await _soundService.playClick();

      await _groupService.createGroup(
        userId: userId,
        name: template['name']!,
        icon: template['icon']!,
        color: template['color']!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(template['name']! + ' group created'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: ' + e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteGroup(String userId, ContactGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Delete Group?',
          style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color),
        ),
        content: Text(
          'Are you sure you want to delete ' + group.name + '?\n\nContacts will not be deleted, only the group.',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _vibrationService.warning();
        await _groupService.deleteGroup(userId, group.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(group.name + ' deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete group: ' + e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _alertGroup(String userId, ContactGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            Text(group.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Alert ' + group.name + '?',
                style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color),
              ),
            ),
          ],
        ),
        content: Text(
          'This will send an emergency alert to all ' + group.contactIds.length.toString() + ' contacts in ' + group.name + '.\n\nContinue?',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        setState(() => _isAlerting = true);
        await _vibrationService.heavy();

        // Get contacts in group using existing service method
        final contacts = await _groupService.getContactsInGroup(userId, group.id);

        if (contacts.isEmpty) {
          if (mounted) {
            setState(() => _isAlerting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No contacts found in this group'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        // Get current location
        Position? position;
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
        } catch (e) {
          debugPrint('Location error: ' + e.toString());
        }

        // Build alert message
        final locationText = position != null
            ? 'Location: https://maps.google.com/?q=' + position.latitude.toString() + ',' + position.longitude.toString()
            : 'Location unavailable';

        final message = 'EMERGENCY ALERT from group ' + group.name + '. I need help! ' + locationText;

        // Log alert to Firestore
        await FirebaseFirestore.instance.collection('group_alerts').add({
          'groupId': group.id,
          'groupName': group.name,
          'userId': userId,
          'contactCount': contacts.length,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
          'location': position != null
              ? {
            'latitude': position.latitude,
            'longitude': position.longitude,
          }
              : null,
        });

        if (mounted) {
          setState(() => _isAlerting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Alert sent to ' + group.name + ' (' + contacts.length.toString() + ' contacts)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isAlerting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to alert group: ' + e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showGroupDetails(ContactGroup group) async {
    await _vibrationService.light();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(group.icon, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      group.contactIds.length.toString() + ' contact' + (group.contactIds.length != 1 ? 's' : ''),
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    onPressed: () {
                      Navigator.pop(context);
                      final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
                      if (userId != null && mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupEditorScreen(userId: userId, group: group),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.warning_amber),
                    label: const Text('Alert Group'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      Navigator.pop(context);
                      final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
                      if (userId != null && mounted) {
                        _alertGroup(userId, group);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'pink':
        return Colors.pink;
      case 'teal':
        return Colors.teal;
      case 'amber':
        return Colors.amber;
      case 'indigo':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Contact Groups')),
        body: const Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Groups'),
        actions: [
          if (_isAlerting)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Custom Group',
            onPressed: () async {
              await _vibrationService.light();
              await _soundService.playClick();
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupEditorScreen(userId: userId),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ContactGroup>>(
        stream: _groupService.getGroups(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading groups',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            );
          }

          final groups = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUICK TEMPLATES',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ContactGroupService.templates.map((template) {
                          final exists = groups.any((g) => g.name == template['name']);
                          return ActionChip(
                            avatar: Text(
                              template['icon']!,
                              style: const TextStyle(fontSize: 20),
                            ),
                            label: Text(template['name']!),
                            onPressed: exists
                                ? null
                                : () => _createGroupFromTemplate(userId, template),
                            backgroundColor: exists
                                ? Colors.grey.withOpacity(0.2)
                                : _getColorFromString(template['color']!).withOpacity(0.1),
                            side: BorderSide(
                              color: exists
                                  ? Colors.grey
                                  : _getColorFromString(template['color']!),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              if (groups.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'YOUR GROUPS (' + groups.length.toString() + ')',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          groups.fold(0, (sum, g) => sum + g.contactIds.length).toString() + ' total contacts',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (groups.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group,
                          size: 64,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Groups Yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap a template above to get started',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final group = groups[index];
                      final color = _getColorFromString(group.color);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: color, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                group.icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          title: Text(
                            group.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.headlineMedium?.color,
                            ),
                          ),
                          subtitle: Text(
                            group.contactIds.length.toString() + ' contact' + (group.contactIds.length != 1 ? 's' : ''),
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.warning_amber, color: Colors.red),
                                tooltip: 'Alert this group',
                                onPressed: group.contactIds.isEmpty
                                    ? null
                                    : () => _alertGroup(userId, group),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Edit group',
                                onPressed: () async {
                                  await _vibrationService.light();
                                  await _soundService.playClick();
                                  if (mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => GroupEditorScreen(
                                          userId: userId,
                                          group: group,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Delete group',
                                onPressed: () => _deleteGroup(userId, group),
                              ),
                            ],
                          ),
                          onTap: () => _showGroupDetails(group),
                        ),
                      );
                    },
                    childCount: groups.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}