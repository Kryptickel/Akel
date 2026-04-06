import 'package:flutter/material.dart';
import '../services/journey_monitor_service.dart';
import 'package:intl/intl.dart';

class JourneyMonitorScreen extends StatefulWidget {
  const JourneyMonitorScreen({super.key});

  @override
  State<JourneyMonitorScreen> createState() => _JourneyMonitorScreenState();
}

class _JourneyMonitorScreenState extends State<JourneyMonitorScreen> {
  final JourneyMonitorService _journeyService = JourneyMonitorService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _journeyService.initialize();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E27),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
        ),
      );
    }

    final activeTrip = _journeyService.getActiveTrip();
    final parkingLocation = _journeyService.getParkingLocation();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Journey Safety'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => _showSettings(),
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            onPressed: () => _showStatistics(),
            icon: const Icon(Icons.assessment),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
// Active Trip Card
            if (activeTrip != null && activeTrip.isActive)
              _buildActiveTripCard(activeTrip)
            else
              _buildStartTripCard(),

            const SizedBox(height: 16),

// Parking Location Card
            if (parkingLocation != null)
              _buildParkingLocationCard(parkingLocation),

            if (parkingLocation != null) const SizedBox(height: 16),

// Quick Actions
            _buildQuickActionsCard(activeTrip, parkingLocation),

            const SizedBox(height: 16),

// Trip History
            _buildSectionHeader('Recent Trips'),
            const SizedBox(height: 12),
            _buildTripHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTripCard(JourneyTrip trip) {
    final duration = trip.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00BFA5), Color(0xFF1DE9B6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BFA5).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.navigation,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trip in Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      trip.name ?? 'Unnamed Trip',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTripStat(
                  'Duration',
                  hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
                  Icons.timer,
                ),
              ),
              Expanded(
                child: _buildTripStat(
                  'Check-ins',
                  '${trip.checkpoints.where((c) => c.isCheckIn).length}',
                  Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addCheckIn(),
                  icon: const Icon(Icons.add_location),
                  label: const Text('Check In'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _endTrip(),
                  icon: const Icon(Icons.stop),
                  label: const Text('End Trip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF00BFA5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStartTripCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00BFA5).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.map,
            color: Color(0xFF00BFA5),
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Start a Journey',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track your trip and let contacts know you\'re safe',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _startTrip(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Trip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParkingLocationCard(ParkingLocation parking) {
    final timeAgo = _getTimeAgo(parking.timestamp);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_parking, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Parking Location Saved',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  await _journeyService.clearParkingLocation();
                  setState(() {});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🗑️ Parking location cleared'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Saved $timeAgo',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (parking.notes != null) ...[
            const SizedBox(height: 8),
            Text(
              parking.notes!,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
// In real app, would open maps to parking location
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🗺️ Opening navigation to parking...'),
                ),
              );
            },
            icon: const Icon(Icons.navigation),
            label: const Text('Navigate Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF5E35B1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(
      JourneyTrip? activeTrip, ParkingLocation? parking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (parking == null)
                _buildActionChip(
                  'Save Parking',
                  Icons.local_parking,
                  const Color(0xFF5E35B1),
                      () => _saveParking(),
                ),
              if (activeTrip != null && activeTrip.isActive)
                _buildActionChip(
                  'Check In',
                  Icons.check_circle,
                  const Color(0xFF00BFA5),
                      () => _addCheckIn(),
                ),
              _buildActionChip(
                'View History',
                Icons.history,
                Colors.blue,
                    () => _showFullHistory(),
              ),
              _buildActionChip(
                'Settings',
                Icons.settings,
                Colors.orange,
                    () => _showSettings(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripHistory() {
    final history = _journeyService.getTripHistory().take(5).toList();

    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 60,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No trip history yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: history.map((trip) => _buildTripHistoryCard(trip)).toList(),
    );
  }

  Widget _buildTripHistoryCard(JourneyTrip trip) {
    final duration = trip.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(12),
        border: trip.arrivedSafely
            ? Border.all(color: Colors.green.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                trip.arrivedSafely ? Icons.check_circle : Icons.location_on,
                color: trip.arrivedSafely ? Colors.green : const Color(0xFF00BFA5),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.name ?? 'Unnamed Trip',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, y h:mm a').format(trip.startTime),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
                style: const TextStyle(
                  color: Color(0xFF00BFA5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (trip.totalDistance != null) ...[
            const SizedBox(height: 8),
            Text(
              '${trip.totalDistance!.toStringAsFixed(1)} km',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTripStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _startTrip() {
    final nameController = TextEditingController();
    final destController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(
          'Start New Trip',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Trip Name (optional)',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'e.g., Drive to Work',
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: destController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Destination (optional)',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'e.g., Home',
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _journeyService.startTrip(
                  name: nameController.text.trim().isEmpty
                      ? null
                      : nameController.text.trim(),
                  destination: destController.text.trim().isEmpty
                      ? null
                      : destController.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🚗 Trip started'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _endTrip() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(
          'End Trip',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Did you arrive safely?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _journeyService.endTrip(arrivedSafely: false);
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _journeyService.endTrip(arrivedSafely: true);
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Trip ended - Arrived safely!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Yes, Safe'),
          ),
        ],
      ),
    );
  }

  void _addCheckIn() async {
    try {
      await _journeyService.addCheckIn();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Check-in recorded'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveParking() {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(
          'Save Parking Location',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: notesController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            labelStyle: TextStyle(color: Colors.white70),
            hintText: 'e.g., Level 3, near elevator',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _journeyService.saveParkingLocation(
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🅿️ Parking location saved'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showFullHistory() {
// Would navigate to full history screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📜 Full history coming soon')),
    );
  }

  void _showStatistics() {
    final stats = _journeyService.getStatistics();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Row(
          children: [
            Icon(Icons.assessment, color: Color(0xFF00BFA5)),
            SizedBox(width: 12),
            Text('Trip Statistics', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Total Trips', '${stats['totalTrips']}'),
            _buildStatRow('Completed', '${stats['completedTrips']}'),
            _buildStatRow('Safe Arrivals', '${stats['safeArrivals']}'),
            _buildStatRow(
                'Total Distance', '${stats['totalDistance'].toStringAsFixed(1)} km'),
            _buildStatRow('Total Duration', '${stats['totalDuration']} min'),
            _buildStatRow('Avg Distance',
                '${stats['averageDistance'].toStringAsFixed(1)} km'),
          ],
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF00BFA5),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
// Would show settings dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⚙️ Settings coming soon')),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}