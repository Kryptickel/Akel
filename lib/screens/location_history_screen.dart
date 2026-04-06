import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:math' as math; // Added for distance calculations
import 'package:path_provider/path_provider.dart';
import '../services/location_history_service.dart';

class LocationHistoryScreen extends StatefulWidget {
  final String emergencyId;
  final String emergencyTitle;

  const LocationHistoryScreen({
    super.key,
    required this.emergencyId,
    required this.emergencyTitle,
  });

  @override
  State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  final LocationHistoryService _historyService = LocationHistoryService();
  List<LocationPoint> _points = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  int? _selectedPointIndex;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    final points = await _historyService.getHistoryForEmergency(widget.emergencyId);
    final stats = await _historyService.getStatistics(points);

    if (mounted) {
      setState(() {
        _points = points;
        _statistics = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final csv = _historyService.exportToCSV(_points);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/location_history_${widget.emergencyId}.csv');
      await file.writeAsString(csv);

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Location History - ${widget.emergencyTitle}',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' Location history exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyCoordinates(LocationPoint point) async {
    await Clipboard.setData(
      ClipboardData(text: '${point.latitude}, ${point.longitude}'),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Coordinates copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  String _formatSpeed(double metersPerSecond) {
    final kmh = metersPerSecond * 3.6;
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location History'),
        actions: [
          if (_points.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportToCSV,
              tooltip: 'Export to CSV',
            ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).primaryColor,
        ),
      )
          : _points.isEmpty
          ? _buildEmptyState()
          : Column(
        children: [
          _buildStatisticsCard(),
          Expanded(
            child: _buildLocationList(),
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
          Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Location History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Location tracking was not active during this emergency',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    if (_statistics == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).primaryColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Trip Statistics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Distance',
                    _formatDistance(_statistics!['totalDistance'] as double),
                    Icons.straighten,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Duration',
                    _formatDuration(_statistics!['duration'] as Duration),
                    Icons.timer,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Points',
                    '${_statistics!['totalPoints']}',
                    Icons.location_on,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Avg Speed',
                    _formatSpeed(_statistics!['averageSpeed'] as double),
                    Icons.speed,
                    Colors.green,
                  ),
                ),
              ],
            ),
            if (_statistics!['startTime'] != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Started: ${DateFormat('MMM d, y • h:mm a').format(_statistics!['startTime'] as DateTime)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Ended: ${DateFormat('MMM d, y • h:mm a').format(_statistics!['endTime'] as DateTime)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _points.length,
      itemBuilder: (context, index) {
        final point = _points[index];
        final isSelected = _selectedPointIndex == index;
        final isFirst = index == 0;
        final isLast = index == _points.length - 1;

        double? distanceFromPrevious;
        if (index > 0) {
          distanceFromPrevious = _calculateDistance(_points[index - 1], point);
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    if (!isFirst)
                      Container(
                        width: 2,
                        height: 20,
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isFirst ? Colors.green : isLast ? Colors.red : Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12, left: 8),
                  color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPointIndex = isSelected ? null : index;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isFirst
                                      ? Colors.green.withOpacity(0.1)
                                      : isLast
                                      ? Colors.red.withOpacity(0.1)
                                      : Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isFirst ? 'START' : isLast ? 'END' : 'Point ${index + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isFirst
                                        ? Colors.green
                                        : isLast
                                        ? Colors.red
                                        : Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                DateFormat('h:mm:ss a').format(point.timestamp),
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 16, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 16),
                                onPressed: () => _copyCoordinates(point),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          if (isSelected) ...[
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            _buildDetailRow('Accuracy', '±${point.accuracy.toStringAsFixed(1)}m', Icons.my_location),
                            _buildDetailRow('Speed', _formatSpeed(point.speed), Icons.speed),
                            _buildDetailRow('Altitude', '${point.altitude.toStringAsFixed(1)}m', Icons.terrain),
                            if (distanceFromPrevious != null)
                              _buildDetailRow('From Previous', _formatDistance(distanceFromPrevious), Icons.straighten),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text('$label:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  double _calculateDistance(LocationPoint p1, LocationPoint p2) {
    const double earthRadius = 6371000; // in meters

    double dLat = _toRadians(p2.latitude - p1.latitude);
    double dLon = _toRadians(p2.longitude - p1.longitude);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(p1.latitude)) * math.cos(_toRadians(p2.latitude)) * math.sin(dLon / 2) * math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }
}