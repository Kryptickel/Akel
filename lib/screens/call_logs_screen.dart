import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart';
import '../services/call_log_service.dart';
import '../services/vibration_service.dart';

class CallLogsScreen extends StatefulWidget {
  const CallLogsScreen({super.key});

  @override
  State<CallLogsScreen> createState() => _CallLogsScreenState();
}

class _CallLogsScreenState extends State<CallLogsScreen> {
  final CallLogService _callLogService = CallLogService();
  final VibrationService _vibrationService = VibrationService();

  List<CallLogEntry> _allLogs = [];
  List<CallLogEntry> _filteredLogs = [];
  Map<String, dynamic>? _statistics;

  String _filterType = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCallLogs();
  }

  Future<void> _loadCallLogs() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        final logs = await _callLogService.getCallLogs(userId);
        final stats = await _callLogService.getCallStatistics(userId);

        if (mounted) {
          setState(() {
            _allLogs = logs;
            _filteredLogs = logs;
            _statistics = stats;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('❌ Load call logs error: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _filterType = filter;

      switch (filter) {
        case 'Answered':
          _filteredLogs = _allLogs
              .where((log) => log.outcome == CallOutcome.answered)
              .toList();
          break;
        case 'Missed':
          _filteredLogs = _allLogs
              .where((log) => log.outcome == CallOutcome.missed)
              .toList();
          break;
        case 'Failed':
          _filteredLogs = _allLogs
              .where((log) => log.outcome == CallOutcome.failed)
              .toList();
          break;
        case 'Auto-Call':
          _filteredLogs = _allLogs
              .where((log) => log.type == CallType.autoCall)
              .toList();
          break;
        default:
          _filteredLogs = _allLogs;
      }
    });
  }

  Future<void> _exportLogs() async {
    await _vibrationService.light();

    final csv = _callLogService.exportCallLogsAsCSV(_filteredLogs);
    await Share.share(csv, subject: 'Emergency Call Logs Export');
  }

  Future<void> _clearAllLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Logs?'),
        content: const Text(
          'This will permanently delete all call logs. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;

      if (userId != null) {
        final success = await _callLogService.clearAllCallLogs(userId);

        if (success && mounted) {
          await _vibrationService.success();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ All call logs cleared'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCallLogs();
        }
      }
    }
  }

  String _formatOutcome(CallOutcome outcome) {
    switch (outcome) {
      case CallOutcome.answered:
        return 'Answered';
      case CallOutcome.missed:
        return 'Missed';
      case CallOutcome.busy:
        return 'Busy';
      case CallOutcome.noAnswer:
        return 'No Answer';
      case CallOutcome.failed:
        return 'Failed';
    }
  }

  String _formatType(CallType type) {
    switch (type) {
      case CallType.autoCall:
        return 'Auto-Call';
      case CallType.emergency:
        return 'Emergency';
      case CallType.manual:
        return 'Manual';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Call Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Export',
            onPressed: _exportLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear All',
            onPressed: _clearAllLogs,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _vibrationService.light();
              _loadCallLogs();
            },
          ),
        ],
      ),
      body: Column(
        children: [
// Statistics Card
          if (_statistics != null) _buildStatisticsCard(),

// Filter Chips
          _buildFilterChips(),

// Call Logs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLogs.isEmpty
                ? _buildEmptyState()
                : _buildCallLogsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final total = _statistics!['totalCalls'] as int;
    final answered = _statistics!['answeredCalls'] as int;
    final successRate = _statistics!['successRate'] as double;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Calls', '$total', Icons.phone),
          _buildStatItem('Answered', '$answered', Icons.check_circle),
          _buildStatItem(
            'Success Rate',
            '${successRate.toStringAsFixed(0)}%',
            Icons.trending_up,
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

  Widget _buildFilterChips() {
    final filters = ['All', 'Answered', 'Missed', 'Failed', 'Auto-Call'];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _filterType == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                _vibrationService.light();
                _applyFilter(filter);
              },
              backgroundColor: Colors.transparent,
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.phone_disabled,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Call Logs',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Emergency call logs will appear here',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCallLogsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredLogs.length,
      itemBuilder: (context, index) {
        final log = _filteredLogs[index];
        return _buildCallLogCard(log);
      },
    );
  }

  Widget _buildCallLogCard(CallLogEntry log) {
    final dateStr = DateFormat('MMM dd, yyyy').format(log.timestamp);
    final timeStr = DateFormat('hh:mm a').format(log.timestamp);

    final outcomeColor = _hexToColor(
      CallLogService.getOutcomeColor(log.outcome),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _vibrationService.light();
          _showCallDetails(log);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
// Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: outcomeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    CallLogService.getOutcomeIcon(log.outcome),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),

              const SizedBox(width: 16),

// Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.contactName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.contactPhone,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: outcomeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatOutcome(log.outcome),
                            style: TextStyle(
                              fontSize: 11,
                              color: outcomeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$dateStr • $timeStr',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

// Type badge
              Text(
                CallLogService.getTypeIcon(log.type),
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCallDetails(CallLogEntry log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Contact', log.contactName),
              _buildDetailRow('Phone', log.contactPhone),
              _buildDetailRow(
                'Date',
                DateFormat('EEEE, MMM dd, yyyy').format(log.timestamp),
              ),
              _buildDetailRow(
                'Time',
                DateFormat('hh:mm:ss a').format(log.timestamp),
              ),
              _buildDetailRow(
                'Outcome',
                _formatOutcome(log.outcome),
              ),
              _buildDetailRow(
                'Type',
                _formatType(log.type),
              ),
              if (log.durationSeconds > 0)
                _buildDetailRow(
                  'Duration',
                  _callLogService.formatDuration(log.durationSeconds),
                ),
              if (log.notes != null && log.notes!.isNotEmpty)
                _buildDetailRow('Notes', log.notes!),
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