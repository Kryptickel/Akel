import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart';
import '../services/trusted_person_service.dart';
import '../services/vibration_service.dart';
import 'pin_verify_screen.dart';

class TrustedPersonPinsScreen extends StatefulWidget {
  const TrustedPersonPinsScreen({super.key});

  @override
  State<TrustedPersonPinsScreen> createState() => _TrustedPersonPinsScreenState();
}

class _TrustedPersonPinsScreenState extends State<TrustedPersonPinsScreen> {
  final TrustedPersonService _pinService = TrustedPersonService();
  final VibrationService _vibrationService = VibrationService();

  List<TrustedPersonPin> _pins = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPins();
  }

  Future<void> _loadPins() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        final pins = await _pinService.getPinsForUser(userId);
        final stats = await _pinService.getPinStatistics(userId);

        if (mounted) {
          setState(() {
            _pins = pins;
            _statistics = stats;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint(' Load PINs error: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createPin() async {
    await _vibrationService.light();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    // Show contact selection dialog
    final contact = await _showContactSelectionDialog(userId);
    if (contact == null) return;

    final pin = await _pinService.createPin(
      userId: userId,
      contactName: contact['name']!,
      contactPhone: contact['phone']!,
    );

    if (pin != null && mounted) {
      await _vibrationService.success();

      // Show PIN to user
      _showPinCreatedDialog(pin);

      _loadPins();
    }
  }

  Future<Map<String, String>?> _showContactSelectionDialog(String userId) async {
    // Get contacts using the public service method
    final contacts = await _pinService.getUserContacts(userId);

    if (contacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' No contacts found. Please add contacts first.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Contact'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    contact['name']!.isNotEmpty ? contact['name']![0] : '?',
                  ),
                ),
                title: Text(contact['name']!),
                subtitle: Text(contact['phone']!),
                onTap: () => Navigator.pop(context, contact),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showPinCreatedDialog(TrustedPersonPin pin) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(' PIN Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PIN for ${pin.contactName}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue,
                  width: 2,
                ),
              ),
              child: Text(
                _pinService.formatPin(pin.pin),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Expires: ${DateFormat('MMM dd, yyyy hh:mm a').format(pin.expiresAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Share this PIN with your trusted contact. They can use it to verify their safety status.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: pin.pin));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(' PIN copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () async {
              await Share.share(
                'Your emergency PIN is: ${_pinService.formatPin(pin.pin)}\n\n'
                    'Use this PIN to verify your safety status in the AKEL app.\n'
                    'Expires: ${DateFormat('MMM dd, yyyy hh:mm a').format(pin.expiresAt)}',
                subject: 'Emergency Safety PIN',
              );
            },
            child: const Text('Share'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePin(String pinId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete PIN?'),
        content: const Text('This PIN will no longer be valid.'),
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
      final success = await _pinService.deletePin(pinId);

      if (success && mounted) {
        await _vibrationService.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' PIN deleted'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPins();
      }
    }
  }

  Future<void> _clearExpiredPins() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Expired PINs?'),
        content: const Text('This will delete all expired PINs permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final deleted = await _pinService.deleteExpiredPins(userId);

      if (mounted) {
        await _vibrationService.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Deleted $deleted expired PIN(s)'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPins();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusted Person PINs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user),
            tooltip: 'Verify PIN',
            onPressed: () async {
              await _vibrationService.light();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PinVerifyScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Expired',
            onPressed: _clearExpiredPins,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _vibrationService.light();
              _loadPins();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          if (_statistics != null) _buildStatisticsCard(),

          // Info Card
          _buildInfoCard(),

          // PINs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pins.isEmpty
                ? _buildEmptyState()
                : _buildPinsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPin,
        icon: const Icon(Icons.add),
        label: const Text('Create PIN'),
        backgroundColor: Colors.amber,
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final active = _statistics!['activePins'] as int;
    final used = _statistics!['usedPins'] as int;
    final safe = _statistics!['safePins'] as int;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber,
            Colors.amber.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Active', '$active', Icons.lock_open),
          _buildStatItem('Used', '$used', Icons.check_circle),
          _buildStatItem('Safe', '$safe', Icons.verified),
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
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How it works:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create a PIN for trusted contacts. They can verify their safety status using the PIN.',
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
            Icons.lock_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No PINs Created',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create PINs for trusted contacts',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createPin,
            icon: const Icon(Icons.add),
            label: const Text('Create First PIN'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pins.length,
      itemBuilder: (context, index) {
        final pin = _pins[index];
        return _buildPinCard(pin);
      },
    );
  }

  Widget _buildPinCard(TrustedPersonPin pin) {
    final isExpired = pin.expiresAt.isBefore(DateTime.now());
    final isActive = !pin.isUsed && !isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isActive ? 4 : 1,
      child: InkWell(
        onTap: () {
          _vibrationService.light();
          _showPinDetails(pin);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Contact Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.amber.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        pin.contactName.isNotEmpty ? pin.contactName[0] : '?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.amber : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Contact Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pin.contactName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pin.contactPhone,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Delete Button (only for active pins)
                  if (isActive)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deletePin(pin.id),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // PIN Display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.amber.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? Colors.amber : Colors.grey,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.vpn_key,
                          size: 20,
                          color: isActive ? Colors.amber : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _pinService.formatPin(pin.pin),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: isActive ? Colors.amber[900] : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (pin.status != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _hexToColor(
                            TrustedPersonService.getStatusColor(pin.status!),
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              TrustedPersonService.getStatusIcon(pin.status!),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              TrustedPersonService.getStatusLabel(pin.status!),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _hexToColor(
                                  TrustedPersonService.getStatusColor(pin.status!),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Status Row
              Row(
                children: [
                  Icon(
                    isExpired ? Icons.schedule : Icons.access_time,
                    size: 14,
                    color: isExpired ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isExpired
                        ? 'Expired ${DateFormat('MMM dd').format(pin.expiresAt)}'
                        : 'Expires ${DateFormat('MMM dd, hh:mm a').format(pin.expiresAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isExpired ? Colors.red : Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (pin.isUsed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'USED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    )
                  else if (isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'EXPIRED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
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

  void _showPinDetails(TrustedPersonPin pin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PIN Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Contact', pin.contactName),
              _buildDetailRow('Phone', pin.contactPhone),
              _buildDetailRow('PIN', _pinService.formatPin(pin.pin)),
              _buildDetailRow(
                'Created',
                DateFormat('MMM dd, yyyy hh:mm a').format(pin.createdAt),
              ),
              _buildDetailRow(
                'Expires',
                DateFormat('MMM dd, yyyy hh:mm a').format(pin.expiresAt),
              ),
              _buildDetailRow('Status', pin.isUsed ? 'Used' : 'Active'),
              if (pin.status != null)
                _buildDetailRow(
                  'Response',
                  TrustedPersonService.getStatusLabel(pin.status!),
                ),
              if (pin.verifiedAt != null)
                _buildDetailRow(
                  'Verified',
                  DateFormat('MMM dd, yyyy hh:mm a').format(pin.verifiedAt!),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: pin.pin));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(' PIN copied'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text('Copy PIN'),
          ),
          if (!pin.isUsed)
            TextButton(
              onPressed: () async {
                await Share.share(
                  'Your emergency PIN is: ${_pinService.formatPin(pin.pin)}\n\n'
                      'Use this PIN to verify your safety status in the AKEL app.\n'
                      'Expires: ${DateFormat('MMM dd, yyyy hh:mm a').format(pin.expiresAt)}',
                  subject: 'Emergency Safety PIN',
                );
              },
              child: const Text('Share PIN'),
            ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
  }
}