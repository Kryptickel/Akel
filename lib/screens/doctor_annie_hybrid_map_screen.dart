import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

// ========================================
// MODELS
// ========================================

/// Represents a medical facility (hospital, clinic, pharmacy)
class MedicalFacility {
  final String id;
  final String name;
  final FacilityType type;
  final double latitude;
  final double longitude;
  final String? address;
  final String? phoneNumber;
  final bool isEmergency;
  final double? rating;

  const MedicalFacility({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.address,
    this.phoneNumber,
    this.isEmergency = false,
    this.rating,
  });

  factory MedicalFacility.fromJson(Map<String, dynamic> json) {
    return MedicalFacility(
      id: json['id']?.toString() ?? json['name']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Facility',
      type: FacilityType.fromString(json['type'] ?? 'hospital'),
      latitude: (json['lat'] ?? json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['lng'] ?? json['longitude'] ?? 0.0).toDouble(),
      address: json['address'] ?? json['vicinity'],
      phoneNumber: json['phone'] ?? json['phoneNumber'],
      isEmergency: json['isEmergency'] ?? false,
      rating: json['rating']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.toString(),
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'phoneNumber': phoneNumber,
    'isEmergency': isEmergency,
    'rating': rating,
  };

  double distanceTo(double lat, double lng) {
    return _calculateDistance(latitude, longitude, lat, lng);
  }

  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // Earth's radius in meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180.0;
}

enum FacilityType {
  hospital,
  clinic,
  pharmacy,
  emergencyCenter;

  static FacilityType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'hospital':
        return FacilityType.hospital;
      case 'clinic':
        return FacilityType.clinic;
      case 'pharmacy':
        return FacilityType.pharmacy;
      case 'emergency':
      case 'emergency_center':
        return FacilityType.emergencyCenter;
      default:
        return FacilityType.hospital;
    }
  }

  IconData get icon {
    switch (this) {
      case FacilityType.hospital:
        return Icons.local_hospital;
      case FacilityType.clinic:
        return Icons.medical_services;
      case FacilityType.pharmacy:
        return Icons.medication;
      case FacilityType.emergencyCenter:
        return Icons.emergency;
    }
  }

  Color get color {
    switch (this) {
      case FacilityType.hospital:
        return Colors.red;
      case FacilityType.clinic:
        return Colors.blue;
      case FacilityType.pharmacy:
        return Colors.green;
      case FacilityType.emergencyCenter:
        return Colors.orange;
    }
  }
}

enum ViewMode {
  onlineMap,
  offlineVisual,
  offlineList;
}

// ========================================
// MAIN SCREEN
// ========================================

class DoctorAnnieHybridScreen extends StatefulWidget {
  const DoctorAnnieHybridScreen({Key? key}) : super(key: key);

  @override
  State<DoctorAnnieHybridScreen> createState() =>
      _DoctorAnnieHybridScreenState();
}

class _DoctorAnnieHybridScreenState extends State<DoctorAnnieHybridScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final Completer<GoogleMapController> _mapController = Completer();

// State
  ViewMode _viewMode = ViewMode.offlineVisual;
  bool _isOnline = true;
  bool _isLoading = false;
  bool _isListening = false;
  bool _mapReady = false;

// Location & Facilities
  Position? _currentLocation;
  List<MedicalFacility> _facilities = [];
  MedicalFacility? _selectedFacility;
  Set<Marker> _markers = {};

// Connectivity
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  double _deviceHeading = 0.0; // Simple heading without compass

// Configuration
  static const String _googlePlacesApiKey = 'YOUR_GOOGLE_PLACES_API_KEY';
  static const String _offlineMapAsset = 'assets/images/offline_map.png';
  static const String _offlineFacilitiesAsset =
      'assets/data/offline_facilities.json';

