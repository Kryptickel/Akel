import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/panic_history_service.dart';
import '../services/vibration_service.dart';

class PanicEventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const PanicEventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<PanicEventDetailScreen> createState() => _PanicEventDetailScreenState();
}

class _PanicEventDetailScreenState extends State<PanicEventDetailScreen> {
  final PanicHistoryService _historyService = PanicHistoryService();
  final VibrationService _vibrationService = VibrationService();

  List<Map<String, dynamic>> _locationTrail = [];
  bool _isLoadingTrail = false;

  @override
  void initState() {
    super.initState();
    if (widget.event['locationTrackingActive'] == true) {
      _loadLocationTrail();
    }
  }

  Future<void> _loadLocationTrail() async {
    setState(() => _isLoadingTrail = true);

    final trail = await _historyService.getLocationTrail(widget.event['id']);

    if (mounted) {
      setState(() {
        _locationTrail = trail;
        _isLoadingTrail = false;
      });
    }
  }

  Future<void> _shareEvent() async {
    await _vibrationService.light();
    final report = _historyService.generatePanicReport(widget.event);
    await Share.share(report, subject: 'AKEL Panic Alert Report');
  }

  Future<void> _copyLocation() async {
    await _vibrationService.light();

    final lat = widget.event['latitude'];
    final lng = widget.event['longitude'];

    if (lat != null && lng != null) {
      await Clipboard.setData(ClipboardData(text: '$lat, $lng'));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Location copied to clipboard'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = (widget.event['timestamp'] as Timestamp).toDate();
    final dateStr = DateFormat('EEEE, MMM dd, yyyy').format(timestamp);
    final timeStr = DateFormat('hh:mm:ss a').format(timestamp);
    final isSilent = widget.event['silentMode'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Report',
            onPressed: _shareEvent,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
// Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSilent
                    ? [Colors.purple, Colors.purple.withValues(alpha: 0.7)]
                    : [Colors.red, Colors.red.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isSilent ? Colors.purple : Colors.red)
                      .withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  isSilent ? Icons.notifications_off : Icons.warning,
                  color: Colors.white,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  isSilent ? 'SILENT ALERT' : 'PANIC ALERT',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

// Event Details
          _buildSectionHeader('EVENT DETAILS'),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                _buildDetailRow(
                  Icons.person,
                  'User',
                  widget.event['userName'] ?? 'Unknown',
                ),
                const Divider(height: 1),
                _buildDetailRow(
                  Icons.people,
                  'Contacts Notified',
                  '${widget.event['contactsNotified'] ?? 0}',
                ),
                const Divider(height: 1),
                _buildDetailRow(
                  isSilent ? Icons.notifications_off : Icons.volume_up,
                  'Alert Mode',
                  isSilent ? 'Silent' : 'Normal',
                ),
                const Divider(height: 1),
                _buildDetailRow(
                  Icons.check_circle,
                  'Status',
                  widget.event['status'] ?? 'Completed',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

// Location
          _buildSectionHeader('LOCATION'),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: widget.event['latitude'] != null &&
                  widget.event['longitude'] != null
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GPS Coordinates',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.event['latitude']}, ${widget.event['longitude']}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        tooltip: 'Copy Location',
                        onPressed: _copyLocation,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
// Open in Google Maps
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('View on Google Maps'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
                  : const Row(
                children: [
                  Icon(Icons.location_off, color: Colors.grey),
                  SizedBox(width: 12),
                  Text(
                    'Location unavailable',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

// Location Trail
          if (widget.event['locationTrackingActive'] == true) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('LOCATION TRAIL'),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isLoadingTrail
                    ? const Center(child: CircularProgressIndicator())
                    : _locationTrail.isEmpty
                    ? const Text('No location trail data')
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.route, color: Colors.green),
                        const SizedBox(width: 12),
                        Text(
                          '${_locationTrail.length} location points recorded',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(
                      _locationTrail.length,
                          (index) => _buildTrailPoint(
                        _locationTrail[index],
                        index,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailPoint(Map<String, dynamic> point, int index) {
    final timestamp = (point['timestamp'] as Timestamp).toDate();
    final timeStr = DateFormat('hh:mm:ss a').format(timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (index < _locationTrail.length - 1)
                Container(
                  width: 2,
                  height: 30,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${point['latitude']}, ${point['longitude']}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}