import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/emergency_service.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final EmergencyService _emergencyService = EmergencyService();
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isLocationSharingActive = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hasPermission = await _emergencyService.requestLocationPermissions();
      if (!hasPermission) {
        setState(() {
          _error = 'Location permissions denied. Please enable location access in settings.';
          _isLoading = false;
        });
        return;
      }

      final isServiceEnabled = await _emergencyService.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        setState(() {
          _error = 'Location services are disabled. Please enable location services.';
          _isLoading = false;
        });
        return;
      }

      final position = await _emergencyService.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoading = false;
        if (position == null) {
          _error = 'Unable to get current location. Please try again.';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleLocationSharing() {
    setState(() {
      _isLocationSharingActive = !_isLocationSharingActive;
    });

    if (_isLocationSharingActive) {
      _startLocationSharing();
    } else {
      _stopLocationSharing();
    }
  }

  void _startLocationSharing() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location sharing started'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _stopLocationSharing() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location sharing stopped'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _openInMaps() async {
    if (_currentPosition == null) return;

    final url = _emergencyService.getGoogleMapsUrl(_currentPosition!);
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open maps application'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareLocation() {
    if (_currentPosition == null) return;

    final locationText = _emergencyService.formatLocationForSharing(_currentPosition!);
    final mapsUrl = _emergencyService.getGoogleMapsUrl(_currentPosition!);
    
    // In a real app, this would use the share plugin
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location: $locationText\nMaps: $mapsUrl'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            // Copy to clipboard functionality would be implemented here
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Sharing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _isLocationSharingActive ? Colors.green[50] : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isLocationSharingActive ? Icons.location_on : Icons.location_off,
                          color: _isLocationSharingActive ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isLocationSharingActive 
                              ? 'Location Sharing Active'
                              : 'Location Sharing Inactive',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLocationSharingActive
                          ? 'Your location is being shared with emergency contacts'
                          : 'Tap the toggle below to start sharing your location',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Location Information
            if (_isLoading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Getting your location...'),
                    ],
                  ),
                ),
              )
            else if (_error != null)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _getCurrentLocation,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_currentPosition != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLocationInfo('Latitude', _currentPosition!.latitude.toStringAsFixed(6)),
                      const SizedBox(height: 8),
                      _buildLocationInfo('Longitude', _currentPosition!.longitude.toStringAsFixed(6)),
                      const SizedBox(height: 8),
                      _buildLocationInfo('Accuracy', '${_currentPosition!.accuracy.toStringAsFixed(1)} meters'),
                      const SizedBox(height: 8),
                      _buildLocationInfo('Timestamp', DateTime.fromMillisecondsSinceEpoch(_currentPosition!.timestamp!.millisecondsSinceEpoch).toString()),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _openInMaps,
                              icon: const Icon(Icons.map),
                              label: const Text('Open in Maps'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _shareLocation,
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const Spacer(),

            // Toggle Button
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Share Location'),
                      subtitle: const Text('Share your live location with emergency contacts'),
                      value: _isLocationSharingActive,
                      onChanged: _currentPosition != null ? (_) => _toggleLocationSharing() : null,
                      activeColor: Colors.green,
                    ),
                    if (_currentPosition == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Location access required to enable sharing',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}