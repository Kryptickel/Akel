import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/hospital_service.dart';
import '../services/location_service.dart';
import '../models/hospital.dart';
import '../screens/route_navigation_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HospitalMapScreen extends StatefulWidget {
  const HospitalMapScreen({super.key});

  @override
  State<HospitalMapScreen> createState() => _HospitalMapScreenState();
}

class _HospitalMapScreenState extends State<HospitalMapScreen> {
  final HospitalService _hospitalService = HospitalService();
  final LocationService _locationService = LocationService();

  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<Hospital> _hospitals = [];
  Set<Marker> _markers = {};
  bool _isLoading = true;
  FacilityType? _filterType;
  bool _showOnlyER = false;
  bool _showOnly24Hours = false;

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
        final hospitals = await _hospitalService.searchNearbyHospitals(
          latitude: position.latitude,
          longitude: position.longitude,
          radiusMiles: 10,
          filterType: _filterType,
        );

        if (mounted) {
          setState(() {
            _currentPosition = position;
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
            content: Text(' Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateMapMarkers() {
    _markers.clear();

    var filteredHospitals = _hospitals;

    // Apply ER filter
    if (_showOnlyER) {
      filteredHospitals = filteredHospitals.where((h) => h.hasEmergencyRoom).toList();
    }

    // Apply 24-hour filter
    if (_showOnly24Hours) {
      filteredHospitals = filteredHospitals.where((h) => h.isOpen24Hours).toList();
    }

    for (final hospital in filteredHospitals) {
      _markers.add(
        Marker(
          markerId: MarkerId(hospital.id),
          position: LatLng(hospital.latitude, hospital.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerHue(hospital.type),
          ),
          infoWindow: InfoWindow(
            title: hospital.name,
            snippet: ' ${hospital.rating} • ${hospital.estimatedWaitTime ?? 0} min wait',
          ),
          onTap: () => _showHospitalDetails(hospital),
        ),
      );
    }
  }

  double _getMarkerHue(FacilityType type) {
    switch (type) {
      case FacilityType.hospital:
        return BitmapDescriptor.hueRed;
      case FacilityType.urgentCare:
        return BitmapDescriptor.hueOrange;
      case FacilityType.clinic:
        return BitmapDescriptor.hueGreen;
      case FacilityType.pharmacy:
        return BitmapDescriptor.hueBlue;
      case FacilityType.emergencyRoom:
        return BitmapDescriptor.hueRose;
    }
  }

  void _showHospitalDetails(Hospital hospital) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2740),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hospital Name & Type
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_hospital,
                        color: Colors.blue,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hospital.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getFacilityTypeName(hospital.type),
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

                // Rating & Reviews
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < hospital.rating.floor()
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 24,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      '${hospital.rating}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
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
                const SizedBox(height: 24),

                // Quick Info Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        ' Wait Time',
                        '${hospital.estimatedWaitTime ?? 0} min',
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        ' Distance',
                        '${hospital.distance.toStringAsFixed(1)} mi',
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Features
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (hospital.hasEmergencyRoom)
                      _buildFeatureChip(' Emergency Room', Colors.red),
                    if (hospital.isOpen24Hours)
                      _buildFeatureChip(' 24 Hours', Colors.blue),
                    if (hospital.acceptsWalkIns)
                      _buildFeatureChip(' Walk-ins', Colors.green),
                    ...hospital.specialties
                        .take(3)
                        .map((s) => _buildFeatureChip(_getSpecialtyName(s), Colors.purple)),
                  ],
                ),
                const SizedBox(height: 24),

