import 'package:flutter/material.dart';
import '../services/offline_sync_service.dart';
import '../services/vibration_service.dart';
import 'package:intl/intl.dart';

class OfflineSyncScreen extends StatefulWidget {
  const OfflineSyncScreen({super.key});

  @override
  State<OfflineSyncScreen> createState() => _OfflineSyncScreenState();
}

class _OfflineSyncScreenState extends State<OfflineSyncScreen> {
  final OfflineSyncService _syncService = OfflineSyncService();
  final VibrationService _vibrationService = VibrationService();

  Map<String, dynamic>? _statistics;
  List<OfflineData> _queueItems = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _syncEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final stats = await _syncService.getSyncStatistics();
      final queue = await _syncService.getAllQueue();
      final enabled = await _syncService.isSyncEnabled();

      if (mounted) {
        setState(() {
          _statistics = stats;
          _queueItems = queue;
          _syncEnabled = enabled;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Load data error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncAll() async {
    await _vibrationService.light();

    setState(() => _isSyncing = true);

    final result = await _syncService.syncAll();

    setState(() => _isSyncing = false);

    if (result['success'] == true && mounted) {
      await _vibrationService.success();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Synced ${result['synced']} items${result['failed'] > 0 ? ", ${result['failed']} failed" : ""}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      _loadData();
    } else if (mounted) {
      await _vibrationService.error();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Sync failed: ${result['message'] ?? "Unknown error"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleSync(bool value) async {
    await _vibrationService.light();

    final success = await _syncService.setSyncEnabled(value);

    if (success && mounted) {
      setState(() {
        _syncEnabled = value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? '✅ Sync enabled' : '⚠️ Sync disabled'),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _clearSynced() async {
    await _vibrationService.light();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Synced Items?'),
        content: const Text('This will remove all synced items from the queue.'),
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
      final success = await _syncService.clearSyncedItems();

      if (success && mounted) {
        await _vibrationService.success();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Synced items cleared'),
            backgroundColor: Colors.green,
          ),
        );

        _loadData();
      }
    }
  }

  Future<void> _retryItem(OfflineData item) async {
    await _vibrationService.light();

    final success = await _syncService.retryFailedItem(item.id);

    if (success && mounted) {
      await _vibrationService.success();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Item synced successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _loadData();
    } else if (mounted) {
      await _vibrationService.error();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Sync failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteItem(OfflineData item) async {
    await _vibrationService.light();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text('This item will be permanently removed from the queue.'),
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
      final success = await _syncService.deleteQueueItem(item.id);

      if (success && mounted) {
        await _vibrationService.success();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Item deleted'),
            backgroundColor: Colors.green,
          ),
        );

        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Sync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Synced',
            onPressed: _clearSynced,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _vibrationService.light();
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
// Statistics Card
          if (_statistics != null && _statistics!.isNotEmpty)
            _buildStatisticsCard(),

          const SizedBox(height: 24),

// Sync Control Card
          _buildSyncControlCard(),

          const SizedBox(height: 24),

// Queue Items
          _buildSectionHeader('Queue Items (${_queueItems.length})'),
          if (_queueItems.isEmpty)
            _buildEmptyState()
          else
            ..._queueItems.map((item) => _buildQueueItemCard(item)),
        ],
      ),
      floatingActionButton: _syncEnabled && !_isSyncing
          ? FloatingActionButton.extended(
        onPressed: _syncAll,
        icon: const Icon(Icons.sync),
        label: const Text('Sync All'),
      )
          : null,
    );
  }

  Widget _buildStatisticsCard() {
    final total = (_statistics!['totalItems'] as int?) ?? 0;
    final pending = (_statistics!['pending'] as int?) ?? 0;
    final synced = (_statistics!['synced'] as int?) ?? 0;
    final failed = (_statistics!['failed'] as int?) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue,
            Colors.blue.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
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
              _buildStatItem('Total', '$total', Icons.storage),
              _buildStatItem('Pending', '$pending', Icons.pending),
              _buildStatItem('Synced', '$synced', Icons.check_circle),
              _buildStatItem('Failed', '$failed', Icons.error),
            ],
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSyncControlCard() {
    final lastSync = _statistics?['lastSync'] as String?;
    DateTime? lastSyncTime;
    if (lastSync != null) {
      try {
        lastSyncTime = DateTime.parse(lastSync);
      } catch (e) {
// Invalid date
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Auto Sync',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _syncEnabled,
                  onChanged: _toggleSync,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Automatically sync offline data when online',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (lastSyncTime != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Last sync: ${_formatDateTime(lastSyncTime)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_done,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'All Synced!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No items in the sync queue',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueItemCard(OfflineData item) {
    final color = _hexToColor(OfflineSyncService.getSyncStatusColor(item.status));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      OfflineSyncService.getSyncStatusIcon(item.status),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatItemType(item.type),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(item.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    OfflineSyncService.getSyncStatusLabel(item.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            if (item.status == SyncStatus.failed) ...[
              const SizedBox(height: 12),
              Text(
                'Retry count: ${item.retryCount}/${OfflineSyncService.maxRetries}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _retryItem(item),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteItem(item),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatItemType(String type) {
    return type.split('_').map((word) =>
    word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
  }
}