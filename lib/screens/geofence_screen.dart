import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/geofencing_service.dart';
import '../services/location_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';

class GeofenceScreen extends StatefulWidget {
  const GeofenceScreen({super.key});

  @override
  State<GeofenceScreen> createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends State<GeofenceScreen> {
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
  String _filterType = 'all'; // 'all', 'safe', 'danger'

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

    final filteredZones = _filterType == 'all'
        ? _zones
        : _zones.where((z) => z.type == _filterType).toList();

    for (final zone in filteredZones) {
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
            snippet:
            '${zone.type == 'safe' ? '🛡️ Safe' : '⚠️ Danger'} Zone - ${zone.radius.toInt()}m',
          ),
          onTap: () => _showZoneDetails(zone),
        ),
      );
    }
  }

  void _showZoneDetails(GeofenceZone zone) {
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
                    color: (zone.type == 'safe' ? Colors.green : Colors.red)
                        .withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    zone.type == 'safe' ? Icons.shield : Icons.warning,
                    color: zone.type == 'safe' ? Colors.green : Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        zone.type == 'safe' ? '🛡️ Safe Zone' : '⚠️ Danger Zone',
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
            const SizedBox(height: 24),
            _buildInfoRow(Icons.radio_button_checked, 'Radius',
                '${zone.radius.toInt()} meters'),
            _buildInfoRow(
                Icons.location_on,
                'Coordinates',
                '${zone.latitude.toStringAsFixed(4)}, '
                    '${zone.longitude.toStringAsFixed(4)}'),
            _buildInfoRow(Icons.login, 'Entry Alert',
                zone.alertOnEntry ? 'Enabled' : 'Disabled'),
            _buildInfoRow(Icons.logout, 'Exit Alert',
                zone.alertOnExit ? 'Enabled' : 'Disabled'),
            if (zone.description != null && zone.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.description, 'Description', zone.description!),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _editZone(zone);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
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
                      _deleteZone(zone);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00BFA5), size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
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

  Future<void> _editZone(GeofenceZone zone) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ZoneDialog(
        position: Position(
          latitude: zone.latitude,
          longitude: zone.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        ),
        existingZone: zone,
      ),
    );

    if (result != null) {
      try {
        final updatedZone = GeofenceZone(
          id: zone.id,
          name: result['name'],
          latitude: result['latitude'],
          longitude: result['longitude'],
          radius: result['radius'],
          type: result['type'],
          alertOnEntry: result['alertOnEntry'],
          alertOnExit: result['alertOnExit'],
          description: result['description'],
          createdAt: zone.createdAt,
        );

        await _geofencingService.updateZone(updatedZone);
        await _vibrationService.success();

        _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Zone updated'),
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
          'Remove "${zone.name}" from geofencing?\n\nThis action cannot be undone.',
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

  List<GeofenceZone> get _filteredZones {
    if (_filterType == 'all') return _zones;
    return _zones.where((z) => z.type == _filterType).toList();
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterType = value;
                _updateMapOverlays();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Zones'),
              ),
              const PopupMenuItem(
                value: 'safe',
                child: Text('🛡️ Safe Zones'),
              ),
              const PopupMenuItem(
                value: 'danger',
                child: Text('⚠️ Danger Zones'),
              ),
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
        onPressed: _addZone,
        backgroundColor: const Color(0xFF00BFA5),
        icon: const Icon(Icons.add_location),
        label: const Text('Add Zone'),
      ),
      body: Column(
        children: [
// Stats Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Zones',
                    _zones.length.toString(),
                    Icons.location_on,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Safe Zones',
                    _zones.where((z) => z.type == 'safe').length.toString(),
                    Icons.shield,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Danger Zones',
                    _zones.where((z) => z.type == 'danger').length.toString(),
                    Icons.warning,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ),

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
              mapType: MapType.normal,
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
            child: _filteredZones.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _filterType == 'all'
                        ? Icons.location_off
                        : Icons.filter_list_off,
                    size: 80,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _filterType == 'all'
                        ? 'No Geofence Zones'
                        : 'No ${_filterType == 'safe' ? 'Safe' : 'Danger'} Zones',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _filterType == 'all'
                        ? 'Tap "Add Zone" to create your first zone'
                        : 'Change filter or add new zones',
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
              itemCount: _filteredZones.length,
              itemBuilder: (context, index) {
                final zone = _filteredZones[index];
                final distance = _currentPosition != null
                    ? _geofencingService.calculateDistance(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  zone.latitude,
                  zone.longitude,
                )
                    : null;

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
                          '${zone.type == 'safe' ? '🛡️ Safe' : '⚠️ Danger'} Zone • ${zone.radius.toInt()}m radius',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        if (distance != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '📍 ${distance < 1000 ? '${distance.toInt()}m' : '${(distance / 1000).toStringAsFixed(1)}km'} away',
                            style: const TextStyle(
                              color: Color(0xFF00BFA5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: IconButton(
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
                        Icons.location_searching,
                        color: Colors.blue,
                      ),
                      tooltip: 'Show on Map',
                    ),
                    onTap: () => _showZoneDetails(zone),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ZoneDialog extends StatefulWidget {
  final Position position;
  final GeofenceZone? existingZone;

  const _ZoneDialog({
    required this.position,
    this.existingZone,
  });

  @override
  State<_ZoneDialog> createState() => _ZoneDialogState();
}

class _ZoneDialogState extends State<_ZoneDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _type;
  late double _radius;
  late bool _alertOnEntry;
  late bool _alertOnExit;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingZone?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.existingZone?.description ?? '',
    );
    _type = widget.existingZone?.type ?? 'safe';
    _radius = widget.existingZone?.radius ?? 500;
    _alertOnEntry = widget.existingZone?.alertOnEntry ?? true;
    _alertOnExit = widget.existingZone?.alertOnExit ?? true;
  }

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
      title: Text(
        widget.existingZone == null ? 'Create Geofence Zone' : 'Edit Zone',
        style: const TextStyle(color: Colors.white),
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
                prefixIcon: Icon(Icons.label, color: Color(0xFF00BFA5)),
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
                prefixIcon: Icon(Icons.description, color: Color(0xFF00BFA5)),
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
                prefixIcon: Icon(Icons.category, color: Color(0xFF00BFA5)),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Radius',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${_radius.toInt()}m',
                      style: const TextStyle(
                        color: Color(0xFF00BFA5),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _radius,
                  min: 100,
                  max: 2000,
                  divisions: 19,
                  activeColor: const Color(0xFF00BFA5),
                  label: '${_radius.toInt()}m',
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
              subtitle: const Text(
                'Notify when entering this zone',
                style: TextStyle(color: Colors.white60, fontSize: 12),
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
              subtitle: const Text(
                'Notify when leaving this zone',
                style: TextStyle(color: Colors.white60, fontSize: 12),
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
          child: Text(widget.existingZone == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }
}