import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/user_service.dart';
import '../services/emergency_service.dart';
import '../widgets/custom_text_field.dart';

class OfflineModeScreen extends StatefulWidget {
  const OfflineModeScreen({super.key});

  @override
  State<OfflineModeScreen> createState() => _OfflineModeScreenState();
}

class _OfflineModeScreenState extends State<OfflineModeScreen> {
  final UserService _userService = UserService();
  final EmergencyService _emergencyService = EmergencyService();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  
  List<String> _emergencyContacts = [];
  String _emergencyMessage = '';
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final contacts = await _userService.getEmergencyContacts();
      final message = await _userService.getEmergencyMessage();
      
      setState(() {
        _emergencyContacts = contacts;
        _emergencyMessage = message;
        _messageController.text = message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendSMS(String phoneNumber, String message) async {
    setState(() {
      _isSending = true;
    });

    try {
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        
        if (mounted) {
          _showSuccessDialog(phoneNumber);
        }
      } else {
        throw Exception('SMS not supported on this device');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send SMS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sendToAllContacts() async {
    if (_emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No emergency contacts configured. Please add contacts in Settings.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await _showBulkSendConfirmation();
    if (!confirmed) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Get current location and create location message
      final position = await _emergencyService.getCurrentPosition();
      String messageWithLocation = _messageController.text.trim();
      
      if (position != null) {
        final locationUrl = _emergencyService.getGoogleMapsUrl(position);
        messageWithLocation += '\n\nLocation: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}\nMaps: $locationUrl';
      }

      // Send to all contacts sequentially
      for (int i = 0; i < _emergencyContacts.length; i++) {
        final contact = _emergencyContacts[i];
        
        final Uri smsUri = Uri(
          scheme: 'sms',
          path: contact,
          queryParameters: {'body': messageWithLocation},
        );

        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
          // Add delay between messages
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (mounted) {
        _showBulkSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending messages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<bool> _showBulkSendConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Send to All Contacts'),
          content: Text(
            'This will send your emergency message to ${_emergencyContacts.length} contacts. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send All'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _showSuccessDialog(String phoneNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Message Sent'),
            ],
          ),
          content: Text('SMS sent to $phoneNumber'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showBulkSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Messages Sent'),
            ],
          ),
          content: Text('Emergency messages sent to ${_emergencyContacts.length} contacts'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Return to home
              },
              child: const Text('OK'),
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
        appBar: AppBar(title: Text('Offline Mode')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Mode'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: Colors.orange[50],
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.wifi_off,
                      size: 48,
                      color: Colors.orange,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Offline Emergency Mode',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Send emergency SMS messages without internet connectivity. Messages will be sent through your device\'s SMS service.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Emergency Message
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
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _messageController,
                      label: 'Message Content',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Note: Location information will be automatically added if available',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Send to All Contacts
            if (_emergencyContacts.isNotEmpty)
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
                      const SizedBox(height: 16),
                      ...List.generate(_emergencyContacts.length, (index) {
                        final contact = _emergencyContacts[index];
                        return ListTile(
                          leading: const Icon(Icons.phone),
                          title: Text(contact),
                          trailing: IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: _isSending 
                                ? null 
                                : () => _sendSMS(contact, _messageController.text.trim()),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isSending ? null : _sendToAllContacts,
                        icon: _isSending 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: Text(_isSending ? 'Sending...' : 'Send to All Contacts'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.contacts,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Emergency Contacts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add emergency contacts in Settings to enable quick messaging.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/settings'),
                        icon: const Icon(Icons.settings),
                        label: const Text('Go to Settings'),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Manual SMS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Send to Custom Number',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isSending 
                          ? null 
                          : () {
                              final phone = _phoneController.text.trim();
                              if (phone.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a phone number'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              _sendSMS(phone, _messageController.text.trim());
                            },
                      icon: const Icon(Icons.send),
                      label: const Text('Send SMS'),
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