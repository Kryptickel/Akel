import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import '../services/emergency_service.dart';
import '../widgets/panic_button.dart';
import '../widgets/quick_action_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final UserService _userService = UserService();
  final EmergencyService _emergencyService = EmergencyService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isLocationSharingActive = false;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserProfile();
    _setupVolumeButtonListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle for background emergency features
    if (state == AppLifecycleState.paused) {
      // App is in background, maintain emergency services if active
    } else if (state == AppLifecycleState.resumed) {
      // App is resumed, refresh status
      _refreshStatus();
    }
  }

  void _setupVolumeButtonListener() {
    // This would be implemented with a platform channel in a real app
    // For now, we'll use gesture detection on the panic button
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _userService.getUserProfile();
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshStatus() async {
    // Refresh emergency status and location sharing status
    setState(() {
      // Update UI based on current emergency status
    });
  }

  Future<void> _triggerPanicMode({bool silent = false}) async {
    try {
      // Show confirmation dialog for non-silent activation
      if (!silent) {
        final confirmed = await _showPanicConfirmation();
        if (!confirmed) return;
      }

      // Haptic feedback
      HapticFeedback.heavyImpact();

      // Show emergency activation overlay
      if (mounted) {
        _showEmergencyActivationOverlay();
      }

      // Trigger emergency services
      await _emergencyService.triggerEmergency();

      // Start location sharing
      _startLocationSharing();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to activate emergency mode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showPanicConfirmation() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Emergency Alert'),
            ],
          ),
          content: const Text(
            'This will immediately alert your emergency contacts and share your location. Continue?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('ACTIVATE EMERGENCY'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _showEmergencyActivationOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
                SizedBox(height: 16),
                Text(
                  'EMERGENCY ACTIVATED',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Alerting emergency contacts...',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Auto-dismiss after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _startLocationSharing() {
    setState(() {
      _isLocationSharingActive = true;
    });

    _locationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // Update location in background
      _emergencyService.updateLocation();
    });
  }

  void _stopLocationSharing() {
    setState(() {
      _isLocationSharingActive = false;
    });
    _locationTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${_userProfile?.name ?? 'User'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _isLocationSharingActive 
                            ? Icons.location_on 
                            : Icons.location_off,
                        color: _isLocationSharingActive 
                            ? Colors.green 
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isLocationSharingActive 
                              ? 'Location sharing active'
                              : 'Location sharing inactive',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      if (_isLocationSharingActive)
                        TextButton(
                          onPressed: _stopLocationSharing,
                          child: const Text('Stop'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Main Panic Button
              Expanded(
                flex: 2,
                child: Center(
                  child: PanicButton(
                    onPressed: () => _triggerPanicMode(silent: false),
                    onLongPress: () => _triggerPanicMode(silent: true),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Quick Actions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          QuickActionCard(
                            icon: Icons.location_on,
                            title: 'Location',
                            subtitle: 'Share location',
                            onTap: () => Navigator.pushNamed(context, '/location'),
                          ),
                          QuickActionCard(
                            icon: Icons.message,
                            title: 'Offline Mode',
                            subtitle: 'Send SMS',
                            onTap: () => Navigator.pushNamed(context, '/offline'),
                          ),
                          QuickActionCard(
                            icon: Icons.settings,
                            title: 'Settings',
                            subtitle: 'Configure alerts',
                            onTap: () => Navigator.pushNamed(context, '/settings'),
                          ),
                          QuickActionCard(
                            icon: Icons.contact_emergency,
                            title: 'Contacts',
                            subtitle: 'Emergency contacts',
                            onTap: () => Navigator.pushNamed(context, '/settings'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _triggerPanicMode(silent: true),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.volume_off),
        label: const Text('Silent Alert'),
      ),
    );
  }
}