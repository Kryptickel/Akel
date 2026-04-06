import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/geofencing_service.dart';
import '../services/location_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';

class GeofenceManagementScreen extends StatefulWidget {
  const GeofenceManagementScreen({super.key});

  @override
  State<GeofenceManagementScreen> createState() =>
      _GeofenceManagementScreenState();
}

class _GeofenceManagementScreenState extends State<GeofenceManagementScreen> {
  final GeofencingService _geofencingService = GeofencingService();
  final LocationService _locationService = LocationService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();

  List<GeofenceZone> _zones = [];
  bool _isLoading = true;
  Position? _currentPosition;
  GoogleMapController? _mapController;
  Set<Circle> _circles = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final zones = await _geofencingService.getAllZones();
      final position = await _locationService.getCurrentLocation();

      if (mounted) {
        setState(() {
          _zones = zones;
          _currentPosition = position;
          _updateMapOverlays();
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

  void _updateMapOverlays() {
    _circles.clear();
    _markers.clear();

    for (final zone in _zones) {
// Add circle
      _circles.add(
        Circle(
          circleId: CircleId(zone.id),
          center: LatLng(zone.latitude, zone.longitude),
          radius: zone.radius,
          fillColor: (zone.type == 'safe' ? Colors.green : Colors.red)
              .withValues(alpha: 0.2),
          strokeColor: zone.type == 'safe' ? Colors.green : Colors.red,
          strokeWidth: 2,
        ),
      );

// Add marker
      _markers.add(
        Marker(
          markerId: MarkerId(zone.id),
          position: LatLng(zone.latitude, zone.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            zone.type == 'safe'
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: zone.name,
            snippet: '${zone.type == 'safe' ? '🛡️ Safe' : '⚠️ Danger'} Zone',
          ),
        ),
      );
    }
  }

  Future<void> _addZone() async {
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
      builder: (context) => _ZoneDialog(
        position: _currentPosition!,
      ),
    );

    if (result != null) {
      try {
        final zone = GeofenceZone(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: result['name'],
          latitude: result['latitude'],
          longitude: result['longitude'],
          radius: result['radius'],
          type: result['type'],
          alertOnEntry: result['alertOnEntry'],
          alertOnExit: result['alertOnExit'],
          description: result['description'],
          createdAt: DateTime.now(),
        );

        await _geofencingService.addZone(zone);
        await _vibrationService.success();
        await _soundService.playSuccess();

        _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Geofence zone created'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteZone(GeofenceZone zone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(
          'Delete Zone?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove "${zone.name}" from geofencing?',
          style: const TextStyle(color: Colors.white70),
        ),
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
      try {
        await _geofencingService.deleteZone(zone.id);
        await _vibrationService.light();

        _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Zone deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Geofence Zones'),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addZone,
        backgroundColor: const Color(0xFF00BFA5),
        child: const Icon(Icons.add_location),
      ),
      body: Column(
        children: [
// Map View
          SizedBox(
            height: 300,
            child: _currentPosition != null
                ? GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: 14,
              ),
              circles: _circles,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            )
                : const Center(
              child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
            ),
          ),

// Zone List
          Expanded(
            child: _zones.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 80,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Geofence Zones',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create a safe or danger zone',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _zones.length,
              itemBuilder: (context, index) {
                final zone = _zones[index];
                return Card(
                  color: const Color(0xFF1E2740),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (zone.type == 'safe'
                            ? Colors.green
                            : Colors.red)
                            .withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        zone.type == 'safe'
                            ? Icons.shield
                            : Icons.warning,
                        color: zone.type == 'safe'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    title: Text(
                      zone.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${zone.type == 'safe' ? '🛡️ Safe' : '⚠️ Danger'} Zone',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Radius: ${zone.radius.toInt()}m',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_mapController != null) {
                              _mapController!.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  LatLng(
                                    zone.latitude,
                                    zone.longitude,
                                  ),
                                  16,
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                          ),
                          tooltip: 'Show on Map',
                        ),
                        IconButton(
                          onPressed: () => _deleteZone(zone),
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          tooltip: 'Delete',
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
}

class _ZoneDialog extends StatefulWidget {
  final Position position;

  const _ZoneDialog({required this.position});

  @override
  State<_ZoneDialog> createState() => _ZoneDialogState();
}

class _ZoneDialogState extends State<_ZoneDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _type = 'safe';
  double _radius = 500;
  bool _alertOnEntry = true;
  bool _alertOnExit = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E2740),
      title: const Text(
        'Create Geofence Zone',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Zone Name',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'e.g., Home, School, Work',
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'Additional details...',
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              dropdownColor: const Color(0xFF1E2740),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Zone Type',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'safe',
                  child: Text('🛡️ Safe Zone'),
                ),
                DropdownMenuItem(
                  value: 'danger',
                  child: Text('⚠️ Danger Zone'),
                ),
              ],
              onChanged: (value) {
                setState(() => _type = value!);
              },
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Radius: ${_radius.toInt()}m',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Slider(
                  value: _radius,
                  min: 100,
                  max: 2000,
                  divisions: 19,
                  activeColor: const Color(0xFF00BFA5),
                  onChanged: (value) {
                    setState(() => _radius = value);
                  },
                ),
              ],
            ),
            CheckboxListTile(
              title: const Text(
                'Alert on Entry',
                style: TextStyle(color: Colors.white),
              ),
              value: _alertOnEntry,
              activeColor: const Color(0xFF00BFA5),
              onChanged: (value) {
                setState(() => _alertOnEntry = value!);
              },
            ),
            CheckboxListTile(
              title: const Text(
                'Alert on Exit',
                style: TextStyle(color: Colors.white),
              ),
              value: _alertOnExit,
              activeColor: const Color(0xFF00BFA5),
              onChanged: (value) {
                setState(() => _alertOnExit = value!);
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
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Please enter zone name'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'description': _descriptionController.text.trim(),
              'latitude': widget.position.latitude,
              'longitude': widget.position.longitude,
              'radius': _radius,
              'type': _type,
              'alertOnEntry': _alertOnEntry,
              'alertOnExit': _alertOnExit,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00BFA5),
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }
}