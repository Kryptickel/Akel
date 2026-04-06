import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/vibration_service.dart';

class PanicHistoryScreen extends StatefulWidget {
  const PanicHistoryScreen({super.key});

  @override
  State<PanicHistoryScreen> createState() => _PanicHistoryScreenState();
}

class _PanicHistoryScreenState extends State<PanicHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final VibrationService _vibrationService = VibrationService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allEvents = [];
  List<Map<String, dynamic>> _filteredEvents = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
// Query without orderBy to avoid index requirement
        final snapshot = await _firestore
            .collection('panic_events')
            .where('userId', isEqualTo: userId)
            .get();

// Sort in memory instead
        final events = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

// Sort by timestamp descending
        events.sort((a, b) {
          final aTime = (a['timestamp'] as Timestamp).toDate();
          final bTime = (b['timestamp'] as Timestamp).toDate();
          return bTime.compareTo(aTime);
        });

        if (mounted) {
          setState(() {
            _allEvents = events;
            _filteredEvents = events;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('❌ Load history error: $e');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading history: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _filterEvents(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();

      if (_searchQuery.isEmpty) {
        _filteredEvents = _allEvents;
      } else {
        _filteredEvents = _allEvents.where((event) {
          final userName = (event['userName'] ?? '').toString().toLowerCase();
          final status = (event['status'] ?? '').toString().toLowerCase();
          final mode = event['silentMode'] == true ? 'silent' : 'normal';

          return userName.contains(_searchQuery) ||
              status.contains(_searchQuery) ||
              mode.contains(_searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panic History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _vibrationService.light();
              _loadHistory();
            },
          ),
        ],
      ),
      body: Column(
        children: [
// Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterEvents,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterEvents('');
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
          ),

// Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEvents.isEmpty
                ? _buildEmptyState()
                : _buildEventsList(),
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
            _searchQuery.isEmpty ? Icons.history : Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No Panic Events' : 'No Results Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Your panic alert history will appear here'
                : 'Try a different search term',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredEvents.length,
      itemBuilder: (context, index) {
        final event = _filteredEvents[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final timestamp = (event['timestamp'] as Timestamp).toDate();
    final dateStr = DateFormat('MMM dd, yyyy').format(timestamp);
    final timeStr = DateFormat('hh:mm a').format(timestamp);
    final isSilent = event['silentMode'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _vibrationService.light();
          _showEventDetails(event);
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSilent
                          ? Colors.purple.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isSilent ? Icons.notifications_off : Icons.warning,
                      color: isSilent ? Colors.purple : Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSilent ? 'Silent Alert' : 'Panic Alert',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$dateStr • $timeStr',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.people,
                    '${event['contactsNotified'] ?? 0} contacts',
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  if (event['locationTrackingActive'] == true)
                    _buildInfoChip(
                      Icons.route,
                      'Trail',
                      Colors.green,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(Map<String, dynamic> event) {
    final timestamp = (event['timestamp'] as Timestamp).toDate();
    final dateStr = DateFormat('EEEE, MMM dd, yyyy').format(timestamp);
    final timeStr = DateFormat('hh:mm:ss a').format(timestamp);
    final isSilent = event['silentMode'] == true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSilent ? Icons.notifications_off : Icons.warning,
              color: isSilent ? Colors.purple : Colors.red,
            ),
            const SizedBox(width: 12),
            const Text('Event Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Date', dateStr),
              const SizedBox(height: 8),
              _buildDetailRow('Time', timeStr),
              const SizedBox(height: 8),
              _buildDetailRow('Mode', isSilent ? 'Silent' : 'Normal'),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Contacts Notified',
                '${event['contactsNotified'] ?? 0}',
              ),
              const SizedBox(height: 8),
              _buildDetailRow('User', event['userName'] ?? 'Unknown'),
              if (event['latitude'] != null && event['longitude'] != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Location:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${event['latitude']}, ${event['longitude']}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
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
    return Row(
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
    );
  }
}