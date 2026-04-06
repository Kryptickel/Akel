import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../services/nearby_places_service.dart';
import '../services/enhanced_location_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';

class NearbyPlacesScreen extends StatefulWidget {
  const NearbyPlacesScreen({super.key});

  @override
  State<NearbyPlacesScreen> createState() => _NearbyPlacesScreenState();
}

class _NearbyPlacesScreenState extends State<NearbyPlacesScreen> {
  final NearbyPlacesService _placesService = NearbyPlacesService();
  final EnhancedLocationService _locationService = EnhancedLocationService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();

  Position? _currentPosition;
  String _selectedCategory = 'hospital';
  List<Map<String, dynamic>> _places = [];
  bool _isLoading = false;
  bool _hasLocation = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _hasLocation = false;
    });

    try {
      final position = await _locationService.getCurrentLocation();

      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
          _hasLocation = true;
        });

        await _searchNearby();
      } else {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(' Could not get your location'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _searchNearby() async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _vibrationService.light();
    await _soundService.playClick();

    try {
      final places = await _placesService.findNearbyPlaces(
        category: _selectedCategory,
        position: _currentPosition!,
      );

      if (mounted) {
        setState(() {
          _places = places;
          _isLoading = false;
        });

        await _vibrationService.success();
        await _soundService.playSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        await _vibrationService.error();
        await _soundService.playError();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _getDirections(Map<String, dynamic> place) async {
    if (_currentPosition == null) return;

    await _vibrationService.light();
    await _soundService.playClick();

    try {
      await _placesService.getDirections(
        fromLat: _currentPosition!.latitude,
        fromLon: _currentPosition!.longitude,
        toLat: place['latitude'],
        toLon: place['longitude'],
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Error opening maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _callPlace(Map<String, dynamic> place) async {
    await _vibrationService.light();
    await _soundService.playClick();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(' Call this place?'),
        content: Text(
          '${place['name']}\n${place['phone']}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Call'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _placesService.callPlace(place['phone']);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(' Error making call: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showPlaceDetails(Map<String, dynamic> place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2740),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Name
            Text(
              place['name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Info rows
            _buildInfoRow(Icons.location_on, place['address']),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, place['phone']),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.straighten,
              NearbyPlacesService.formatDistance(place['distance']),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.access_time,
              NearbyPlacesService.estimateTravelTime(place['distance']),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.schedule,
              place['openingHours'],
              color: place['isOpen'] ? Colors.green : Colors.red,
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _getDirections(place);
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _callPlace(place);
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.white70, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color ?? Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Nearby Places'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.my_location),
            tooltip: 'Update location',
          ),
        ],
      ),
      body: Column(
        children: [
          // Category selector
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: NearbyPlacesService.getAllCategories().length,
              itemBuilder: (context, index) {
                final category = NearbyPlacesService.getAllCategories()[index];
                final categoryData = NearbyPlacesService.getCategoryData(category)!;
                final isSelected = _selectedCategory == category;

                return GestureDetector(
                  onTap: () async {
                    if (_selectedCategory != category) {
                      setState(() {
                        _selectedCategory = category;
                      });
                      await _searchNearby();
                    }
                  },
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(categoryData['color'] as int)
                          : const Color(0xFF1E2740),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Color(categoryData['color'] as int)
                            : Colors.white24,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          categoryData['icon'] as String,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          categoryData['name'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00BFA5)),
                  SizedBox(height: 16),
                  Text(
                    'Searching nearby...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
                : !_hasLocation
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_off,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Location Required',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enable location to find nearby places',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.location_on),
                    label: const Text('Enable Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            )
                : _places.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 80,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No places found',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _places.length,
              itemBuilder: (context, index) {
                final place = _places[index];
                final categoryData = NearbyPlacesService.getCategoryData(
                  place['category'],
                )!;

                return Card(
                  color: const Color(0xFF1E2740),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _showPlaceDetails(place),
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
                              color: Color(categoryData['color'] as int)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                categoryData['icon'] as String,
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
                                  place['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.straighten,
                                      size: 14,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      NearbyPlacesService.formatDistance(
                                        place['distance'],
                                      ),
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      NearbyPlacesService.estimateTravelTime(
                                        place['distance'],
                                      ),
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: place['isOpen']
                                            ? Colors.green
                                            : Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      place['isOpen'] ? 'Open' : 'Closed',
                                      style: TextStyle(
                                        color: place['isOpen']
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Actions
                          Column(
                            children: [
                              IconButton(
                                onPressed: () => _getDirections(place),
                                icon: const Icon(Icons.directions),
                                color: const Color(0xFF00BFA5),
                                tooltip: 'Directions',
                              ),
                              IconButton(
                                onPressed: () => _callPlace(place),
                                icon: const Icon(Icons.phone),
                                color: Colors.green,
                                tooltip: 'Call',
                              ),
                            ],
                          ),
                        ],
                      ),
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