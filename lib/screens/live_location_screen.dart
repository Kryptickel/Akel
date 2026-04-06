import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart';
import '../services/live_location_service.dart';
import '../services/vibration_service.dart';

class LiveLocationScreen extends StatefulWidget {
  const LiveLocationScreen({super.key});

  @override
  State<LiveLocationScreen> createState() => _LiveLocationScreenState();
}

class _LiveLocationScreenState extends State<LiveLocationScreen> {
  final LiveLocationService _locationService = LiveLocationService();
  final VibrationService _vibrationService = VibrationService();

  List<LiveLocationShare> _shares = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _loadShares();
    _loadStatistics();
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }

  Future<void> _loadShares() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        final shares = await _locationService.getAllShares(userId);

        if (mounted) {
          setState(() {
            _shares = shares;
            _isSharing = shares.any((s) => s.isActive);
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('❌ Load shares error: $e');
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
        final stats = await _locationService.getShareStatistics(userId);

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

  Future<void> _startSharing() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    final userName = authProvider.userProfile?['name'] ?? 'User';

    if (userId == null) return;

// Show duration selection dialog
    final duration = await _showDurationDialog();
    if (duration == null) return;

    await _vibrationService.light();

    setState(() => _isLoading = true);

    final share = await _locationService.startSharing(
      userId: userId,
      userName: userName,
      duration: duration,
    );

    setState(() => _isLoading = false);

    if (share != null && mounted) {
      await _vibrationService.success();

      _showShareDialog(share, userName);

      _loadShares();
      _loadStatistics();
    } else if (mounted) {
      await _vibrationService.error();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to start sharing'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<ShareDuration?> _showDurationDialog() async {
    return showDialog<ShareDuration>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ShareDuration.values.map((duration) {
            return ListTile(
              leading: Text(
                LiveLocationService.getDurationIcon(duration),
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(LiveLocationService.getDurationLabel(duration)),
              onTap: () => Navigator.pop(context, duration),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showShareDialog(LiveLocationShare share, String userName) {
    final message = _locationService.generateShareMessage(
      userName,
      share.shareCode,
      share.duration,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📍 Live Location Sharing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your location is now being shared!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Share Code', share.shareCode),
            _buildInfoRow(
              'Duration',
              LiveLocationService.getDurationLabel(share.duration),
            ),
            if (share.endTime != null)
              _buildInfoRow(
                'Expires',
                DateFormat('hh:mm a').format(share.endTime!),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Text(
                message,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: share.shareCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 Share code copied'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text('Copy Code'),
          ),
          TextButton(
            onPressed: () async {
              await Share.share(message, subject: 'Emergency Live Location');
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

  Widget _buildInfoRow(String label, String value) {
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

  Future<void> _stopSharing(LiveLocationShare share) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Sharing?'),
        content: const Text('Your live location will no longer be shared.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Stop'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _locationService.stopSharing(share.id);

      if (success && mounted) {
        await _vibrationService.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🛑 Location sharing stopped'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadShares();
        _loadStatistics();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Location Sharing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _vibrationService.light();
              _loadShares();
              _loadStatistics();
            },
          ),
        ],
      ),
      body: Column(
        children: [
// Active sharing banner
          if (_isSharing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.green.withValues(alpha: 0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.my_location, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Live Location Sharing Active',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),

// Statistics Card
          if (_statistics != null) _buildStatisticsCard(),

// Info Card
          _buildInfoCard(),

// Shares List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _shares.isEmpty
                ? _buildEmptyState()
                : _buildSharesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startSharing,
        icon: const Icon(Icons.share_location),
        label: const Text('Share Location'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final total = _statistics!['totalShares'] as int;
    final active = _statistics!['activeShares'] as int;
    final expired = _statistics!['expiredShares'] as int;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green,
            Colors.green.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', '$total', Icons.share_location),
          _buildStatItem('Active', '$active', Icons.my_location),
          _buildStatItem('Expired', '$expired', Icons.location_off),
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
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
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
                  'Live Location Sharing',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Share your real-time location with trusted contacts.',
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
            Icons.location_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Shares',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your live location with contacts',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startSharing,
            icon: const Icon(Icons.share_location),
            label: const Text('Start Sharing'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
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

  Widget _buildSharesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _shares.length,
      itemBuilder: (context, index) {
        final share = _shares[index];
        return _buildShareCard(share);
      },
    );
  }

  Widget _buildShareCard(LiveLocationShare share) {
    final isActive = share.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isActive ? 4 : 1,
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
                    color: (isActive ? Colors.green : Colors.grey)
                        .withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActive ? Icons.my_location : Icons.location_off,
                    color: isActive ? Colors.green : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LiveLocationService.getDurationLabel(share.duration),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code: ${share.shareCode}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  ElevatedButton.icon(
                    onPressed: () => _stopSharing(share),
                    icon: const Icon(Icons.stop, size: 16),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Started: ${DateFormat('MMM dd, hh:mm a').format(share.startTime)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (share.endTime != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.timer_off, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    isActive
                        ? 'Expires: ${DateFormat('hh:mm a').format(share.endTime!)}'
                        : 'Ended: ${DateFormat('MMM dd, hh:mm a').format(share.endTime!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (isActive ? Colors.green : Colors.grey)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive ? Icons.check_circle : Icons.cancel,
                    color: isActive ? Colors.green : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isActive ? 'ACTIVE' : 'ENDED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}