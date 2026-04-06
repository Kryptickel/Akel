import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/auth_provider.dart';
import '../services/geofence_service.dart';
import '../services/vibration_service.dart';

class GeofenceCreateScreen extends StatefulWidget {
  final Position? currentPosition;

  const GeofenceCreateScreen({
    super.key,
    this.currentPosition,
  });

  @override
  State<GeofenceCreateScreen> createState() => _GeofenceCreateScreenState();
}

class _GeofenceCreateScreenState extends State<GeofenceCreateScreen> {
  final GeofenceService _geofenceService = GeofenceService();
  final VibrationService _vibrationService = VibrationService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  ZoneType _selectedType = ZoneType.safe;
  double _radius = 100; // meters
  bool _notifyOnEntry = true;
  bool _notifyOnExit = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentPosition != null) {
      _latController.text = widget.currentPosition!.latitude.toStringAsFixed(6);
      _lngController.text = widget.currentPosition!.longitude.toStringAsFixed(6);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    await _vibrationService.light();

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Location updated'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Location error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createZone() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please enter a zone name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_latController.text.trim().isEmpty || _lngController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please enter coordinates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Invalid coordinates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Coordinates out of range'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        await _geofenceService.createZone(
          userId: userId,
          name: _nameController.text.trim(),
          latitude: lat,
          longitude: lng,
          radiusMeters: _radius,
          type: _selectedType,
          notifyOnEntry: _notifyOnEntry,
          notifyOnExit: _notifyOnExit,
        );

        await _vibrationService.success();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Geofence zone created'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() => _isCreating = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Geofence Zone'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
// Zone Name
            const Text(
              'Zone Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g., Home, Office, School',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.label),
              ),
            ),

            const SizedBox(height: 24),

// Zone Type
            const Text(
              'Zone Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ZoneType.values.map((type) {
                final isSelected = _selectedType == type;
                final color = _hexToColor(GeofenceService.getTypeColor(type));

                return FilterChip(
                  selected: isSelected,
                  onSelected: (_) {
                    _vibrationService.light();
                    setState(() => _selectedType = type);
                  },
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(GeofenceService.getTypeIcon(type)),
                      const SizedBox(width: 8),
                      Text(GeofenceService.getTypeLabel(type)),
                    ],
                  ),
                  backgroundColor: color.withValues(alpha: 0.1),
                  selectedColor: color.withValues(alpha: 0.3),
                  checkmarkColor: color,
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

// Location
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.south),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lngController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.east),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _useCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Use Current Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 24),

// Radius
            const Text(
              'Radius',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.radio_button_unchecked, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            _geofenceService.formatRadius(_radius),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _radius >= 1000 ? 'Large' : _radius >= 300 ? 'Medium' : 'Small',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _radius,
                    min: 50,
                    max: 5000,
                    divisions: 99,
                    label: _geofenceService.formatRadius(_radius),
                    onChanged: (value) {
                      setState(() => _radius = value);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '50m',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '5km',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

// Notifications
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _notifyOnEntry,
              onChanged: (value) {
                _vibrationService.light();
                setState(() => _notifyOnEntry = value);
              },
              title: const Text('Notify on Entry'),
              subtitle: const Text('Alert when entering this zone'),
              secondary: const Icon(Icons.login, color: Colors.green),
            ),
            SwitchListTile(
              value: _notifyOnExit,
              onChanged: (value) {
                _vibrationService.light();
                setState(() => _notifyOnExit = value);
              },
              title: const Text('Notify on Exit'),
              subtitle: const Text('Alert when leaving this zone'),
              secondary: const Icon(Icons.logout, color: Colors.orange),
            ),

            const SizedBox(height: 24),

// Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createZone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCreating
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Create Geofence Zone',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

// Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You will receive notifications when entering or leaving this zone based on your settings.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
  }
}