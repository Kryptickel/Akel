import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/community_alert_map_service.dart';
import '../services/emergency_map_service.dart';
import '../services/hospital_service.dart';
import '../services/location_service.dart';
import '../models/hospital.dart';
import '../screens/route_navigation_screen.dart';

class CommunityAlertMapScreen extends StatefulWidget {
  const CommunityAlertMapScreen({super.key});

  @override
  State<CommunityAlertMapScreen> createState() =>
      _CommunityAlertMapScreenState();
}

class _CommunityAlertMapScreenState extends State<CommunityAlertMapScreen> {
  final CommunityAlertMapService _alertService = CommunityAlertMapService();
  final EmergencyMapService _emergencyService = EmergencyMapService();
  final HospitalService _hospitalService = HospitalService();
  final LocationService _locationService = LocationService();

  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<CommunityAlert> _alerts = [];
  List<EmergencyMarker> _emergencies = [];
  List<Hospital> _hospitals = [];
  Set<Marker> _markers = {};
  bool _isLoading = true;

// Layer toggles
  bool _showAlerts = true;
  bool _showEmergencies = true;
  bool _showHospitals = true;

// Filters
  String _alertFilter = 'all';
  String _emergencyFilter = 'all';

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

      if (position != null) {
// Initialize sample data if needed
        await _alertService.initializeSampleData(position);

        final alerts = await _alertService.getAllAlerts();
        final emergencies = await _emergencyService.getAllMarkers();
        final hospitals = await _hospitalService.searchNearbyHospitals(
          latitude: position.latitude,
          longitude: position.longitude,
          radiusMiles: 5,
        );

        if (mounted) {
          setState(() {
            _currentPosition = position;
            _alerts = alerts;
            _emergencies = emergencies.where((e) => e.isActive).toList();
            _hospitals = hospitals;
            _updateMapMarkers();
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Could not get location');
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
    _markers.clear();

// Add community alerts
    if (_showAlerts) {
      final filteredAlerts = _alertFilter == 'all'
          ? _alerts
          : _alerts.where((a) => a.type == _alertFilter).toList();

      for (final alert in filteredAlerts) {
        final alertType = CommunityAlertMapService.alertTypes
            .firstWhere((t) => t['value'] == alert.type);

        _markers.add(
          Marker(
            markerId: MarkerId('alert_${alert.id}'),
            position: LatLng(alert.latitude, alert.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet,
            ),
            infoWindow: InfoWindow(
              title: '${alertType['icon']} ${alert.title}',
              snippet: '${alert.confirmations} confirmations',
            ),
            onTap: () => _showAlertDetails(alert),
          ),
        );
      }
    }

// Add emergencies
    if (_showEmergencies) {
      final filteredEmergencies = _emergencyFilter == 'all'
          ? _emergencies
          : _emergencies.where((e) => e.type == _emergencyFilter).toList();

      for (final emergency in filteredEmergencies) {
        _markers.add(
          Marker(
            markerId: MarkerId('emergency_${emergency.id}'),
            position: LatLng(emergency.latitude, emergency.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: '🚨 ${emergency.title}',
              snippet: emergency.severity.toUpperCase(),
            ),
            onTap: () => _showEmergencyDetails(emergency),
          ),
        );
      }
    }

// Add hospitals
    if (_showHospitals) {
      for (final hospital in _hospitals.take(10)) {
        _markers.add(
          Marker(
            markerId: MarkerId('hospital_${hospital.id}'),
            position: LatLng(hospital.latitude, hospital.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: InfoWindow(
              title: '🏥 ${hospital.name}',
              snippet: '⭐ ${hospital.rating}',
            ),
            onTap: () => _showHospitalDetails(hospital),
          ),
        );
      }
    }
  }

  void _showAlertDetails(CommunityAlert alert) {
    final distance = _currentPosition != null
        ? Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      alert.latitude,
      alert.longitude,
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
                    color: Color(CommunityAlertMapService.alertTypes
                        .firstWhere((t) => t['value'] == alert.type)['color']
                    as int)
                        .withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    CommunityAlertMapService.alertTypes
                        .firstWhere((t) => t['value'] == alert.type)['icon'] as String,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          if (alert.isVerified)
                            const Icon(Icons.verified,
                                color: Color(0xFF00BFA5), size: 16),
                          if (alert.isVerified) const SizedBox(width: 4),
                          Text(
                            alert.isVerified ? 'Verified' : 'Unverified',
                            style: TextStyle(
                              color: alert.isVerified
                                  ? const Color(0xFF00BFA5)
                                  : Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              alert.description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
                Icons.person, 'Reported by', alert.reportedBy),
            _buildInfoRow(Icons.access_time, 'Time',
                _alertService.getTimeElapsed(alert)),
            _buildInfoRow(Icons.people, 'Confirmations',
                '${alert.confirmations} people confirmed'),
            if (distance != null)
              _buildInfoRow(Icons.navigation, 'Distance',
                  _alertService.formatDistance(distance)),
            if (alert.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: alert.tags
                    .map((tag) => Chip(
                  label: Text(tag),
                  backgroundColor:
                  Colors.purple.withValues(alpha: 0.2),
                  labelStyle: const TextStyle(
                    color: Colors.purple,
                    fontSize: 11,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _alertService.confirmAlert(alert.id);
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Alert confirmed'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RouteNavigationScreen(
                            destination:
                            LatLng(alert.latitude, alert.longitude),
                            destinationName: alert.title,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.navigation),
                    label: const Text('Navigate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA5),
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

  void _showEmergencyDetails(EmergencyMarker emergency) {
    final distance = _currentPosition != null
        ? Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      emergency.latitude,
      emergency.longitude,
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
            Text(
              '🚨 ${emergency.title}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emergency.description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
                Icons.access_time,
                'Time',
                _emergencyService.getTimeElapsed(emergency)),
            _buildInfoRow(Icons.people, 'Responders',
                '${emergency.responderCount} responding'),
            if (distance != null)
              _buildInfoRow(Icons.navigation, 'Distance',
                  _emergencyService.formatDistance(distance)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RouteNavigationScreen(
                        destination: LatLng(emergency.latitude, emergency.longitude),
                        destinationName: emergency.title,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.navigation),
                label: const Text('Navigate to Emergency'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHospitalDetails(Hospital hospital) {
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
            Text(
              '🏥 ${hospital.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${hospital.rating}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' (${hospital.reviewCount} reviews)',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.location_on, 'Address', hospital.address),
            _buildInfoRow(
                Icons.timer, 'Wait Time', '${hospital.estimatedWaitTime ?? 0} min'),
            _buildInfoRow(Icons.straighten, 'Distance',
                '${hospital.distance.toStringAsFixed(1)} mi'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RouteNavigationScreen(
                        destination:
                        LatLng(hospital.latitude, hospital.longitude),
                        destinationName: hospital.name,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.navigation),
                label: const Text('Navigate to Hospital'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
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

  Future<void> _addCommunityAlert() async {
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
      builder: (context) => const _AlertDialog(),
    );

    if (result != null) {
      try {
        final alert = CommunityAlert(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: result['type'],
          title: result['title'],
          description: result['description'],
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          timestamp: DateTime.now(),
          reportedBy: result['name'],
          severity: result['severity'],
          tags: result['tags'] ?? [],
        );

        await _alertService.addAlert(alert);
        _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Community alert submitted'),
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
  }

  void _showLayerControls() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2740),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Map Layers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: Text(
                    '📍 Community Alerts (${_alerts.length})',
                    style: const TextStyle(color: Colors.white),
                  ),
                  value: _showAlerts,
                  activeColor: const Color(0xFF00BFA5),
                  onChanged: (value) {
                    setSheetState(() => _showAlerts = value);
                    setState(() {
                      _showAlerts = value;
                      _updateMapMarkers();
                    });
                  },
                ),
                SwitchListTile(
                  title: Text(
                    '🚨 Emergencies (${_emergencies.length})',
                    style: const TextStyle(color: Colors.white),
                  ),
                  value: _showEmergencies,
                  activeColor: const Color(0xFF00BFA5),
                  onChanged: (value) {
                    setSheetState(() => _showEmergencies = value);
                    setState(() {
                      _showEmergencies = value;
                      _updateMapMarkers();
                    });
                  },
                ),
                SwitchListTile(
                  title: Text(
                    '🏥 Hospitals (${_hospitals.length})',
                    style: const TextStyle(color: Colors.white),
                  ),
                  value: _showHospitals,
                  activeColor: const Color(0xFF00BFA5),
                  onChanged: (value) {
                    setSheetState(() => _showHospitals = value);
                    setState(() {
                      _showHospitals = value;
                      _updateMapMarkers();
                    });
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA5),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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

    final alertStats = _alertService.getStatistics();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Community Alert Map'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _showLayerControls,
            icon: const Icon(Icons.layers),
            tooltip: 'Layers',
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCommunityAlert,
        backgroundColor: const Color(0xFF00BFA5),
        icon: const Icon(Icons.add_location),
        label: const Text('Report Alert'),
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
                  _buildStatChip('📍 Alerts', alertStats['totalAlerts'] as int,
                      Colors.purple),
                  const SizedBox(width: 8),
                  _buildStatChip(
                      '🚨 Emergencies', _emergencies.length, Colors.red),
                  const SizedBox(width: 8),
                  _buildStatChip('🏥 Hospitals', _hospitals.length, Colors.blue),
                  const SizedBox(width: 8),
                  _buildStatChip('✅ Verified',
                      alertStats['verifiedAlerts'] as int, Colors.green),
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
              markers: _markers,
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

// Legend
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E2740),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('📍', 'Alerts', _showAlerts, Colors.purple),
                _buildLegendItem('🚨', 'Emergencies', _showEmergencies, Colors.red),
                _buildLegendItem('🏥', 'Hospitals', _showHospitals, Colors.blue),
              ],
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

  Widget _buildLegendItem(
      String icon, String label, bool isActive, Color color) {
    return Opacity(
      opacity: isActive ? 1.0 : 0.3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? color : Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertDialog extends StatefulWidget {
  const _AlertDialog();

  @override
  State<_AlertDialog> createState() => _AlertDialogState();
}

class _AlertDialogState extends State<_AlertDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nameController = TextEditingController();
  String _type = 'other';
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
        '📍 Report Community Alert',
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
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'What did you observe?',
                hintStyle: TextStyle(color: Colors.white38),
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
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              dropdownColor: const Color(0xFF1E2740),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Alert Type',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              items: CommunityAlertMapService.alertTypes
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
              ),
              items: CommunityAlertMapService.severityLevels
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
              'name': _nameController.text.trim().isEmpty
                  ? 'Anonymous'
                  : _nameController.text.trim(),
              'type': _type,
              'severity': _severity,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00BFA5),
          ),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}