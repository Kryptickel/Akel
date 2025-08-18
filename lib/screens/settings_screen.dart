import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import '../widgets/custom_text_field.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();
  final _emergencyMessageController = TextEditingController();
  final _contactController = TextEditingController();
  
  UserProfile? _userProfile;
  List<String> _emergencyContacts = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _emergencyMessageController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final profile = await _userService.getUserProfile();
      final contacts = await _userService.getEmergencyContacts();
      final message = await _userService.getEmergencyMessage();

      setState(() {
        _userProfile = profile;
        _emergencyContacts = contacts;
        _emergencyMessageController.text = message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveEmergencyMessage() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final success = await _userService.saveEmergencyMessage(
        _emergencyMessageController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency message saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save emergency message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _addEmergencyContact() async {
    final contact = _contactController.text.trim();
    if (contact.isEmpty) return;

    // Basic phone number validation
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
    if (!phoneRegex.hasMatch(contact)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _emergencyContacts.add(contact);
      _contactController.clear();
    });

    await _saveEmergencyContacts();
  }

  Future<void> _removeEmergencyContact(int index) async {
    setState(() {
      _emergencyContacts.removeAt(index);
    });

    await _saveEmergencyContacts();
  }

  Future<void> _saveEmergencyContacts() async {
    try {
      final success = await _userService.saveEmergencyContacts(_emergencyContacts);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency contacts updated'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save contacts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _previewEmergencyMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Emergency Message Preview'),
          content: SingleChildScrollView(
            child: Text(
              _emergencyMessageController.text.trim().isEmpty
                  ? 'No emergency message set'
                  : _emergencyMessageController.text.trim(),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _resetToDefault() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset to Default'),
          content: const Text('This will reset your emergency message to the default template. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _emergencyMessageController.text = 
                      'Emergency! I need immediate assistance. Please send help to my location.';
                });
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: AppBar(title: Text('Settings')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Settings Help'),
                  content: const Text(
                    'Configure your emergency message and contacts here. '
                    'When the panic button is activated, your message will be sent to all emergency contacts with your location.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Section
            if (_userProfile != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(_userProfile!.name),
                        subtitle: Text('Age: ${_userProfile!.age} • ${_userProfile!.sex}'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.location_on),
                        title: const Text('Address'),
                        subtitle: Text(_userProfile!.address),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Emergency Message Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency Message',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This message will be sent to your emergency contacts when the panic button is activated.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _emergencyMessageController,
                      label: 'Emergency Message',
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an emergency message';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _previewEmergencyMessage,
                            icon: const Icon(Icons.preview),
                            label: const Text('Preview'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _resetToDefault,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveEmergencyMessage,
                      child: _isSaving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Saving...'),
                              ],
                            )
                          : const Text('Save Message'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Emergency Contacts Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency Contacts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add phone numbers of people who should be notified in an emergency.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Add contact field
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _contactController,
                            label: 'Phone Number (e.g., +1234567890)',
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addEmergencyContact,
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Contact list
                    if (_emergencyContacts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.contacts,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No emergency contacts added',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Add at least one contact for emergency alerts',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          const Divider(),
                          ...List.generate(_emergencyContacts.length, (index) {
                            final contact = _emergencyContacts[index];
                            return ListTile(
                              leading: const Icon(Icons.phone),
                              title: Text(contact),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeEmergencyContact(index),
                              ),
                            );
                          }),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}