                // Details
                _buildDetailRow(Icons.location_on, 'Address', hospital.address),
                _buildDetailRow(Icons.phone, 'Phone', hospital.phoneNumber),
                _buildDetailRow(Icons.access_time, 'Hours', hospital.operatingHours ?? 'Call for hours'),
                if (hospital.website != null)
                  _buildDetailRow(Icons.language, 'Website', hospital.website!),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _callHospital(hospital.phoneNumber),
                        icon: const Icon(Icons.phone),
                        label: const Text('Call'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToHospital(hospital);
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _addReview(hospital),
                    icon: const Icon(Icons.rate_review),
                    label: const Text('Write Review'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00BFA5),
                      side: const BorderSide(color: Color(0xFF00BFA5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getFacilityTypeName(FacilityType type) {
    switch (type) {
      case FacilityType.hospital:
        return 'Hospital';
      case FacilityType.urgentCare:
        return 'Urgent Care';
      case FacilityType.clinic:
        return 'Clinic';
      case FacilityType.pharmacy:
        return 'Pharmacy';
      case FacilityType.emergencyRoom:
        return 'Emergency Room';
    }
  }

  String _getSpecialtyName(Specialty specialty) {
    return specialty.toString().split('.').last.replaceAllMapped(
      RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
    ).trim();
  }

  Widget _buildInfoCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, Color color) {
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.2),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      labelStyle: TextStyle(color: color, fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF00BFA5), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToHospital(Hospital hospital) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteNavigationScreen(
          destination: LatLng(hospital.latitude, hospital.longitude),
          destinationName: hospital.name,
        ),
      ),
    );
  }

  Future<void> _callHospital(String phone) async {
    try {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Could not make call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addReview(Hospital hospital) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => _ReviewDialog(hospital: hospital),
    ).then((result) {
      if (result == true) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' Review submitted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  List<Hospital> get _filteredHospitals {
    var filtered = _hospitals;

    if (_showOnlyER) {
      filtered = filtered.where((h) => h.hasEmergencyRoom).toList();
    }

    if (_showOnly24Hours) {
      filtered = filtered.where((h) => h.isOpen24Hours).toList();
    }

    return filtered;
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

    final stats = _hospitalService.getStatistics(_hospitals);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Hospital Finder'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1E2740),
                builder: (context) => _buildFilterSheet(),
              );
            },
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filters',
          ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
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
                      'Total', stats['totalHospitals'] as int, Colors.blue),
                  const SizedBox(width: 8),
                  _buildStatChip('ER', stats['withER'] as int, Colors.red),
                  const SizedBox(width: 8),
                  _buildStatChip(
                      '24h', stats['open24Hours'] as int, Colors.green),
                  const SizedBox(width: 8),
                  _buildStatChip(
                      ' ${(stats['averageRating'] as double).toStringAsFixed(1)}',
                      stats['totalReviews'] as int,
                      Colors.amber),
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

          // Horizontal List
          if (_filteredHospitals.isNotEmpty)
            Container(
              height: 140,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredHospitals.length,
                itemBuilder: (context, index) {
                  final hospital = _filteredHospitals[index];

                  return GestureDetector(
                    onTap: () {
                      if (_mapController != null) {
                        _mapController!.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(hospital.latitude, hospital.longitude),
                            16,
                          ),
                        );
                      }
                      _showHospitalDetails(hospital);
                    },
                    child: Container(
                      width: 220,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2740),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.local_hospital,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  hospital.name,
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
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${hospital.rating}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                ' (${hospital.reviewCount})',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ' ${hospital.estimatedWaitTime ?? 0} min wait',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ' ${hospital.distance.toStringAsFixed(1)} mi',
                                style: const TextStyle(
                                  color: Color(0xFF00BFA5),
                                  fontSize: 11,
                                ),
                              ),
                              Row(
                                children: [
                                  if (hospital.hasEmergencyRoom)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                        Colors.red.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'ER',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  if (hospital.isOpen24Hours) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                        Colors.blue.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        '24h',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
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

  Widget _buildFilterSheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Hospitals',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                title: const Text(
                  'Emergency Room Only',
                  style: TextStyle(color: Colors.white),
                ),
                value: _showOnlyER,
                activeColor: const Color(0xFF00BFA5),
                onChanged: (value) {
                  setSheetState(() => _showOnlyER = value!);
                  setState(() => _showOnlyER = value!);
                  _updateMapMarkers();
                },
              ),
              CheckboxListTile(
                title: const Text(
                  '24-Hour Facilities Only',
                  style: TextStyle(color: Colors.white),
                ),
                value: _showOnly24Hours,
                activeColor: const Color(0xFF00BFA5),
                onChanged: (value) {
                  setSheetState(() => _showOnly24Hours = value!);
                  setState(() => _showOnly24Hours = value!);
                  _updateMapMarkers();
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFA5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  final Hospital hospital;

  const _ReviewDialog({required this.hospital});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  final _nameController = TextEditingController();
  double _rating = 5.0;

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E2740),
      title: Text(
        'Review ${widget.hospital.name}',
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
                labelText: 'Your Name',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'Anonymous',
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Review Title',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'Summarize your experience',
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Your Review',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'Share your experience...',
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rating',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setState(() => _rating = (index + 1).toDouble());
                      },
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                    );
                  }),
                ),
                Center(
                  child: Text(
                    _rating.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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
          onPressed: () async {
            if (_titleController.text.trim().isEmpty ||
                _commentController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(' Please fill in all fields'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            final review = HospitalReview(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              hospitalId: widget.hospital.id,
              userName: _nameController.text.trim().isEmpty
                  ? 'Anonymous'
                  : _nameController.text.trim(),
              rating: _rating,
              title: _titleController.text.trim(),
              comment: _commentController.text.trim(),
              date: DateTime.now(),
            );

            await HospitalService().addReview(review);
            if (context.mounted) {
              Navigator.pop(context, true);
            }
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