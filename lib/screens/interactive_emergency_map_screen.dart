import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/emergency_map_service.dart';
import '../services/location_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';
import '../screens/route_navigation_screen.dart';

class InteractiveEmergencyMapScreen extends StatefulWidget {
  const InteractiveEmergencyMapScreen({super.key});

  @override
  State<InteractiveEmergencyMapScreen> createState() =>
      _InteractiveEmergencyMapScreenState();
}

class _InteractiveEmergencyMapScreenState
    extends State<InteractiveEmergencyMapScreen> {
  final EmergencyMapService _emergencyMapService = EmergencyMapService();
  final LocationService _locationService = LocationService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();

  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<EmergencyMarker> _markers = [];
  final Set<Marker> _mapMarkers = {};
  bool _isLoading = true;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final position = await _locationService.getCurrentLocation();
      final markers = await _emergencyMapService.getAllMarkers();

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _markers = markers;
          _updateMapMarkers();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateMapMarkers() {
    _mapMarkers.clear();

    final filteredMarkers = _filterType == 'all'
        ? _markers.where((m) => m.isActive).toList()
        : _markers.where((m) => m.type == _filterType && m.isActive).toList();

    for (final marker in filteredMarkers) {
      final markerType = EmergencyMapService.markerTypes
          .firstWhere((t) => t['value'] == marker.type);

      _mapMarkers.add(
        Marker(
          markerId: MarkerId(marker.id),
          position: LatLng(marker.latitude, marker.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerHue(marker.type),
          ),
          infoWindow: InfoWindow(
            title: '${markerType['icon']} ${marker.title}',
            snippet:
            '${marker.severity.toUpperCase()} • ${_emergencyMapService.getTimeElapsed(marker)}',
          ),
          onTap: () => _showMarkerDetails(marker),
        ),
      );
    }
  }

  double _getMarkerHue(String type) {
    switch (type) {
      case 'medical':
        return BitmapDescriptor.hueRed;
      case 'security':
        return BitmapDescriptor.hueOrange;
      case 'fire':
        return BitmapDescriptor.hueYellow;
      default:
        return BitmapDescriptor.hueBlue;
    }
  }

  void _showMarkerDetails(EmergencyMarker marker) {
    final distance = _currentPosition != null
        ? Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      marker.latitude,
      marker.longitude,
    )
        : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2740),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(EmergencyMapService.markerTypes
                        .firstWhere((t) => t['value'] == marker.type)['color']
                    as int)
                        .withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    EmergencyMapService.markerTypes
                        .firstWhere((t) => t['value'] == marker.type)['icon'] as String,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        marker.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        marker.severity.toUpperCase(),
                        style: TextStyle(
                          color: Color(EmergencyMapService.severityLevels
                              .firstWhere((s) => s['value'] == marker.severity)['color'] as int),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              marker.description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.access_time, 'Time',
                _emergencyMapService.getTimeElapsed(marker)),
            if (marker.userName != null)
              _buildInfoRow(Icons.person, 'Reported by', marker.userName!),
            _buildInfoRow(Icons.people, 'Responders',
                '${marker.responderCount} responding'),
            if (distance != null)
              _buildInfoRow(Icons.navigation, 'Distance',
                  _emergencyMapService.formatDistance(distance)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToMarker(marker);
                    },
                    icon: const Icon(Icons.navigation),
                    label: const Text('Navigate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00BFA5),
                      side: const BorderSide(color: Color(0xFF00BFA5)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _respondToEmergency(marker);
                    },
                    icon: const Icon(Icons.emergency),
                    label: const Text('Respond'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00BFA5), size: 18),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToMarker(EmergencyMarker marker) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteNavigationScreen(
          destination: LatLng(marker.latitude, marker.longitude),
          destinationName: marker.title,
        ),
      ),
    );
  }

  Future<void> _respondToEmergency(EmergencyMarker marker) async {
    try {
      await _emergencyMapService.addResponder(marker.id);
      await _vibrationService.success();
      await _soundService.playSuccess();

      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ You are now responding to this emergency'),
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

  Future<void> _addEmergency() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Location not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _EmergencyDialog(),
    );

    if (result != null) {
      try {
        final userId = await _emergencyMapService.getUserId();

        final marker = EmergencyMarker(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: result['type'],
          title: result['title'],
          description: result['description'],
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          timestamp: DateTime.now(),
          userId: userId,
          userName: result['userName'],
          severity: result['severity'],
        );

        await _emergencyMapService.addMarker(marker);
        await _vibrationService.warning();
        await _soundService.playError();

        _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🚨 Emergency alert broadcasted'),
              backgroundColor: Colors.red,
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
  }

  List<EmergencyMarker> get _filteredMarkers {
    if (_filterType == 'all') {
      return _markers.where((m) => m.isActive).toList();
    }
    return _markers.where((m) => m.type == _filterType && m.isActive).toList();
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

    final stats = _emergencyMapService.getStatistics();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Emergency Map'),
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterType = value;
                _updateMapMarkers();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Emergencies')),
              const PopupMenuItem(
                  value: 'medical', child: Text('🏥 Medical')),
              const PopupMenuItem(
                  value: 'security', child: Text('🚨 Security')),
              const PopupMenuItem(value: 'fire', child: Text('🔥 Fire')),
              const PopupMenuItem(
                  value: 'general', child: Text('⚠️ General')),
            ],
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEmergency,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.add_alert),
        label: const Text('Report Emergency'),
      ),
      body: Column(
        children: [
// Stats Bar
          Container(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatChip('Active', stats['activeMarkers'] as int, Colors.red),
                  const SizedBox(width: 8),
                  _buildStatChip('🏥', stats['medicalEmergencies'] as int, Colors.red),
                  const SizedBox(width: 8),
                  _buildStatChip(
                      '🚨', stats['securityEmergencies'] as int, Colors.orange),
                  const SizedBox(width: 8),
                  _buildStatChip('🔥', stats['fireEmergencies'] as int, Colors.amber),
                  const SizedBox(width: 8),
                  _buildStatChip(
                      'Responders', stats['totalResponders'] as int, Colors.green),
                ],
              ),
            ),
          ),

