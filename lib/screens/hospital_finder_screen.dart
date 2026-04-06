import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/hospital_service.dart';
import '../models/hospital.dart';

class HospitalFinderScreen extends StatefulWidget {
  final String? searchQuery;
  final bool fromDoctorAnnie;

  const HospitalFinderScreen({
    super.key,
    this.searchQuery,
    this.fromDoctorAnnie = false,
  });

  @override
  State<HospitalFinderScreen> createState() => _HospitalFinderScreenState();
}

class _HospitalFinderScreenState extends State<HospitalFinderScreen> {
  final HospitalService _hospitalService = HospitalService();

  List<Hospital> _hospitals = [];
  List<Hospital> _filteredHospitals = [];
  bool _isLoading = true;
  Position? _currentPosition;
  FacilityType? _selectedFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.searchQuery ?? '';
    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    setState(() => _isLoading = true);

    try {
      // Get current location
      _currentPosition = await _hospitalService.getCurrentLocation();

      if (_currentPosition == null) {
        throw Exception('Could not get location');
      }

      // Search nearby hospitals
      final hospitals = await _hospitalService.searchNearbyHospitals(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusMiles: 10,
        filterType: _selectedFilter,
      );

      setState(() {
        _hospitals = hospitals;
        _filteredHospitals = hospitals;
        _isLoading = false;
      });

      // Apply recommendations if from Doctor Annie
      if (widget.fromDoctorAnnie && _searchQuery.isNotEmpty) {
        _applyRecommendations();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading hospitals: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyRecommendations() {
    final recommended = _hospitalService.getRecommendations(
      _hospitals,
      _searchQuery,
    );

    if (recommended.isNotEmpty) {
      setState(() {
        _filteredHospitals = recommended;
      });
    }
  }

  void _filterByType(FacilityType? type) {
    setState(() {
      _selectedFilter = type;
      if (type == null) {
        _filteredHospitals = _hospitals;
      } else {
        _filteredHospitals = _hospitals.where((h) => h.type == type).toList();
      }
    });
  }

  Future<void> _callHospital(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _getDirections(Hospital hospital) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${hospital.latitude},${hospital.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWebsite(String? website) async {
    if (website == null) return;
    final uri = Uri.parse(website);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(' Find Medical Facilities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadHospitals,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? const Color(0xFF1E2740) : Colors.grey[100],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', null),
                  const SizedBox(width: 8),
                  _buildFilterChip(' Hospitals', FacilityType.hospital),
                  const SizedBox(width: 8),
                  _buildFilterChip(' Urgent Care', FacilityType.urgentCare),
                  const SizedBox(width: 8),
                  _buildFilterChip(' Pharmacies', FacilityType.pharmacy),
                  const SizedBox(width: 8),
                  _buildFilterChip(' Clinics', FacilityType.clinic),
                  const SizedBox(width: 8),
                  _buildFilterChip(' Emergency', FacilityType.emergencyRoom),
                ],
              ),
            ),
          ),

          // Results count
          if (!_isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Found ${_filteredHospitals.length} facilities nearby',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),

          // Hospital list
          Expanded(
            child: _isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Finding nearby medical facilities...'),
                ],
              ),
            )
                : _filteredHospitals.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_hospital_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No facilities found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your filters',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredHospitals.length,
              itemBuilder: (context, index) {
                final hospital = _filteredHospitals[index];
                return _buildHospitalCard(hospital);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, FacilityType? type) {
    final isSelected = _selectedFilter == type;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _filterByType(selected ? type : null),
      selectedColor: const Color(0xFF00BFA5),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }

  Widget _buildHospitalCard(Hospital hospital) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showHospitalDetails(hospital),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    hospital.typeEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hospital.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hospital.typeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hospital.hasEmergencyRoom)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red),
                      ),
                      child: const Text(
                        'ER',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Rating & Distance
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    hospital.rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ' (${hospital.reviewCount} reviews)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    hospital.distanceLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Wait time
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hospital.estimatedWaitTime < 15
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: hospital.estimatedWaitTime < 15
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hospital.waitTimeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: hospital.estimatedWaitTime < 15
                              ? Colors.green[900]
                              : Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _callHospital(hospital.phoneNumber),
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _getDirections(hospital),
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Directions'),
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
    );
  }

  void _showHospitalDetails(Hospital hospital) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Row(
                  children: [
                    Text(hospital.typeEmoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hospital.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            hospital.typeLabel,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Rating
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      hospital.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' (${hospital.reviewCount} reviews)',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Distance
                _buildInfoRow(Icons.location_on, hospital.distanceLabel),

                // Wait time
                _buildInfoRow(Icons.access_time, hospital.waitTimeLabel),

                // Hours
                _buildInfoRow(
                  Icons.schedule,
                  hospital.isOpen24Hours
                      ? ' Open 24/7'
                      : hospital.operatingHours ?? 'Call for hours',
                ),

                // Phone
                InkWell(
                  onTap: () => _callHospital(hospital.phoneNumber),
                  child: _buildInfoRow(
                    Icons.phone,
                    hospital.phoneNumber,
                    isLink: true,
                  ),
                ),

                // Address
                _buildInfoRow(Icons.place, hospital.address),

                // Website
                if (hospital.website != null)
                  InkWell(
                    onTap: () => _openWebsite(hospital.website),
                    child: _buildInfoRow(
                      Icons.language,
                      'Visit Website',
                      isLink: true,
                    ),
                  ),

                // Features
                if (hospital.hasEmergencyRoom || hospital.acceptsWalkIns)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      const Text(
                        'Features',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (hospital.hasEmergencyRoom)
                        _buildFeatureChip(' Emergency Room'),
                      if (hospital.acceptsWalkIns)
                        _buildFeatureChip(' Walk-ins Welcome'),
                    ],
                  ),

                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _callHospital(hospital.phoneNumber);
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('Call Now'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _getDirections(hospital);
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('Get Directions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BFA5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isLink ? const Color(0xFF00BFA5) : null,
                decoration: isLink ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Chip(
        label: Text(label),
        backgroundColor: const Color(0xFF00BFA5).withValues(alpha: 0.1),
        labelStyle: const TextStyle(
          color: Color(0xFF00BFA5),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}