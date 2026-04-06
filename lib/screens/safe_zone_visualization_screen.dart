import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/safe_zone_visualization_service.dart';
import '../services/location_service.dart';
import '../screens/route_navigation_screen.dart';

class SafeZoneVisualizationScreen extends StatefulWidget {
  const SafeZoneVisualizationScreen({super.key});

  @override
  State<SafeZoneVisualizationScreen> createState() =>
      _SafeZoneVisualizationScreenState();
}

class _SafeZoneVisualizationScreenState
    extends State<SafeZoneVisualizationScreen> {
  final SafeZoneVisualizationService _zoneService =
  SafeZoneVisualizationService();
  final LocationService _locationService = LocationService();

  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<SafeZone> _zones = [];
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  bool _isLoading = true;
  String _filterType = 'all';
  bool _showCircles = true;
  SafeZone? _currentSafeZone;

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
        await _zoneService.initializeSampleData(position);

        final zones = await _zoneService.getAllZones();

        // Check if user is inside a safe zone
        final insideZone = _zoneService.isInsideSafeZone(position);

        if (mounted) {
          setState(() {
            _currentPosition = position;
            _zones = zones;
            _currentSafeZone = insideZone?['zone'];
            _updateMapElements();
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
            content: Text(' Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateMapElements() {
    _markers.clear();
    _circles.clear();

    final filteredZones = _filterType == 'all'
        ? _zones
        : _zones.where((z) => z.type == _filterType).toList();

    for (final zone in filteredZones) {
      // Add marker
      _markers.add(
        _zoneService.createZoneMarker(
          zone,
          onTap: () => _showZoneDetails(zone),
        ),
      );

      // Add circle overlay
      if (_showCircles) {
        _circles.add(_zoneService.createZoneCircle(zone));
      }
    }
  }

  void _showZoneDetails(SafeZone zone) {
    final distance = _currentPosition != null
        ? Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      zone.latitude,
      zone.longitude,
    )
        : null;

    final isInside = distance != null && distance <= zone.radius;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2740),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Zone Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getZoneTypeColor(zone.type)
                            .withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _getZoneTypeIcon(zone.type),
                        style: const TextStyle(fontSize: 32),
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
                            SafeZoneVisualizationService.zoneTypes
                                .firstWhere((t) => t['value'] == zone.type)['name'] as String,
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
                const SizedBox(height: 16),

                // Status Badge
                if (isInside)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield, color: Colors.green, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'You are in this safe zone',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Safety Rating
                Row(
                  children: [
                    const Text(
                      'Safety Rating: ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    ...List.generate(5, (index) {
                      return Icon(
                        index < zone.safetyRating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      '${zone.safetyRating}/5',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  zone.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Info Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        Icons.straighten,
                        'Coverage',
                        '${zone.radius.toInt()}m radius',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        Icons.navigation,
                        'Distance',
                        distance != null
                            ? _zoneService.formatDistance(distance)
                            : 'N/A',
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Features
                if (zone.features.isNotEmpty) ...[
                  const Text(
                    'Safety Features',
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
                    children: zone.features
                        .map((feature) => _buildFeatureChip(feature))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Contact Info
                if (zone.contactInfo != null) ...[
                  _buildDetailRow(
                    Icons.phone,
                    'Contact',
                    zone.contactInfo!,
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          if (_mapController != null) {
                            _mapController!.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(zone.latitude, zone.longitude),
                                16,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.zoom_in),
                        label: const Text('View'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00BFA5),
                          side: const BorderSide(color: Color(0xFF00BFA5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                                LatLng(zone.latitude, zone.longitude),
                                destinationName: zone.name,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.navigation),
                        label: const Text('Navigate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BFA5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getZoneTypeIcon(String type) {
    return SafeZoneVisualizationService.zoneTypes
        .firstWhere((t) => t['value'] == type)['icon'] as String;
  }

  Color _getZoneTypeColor(String type) {
    return Color(SafeZoneVisualizationService.zoneTypes
        .firstWhere((t) => t['value'] == type)['color'] as int);
  }

  Widget _buildInfoCard(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String feature) {
    return Chip(
      label: Text(feature),
      backgroundColor: const Color(0xFF00BFA5).withValues(alpha: 0.2),
      side: BorderSide(color: const Color(0xFF00BFA5).withValues(alpha: 0.5)),
      labelStyle: const TextStyle(
        color: Color(0xFF00BFA5),
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
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
    );
  }

  void _showFilterOptions() {
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
                  'Filter Safe Zones',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Zone Type',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All Zones'),
                      selected: _filterType == 'all',
                      onSelected: (selected) {
                        setSheetState(() => _filterType = 'all');
                        setState(() {
                          _filterType = 'all';
                          _updateMapElements();
                        });
                      },
                    ),
                    ...SafeZoneVisualizationService.zoneTypes.map((type) {
                      return ChoiceChip(
                        label: Text('${type['icon']} ${type['name']}'),
                        selected: _filterType == type['value'],
                        onSelected: (selected) {
                          setSheetState(() => _filterType = type['value'] as String);
                          setState(() {
                            _filterType = type['value'] as String;
                            _updateMapElements();
                          });
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text(
                    'Show Coverage Circles',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: _showCircles,
                  activeColor: const Color(0xFF00BFA5),
                  onChanged: (value) {
                    setSheetState(() => _showCircles = value);
                    setState(() {
                      _showCircles = value;
                      _updateMapElements();
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

  void _findNearestSafeZone() {
    if (_currentPosition == null) return;

    final result = _zoneService.getNearestSafeZone(_currentPosition!);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' No safe zones found'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final zone = result['zone'] as SafeZone;
    final distance = result['distance'] as double;

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(zone.latitude, zone.longitude),
          16,
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ' Nearest: ${zone.name} (${_zoneService.formatDistance(distance)} away)',
        ),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Navigate',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RouteNavigationScreen(
                  destination: LatLng(zone.latitude, zone.longitude),
                  destinationName: zone.name,
                ),
              ),
            );
          },
        ),
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

    final stats = _zoneService.getStatistics();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Safe Zones'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _showFilterOptions,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentSafeZone != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'You are in a safe zone',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currentSafeZone!.name,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          FloatingActionButton.extended(
            onPressed: _findNearestSafeZone,
            backgroundColor: const Color(0xFF00BFA5),
            icon: const Icon(Icons.my_location),
            label: const Text('Find Nearest'),
          ),
        ],
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
                  _buildStatChip(
                      'Total', stats['totalZones'] as int, Colors.blue),
                  const SizedBox(width: 8),
                  _buildStatChip(
                      ' ', stats['policeStations'] as int, Colors.blue),
                  const SizedBox(width: 8),
                  _buildStatChip(' ', stats['hospitals'] as int, Colors.red),
                  const SizedBox(width: 8),
                  _buildStatChip(
                      ' ', stats['safeHouses'] as int, Colors.green),
                  const SizedBox(width: 8),
                  _buildStatChip(' ${(stats['averageRating'] as double).toStringAsFixed(1)}',
                      stats['publicZones'] as int, Colors.amber),
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
                zoom: 13,
              ),
              markers: _markers,
              circles: _circles,
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

          // Horizontal Zone List
          if (_zones.isNotEmpty)
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _zones.length,
                itemBuilder: (context, index) {
                  final zone = _zones[index];
                  final distance = _currentPosition != null
                      ? Geolocator.distanceBetween(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                    zone.latitude,
                    zone.longitude,
                  )
                      : null;

                  return GestureDetector(
                    onTap: () {
                      if (_mapController != null) {
                        _mapController!.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(zone.latitude, zone.longitude),
                            16,
                          ),
                        );
                      }
                      _showZoneDetails(zone);
                    },
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2740),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getZoneTypeColor(zone.type)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _getZoneTypeIcon(zone.type),
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  zone.name,
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
                          Row(
                            children: [
                              ...List.generate(
                                zone.safetyRating,
                                    (index) => const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (distance != null)
                            Text(
                              ' ${_zoneService.formatDistance(distance)}',
                              style: const TextStyle(
                                color: Color(0xFF00BFA5),
                                fontSize: 11,
                              ),
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
          if (!label.contains(' ')) ...[
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
        ],
      ),
    );
  }
}