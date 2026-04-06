import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../services/enhanced_location_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';
import '../providers/auth_provider.dart';

class LocationTrackerScreen extends StatefulWidget {
  const LocationTrackerScreen({super.key});

  @override
  State<LocationTrackerScreen> createState() => _LocationTrackerScreenState();
}

class _LocationTrackerScreenState extends State<LocationTrackerScreen> {
  final EnhancedLocationService _locationService = EnhancedLocationService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();

  Position? _currentPosition;
  String? _currentAddress;
  bool _isTracking = false;
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    await _locationService.initialize(
      onLocationUpdate: _handleLocationUpdate,
      onAddressUpdate: _handleAddressUpdate,
    );

    _loadStatistics();
  }

  void _handleLocationUpdate(Position position) {
    if (mounted) {
      setState(() {
        _currentPosition = position;
      });
      _loadStatistics();
    }
  }

  void _handleAddressUpdate(String address) {
    if (mounted) {
      setState(() {
        _currentAddress = address;
      });
    }
  }

  void _loadStatistics() {
    setState(() {
      _statistics = _locationService.getStatistics();
      _isTracking = _statistics['isTracking'] ?? false;
    });
  }

  Future<void> _getCurrentLocation() async {
    await _vibrationService.light();
    await _soundService.playClick();

    setState(() {
      _currentPosition = null;
      _currentAddress = null;
    });

    final position = await _locationService.getCurrentLocation();

    if (position != null && mounted) {
      await _vibrationService.success();
      await _soundService.playSuccess();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Location updated'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      await _vibrationService.error();
      await _soundService.playError();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Failed to get location'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleTracking() async {
    await _vibrationService.light();
    await _soundService.playClick();

    try {
      if (_isTracking) {
        _locationService.stopTracking();
      } else {
        await _locationService.startTracking(intervalSeconds: 30);
      }

      _loadStatistics();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isTracking
                  ? ' Location tracking started'
                  : ' Location tracking stopped',
            ),
            backgroundColor: _isTracking ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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

  Future<void> _saveCurrentLocation() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' No location available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await _vibrationService.light();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _SaveLocationDialog(),
    );

    if (result != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;

      if (userId != null) {
        await _locationService.saveLocation(
          userId: userId,
          position: _currentPosition!,
          label: result['label'],
          notes: result['notes'],
        );

        if (mounted) {
          await _vibrationService.success();
          await _soundService.playSuccess();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(' Location saved'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  void _copyCoordinates() {
    if (_currentPosition == null) return;

    final coords = '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}';
    Clipboard.setData(ClipboardData(text: coords));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(' Coordinates copied'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openInMaps() {
    if (_currentPosition == null) return;

    final url = 'https://www.google.com/maps?q=${_currentPosition!.latitude},${_currentPosition!.longitude}';
    Clipboard.setData(ClipboardData(text: url));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(' Maps URL copied - paste in browser'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Location Tracker'),
        backgroundColor: Colors.transparent,
        actions: [
          if (_isTracking)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'TRACKING',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current Location Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00BFA5).withValues(alpha: 0.2),
                  Colors.blue.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF00BFA5).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00BFA5).withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.my_location,
                    size: 40,
                    color: Color(0xFF00BFA5),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Current Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_currentPosition != null) ...[
                  Text(
                    '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_currentAddress != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFF00BFA5),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentAddress!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else ...[
                  const Text(
                    'No location available',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.gps_fixed, size: 20),
                  label: const Text('Update'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFA5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleTracking,
                  icon: Icon(
                    _isTracking ? Icons.stop : Icons.play_arrow,
                    size: 20,
                  ),
                  label: Text(_isTracking ? 'Stop' : 'Track'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTracking ? Colors.red : Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentPosition != null ? _copyCoordinates : null,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00BFA5),
                    side: const BorderSide(color: Color(0xFF00BFA5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentPosition != null ? _openInMaps : null,
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text('Maps'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _currentPosition != null ? _saveCurrentLocation : null,
              icon: const Icon(Icons.save, size: 20),
              label: const Text('Save Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Statistics
          const Text(
            'TRACKING STATISTICS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00BFA5),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            color: const Color(0xFF1E2740),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatRow(
                    'Distance Traveled',
                    _statistics['totalDistanceKm'] != null
                        ? '${_statistics['totalDistanceKm']} km'
                        : '0.00 km',
                    Icons.straighten,
                  ),
                  const Divider(height: 24, color: Colors.white24),
                  _buildStatRow(
                    'Location Updates',
                    '${_statistics['locationUpdates'] ?? 0}',
                    Icons.update,
                  ),
                  const Divider(height: 24, color: Colors.white24),
                  _buildStatRow(
                    'History Points',
                    '${_statistics['historySize'] ?? 0}',
                    Icons.history,
                  ),
                  const Divider(height: 24, color: Colors.white24),
                  _buildStatRow(
                    'Accuracy',
                    '${_statistics['currentAccuracy'] ?? 'N/A'} m',
                    Icons.my_location,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'How It Works',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '• Update: Get current location once\n'
                      '• Track: Continuous location monitoring\n'
                      '• Save: Store important locations\n'
                      '• Works in background when tracking\n'
                      '• Battery optimized updates',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00BFA5), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }
}

class _SaveLocationDialog extends StatefulWidget {
  @override
  State<_SaveLocationDialog> createState() => _SaveLocationDialogState();
}

class _SaveLocationDialogState extends State<_SaveLocationDialog> {
  final _labelController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E2740),
      title: const Text(
        'Save Location',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Label (optional)',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'e.g., Home, Work, Hospital',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'Additional information',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'label': _labelController.text.trim(),
              'notes': _notesController.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00BFA5),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}