import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../services/community_safety_service.dart';
import '../services/enhanced_location_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';
import '../providers/auth_provider.dart';

class BroadcastAlertScreen extends StatefulWidget {
  const BroadcastAlertScreen({super.key});

  @override
  State<BroadcastAlertScreen> createState() => _BroadcastAlertScreenState();
}

class _BroadcastAlertScreenState extends State<BroadcastAlertScreen> {
  final CommunitySafetyService _communityService = CommunitySafetyService();
  final EnhancedLocationService _locationService = EnhancedLocationService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();

  final _descriptionController = TextEditingController();

  String _selectedAlertType = 'Emergency';
  String _selectedSeverity = 'High';
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoading = false;
  bool _hasLocation = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      _currentPosition = await _locationService.getCurrentLocation();

      if (_currentPosition != null) {
        _currentAddress = await _locationService.getAddressFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );

        if (mounted) {
          setState(() {
            _hasLocation = true;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _hasLocation = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Get location error: $e');
      if (mounted) {
        setState(() {
          _hasLocation = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _broadcastAlert() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please enter a description'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Location required to broadcast alert'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    final userName = authProvider.user?.displayName ?? 'Anonymous';

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please sign in to broadcast alerts'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await _vibrationService.light();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Row(
          children: [
            Icon(Icons.campaign, color: Colors.orange),
            SizedBox(width: 12),
            Text(
              'Broadcast Alert?',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your alert will be visible to nearby users in the community.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Type: $_selectedAlertType',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Severity: $_selectedSeverity',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Location: ${_currentAddress ?? 'Unknown'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Broadcast'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _vibrationService.warning();
      await _soundService.playWarning();

      final alertId = await _communityService.broadcastAlert(
        userId: userId,
        userName: userName,
        alertType: _selectedAlertType,
        severity: _selectedSeverity,
        description: _descriptionController.text.trim(),
        position: _currentPosition!,
        address: _currentAddress,
      );

      if (alertId != null && mounted) {
        await _vibrationService.success();
        await _soundService.playSuccess();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Alert broadcast to community!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } else if (mounted) {
        throw Exception('Failed to broadcast alert');
      }
    } catch (e) {
      if (mounted) {
        await _vibrationService.error();
        await _soundService.playError();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Broadcast Alert'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading && !_hasLocation
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF00BFA5)),
            SizedBox(height: 16),
            Text(
              'Getting your location...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
// Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withValues(alpha: 0.2),
                    Colors.deepOrange.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.campaign,
                      color: Colors.orange,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Community Alert',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Notify nearby users about emergencies',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

// Alert Type
            const Text(
              'ALERT TYPE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00BFA5),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _selectedAlertType,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedAlertType = value);
                }
              },
              dropdownColor: const Color(0xFF1E2740),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E2740),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  CommunitySafetyService.getAlertIcon(_selectedAlertType),
                  color: const Color(0xFF00BFA5),
                ),
              ),
              items: CommunitySafetyService.alertTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

// Severity
            const Text(
              'SEVERITY LEVEL',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00BFA5),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: CommunitySafetyService.severityLevels.map((severity) {
                final isSelected = _selectedSeverity == severity;
                final color = CommunitySafetyService.getSeverityColor(severity);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(
                        severity,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedSeverity = severity);
                        }
                      },
                      selectedColor: color,
                      backgroundColor: const Color(0xFF1E2740),
                      side: BorderSide(color: color),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

// Description
            const Text(
              'DESCRIPTION',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00BFA5),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descriptionController,
              maxLines: 5,
              maxLength: 500,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Describe what\'s happening...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1E2740),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

// Location info
            if (_hasLocation && _currentAddress != null) ...[
              const Text(
                'YOUR LOCATION',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00BFA5),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2740),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF00BFA5),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
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

              const SizedBox(height: 32),
            ],

// Broadcast button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _broadcastAlert,
                icon: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.campaign, size: 24),
                label: Text(
                  _isLoading ? 'Broadcasting...' : 'Broadcast Alert',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                ),
              ),
            ),

            const SizedBox(height: 24),

// Info
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
                    '• Your alert will be visible to nearby users\n'
                        '• Your name and location will be shared\n'
                        '• Community members can offer help\n'
                        '• Alert stays active until resolved\n'
                        '• Only broadcast real emergencies',
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
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}