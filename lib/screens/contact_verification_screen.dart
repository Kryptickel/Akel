import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/contact_verification_service.dart';
import '../services/vibration_service.dart';

/// ==================== CONTACT VERIFICATION SCREEN ====================
/// Verify emergency contacts via SMS/call
/// BUILD 55 - SIMPLIFIED VERSION
/// ================================================================

class ContactVerificationScreen extends StatefulWidget {
  const ContactVerificationScreen({super.key});

  @override
  State<ContactVerificationScreen> createState() => _ContactVerificationScreenState();
}

class _ContactVerificationScreenState extends State<ContactVerificationScreen> {
  final ContactVerificationService _verificationService = ContactVerificationService();
  final VibrationService _vibrationService = VibrationService();

  List<Map<String, dynamic>> _contacts = [];
  Map<String, int> _statistics = {};
  bool _isLoading = true;
  bool _isVerifying = false;
  String? _verifyingContactId;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _loadStatistics();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        final firestore = FirebaseFirestore.instance;
        final snapshot = await firestore
            .collection('users')
            .doc(userId)
            .collection('contacts')
            .get();

        final contacts = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown',
            'phone': data['phone'] ?? '',
            'verified': data['verified'] ?? false,
            'verifiedAt': data['verifiedAt'],
            'trustScore': (data['trustScore'] ?? 0.0).toDouble(),
            'priority': data['priority'] ?? 2,
          };
        }).toList();

        if (mounted) {
          setState(() {
            _contacts = contacts;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint(' Load contacts error: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStatistics() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      final stats = await _verificationService.verifyAllContacts(userId: userId);
      if (mounted) {
        setState(() {
          _statistics = Map<String, int>.from(stats);
        });
      }
    }
  }

  Future<void> _verifyContact(Map<String, dynamic> contact) async {
    await _vibrationService.light();

    setState(() {
      _isVerifying = true;
      _verifyingContactId = contact['id'];
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      setState(() {
        _isVerifying = false;
        _verifyingContactId = null;
      });
      return;
    }

    final result = await _verificationService.sendVerificationCode(
      userId: userId,
      contactId: contact['id'],
      phoneNumber: contact['phone'],
      contactName: contact['name'],
    );

    setState(() {
      _isVerifying = false;
      _verifyingContactId = null;
    });

    if (result['success'] == true) {
      await _vibrationService.success();

      if (mounted) {
        // Show verification code dialog
        _showVerificationCodeDialog(contact, userId);
      }
    } else {
      await _vibrationService.error();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showVerificationCodeDialog(Map<String, dynamic> contact, String userId) async {
    final codeController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Verify ${contact['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SMS sent to ${contact['phone']}'),
            const SizedBox(height: 16),
            const Text('Enter 6-digit code:'),
            const SizedBox(height: 8),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: '000000',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.length == 6) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final code = codeController.text;

      final verifyResult = await _verificationService.verifyCode(
        userId: userId,
        contactId: contact['id'],
        code: code,
      );

      if (verifyResult['success'] == true) {
        await _vibrationService.success();
        await _loadContacts();
        await _loadStatistics();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(' ${contact['name']} verified!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _vibrationService.error();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(' ${verifyResult['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    codeController.dispose();
  }

  Future<void> _verifyViaCall(Map<String, dynamic> contact) async {
    await _vibrationService.light();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    final result = await _verificationService.sendVerificationCall(
      userId: userId,
      contactId: contact['id'],
      phoneNumber: contact['phone'],
      contactName: contact['name'],
    );

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' ${result['message']}\nCode: ${result['code']}'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showVerificationOptions(Map<String, dynamic> contact) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Verify ${contact['name']}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.sms, color: Colors.green),
              title: const Text('Verify via SMS'),
              subtitle: const Text('Send verification code via text'),
              onTap: () {
                Navigator.pop(context);
                _verifyContact(contact);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.blue),
              title: const Text('Verify via Call'),
              subtitle: const Text('Call and verify code verbally'),
              onTap: () {
                Navigator.pop(context);
                _verifyViaCall(contact);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVerificationDetails(Map<String, dynamic> contact) {
    final verified = contact['verified'] as bool;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${verified ? ' ' : ' '} Verification Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Contact', contact['name']),
              _buildDetailRow('Phone', contact['phone']),
              _buildDetailRow('Status', verified ? 'Verified ✓' : 'Unverified'),
              if (contact['verifiedAt'] != null)
                _buildDetailRow(
                  'Verified',
                  DateFormat('MMM dd, yyyy').format((contact['verifiedAt'] as Timestamp).toDate()),
                ),
              _buildDetailRow('Trust Score', '${contact['trustScore'].toStringAsFixed(0)}%'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (verified ? Colors.green : Colors.grey).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (verified ? Colors.green : Colors.grey).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      verified ? Icons.check_circle : Icons.help_outline,
                      color: verified ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        verified
                            ? 'This contact can receive emergency alerts'
                            : 'Verify to enable emergency alerts',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!verified)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showVerificationOptions(contact);
              },
              child: const Text('Verify Now'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTrustScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    if (score >= 20) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _vibrationService.light();
              _loadContacts();
              _loadStatistics();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          if (_statistics.isNotEmpty) _buildStatisticsCard(),

          // Info Card
          _buildInfoCard(),

          // Contacts List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _contacts.isEmpty
                ? _buildEmptyState()
                : _buildContactsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final total = _statistics['total'] ?? 0;
    final verified = _statistics['verified'] ?? 0;
    final unverified = _statistics['unverified'] ?? 0;
    final rate = _statistics['verificationRate'] ?? '0';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green,
            Colors.green.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', '$total', Icons.people),
              _buildStatItem('Verified', '$verified', Icons.verified),
              _buildStatItem('Pending', '$unverified', Icons.pending),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Verification Rate: $rate%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contact Verification',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verify contacts can receive emergency alerts via SMS or call.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contacts_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Contacts Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add emergency contacts to verify them',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return _buildContactCard(contact);
      },
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact) {
    final verified = contact['verified'] as bool;
    final trustScore = contact['trustScore'] as double;
    final isVerifying = _verifyingContactId == contact['id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      child: InkWell(
        onTap: () {
          _vibrationService.light();
          _showVerificationDetails(contact);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: (verified ? Colors.green : Colors.grey).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        verified ? ' ' : ' ',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contact['phone'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!verified && !isVerifying)
                    ElevatedButton.icon(
                      onPressed: () => _showVerificationOptions(contact),
                      icon: const Icon(Icons.verified, size: 16),
                      label: const Text('Verify'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  if (isVerifying)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (verified ? Colors.green : Colors.grey).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          verified ? Icons.check_circle : Icons.help,
                          color: verified ? Colors.green : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          verified ? 'VERIFIED' : 'UNVERIFIED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: verified ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (verified)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getTrustScoreColor(trustScore).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.security,
                            color: _getTrustScoreColor(trustScore),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Trust: ${trustScore.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getTrustScoreColor(trustScore),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}