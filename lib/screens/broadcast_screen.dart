import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/broadcast_service.dart';
import '../services/vibration_service.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final BroadcastService _broadcastService = BroadcastService();
  final VibrationService _vibrationService = VibrationService();

  List<BroadcastMessage> _broadcasts = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBroadcasts();
    _loadStatistics();
  }

  Future<void> _loadBroadcasts() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        final broadcasts = await _broadcastService.getBroadcasts(userId);

        if (mounted) {
          setState(() {
            _broadcasts = broadcasts;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('❌ Load broadcasts error: $e');
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
      try {
        final stats = await _broadcastService.getBroadcastStatistics(userId);

        if (mounted) {
          setState(() {
            _statistics = stats;
          });
        }
      } catch (e) {
        debugPrint('❌ Load statistics error: $e');
      }
    }
  }

  Future<void> _sendBroadcast(BroadcastType type) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    final userName = authProvider.userProfile?['name'] ?? 'User';

    if (userId == null) return;

// Get contacts
    final firestore = FirebaseFirestore.instance;
    final contactsSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .get();

    final contacts = contactsSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'name': data['name'] ?? 'Unknown',
        'phone': data['phone'] ?? '',
        'priority': data['priority'] ?? 2,
      };
    }).toList();

    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No contacts found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

// Show confirmation dialog
    String message = BroadcastService.getTemplateMessage(type, userName);

    if (type == BroadcastType.custom) {
      message = await _showCustomMessageDialog() ?? '';
      if (message.isEmpty) return;
    }

    final confirmed = await _showConfirmationDialog(type, contacts.length, message);
    if (confirmed != true) return;

    await _vibrationService.light();

    setState(() => _isLoading = true);

    final broadcast = await _broadcastService.sendBroadcast(
      userId: userId,
      userName: userName,
      type: type,
      message: message,
      contacts: contacts,
      includeLocation: true,
    );

    setState(() => _isLoading = false);

    if (broadcast != null && mounted) {
      await _vibrationService.success();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '📢 Broadcast sent to ${broadcast.successfulDeliveries} contact(s)',
          ),
          backgroundColor: Colors.green,
        ),
      );

      _loadBroadcasts();
      _loadStatistics();
    } else if (mounted) {
      await _vibrationService.error();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to send broadcast'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showCustomMessageDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Broadcast Message'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter your message...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(
      BroadcastType type,
      int contactCount,
      String message,
      ) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${BroadcastService.getTypeIcon(type)} Send Broadcast?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recipients: $contactCount contact(s)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Message Preview:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Text(
                message,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.blue),
                SizedBox(width: 4),
                Text(
                  'Location will be included',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Send Broadcast'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBroadcast(BroadcastMessage broadcast) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Broadcast?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
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
      final success = await _broadcastService.deleteBroadcast(broadcast.id);

      if (success && mounted) {
        await _vibrationService.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Broadcast deleted'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBroadcasts();
        _loadStatistics();
      }
    }
  }

  void _showBroadcastDetails(BroadcastMessage broadcast) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${BroadcastService.getTypeIcon(broadcast.type)} Broadcast Details',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Type', BroadcastService.getTypeLabel(broadcast.type)),
              _buildDetailRow('Sent', DateFormat('MMM dd, yyyy hh:mm a').format(broadcast.timestamp)),
              _buildDetailRow('Recipients', '${broadcast.totalRecipients}'),
              _buildDetailRow('Successful', '${broadcast.successfulDeliveries}'),
              _buildDetailRow('Failed', '${broadcast.failedDeliveries}'),
              const SizedBox(height: 16),
              const Text(
                'Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Text(broadcast.message),
              ),
              if (broadcast.latitude != null && broadcast.longitude != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Location: ${broadcast.latitude}, ${broadcast.longitude}',
                        style: const TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Broadcast'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _vibrationService.light();
              _loadBroadcasts();
              _loadStatistics();
            },
          ),
        ],
      ),
      body: Column(
        children: [
// Statistics Card
          if (_statistics != null) _buildStatisticsCard(),

// Quick Broadcast Buttons
          _buildQuickBroadcastButtons(),

// Broadcasts List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _broadcasts.isEmpty
                ? _buildEmptyState()
                : _buildBroadcastsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final total = _statistics!['totalBroadcasts'] as int;
    final successRate = _statistics!['successRate'] as String;
    final sent = _statistics!['successfulDeliveries'] as int;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepOrange,
            Colors.deepOrange.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', '$total', Icons.campaign),
          _buildStatItem('Sent', '$sent', Icons.done_all),
          _buildStatItem('Success', '$successRate%', Icons.trending_up),
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

  Widget _buildQuickBroadcastButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Broadcast',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickButton(BroadcastType.fire),
              _buildQuickButton(BroadcastType.medical),
              _buildQuickButton(BroadcastType.police),
              _buildQuickButton(BroadcastType.danger),
              _buildQuickButton(BroadcastType.safe),
              _buildQuickButton(BroadcastType.custom),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(BroadcastType type) {
    final color = _hexToColor(BroadcastService.getTypeColor(type));

    return ElevatedButton.icon(
      onPressed: () => _sendBroadcast(type),
      icon: Text(
        BroadcastService.getTypeIcon(type),
        style: const TextStyle(fontSize: 16),
      ),
      label: Text(
        BroadcastService.getTypeLabel(type),
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Broadcasts Sent',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send emergency broadcasts to all contacts',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildBroadcastsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _broadcasts.length,
      itemBuilder: (context, index) {
        final broadcast = _broadcasts[index];
        return _buildBroadcastCard(broadcast);
      },
    );
  }

  Widget _buildBroadcastCard(BroadcastMessage broadcast) {
    final typeColor = _hexToColor(BroadcastService.getTypeColor(broadcast.type));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      child: InkWell(
        onTap: () {
          _vibrationService.light();
          _showBroadcastDetails(broadcast);
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
                      color: typeColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        BroadcastService.getTypeIcon(broadcast.type),
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
                          BroadcastService.getTypeLabel(broadcast.type),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy hh:mm a').format(broadcast.timestamp),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteBroadcast(broadcast),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${broadcast.totalRecipients} recipients',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '${broadcast.successfulDeliveries} sent',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                  if (broadcast.failedDeliveries > 0) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.error, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      '${broadcast.failedDeliveries} failed',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
  }
}