// Offline map bounds (Lagos, Nigeria - adjust for your region)
  static const double _mapMinLat = 6.430;
  static const double _mapMaxLat = 6.445;
  static const double _mapMinLng = 3.410;
  static const double _mapMaxLng = 3.425;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await _initializeConnectivity();
    await _initializeLocation();
    await _initializeSpeech();
  }

  Future<void> _initializeConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.mobile);
    });

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
          final wasOnline = _isOnline;
          final nowOnline = results.contains(ConnectivityResult.wifi) ||
              results.contains(ConnectivityResult.mobile);

          if (wasOnline != nowOnline) {
            setState(() {
              _isOnline = nowOnline;
              _viewMode = nowOnline ? ViewMode.onlineMap : ViewMode.offlineList;
            });

            if (nowOnline) {
              _speak('Connection restored. Loading live medical facilities.');
              _fetchOnlineFacilities();
            } else {
              _speak('Connection lost. Switching to offline mode.');
              _loadOfflineFacilities();
            }
          }
        });
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission is required');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permissions are permanently denied');
        return;
      }

      final location = await Geolocator.getCurrentPosition();
      setState(() => _currentLocation = location);

      if (_isOnline) {
        await _fetchOnlineFacilities();
      } else {
        await _loadOfflineFacilities();
      }