// Map
          Expanded(
            child: _currentPosition != null
                ? GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: 14,
              ),
              markers: _mapMarkers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.normal,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            )
                : const Center(
              child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
            ),
          ),

// Horizontal List View
          if (_filteredMarkers.isNotEmpty)
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredMarkers.length,
                itemBuilder: (context, index) {
                  final marker = _filteredMarkers[index];
                  final markerType = EmergencyMapService.markerTypes
                      .firstWhere((t) => t['value'] == marker.type);

                  return GestureDetector(
                    onTap: () {
                      if (_mapController != null) {
                        _mapController!.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(marker.latitude, marker.longitude),
                            16,
                          ),
                        );
                      }
                      _showMarkerDetails(marker);
                    },
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2740),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(markerType['color'] as int)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                markerType['icon'] as String,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  marker.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            marker.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _emergencyMapService.getTimeElapsed(marker),
                                style: const TextStyle(
                                  color: Color(0xFF00BFA5),
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '${marker.responderCount} 👥',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyDialog extends StatefulWidget {
  const _EmergencyDialog();

  @override
  State<_EmergencyDialog> createState() => _EmergencyDialogState();
}

class _EmergencyDialogState extends State<_EmergencyDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nameController = TextEditingController();
  String _type = 'general';
  String _severity = 'medium';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E2740),
      title: const Text(
        '🚨 Report Emergency',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'Brief description',
                hintStyle: TextStyle(color: Colors.white38),
                prefixIcon: Icon(Icons.title, color: Color(0xFF00BFA5)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Details',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'What is happening?',
                hintStyle: TextStyle(color: Colors.white38),
                prefixIcon: Icon(Icons.description, color: Color(0xFF00BFA5)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Your Name (Optional)',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'Anonymous',
                hintStyle: TextStyle(color: Colors.white38),
                prefixIcon: Icon(Icons.person, color: Color(0xFF00BFA5)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              dropdownColor: const Color(0xFF1E2740),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Emergency Type',
                labelStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.category, color: Color(0xFF00BFA5)),
              ),
              items: EmergencyMapService.markerTypes
                  .map((type) => DropdownMenuItem(
                value: type['value'] as String,
                child: Text('${type['icon']} ${type['name']}'),
              ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _type = value);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _severity,
              dropdownColor: const Color(0xFF1E2740),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Severity',
                labelStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.priority_high, color: Color(0xFF00BFA5)),
              ),
              items: EmergencyMapService.severityLevels
                  .map((level) => DropdownMenuItem(
                value: level['value'] as String,
                child: Text(level['name'] as String),
              ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _severity = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.trim().isEmpty ||
                _descriptionController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Please fill in all required fields'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            Navigator.pop(context, {
              'title': _titleController.text.trim(),
              'description': _descriptionController.text.trim(),
              'userName': _nameController.text.trim().isEmpty
                  ? 'Anonymous'
                  : _nameController.text.trim(),
              'type': _type,
              'severity': _severity,
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Report'),
        ),
      ],
    );
  }
}