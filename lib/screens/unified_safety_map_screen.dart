import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../services/enhanced_location_service.dart';
import '../services/geofence_service.dart';
import '../services/places_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import '../widgets/futuristic_widgets.dart';

class UnifiedSafetyMapScreen extends StatefulWidget {
  const UnifiedSafetyMapScreen({super.key});

  @override
  State<UnifiedSafetyMapScreen> createState() => _UnifiedSafetyMapScreenState();
}

class _UnifiedSafetyMapScreenState extends State<UnifiedSafetyMapScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _mapController;

  final EnhancedLocationService _locationService = EnhancedLocationService();
  final GeofenceService _geofenceService = GeofenceService();
  final PlacesService _placesService = PlacesService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();

  // Map state
  Position? _currentPosition;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  String _currentAddress = 'Loading...';

  // Layer visibility
  bool _showHospitals = true;
  bool _showPoliceStations = true;
  bool _showFireStations = false;
  bool _showSafeZones = true;
  bool _showGeofences = true;
  bool _showCommunityAlerts = false;

  // Map type
  MapType _mapType = MapType.normal;

  // Location tracking
  StreamSubscription<Position>? _positionStream;
  bool _isTrackingLocation = false;

  // Search
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeMap();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ==================== INITIALIZATION ====================

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);

    try {
      // Get current location
      final position = await _locationService.getCurrentLocation();

      if (position != null) {
        setState(() {
          _currentPosition = position;
        });

        // Get address
        final address = await _locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (address != null) {
          setState(() {
            _currentAddress = address;
          });
        }

        // Load all layers
        await _loadAllLayers();
      }
    } catch (e) {
      debugPrint(' Map initialization error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAllLayers() async {
    if (_currentPosition == null) return;

    await Future.wait([
      if (_showHospitals) _loadHospitals(),
      if (_showPoliceStations) _loadPoliceStations(),
      if (_showFireStations) _loadFireStations(),
      if (_showSafeZones) _loadSafeZones(),
      if (_showGeofences) _loadGeofences(),
    ]);
  }

  // ==================== LOAD LAYERS ====================

  Future<void> _loadHospitals() async {
    if (_currentPosition == null) return;

    try {
      final hospitals = await _placesService.getNearbyHospitals(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        radius: 5000,
      );

      final hospitalMarkers = hospitals.map((hospital) {
        return Marker(
          markerId: MarkerId('hospital_${hospital['place_id']}'),
          position: LatLng(
            hospital['geometry']['location']['lat'],
            hospital['geometry']['location']['lng'],
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: hospital['name'],
            snippet: 'Hospital • ${hospital['vicinity']}',
          ),
          onTap: () => _showPlaceDetails(hospital),
        );
      }).toSet();

      setState(() {
        _markers.addAll(hospitalMarkers);
      });

      debugPrint(' Loaded ${hospitals.length} hospitals');
    } catch (e) {
      debugPrint(' Load hospitals error: $e');
    }
  }

  Future<void> _loadPoliceStations() async {
    if (_currentPosition == null) return;

    try {
      final stations = await _placesService.getNearbyPoliceStations(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        radius: 5000,
      );

      final stationMarkers = stations.map((station) {
        return Marker(
          markerId: MarkerId('police_${station['place_id']}'),
          position: LatLng(
            station['geometry']['location']['lat'],
            station['geometry']['location']['lng'],
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: station['name'],
            snippet: 'Police Station • ${station['vicinity']}',
          ),
          onTap: () => _showPlaceDetails(station),
        );
      }).toSet();

      setState(() {
        _markers.addAll(stationMarkers);
      });

      debugPrint(' Loaded ${stations.length} police stations');
    } catch (e) {
      debugPrint(' Load police stations error: $e');
    }
  }

  Future<void> _loadFireStations() async {
    if (_currentPosition == null) return;

    try {
      final stations = await _placesService.getNearbyFireStations(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        radius: 5000,
      );

      final stationMarkers = stations.map((station) {
        return Marker(
          markerId: MarkerId('fire_${station['place_id']}'),
          position: LatLng(
            station['geometry']['location']['lat'],
            station['geometry']['location']['lng'],
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: station['name'],
            snippet: 'Fire Station • ${station['vicinity']}',
          ),
          onTap: () => _showPlaceDetails(station),
        );
      }).toSet();

      setState(() {
        _markers.addAll(stationMarkers);
      });

      debugPrint(' Loaded ${stations.length} fire stations');
    } catch (e) {
      debugPrint(' Load fire stations error: $e');
    }
  }

  Future<void> _loadSafeZones() async {
    // Load predefined safe zones (police stations, hospitals, etc.)
    // This is a placeholder - implement based on your data source
  }

  Future<void> _loadGeofences() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;

    try {
      final geofences = await _geofenceService.getUserGeofences(
        authProvider.user!.uid,
      );

      final geofenceCircles = geofences.map((geofence) {
        return Circle(
          circleId: CircleId(geofence.id),
          center: LatLng(geofence.latitude, geofence.longitude),
          radius: geofence.radius,
          fillColor: geofence.type == 'safe'
              ? AkelDesign.successGreen.withValues(alpha: 0.2)
              : AkelDesign.errorRed.withValues(alpha: 0.2),
          strokeColor: geofence.type == 'safe'
              ? AkelDesign.successGreen
              : AkelDesign.errorRed,
          strokeWidth: 2,
        );
      }).toSet();

      setState(() {
        _circles.addAll(geofenceCircles);
      });

      debugPrint(' Loaded ${geofences.length} geofences');
    } catch (e) {
      debugPrint(' Load geofences error: $e');
    }
  }

  // ==================== LOCATION TRACKING ====================

  void _toggleLocationTracking() {
    if (_isTrackingLocation) {
      _stopLocationTracking();
    } else {
      _startLocationTracking();
    }
  }

  void _startLocationTracking() {
    _positionStream = _locationService.getPositionStream().listen((position) {
      setState(() {
        _currentPosition = position;
      });

      // Update camera
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );

      // Update current location marker
      _updateCurrentLocationMarker(position);
    });

    setState(() => _isTrackingLocation = true);
    _vibrationService.light();
    debugPrint(' Location tracking started');
  }

  void _stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    setState(() => _isTrackingLocation = false);
    _vibrationService.light();
    debugPrint(' Location tracking stopped');
  }

  void _updateCurrentLocationMarker(Position position) {
    final currentMarker = Marker(
      markerId: const MarkerId('current_location'),
      position: LatLng(position.latitude, position.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: InfoWindow(
        title: 'You are here',
        snippet: _currentAddress,
      ),
    );

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'current_location');
      _markers.add(currentMarker);
    });
  }

  // ==================== SEARCH ====================

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty || _currentPosition == null) return;

    try {
      final results = await _placesService.searchNearby(
        query: query,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radius: 10000,
      );

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      debugPrint(' Search error: $e');
    }
  }

  void _showPlaceDetails(Map<String, dynamic> place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlaceDetailsSheet(
        place: place,
        currentPosition: _currentPosition,
        onNavigate: () => _navigateToPlace(place),
      ),
    );
  }

  Future<void> _navigateToPlace(Map<String, dynamic> place) async {
    if (_currentPosition == null) return;

    final destination = LatLng(
      place['geometry']['location']['lat'],
      place['geometry']['location']['lng'],
    );

    // Draw route
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: [
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        destination,
      ],
      color: AkelDesign.neonBlue,
      width: 5,
    );

    setState(() {
      _polylines.add(polyline);
    });

    // Animate to show both points
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            _currentPosition!.latitude < destination.latitude
                ? _currentPosition!.latitude
                : destination.latitude,
            _currentPosition!.longitude < destination.longitude
                ? _currentPosition!.longitude
                : destination.longitude,
          ),
          northeast: LatLng(
            _currentPosition!.latitude > destination.latitude
                ? _currentPosition!.latitude
                : destination.latitude,
            _currentPosition!.longitude > destination.longitude
                ? _currentPosition!.longitude
                : destination.longitude,
          ),
        ),
        50,
      ),
    );
  }

  // ==================== BUILD UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AkelDesign.deepBlack,
      body: Stack(
        children: [
          // Map
          _buildMap(),

          // Top controls
          _buildTopControls(),

          // Bottom tabs
          _buildBottomTabs(),

          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Location tracking toggle
          FloatingActionButton(
            heroTag: 'tracking',
            onPressed: _toggleLocationTracking,
            backgroundColor: _isTrackingLocation
                ? AkelDesign.successGreen
                : AkelDesign.darkPanel,
            child: Icon(
              _isTrackingLocation ? Icons.my_location : Icons.location_searching,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Recenter button
          FloatingActionButton(
            heroTag: 'recenter',
            onPressed: _recenterMap,
            backgroundColor: AkelDesign.neonBlue,
            child: const Icon(Icons.center_focus_strong, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_currentPosition == null) {
      return const Center(child: FuturisticLoadingIndicator());
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        zoom: 14,
      ),
      mapType: _mapType,
      markers: _markers,
      circles: _circles,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: true,
      onMapCreated: (controller) {
        _mapController = controller;
      },
    );
  }

  Widget _buildTopControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AkelDesign.md),
        child: Column(
          children: [
            // Header
            FuturisticCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AkelDesign.md,
                vertical: AkelDesign.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AkelDesign.neonBlue),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SAFETY MAP', style: AkelDesign.h3.copyWith(fontSize: 14)),
                        Text(
                          _currentAddress,
                          style: AkelDesign.caption.copyWith(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  FuturisticIconButton(
                    icon: Icons.layers,
                    onPressed: _showLayersMenu,
                    size: 40,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AkelDesign.sm),

            // Search bar
            FuturisticTextField(
              controller: _searchController,
              hintText: 'Search places...',
              prefixIcon: Icons.search,
              onChanged: _searchPlaces,
            ),

            // Search results
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: AkelDesign.sm),
              _buildSearchResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: FuturisticCard(
        padding: EdgeInsets.zero,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final place = _searchResults[index];
            return ListTile(
              leading: const Icon(Icons.place, color: AkelDesign.neonBlue),
              title: Text(place['name'], style: AkelDesign.body.copyWith(fontSize: 13)),
              subtitle: Text(
                place['vicinity'] ?? '',
                style: AkelDesign.caption.copyWith(fontSize: 11),
              ),
              onTap: () {
                _showPlaceDetails(place);
                setState(() {
                  _searchResults = [];
                  _searchController.clear();
                });
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomTabs() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              AkelDesign.deepBlack.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AkelDesign.neonBlue,
                labelColor: AkelDesign.neonBlue,
                unselectedLabelColor: AkelDesign.metalChrome,
                tabs: const [
                  Tab(icon: Icon(Icons.local_hospital), text: 'Emergency'),
                  Tab(icon: Icon(Icons.shield), text: 'Safe Zones'),
                  Tab(icon: Icon(Icons.location_on), text: 'Live Track'),
                  Tab(icon: Icon(Icons.share_location), text: 'Share'),
                  Tab(icon: Icon(Icons.route), text: 'Navigate'),
                ],
              ),
              SizedBox(
                height: 120,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEmergencyTab(),
                    _buildSafeZonesTab(),
                    _buildLiveTrackTab(),
                    _buildShareTab(),
                    _buildNavigateTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyTab() {
    return Padding(
      padding: const EdgeInsets.all(AkelDesign.sm),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickAction(
              'Hospitals',
              Icons.local_hospital,
              AkelDesign.errorRed,
                  () => _focusOnLayer('hospitals'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildQuickAction(
              'Police',
              Icons.local_police,
              Colors.blue,
                  () => _focusOnLayer('police'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildQuickAction(
              'Fire',
              Icons.local_fire_department,
              Colors.orange,
                  () => _focusOnLayer('fire'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeZonesTab() {
    return Center(
      child: FuturisticButton(
        text: 'Create Safe Zone',
        icon: Icons.add_location,
        onPressed: _createSafeZone,
        color: AkelDesign.successGreen,
        isSmall: true,
      ),
    );
  }

  Widget _buildLiveTrackTab() {
    return Center(
      child: FuturisticButton(
        text: _isTrackingLocation ? 'Stop Tracking' : 'Start Tracking',
        icon: _isTrackingLocation ? Icons.stop : Icons.play_arrow,
        onPressed: _toggleLocationTracking,
        color: _isTrackingLocation ? AkelDesign.errorRed : AkelDesign.successGreen,
        isSmall: true,
      ),
    );
  }

  Widget _buildShareTab() {
    return Center(
      child: FuturisticButton(
        text: 'Share Location',
        icon: Icons.share,
        onPressed: _shareLocation,
        color: AkelDesign.neonBlue,
        isSmall: true,
      ),
    );
  }

  Widget _buildNavigateTab() {
    return Center(
      child: Text(
        'Search for a place to navigate',
        style: AkelDesign.caption,
      ),
    );
  }

  Widget _buildQuickAction(
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
      child: FuturisticCard(
        padding: const EdgeInsets.all(AkelDesign.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 4),
            Text(
              label,
              style: AkelDesign.caption.copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: AkelDesign.deepBlack.withValues(alpha: 0.9),
      child: const Center(
        child: FuturisticLoadingIndicator(size: 80),
      ),
    );
  }

  // ==================== ACTIONS ====================

  void _recenterMap() {
    if (_currentPosition == null || _mapController == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        14,
      ),
    );

    _vibrationService.light();
  }

  void _showLayersMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _LayersMenuSheet(
        showHospitals: _showHospitals,
        showPoliceStations: _showPoliceStations,
        showFireStations: _showFireStations,
        showSafeZones: _showSafeZones,
        showGeofences: _showGeofences,
        showCommunityAlerts: _showCommunityAlerts,
        mapType: _mapType,
        onToggleLayer: _toggleLayer,
        onChangeMapType: _changeMapType,
      ),
    );
  }

  void _toggleLayer(String layer, bool value) {
    setState(() {
      switch (layer) {
        case 'hospitals':
          _showHospitals = value;
          break;
        case 'police':
          _showPoliceStations = value;
          break;
        case 'fire':
          _showFireStations = value;
          break;
        case 'safe_zones':
          _showSafeZones = value;
          break;
        case 'geofences':
          _showGeofences = value;
          break;
        case 'community_alerts':
          _showCommunityAlerts = value;
          break;
      }
    });

    // Reload layers
    _markers.clear();
    _circles.clear();
    _loadAllLayers();
  }

  void _changeMapType(MapType type) {
    setState(() {
      _mapType = type;
    });
  }

  void _focusOnLayer(String layer) {
    // Implementation for focusing on specific layer
  }

  void _createSafeZone() {
    // Implementation for creating safe zone
  }

  void _shareLocation() {
    // Implementation for sharing location
  }
}

// ==================== PLACE DETAILS SHEET ====================

class _PlaceDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> place;
  final Position? currentPosition;
  final VoidCallback onNavigate;

  const _PlaceDetailsSheet({
    required this.place,
    required this.currentPosition,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AkelDesign.md),
      decoration: BoxDecoration(
        gradient: AkelDesign.carbonGradient,
        borderRadius: BorderRadius.circular(AkelDesign.radiusXl),
        border: Border.all(color: AkelDesign.neonBlue.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AkelDesign.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(place['name'], style: AkelDesign.h2),
            const SizedBox(height: 8),
            Text(place['vicinity'] ?? '', style: AkelDesign.caption),
            const SizedBox(height: AkelDesign.lg),
            FuturisticButton(
              text: 'Navigate Here',
              icon: Icons.directions,
              onPressed: () {
                Navigator.pop(context);
                onNavigate();
              },
              color: AkelDesign.neonBlue,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== LAYERS MENU SHEET ====================

class _LayersMenuSheet extends StatelessWidget {
  final bool showHospitals;
  final bool showPoliceStations;
  final bool showFireStations;
  final bool showSafeZones;
  final bool showGeofences;
  final bool showCommunityAlerts;
  final MapType mapType;
  final Function(String, bool) onToggleLayer;
  final Function(MapType) onChangeMapType;

  const _LayersMenuSheet({
    required this.showHospitals,
    required this.showPoliceStations,
    required this.showFireStations,
    required this.showSafeZones,
    required this.showGeofences,
    required this.showCommunityAlerts,
    required this.mapType,
    required this.onToggleLayer,
    required this.onChangeMapType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AkelDesign.md),
      decoration: BoxDecoration(
        gradient: AkelDesign.carbonGradient,
        borderRadius: BorderRadius.circular(AkelDesign.radiusXl),
        border: Border.all(color: AkelDesign.neonBlue.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AkelDesign.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Map Layers', style: AkelDesign.h2),
            const SizedBox(height: AkelDesign.lg),

            _buildLayerToggle(
              'Hospitals',
              Icons.local_hospital,
              AkelDesign.errorRed,
              showHospitals,
                  () => onToggleLayer('hospitals', !showHospitals),
            ),
            _buildLayerToggle(
              'Police Stations',
              Icons.local_police,
              Colors.blue,
              showPoliceStations,
                  () => onToggleLayer('police', !showPoliceStations),
            ),
            _buildLayerToggle(
              'Fire Stations',
              Icons.local_fire_department,
              Colors.orange,
              showFireStations,
                  () => onToggleLayer('fire', !showFireStations),
            ),
            _buildLayerToggle(
              'Safe Zones',
              Icons.shield,
              AkelDesign.successGreen,
              showSafeZones,
                  () => onToggleLayer('safe_zones', !showSafeZones),
            ),
            _buildLayerToggle(
              'Geofences',
              Icons.fence,
              AkelDesign.warningOrange,
              showGeofences,
                  () => onToggleLayer('geofences', !showGeofences),
            ),

            const SizedBox(height: AkelDesign.lg),
            Text('Map Type', style: AkelDesign.subtitle),
            const SizedBox(height: AkelDesign.sm),

            Row(
              children: [
                Expanded(
                  child: FuturisticChip(
                    label: 'Normal',
                    isSelected: mapType == MapType.normal,
                    onTap: () => onChangeMapType(MapType.normal),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FuturisticChip(
                    label: 'Satellite',
                    isSelected: mapType == MapType.satellite,
                    onTap: () => onChangeMapType(MapType.satellite),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FuturisticChip(
                    label: 'Hybrid',
                    isSelected: mapType == MapType.hybrid,
                    onTap: () => onChangeMapType(MapType.hybrid),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerToggle(
      String label,
      IconData icon,
      Color color,
      bool isEnabled,
      VoidCallback onTap,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AkelDesign.sm),
          decoration: BoxDecoration(
            color: isEnabled
                ? color.withValues(alpha: 0.2)
                : AkelDesign.darkPanel.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
            border: Border.all(
              color: isEnabled ? color : AkelDesign.metalChrome.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: isEnabled ? color : AkelDesign.metalChrome, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AkelDesign.body.copyWith(
                    fontSize: 14,
                    color: isEnabled ? Colors.white : AkelDesign.metalChrome,
                  ),
                ),
              ),
              Icon(
                isEnabled ? Icons.visibility : Icons.visibility_off,
                color: isEnabled ? color : AkelDesign.metalChrome,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}