// Listen for location updates and calculate heading
      Position? lastPosition = location;
      Geolocator.getPositionStream().listen((Position newPosition) {
        if (!mounted) return;

        final previous = lastPosition;

        if (previous != null) {
          try {
            final heading = Geolocator.bearingBetween(
              previous.latitude,
              previous.longitude,
              newPosition.latitude,
              newPosition.longitude,
            );
            setState(() {
              _currentLocation = newPosition;
              _deviceHeading = heading;
            });
          } catch (e) {
            debugPrint('Bearing calculation error: $e');
            setState(() => _currentLocation = newPosition);
          }
        } else {
          setState(() => _currentLocation = newPosition);
        }

        lastPosition = newPosition;
      });
    } catch (e) {
      debugPrint('Location initialization error: $e');
      _showError('Failed to initialize location services');
    }
  }

  Future<void> _initializeSpeech() async {
    await _speech.initialize();
  }

  Future<void> _fetchOnlineFacilities() async {
    if (_currentLocation == null) return;

    setState(() => _isLoading = true);

    try {
      final lat = _currentLocation!.latitude;
      final lng = _currentLocation!.longitude;

      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
              '?location=$lat,$lng'
              '&radius=5000'
              '&type=hospital'
              '&key=$_googlePlacesApiKey');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          final facilities = results.map((place) {
            final geometry = place['geometry']?['location'];
            return MedicalFacility(
              id: place['place_id'] ?? place['name'] ?? '',
              name: place['name'] ?? 'Unknown',
              type: _determineFacilityType(place['types']),
              latitude: geometry?['lat']?.toDouble() ?? 0.0,
              longitude: geometry?['lng']?.toDouble() ?? 0.0,
              address: place['vicinity'],
              rating: place['rating']?.toDouble(),
            );
          }).toList();

          setState(() => _facilities = facilities);
          await _cacheFacilities();
          _updateMarkers();

          _speak('Found ${facilities.length} nearby medical facilities');
        } else {
          throw Exception('API returned status: ${data['status']}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching facilities: $e');
      _speak('Unable to load online data. Switching to offline mode.');
      await _loadOfflineFacilities();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  FacilityType _determineFacilityType(List? types) {
    if (types == null) return FacilityType.hospital;

    if (types.contains('pharmacy')) return FacilityType.pharmacy;
    if (types.contains('doctor') || types.contains('clinic')) {
      return FacilityType.clinic;
    }
    return FacilityType.hospital;
  }

  Future<void> _loadOfflineFacilities() async {
    setState(() => _isLoading = true);

    try {
// Try cached facilities first
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_facilities');

      if (cachedJson != null) {
        final List<dynamic> cachedData = jsonDecode(cachedJson);
        setState(() {
          _facilities = cachedData
              .map((json) => MedicalFacility.fromJson(json))
              .toList();
        });
      }

// Load bundled offline data
      if (_facilities.isEmpty) {
        try {
          final jsonString =
          await rootBundle.loadString(_offlineFacilitiesAsset);
          final List<dynamic> jsonData = jsonDecode(jsonString);
          setState(() {
            _facilities = jsonData
                .map((json) => MedicalFacility.fromJson(json))
                .toList();
          });
        } catch (e) {
          debugPrint('Error loading offline facilities: $e');
        }
      }

      _updateMarkers();
      _speak('${_facilities.length} offline facilities loaded');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cacheFacilities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString =
      jsonEncode(_facilities.map((f) => f.toJson()).toList());
      await prefs.setString('cached_facilities', jsonString);
      await prefs.setString(
          'cached_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error caching facilities: $e');
    }
  }

  void _updateMarkers() {
    final markers = <Marker>{};

    for (final facility in _facilities) {
      markers.add(Marker(
        markerId: MarkerId(facility.id),
        position: LatLng(facility.latitude, facility.longitude),
        icon:
        BitmapDescriptor.defaultMarkerWithHue(_getMarkerHue(facility.type)),
        infoWindow: InfoWindow(
          title: facility.name,
          snippet: facility.address ?? '',
        ),
        onTap: () => setState(() => _selectedFacility = facility),
      ));
    }

    setState(() => _markers = markers);
  }

  double _getMarkerHue(FacilityType type) {
    switch (type) {
      case FacilityType.hospital:
        return BitmapDescriptor.hueRed;
      case FacilityType.clinic:
        return BitmapDescriptor.hueBlue;
      case FacilityType.pharmacy:
        return BitmapDescriptor.hueGreen;
      case FacilityType.emergencyCenter:
        return BitmapDescriptor.hueOrange;
    }
  }

  Future<void> _speak(String text) async {
    debugPrint('🔊 Annie: $text');
// TODO: Integrate with TTS service when available
  }

  void _startListening() async {
    if (_isListening) return;

    final available = await _speech.initialize();
    if (!available) {
      _showError('Speech recognition not available');
      return;
    }

    setState(() => _isListening = true);

    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final command = result.recognizedWords.toLowerCase();
          _processVoiceCommand(command);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _processVoiceCommand(String command) {
    if (command.contains('nearest') && command.contains('hospital')) {
      _findNearestFacility(FacilityType.hospital);
    } else if (command.contains('nearest') && command.contains('pharmacy')) {
      _findNearestFacility(FacilityType.pharmacy);
    } else if (command.contains('call') || command.contains('emergency')) {
      _callEmergency();
    } else {
      _speak(
          'I can help you find the nearest hospital, clinic, or pharmacy. You can also say "call emergency".');
    }
  }

  void _findNearestFacility([FacilityType? type]) {
    if (_currentLocation == null || _facilities.isEmpty) {
      _speak('Location or facilities not available');
      return;
    }

    final filteredFacilities = type != null
        ? _facilities.where((f) => f.type == type).toList()
        : _facilities;

    if (filteredFacilities.isEmpty) {
      _speak('No ${type?.toString() ?? 'facilities'} found');
      return;
    }

    final lat = _currentLocation!.latitude;
    final lng = _currentLocation!.longitude;

    final nearest = filteredFacilities.reduce((a, b) {
      return a.distanceTo(lat, lng) < b.distanceTo(lat, lng) ? a : b;
    });

    setState(() => _selectedFacility = nearest);

    if (_viewMode == ViewMode.onlineMap && _mapReady) {
      _mapController.future.then((controller) {
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(nearest.latitude, nearest.longitude),
            15,
          ),
        );
      });
    }

    final distance = nearest.distanceTo(lat, lng);
    _speak('Nearest ${type?.toString() ?? 'facility'} is ${nearest.name}, '
        '${_formatDistance(distance)} away');
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} kilometers';
    }
    return '${meters.toStringAsFixed(0)} meters';
  }

  Future<void> _navigateToFacility(MedicalFacility facility) async {
    if (_isOnline) {
      final url = Uri.parse(
          'google.navigation:q=${facility.latitude},${facility.longitude}&mode=d');

      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        final webUrl = Uri.parse(
            'https://www.google.com/maps/dir/?api=1'
                '&destination=${facility.latitude},${facility.longitude}');
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } else {
      final distance = _currentLocation != null
          ? facility.distanceTo(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      )
          : 0.0;

      _speak('Offline mode. ${facility.name} is approximately '
          '${_formatDistance(distance)} away. '
          'Navigation will be available when connection is restored.');
    }
  }

  Future<void> _callFacility(MedicalFacility facility) async {
    final phoneNumber = facility.phoneNumber ?? '911';
    final uri = Uri.parse('tel:$phoneNumber');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showError('Unable to make phone calls on this device');
    }
  }

  Future<void> _callEmergency() async {
    final uri = Uri.parse('tel:911');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      _speak('Calling emergency services');
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Annie Emergency Map'),
        backgroundColor: Colors.red.shade700,
        actions: [
          IconButton(
            icon: Icon(_isOnline ? Icons.cloud : Icons.cloud_off),
            onPressed: () {
              _showError(
                _isOnline
                    ? 'Online: Live medical facility data'
                    : 'Offline: Using cached data',
              );
            },
          ),
          PopupMenuButton<ViewMode>(
            icon: const Icon(Icons.view_module),
            onSelected: (mode) => setState(() => _viewMode = mode),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ViewMode.onlineMap,
                enabled: _isOnline,
                child: Row(
                  children: [
                    Icon(Icons.map, color: _isOnline ? null : Colors.grey),
                    const SizedBox(width: 8),
                    Text(_isOnline ? 'Online Map' : 'Online Map (unavailable)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ViewMode.offlineVisual,
                child: Row(
                  children: [
                    Icon(Icons.map_outlined),
                    SizedBox(width: 8),
                    Text('Offline Visual Map'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ViewMode.offlineList,
                child: Row(
                  children: [
                    Icon(Icons.list),
                    SizedBox(width: 8),
                    Text('List + Compass'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildMainContent(),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (_selectedFacility != null) _buildFacilityCard(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildMainContent() {
    switch (_viewMode) {
      case ViewMode.onlineMap:
        return _buildOnlineMap();
      case ViewMode.offlineVisual:
        return _buildOfflineVisualMap();
      case ViewMode.offlineList:
        return _buildOfflineListView();
    }
  }

  Widget _buildOnlineMap() {
    final initialPosition = CameraPosition(
      target: _currentLocation != null
          ? LatLng(_currentLocation!.latitude, _currentLocation!.longitude)
          : const LatLng(6.5244, 3.3792),
      zoom: 13,
    );

    return GoogleMap(
      initialCameraPosition: initialPosition,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      markers: _markers,
      onMapCreated: (controller) {
        if (!_mapController.isCompleted) {
          _mapController.complete(controller);
          setState(() => _mapReady = true);
        }
      },
      onTap: (_) => setState(() => _selectedFacility = null),
    );
  }

  Widget _buildOfflineVisualMap() {
    return OfflineVisualMapWidget(
      assetPath: _offlineMapAsset,
      facilities: _facilities,
      userLocation: _currentLocation,
      minLat: _mapMinLat,
      maxLat: _mapMaxLat,
      minLng: _mapMinLng,
      maxLng: _mapMaxLng,
      onTapFacility: (facility) {
        setState(() => _selectedFacility = facility);
      },
    );
  }

  Widget _buildOfflineListView() {
    return OfflineListCompassWidget(
      facilities: _facilities,
      userLocation: _currentLocation,
      heading: _deviceHeading,
      onSelectFacility: (facility) {
        setState(() => _selectedFacility = facility);
      },
    );
  }

  Widget _buildFacilityCard() {
    final facility = _selectedFacility!;
    double? distance;

    if (_currentLocation != null) {
      distance = facility.distanceTo(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: 80,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(facility.type.icon, color: facility.type.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      facility.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedFacility = null),
                  ),
                ],
              ),
              if (facility.address != null) ...[
                const SizedBox(height: 8),
                Text(facility.address!),
              ],
              if (distance != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatDistance(distance),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.directions),
                    label: const Text('Navigate'),
                    onPressed: () => _navigateToFacility(facility),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.phone),
                    label: const Text('Call'),
                    onPressed: () => _callFacility(facility),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    onPressed: () {
                      _speak('Share feature coming soon');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
              label: Text(_isListening ? 'Listening...' : 'Voice Command'),
              onPressed: _isListening ? _stopListening : _startListening,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isListening ? Colors.red : Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            onPressed: () => _findNearestFacility(),
            backgroundColor: Colors.red.shade700,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}

// ========================================
// OFFLINE VISUAL MAP WIDGET
// ========================================

class OfflineVisualMapWidget extends StatelessWidget {
  final String assetPath;
  final List<MedicalFacility> facilities;
  final Position? userLocation;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;
  final Function(MedicalFacility) onTapFacility;

  const OfflineVisualMapWidget({
    Key? key,
    required this.assetPath,
    required this.facilities,
    required this.userLocation,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    required this.onTapFacility,
  }) : super(key: key);

  Offset _projectToScreen(double lat, double lng, Size size) {
    final x = (lng - minLng) / (maxLng - minLng);
    final y = 1 - ((lat - minLat) / (maxLat - minLat));
    return Offset(x * size.width, y * size.height);
  }

  @override
  Widget build(BuildContext context) {
    if (facilities.isEmpty) {
      return const Center(
        child: Text('No offline facilities available'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Text('Offline map unavailable'),
                    ),
                  );
                },
              ),
            ),
            ...facilities.map((facility) {
              final position = _projectToScreen(
                facility.latitude,
                facility.longitude,
                size,
              );

              return Positioned(
                left: position.dx - 15,
                top: position.dy - 30,
                child: GestureDetector(
                  onTap: () => onTapFacility(facility),
                  child: Column(
                    children: [
                      Icon(
                        facility.type.icon,
                        color: facility.type.color,
                        size: 30,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          facility.name,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            if (userLocation != null)
              Builder(
                builder: (context) {
                  final position = _projectToScreen(
                    userLocation!.latitude,
                    userLocation!.longitude,
                    size,
                  );

                  return Positioned(
                    left: position.dx - 12,
                    top: position.dy - 12,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 24,
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

// ========================================
// OFFLINE LIST + COMPASS WIDGET
// ========================================

class OfflineListCompassWidget extends StatelessWidget {
  final List<MedicalFacility> facilities;
  final Position? userLocation;
  final double heading;
  final Function(MedicalFacility) onSelectFacility;

  const OfflineListCompassWidget({
    Key? key,
    required this.facilities,
    required this.userLocation,
    required this.heading,
    required this.onSelectFacility,
  }) : super(key: key);

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = _toRadians(lon2 - lon1);
    final y = sin(dLon) * cos(_toRadians(lat2));
    final x = cos(_toRadians(lat1)) * sin(_toRadians(lat2)) -
        sin(_toRadians(lat1)) * cos(_toRadians(lat2)) * cos(dLon);
    final bearing = atan2(y, x);
    return (bearing * 180 / pi + 360) % 360;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  @override
  Widget build(BuildContext context) {
    if (facilities.isEmpty) {
      return const Center(
        child: Text('No facilities available'),
      );
    }

    return Column(
      children: [
        Container(
          height: 150,
          color: Colors.grey[100],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.rotate(
                  angle: -heading * pi / 180,
                  child: const Icon(
                    Icons.navigation,
                    size: 48,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Heading: ${heading.toStringAsFixed(0)}°',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: facilities.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final facility = facilities[index];
              double? distance;
              double? bearing;

              if (userLocation != null) {
                distance = facility.distanceTo(
                  userLocation!.latitude,
                  userLocation!.longitude,
                );
                bearing = _calculateBearing(
                  userLocation!.latitude,
                  userLocation!.longitude,
                  facility.latitude,
                  facility.longitude,
                );
              }

              return ListTile(
                leading: Icon(facility.type.icon, color: facility.type.color),
                title: Text(facility.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (facility.address != null) Text(facility.address!),
                    if (distance != null && bearing != null)
                      Text(
                        '${_formatDistance(distance)} • ${bearing.toStringAsFixed(0)}°',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => onSelectFacility(facility),
                ),
                onTap: () => onSelectFacility(facility),
              );
            },
          ),
        ),
      ],
    );
  }
}