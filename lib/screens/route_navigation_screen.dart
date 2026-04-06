import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/route_navigation_service.dart';
import '../services/location_service.dart';
import '../services/vibration_service.dart';

class RouteNavigationScreen extends StatefulWidget {
  final LatLng destination;
  final String destinationName;

  const RouteNavigationScreen({
    super.key,
    required this.destination,
    required this.destinationName,
  });

  @override
  State<RouteNavigationScreen> createState() => _RouteNavigationScreenState();
}

class _RouteNavigationScreenState extends State<RouteNavigationScreen> {
  final RouteNavigationService _routeService = RouteNavigationService();
  final LocationService _locationService = LocationService();
  final VibrationService _vibrationService = VibrationService();

  GoogleMapController? _mapController;
  Position? _currentPosition;
  RouteInfo? _routeInfo;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _isLoading = true;
  int _currentStepIndex = 0;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadRoute() async {
    setState(() => _isLoading = true);

    try {
      final position = await _locationService.getCurrentLocation();

      if (position != null) {
        final origin = LatLng(position.latitude, position.longitude);
        final routeInfo = await _routeService.calculateRoute(
          origin: origin,
          destination: widget.destination,
        );

        if (mounted) {
          setState(() {
            _currentPosition = position;
            _routeInfo = routeInfo;
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
            content: Text(' Error loading route: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateMapElements() {
    if (_routeInfo == null || _currentPosition == null) return;

    // Clear existing elements
    _polylines.clear();
    _markers.clear();

    // Add polyline
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: _routeInfo!.polylinePoints,
        color: const Color(0xFF00BFA5),
        width: 5,
        patterns: [PatternItem.dot, PatternItem.gap(10)],
      ),
    );

    // Add origin marker
    _markers.add(
      Marker(
        markerId: const MarkerId('origin'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );

    // Add destination marker
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: widget.destinationName),
      ),
    );
  }

  void _startNavigation() {
    setState(() => _isNavigating = true);
    _vibrationService.success();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(' Navigation started'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _stopNavigation() {
    setState(() => _isNavigating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(' Navigation stopped'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showRouteDetails() {
    if (_routeInfo == null) return;

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
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BFA5).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions,
                      color: Color(0xFF00BFA5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Route Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_routeInfo!.steps.length} steps',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24),

            // Steps List
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _routeInfo!.steps.length,
                itemBuilder: (context, index) {
                  final step = _routeInfo!.steps[index];
                  final isCurrentStep = index == _currentStepIndex && _isNavigating;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCurrentStep
                          ? const Color(0xFF00BFA5).withValues(alpha: 0.2)
                          : const Color(0xFF2A2F42),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrentStep
                            ? const Color(0xFF00BFA5)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BFA5).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _routeService.getManeuverIcon(step.maneuver),
                            color: const Color(0xFF00BFA5),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.instruction,
                                style: TextStyle(
                                  color: isCurrentStep ? Colors.white : Colors.white70,
                                  fontSize: 14,
                                  fontWeight: isCurrentStep
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_routeService.formatDistance(step.distance)} • ${_routeService.formatDuration(step.duration)}',
                                style: TextStyle(
                                  color: isCurrentStep
                                      ? const Color(0xFF00BFA5)
                                      : Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isCurrentStep)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00BFA5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'NEXT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E27),
        appBar: AppBar(
          title: const Text('Route Navigation'),
          backgroundColor: Colors.transparent,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF00BFA5)),
              SizedBox(height: 16),
              Text(
                'Calculating route...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    if (_routeInfo == null || _currentPosition == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E27),
        appBar: AppBar(
          title: const Text('Route Navigation'),
          backgroundColor: Colors.transparent,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to calculate route',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadRoute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final eta = _routeService.calculateETA(_routeInfo!.totalDuration);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: Text(
          _isNavigating ? 'Navigating...' : 'Route Preview',
          style: TextStyle(
            color: _isNavigating ? const Color(0xFF00BFA5) : Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _showRouteDetails,
            icon: const Icon(Icons.list),
            tooltip: 'Route Steps',
          ),
          IconButton(
            onPressed: _loadRoute,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recalculate',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              zoom: 14,
            ),
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            onMapCreated: (controller) {
              _mapController = controller;

              // Fit bounds to show entire route
              if (_routeInfo != null) {
                final bounds = _calculateBounds(_routeInfo!.polylinePoints);
                controller.animateCamera(
                  CameraUpdate.newLatLngBounds(bounds, 50),
                );
              }
            },
          ),

          // Route Info Card (Top)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2740),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.timer,
                          _routeInfo!.formattedDuration,
                          'Duration',
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.straighten,
                          _routeInfo!.formattedDistance,
                          'Distance',
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.access_time,
                          _routeService.formatETA(eta),
                          'ETA',
                        ),
                      ),
                    ],
                  ),
                  if (_routeInfo!.hasTraffic) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.traffic,
                          color: _routeService.getTrafficColor(_routeInfo!.trafficLevel),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_routeInfo!.trafficLevel.toUpperCase()} traffic',
                          style: TextStyle(
                            color: _routeService.getTrafficColor(_routeInfo!.trafficLevel),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Current Step Card (Bottom - when navigating)
          if (_isNavigating && _currentStepIndex < _routeInfo!.steps.length)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00BFA5), Color(0xFF1DE9B6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00BFA5).withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _routeService.getManeuverIcon(
                          _routeInfo!.steps[_currentStepIndex].maneuver),
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _routeInfo!.steps[_currentStepIndex].instruction,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'In ${_routeService.formatDistance(_routeInfo!.steps[_currentStepIndex].distance)}',
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
              ),
            ),

          // Navigation Control Button
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _isNavigating ? _stopNavigation : _startNavigation,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isNavigating ? Colors.red : const Color(0xFF00BFA5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isNavigating ? Icons.stop : Icons.navigation,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isNavigating ? 'Stop Navigation' : 'Start Navigation',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00BFA5), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}