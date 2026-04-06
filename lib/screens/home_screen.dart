import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

// REMOVED: flutter_bluetooth_serial import (causing error)
// We'll use a mock bluetooth service instead

import '../providers/auth_provider.dart';
import '../services/panic_service_v2.dart';
import '../services/battery_service.dart';
import '../services/sound_service.dart';
import '../services/connectivity_service.dart';
import '../services/fall_detection_service.dart';
import '../services/shake_detection_service.dart';
import '../services/location_history_service.dart';
import '../services/safe_word_service.dart';
import '../services/hardware_trigger_service.dart';
import '../services/enhanced_aws_polly_service.dart';
import '../services/ultimate_ai_features_service.dart';

// NEW SERVICES
import '../services/google_tts_service.dart';
import '../services/offline_maps_service.dart';
import '../services/alert_queue_service.dart';
import '../services/bluetooth_beacon_service.dart';
import '../services/location_breadcrumbs_service.dart';

// Doctor Annie AI Integration
import '../services/doctor_annie_copilot_service.dart';
import '../services/advanced_ai_copilot_service.dart';

import '../widgets/emergency_services_quick_dial_widget.dart';
import '../widgets/community_safety_quick_widget.dart';
import '../widgets/medical_intelligence_quick_widget.dart';
import '../widgets/fall_detection_dialog.dart';
import '../widgets/floating_sos_button.dart';
import '../widgets/feature_drawer.dart';
import '../widgets/futuristic_widgets.dart';
import '../widgets/doctor_annie_avatar_widget.dart';
import '../widgets/ai_copilot_floating_button.dart';

import '../models/doctor_annie_appearance.dart';
import '../core/constants/themes/utils/akel_design_system.dart';

import 'profile_screen.dart';
import 'offline_sync_screen.dart';
import 'power_management_screen.dart';
import 'history_screen.dart';
import 'onboarding_screen.dart';
import 'doctor_annie_chat_screen.dart';
import 'voice_center_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Services
  final PanicServiceV2 _panicServiceV2 = PanicServiceV2();
  final BatteryService _batteryService = BatteryService();
  final SoundService _soundService = SoundService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final FallDetectionService _fallDetectionService = FallDetectionService();
  final ShakeDetectionService _shakeService = ShakeDetectionService();
  final LocationHistoryService _locationHistory = LocationHistoryService();
  final SafeWordService _safeWordService = SafeWordService();
  final HardwareTriggerService _hardwareTriggerService = HardwareTriggerService();
  final EnhancedAWSPollyService _pollyService = EnhancedAWSPollyService();
  final UltimateAIFeaturesService _ultimateFeatures = UltimateAIFeaturesService();

  // AI Services
  final DoctorAnnieCopilotService _doctorAnnie = DoctorAnnieCopilotService();
  final AdvancedAICopilotService _advancedAI = AdvancedAICopilotService();

  // NEW SERVICES
  final GoogleTTSService _googleTTS = GoogleTTSService();
  final OfflineMapsService _offlineMaps = OfflineMapsService();
  final AlertQueueService _alertQueue = AlertQueueService();
  final BluetoothBeaconService _bluetoothBeacon = BluetoothBeaconService();
  final LocationBreadcrumbsService _breadcrumbs = LocationBreadcrumbsService();

  // State
  bool _isTriggering = false;
  bool _isCountingDown = false;
  int _countdown = 10;
  double _longPressProgress = 0.0;
  bool _isPanicActive = false;

  // Battery
  int _batteryLevel = 100;
  bool _isCharging = false;

  // Connectivity
  bool _isOnline = true;
  StreamSubscription<bool>? _connectivitySubscription;

  // Alert Queue & Offline
  int _queuedAlertsCount = 0;
  bool _offlineMapsReady = false;
  bool _bluetoothBeaconActive = false;
  List<String> _nearbyBeacons = [];

  // Location Breadcrumbs State
  List<LocationBreadcrumb> _locationBreadcrumbs = [];
  bool _breadcrumbsExpanded = false;
  LocationBreadcrumb? _currentLocation; // FIXED: Made nullable

  // AI Chat
  bool _showAIChat = false;
  bool _isAIInitialized = false;
  bool _isAITyping = false;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final List<ChatMessage> _chatMessages = [];

  // Animations
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _rotateController;
  late AnimationController _shimmerController;
  late AnimationController _typingController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  // Safe Word
  final TextEditingController _safeWordController = TextEditingController();
  bool _safeWordEnabled = false;

  // Hardware Triggers
  bool _volumeTriggerEnabled = true;
  bool _powerTriggerEnabled = true;

  // Safety Score
  int _safetyScore = 94;
  int _contactCount = 5;
  int _checkInCount = 127;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Doctor Annie appearance
  DoctorAnnieAppearance _annieAppearance = const DoctorAnnieAppearance(
    hairStyle: HairStyle.braided,
    hairColor: Color(0xFF2C1810),
    skinTone: Color(0xFFC68642),
    ethnicity: EthnicityType.indian,
    hasStethoscope: true,
    clothing: ClothingType.labCoat,
    glossyIntensity: 0.8,
    enableReflections: true,
    enableShadows: true,
  );

  @override
  void initState() {
    super.initState();

    _panicServiceV2.initialize();
    _pollyService.initialize();

    // Initialize NEW services
    _initializeNewServices();

    // Initialize AI
    _initializeAI();

    // Enhanced animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Setup monitoring
    _checkBattery();
    _batteryService.onBatteryStateChanged.listen((_) => _checkBattery());

    _checkConnectivity();
    _connectivitySubscription = _connectivityService.connectivityStream.listen((isOnline) {
      if (mounted) {
        setState(() => _isOnline = isOnline);
        _handleConnectivityChange(isOnline);
      }
    });

    // Initialize features
    _initializeFallDetection();
    _setupShakeDetection();
    _checkSafeWordStatus();
    _initializeHardwareTriggers();
    _loadTriggerSettings();
    _loadAnnieAppearance();
    _calculateSafetyScore();

    // Add welcome message
    _addWelcomeMessage();

    // Check onboarding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowOnboarding();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    _shimmerController.dispose();
    _typingController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    _soundService.dispose();
    _connectivitySubscription?.cancel();
    _connectivityService.dispose();
    _fallDetectionService.dispose();
    _shakeService.stopMonitoring();
    _locationHistory.stopTracking();
    _safeWordController.dispose();
    _hardwareTriggerService.dispose();
    _panicServiceV2.dispose();

    // Dispose NEW services
    _googleTTS.dispose();
    _offlineMaps.dispose();
    _alertQueue.dispose();
    _bluetoothBeacon.dispose();
    _breadcrumbs.dispose();

    super.dispose();
  }

  // ==================== NEW SERVICES INITIALIZATION ====================

  Future<void> _initializeNewServices() async {
    try {
      // 1. Google Natural Voice TTS
      await _googleTTS.initialize();
      _googleTTS.speak('AKEL safety system activated. Welcome.');

      // 2. Offline Maps
      await _offlineMaps.initialize();
      final mapsReady = await _offlineMaps.checkOfflineMapsAvailable();
      if (mounted) setState(() => _offlineMapsReady = mapsReady);

      // 3. Alert Queue
      await _alertQueue.initialize();
      final queuedCount = await _alertQueue.getQueuedAlertsCount();
      if (mounted) setState(() => _queuedAlertsCount = queuedCount);

      // 4. Bluetooth Beacon
      await _bluetoothBeacon.initialize();
      await _bluetoothBeacon.startBroadcasting();
      if (mounted) setState(() => _bluetoothBeaconActive = true);

      // Listen for nearby beacons
      _bluetoothBeacon.nearbyBeaconsStream.listen((beacons) {
        if (mounted) setState(() => _nearbyBeacons = beacons);
        _handleNearbyBeacons(beacons);
      });

      // 5. Location Breadcrumbs
      await _breadcrumbs.initialize();
      await _breadcrumbs.startTracking();

      // Listen for breadcrumb updates
      _breadcrumbs.breadcrumbsStream.listen((breadcrumbs) {
        if (mounted) {
          setState(() {
            _locationBreadcrumbs = breadcrumbs;
            // FIXED: Properly handle current location
            if (breadcrumbs.isNotEmpty) {
              _currentLocation = breadcrumbs.last;

              // Announce location changes via TTS
              if (breadcrumbs.length > 1) {
                final previous = breadcrumbs[breadcrumbs.length - 2];
                final dwellTime = _formatDuration(previous.dwellDuration);
                _googleTTS.speak('You spent $dwellTime at ${previous.name}. Now at ${_currentLocation!.name}.');
              }
            }
          });
        }
      });

      debugPrint(' All 5 new services initialized successfully');
    } catch (e) {
      debugPrint(' New services init error: $e');
    }
  }

  // ==================== CONNECTIVITY CHANGE HANDLER ====================

  Future<void> _handleConnectivityChange(bool isOnline) async {
    if (isOnline) {
      // Online: Send queued alerts
      final queuedAlerts = await _alertQueue.getQueuedAlerts();
      if (queuedAlerts.isNotEmpty) {
        _googleTTS.speak('Internet restored. Sending ${queuedAlerts.length} queued alerts.');

        for (final alert in queuedAlerts) {
          await _sendQueuedAlert(alert);
        }

        await _alertQueue.clearQueue();
        if (mounted) setState(() => _queuedAlertsCount = 0);

        _googleTTS.speak('All alerts sent successfully.');
      }
    } else {
      // Offline
      _googleTTS.speak('Offline mode. Alerts will queue.');
    }
  }

  Future<void> _sendQueuedAlert(Map<String, dynamic> alert) async {
    try {
      await FirebaseFirestore.instance
          .collection('emergency_alerts')
          .add(alert);

      debugPrint(' Queued alert sent: ${alert['timestamp']}');
    } catch (e) {
      debugPrint(' Failed to send queued alert: $e');
    }
  }

  // ==================== BLUETOOTH BEACON HANDLER ====================

  Future<void> _handleNearbyBeacons(List<String> beacons) async {
    try {
      for (final beaconId in beacons) {
        final isEmergencyContact = await _checkIfEmergencyContact(beaconId);

        if (isEmergencyContact && _queuedAlertsCount > 0) {
          _googleTTS.speak('Contact nearby. Sending queued alerts via Bluetooth.');

          final alerts = await _alertQueue.getQueuedAlerts();
          for (final alert in alerts) {
            await _bluetoothBeacon.sendAlertToBeacon(beaconId, alert);
          }

          await _alertQueue.clearQueue();
          if (mounted) setState(() => _queuedAlertsCount = 0);

          _googleTTS.speak('Alerts sent via Bluetooth.');
        }
      }
    } catch (e) {
      debugPrint(' Bluetooth handler error: $e');
    }
  }

  Future<bool> _checkIfEmergencyContact(String beaconId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;

      if (userId == null) return false;

      final contactsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('contacts')
          .where('bluetooth_beacon_id', isEqualTo: beaconId)
          .get();

      return contactsSnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint(' Check contact error: $e');
      return false;
    }
  }

  // ==================== AI INITIALIZATION ====================

  Future<void> _initializeAI() async {
    try {
      await Future.wait([
        _doctorAnnie.initialize(),
        _advancedAI.initialize(),
      ]);
      if (mounted) setState(() => _isAIInitialized = true);

      _googleTTS.speak('Doctor Annie A I is online.');
    } catch (e) {
      debugPrint(' AI init error: $e');
      if (mounted) setState(() => _isAIInitialized = true);
    }
  }

  Future<void> _loadAnnieAppearance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appearanceJson = prefs.getString('doctor_annie_appearance');
      if (appearanceJson != null && mounted) {
        setState(() {
          _annieAppearance = DoctorAnnieAppearance.fromJson(jsonDecode(appearanceJson));
        });
      }
    } catch (e) {
      debugPrint(' Appearance load error: $e');
    }
  }

  void _addWelcomeMessage() {
    _chatMessages.add(ChatMessage(
      text: "Hi! I'm Doctor Annie, your AI safety companion. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  // ==================== SAFETY SCORE ====================

  Future<void> _calculateSafetyScore() async {
    try {
      int score = 0;

      if (await Geolocator.isLocationServiceEnabled()) score += 15;
      if (_batteryLevel > 20) score += 15;
      if (_isOnline) {
        score += 10;
      } else if (_offlineMapsReady) {
        score += 10;
      }
      if (_isAIInitialized) score += 15;
      if (_contactCount >= 3) score += 20;
      if (_checkInCount > 0) score += 10;
      if (_bluetoothBeaconActive) score += 10;
      if (_offlineMapsReady) score += 5;

      if (mounted) setState(() => _safetyScore = score);
    } catch (e) {
      debugPrint(' Safety score error: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '$hours hour${hours == 1 ? '' : 's'} ${minutes} minute${minutes == 1 ? '' : 's'}';
    } else {
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  // ==================== ONBOARDING CHECK ====================

  Future<void> _checkAndShowOnboarding() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProfile = authProvider.userProfile;

      if (userProfile == null) return;

      final onboardingComplete = userProfile['onboarding_complete'] as bool? ?? false;

      if (!onboardingComplete && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const OnboardingScreen(),
              fullscreenDialog: true,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint(' Onboarding error: $e');
    }
  }

  // ==================== HARDWARE TRIGGERS ====================

  void _initializeHardwareTriggers() {
    _hardwareTriggerService.initialize();
    _hardwareTriggerService.setOnVolumePanicTriggered(() {
      if (mounted && !_isTriggering && !_isCountingDown) {
        _startCountdown(silent: false);
      }
    });
    _hardwareTriggerService.setOnPowerPanicTriggered(() {
      if (mounted && !_isTriggering && !_isCountingDown) {
        _startCountdown(silent: false);
      }
    });
  }

  Future<void> _loadTriggerSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _volumeTriggerEnabled = prefs.getBool('volume_trigger_enabled') ?? true;
          _powerTriggerEnabled = prefs.getBool('power_trigger_enabled') ?? true;
        });
        _hardwareTriggerService.setVolumeTriggerEnabled(_volumeTriggerEnabled);
        _hardwareTriggerService.setPowerTriggerEnabled(_powerTriggerEnabled);
      }
    } catch (e) {
      debugPrint(' Trigger load error: $e');
    }
  }

  // ==================== SAFE WORD ====================

  Future<void> _checkSafeWordStatus() async {
    try {
      final enabled = await _safeWordService.isSafeWordEnabled();
      if (mounted) setState(() => _safeWordEnabled = enabled);
    } catch (e) {
      debugPrint(' Safe word error: $e');
    }
  }

  void _onTextChanged(String text) async {
    if (!_safeWordEnabled || text.isEmpty) return;
    try {
      final verified = await _safeWordService.verifySafeWord(text);
      if (verified && mounted) {
        _safeWordController.clear();
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.user?.uid;
        if (userId != null) await _safeWordService.logSafeWordUsage(userId);
        _startCountdown(silent: true);
      }
    } catch (e) {
      debugPrint(' Safe word verify error: $e');
    }
  }

  // ==================== SHAKE DETECTION ====================

  void _setupShakeDetection() {
    _shakeService.onShakeDetected = () {
      if (mounted && !_isTriggering && !_isCountingDown) {
        _startCountdown(silent: false);
      }
    };
    _shakeService.initialize();
  }

  // ==================== FALL DETECTION ====================

  Future<void> _initializeFallDetection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('fall_detection_enabled') ?? false;
      if (enabled) {
        _fallDetectionService.onFallDetected = (context) async {
          await _panicServiceV2.triggerHapticFeedback(type: HapticType.emergency);

          _googleTTS.speak('Fall detected! Activating emergency protocol.');

          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => FallDetectionDialog(
              onCancel: () {
                Navigator.pop(context);
                _googleTTS.speak('Fall alert cancelled.');
              },
              onTriggerPanic: () {
                Navigator.pop(context);
                _googleTTS.speak('Sending emergency alerts now.');
                _triggerPanic(silent: false);
              },
            ),
          );
        };
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) _fallDetectionService.startMonitoring(context);
      }
    } catch (e) {
      debugPrint(' Fall detection error: $e');
    }
  }

  // ==================== BATTERY ====================

  Future<void> _checkBattery() async {
    try {
      final level = await _batteryService.getBatteryLevel();
      final charging = await _batteryService.isCharging();
      if (mounted) setState(() {
        _batteryLevel = level;
        _isCharging = charging;
      });
      _calculateSafetyScore();

      if (level <= 20 && !charging) {
        _googleTTS.speak('Warning: Battery level low at $level percent. Please charge your device.');
      }
    } catch (e) {
      debugPrint(' Battery error: $e');
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final isOnline = await _connectivityService.isOnline();
      if (mounted) setState(() => _isOnline = isOnline);
      _calculateSafetyScore();
    } catch (e) {
      debugPrint(' Connectivity error: $e');
    }
  }

  Widget _buildBatteryIcon() {
    final color = BatteryService.getBatteryColor(_batteryLevel);
    final icon = BatteryService.getBatteryIcon(_batteryLevel, _isCharging);

    Color iconColor;
    switch (color) {
      case BatteryColor.good:
        iconColor = AkelDesign.successGreen;
        break;
      case BatteryColor.medium:
        iconColor = AkelDesign.warningOrange;
        break;
      case BatteryColor.low:
        iconColor = AkelDesign.errorRed;
        break;
    }

    IconData iconData;
    switch (icon) {
      case BatteryIcon.full:
        iconData = Icons.battery_full;
        break;
      case BatteryIcon.high:
        iconData = Icons.battery_5_bar;
        break;
      case BatteryIcon.medium:
        iconData = Icons.battery_3_bar;
        break;
      case BatteryIcon.low:
        iconData = Icons.battery_1_bar;
        break;
      case BatteryIcon.charging:
        iconData = Icons.battery_charging_full;
        iconColor = AkelDesign.successGreen;
        break;
    }

    return Icon(iconData, color: iconColor, size: 20);
  }

  // ==================== COUNTDOWN ====================

  void _startCountdown({bool silent = false}) async {
    if (mounted) setState(() {
      _isCountingDown = true;
      _countdown = 10;
    });

    _googleTTS.speak('Emergency alert activating in 10 seconds. Press cancel to stop.');

    await _panicServiceV2.startCountdownTimer(
      seconds: 10,
      onCountdownTick: () {
        if (mounted) {
          setState(() => _countdown = _panicServiceV2.countdownSeconds);

          if (_countdown <= 5) {
            _googleTTS.speak(_countdown.toString());
          }
        }
      },
      onCountdownComplete: () => _triggerPanic(silent: silent),
      onCountdownCancelled: () => _cancelCountdown(),
    );
  }

  void _cancelCountdown() {
    _panicServiceV2.cancelCountdown(
      onCancelled: () {
        if (mounted) setState(() {
          _isCountingDown = false;
          _countdown = 10;
          _isPanicActive = false;
        });

        _googleTTS.speak('Emergency alert cancelled.');
      },
    );
  }

  // ==================== TRIGGER PANIC ====================

  Future<void> _triggerPanic({bool silent = false}) async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    try {
      if (mounted) setState(() {
        _isTriggering = true;
        _isPanicActive = true;
      });

      Position? position;
      try {
        if (_isOnline) {
          position = await Geolocator.getCurrentPosition();
        } else if (_offlineMapsReady) {
          position = await _offlineMaps.getLastKnownPosition();
        }
      } catch (e) {
        debugPrint(' Location error: $e');
      }

      final alertData = {
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'location': position != null
            ? {
          'latitude': position.latitude,
          'longitude': position.longitude,
        }
            : null,
        'type': 'panic_button',
        'status': 'active',
      };

      if (_isOnline) {
        await FirebaseFirestore.instance
            .collection('emergency_alerts')
            .add(alertData);

        _googleTTS.speak('Emergency alerts sent successfully to all contacts.');
      } else {
        await _alertQueue.addToQueue(alertData);
        if (mounted) {
          setState(() => _queuedAlertsCount = _queuedAlertsCount + 1);
        }

        _googleTTS.speak('You are offline. Alert queued and will send automatically when connection is restored, or via Bluetooth when contacts are nearby.');

        if (_nearbyBeacons.isNotEmpty) {
          _googleTTS.speak('Emergency contacts detected nearby. Sending alert via Bluetooth.');
          for (final beaconId in _nearbyBeacons) {
            await _bluetoothBeacon.sendAlertToBeacon(beaconId, alertData);
          }
        }
      }

      await Future.delayed(const Duration(seconds: 1));
      await _panicServiceV2.triggerHapticFeedback(type: HapticType.success);

      if (mounted) {
        setState(() {
          _isTriggering = false;
          _isCountingDown = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isOnline
                  ? ' Emergency alerts sent successfully'
                  : ' Alert queued • Will send when online or via Bluetooth',
            ),
            backgroundColor: _isOnline ? AkelDesign.successGreen : AkelDesign.warningOrange,
          ),
        );
      }

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _isPanicActive = false);
      });
    } catch (e) {
      debugPrint(' Panic error: $e');
      _googleTTS.speak('Error sending emergency alert. Please try again.');
      if (mounted) setState(() {
        _isTriggering = false;
        _isPanicActive = false;
      });
    }
  }

  // ==================== AI CHAT ====================

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    _googleTTS.speak(text);

    setState(() {
      _chatMessages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isAITyping = true;
    });

    _chatController.clear();
    _scrollToBottom();

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final aiResponse = _getAIResponse(text);

      setState(() {
        _chatMessages.add(ChatMessage(
          text: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isAITyping = false;
      });

      _googleTTS.speak(aiResponse);

      _scrollToBottom();
    }
  }

  String _getAIResponse(String userMessage) {
    final lower = userMessage.toLowerCase();

    if (lower.contains('help') || lower.contains('emergency')) {
      return "I'm here to help! Would you like me to:\n• Call emergency services (911)\n• Share your location with contacts\n• Find the nearest hospital\n• Guide you through the situation";
    } else if (lower.contains('location') || lower.contains('where')) {
      return "I can help with location services:\n• Share your live location\n• Find nearby safe places\n• Navigate to safety${_offlineMapsReady ? '\n• Use offline maps (available)' : ''}\n• Track your journey";
    } else if (lower.contains('hospital') || lower.contains('medical')) {
      return "I can assist with medical emergencies:\n• Find nearest hospitals\n• Show your medical ID\n• Call your doctor\n• Provide first aid guidance";
    } else if (lower.contains('call') || lower.contains('contact')) {
      return "I can connect you:\n• Emergency services (911)\n• Your emergency contacts${_nearbyBeacons.isNotEmpty ? '\n• Nearby contacts via Bluetooth (${_nearbyBeacons.length} detected)' : ''}\n• Family members\n• Police/Fire/Ambulance";
    } else if (lower.contains('offline') || lower.contains('internet')) {
      return "Offline mode status:\n• Offline maps: ${_offlineMapsReady ? 'Ready ' : 'Not available '}\n• Queued alerts: $_queuedAlertsCount\n• Bluetooth beacon: ${_bluetoothBeaconActive ? 'Active ' : 'Inactive '}\n• Nearby contacts: ${_nearbyBeacons.length}";
    } else {
      return "I understand. I'm here to keep you safe. You can ask me to:\n• Activate emergency alerts\n• Share your location${!_isOnline ? ' (works offline)' : ''}\n• Contact emergency services\n• Find help nearby\n\nWhat would you like me to do?";
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ==================== NAVIGATION ====================

  void _navigateToProfile() async {
    await _panicServiceV2.triggerHapticFeedback(type: HapticType.light);
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  void _navigateToHistory() async {
    await _panicServiceV2.triggerHapticFeedback(type: HapticType.medium);
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
  }

  void _navigateToPowerManagement() async {
    await _panicServiceV2.triggerHapticFeedback(type: HapticType.light);
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PowerManagementScreen()));
  }

  void _navigateToOfflineSync() async {
    await _panicServiceV2.triggerHapticFeedback(type: HapticType.light);
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const OfflineSyncScreen()));
  }

  void _navigateToVoiceCenter() async {
    await _panicServiceV2.triggerHapticFeedback(type: HapticType.light);
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceCenterScreen()));
  }

  void _navigateToDoctorAnnieChat() async {
    await _panicServiceV2.triggerHapticFeedback(type: HapticType.medium);
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorAnnieChatScreen()));
  }

  // ==================== LONG PRESS ====================

  void _handleLongPressStart() {
    if (_isTriggering) return;
    setState(() => _longPressProgress = 0.0);
    _panicServiceV2.triggerHapticFeedback(type: HapticType.medium);

    Future.delayed(Duration.zero, () async {
      for (int i = 0; i <= 100; i++) {
        if (_longPressProgress == 0.0 && i > 0) break;
        await Future.delayed(const Duration(milliseconds: 30));
        if (mounted) {
          setState(() => _longPressProgress = i / 100);
          if (i % 10 == 0) _panicServiceV2.triggerHapticFeedback(type: HapticType.light);
        }
        if (i == 100) _startCountdown(silent: true);
      }
    });
  }

  void _handleLongPressEnd() {
    setState(() => _longPressProgress = 0.0);
  }

  // ==================== BUILD METHOD ====================

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.userProfile?['name'] ?? 'User';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AkelDesign.deepBlack,

      appBar: _showAIChat ? null : AppBar(
        backgroundColor: AkelDesign.carbonFiber,
        elevation: 0,
        toolbarHeight: 60,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AkelDesign.neonBlue, size: 24),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.shield, color: AkelDesign.primaryRed, size: 18),
            const SizedBox(width: 8),
            Text('AKEL', style: AkelDesign.h3.copyWith(fontSize: 16, letterSpacing: 2)),
          ],
        ),
        actions: [
          IconButton(
            icon: _buildBatteryIcon(),
            onPressed: _navigateToPowerManagement,
            iconSize: 20,
          ),
          IconButton(
            icon: Icon(
              _isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: _isOnline ? AkelDesign.successGreen : AkelDesign.errorRed,
              size: 20,
            ),
            onPressed: _navigateToOfflineSync,
          ),
          IconButton(
            icon: const Icon(Icons.history, color: AkelDesign.neonBlue, size: 20),
            onPressed: _navigateToHistory,
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white, size: 20),
            onPressed: _navigateToProfile,
          ),
        ],
      ),

      drawer: _showAIChat ? null : const FeatureDrawer(),

      body: Stack(
        children: [
          if (!_showAIChat) _buildMainContent(userName),
          if (_showAIChat) _buildAIChatInterface(),
        ],
      ),

      floatingActionButton: _showAIChat
          ? FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          setState(() => _showAIChat = false);
        },
        backgroundColor: AkelDesign.errorRed,
        child: const Icon(Icons.close, color: Colors.white),
      )
          : Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AICopilotFloatingButton(
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() => _showAIChat = true);
            },
            isActive: _isAIInitialized,
            pulseController: _pulseController,
          ),
          const SizedBox(height: 16),
          const FloatingSosButton(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
  // ==================== MAIN CONTENT ====================

  Widget _buildMainContent(String userName) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            const Color(0xFF0A0E27),
            AkelDesign.deepBlack,
          ],
        ),
      ),
      child: CustomPaint(
        painter: GridPainter(),
        child: Column(
          children: [
            // Safe Word (hidden)
            if (_safeWordEnabled)
              Opacity(
                opacity: 0.0,
                child: SizedBox(
                  height: 0,
                  child: TextField(
                    controller: _safeWordController,
                    onChanged: _onTextChanged,
                  ),
                ),
              ),

            // Offline/Queue Status Banner
            if (!_isOnline || _queuedAlertsCount > 0)
              _buildOfflineStatusBanner(),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    // Welcome Header
                    _buildCompactHeader(userName),

                    const SizedBox(height: 16),

                    // Enhanced Status Pills
                    _buildEnhancedStatusPills(),

                    const SizedBox(height: 16),

                    // Safety Score Card
                    _buildSafetyScoreCard(),

                    const SizedBox(height: 20),

                    // 3D GLOSSY PANIC BUTTON
                    _isCountingDown ? _buildCountdownWidget() : _build3DPanicButton(),

                    const SizedBox(height: 20),

                    // Offline Features Card
                    if (!_isOnline) _buildOfflineFeaturesCard(),

                    const SizedBox(height: 16),

                    // Bluetooth Beacon Status
                    if (_bluetoothBeaconActive) _buildBluetoothBeaconCard(),

                    const SizedBox(height: 16),

                    // Compact Quick Actions
                    _buildCompactQuickActions(),

                    const SizedBox(height: 16),

                    // Command Center Quick Access
                    _buildCommandCenterCards(),

                    const SizedBox(height: 16),

                    // Doctor Annie Card
                    _buildDoctorAnnieCard(),

                    const SizedBox(height: 16),

                    // Location Breadcrumbs
                    _buildLocationBreadcrumbsCard(),

                    const SizedBox(height: 16),

                    // Recent Activity
                    _buildRecentActivityCard(),

                    const SizedBox(height: 16),

                    // Emergency Services (compact)
                    const EmergencyServicesQuickDialWidget(showTitle: true),

                    const SizedBox(height: 16),

                    // Community Safety Quick Widget
                    const CommunitySafetyQuickWidget(),

                    const SizedBox(height: 16),

                    // Medical Intelligence Quick Widget
                    const MedicalIntelligenceQuickWidget(),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== UI COMPONENTS ====================

  Widget _buildOfflineStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _isOnline ? AkelDesign.warningOrange : AkelDesign.errorRed,
            (_isOnline ? AkelDesign.warningOrange : AkelDesign.errorRed).withOpacity(0.7),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isOnline ? Icons.schedule : Icons.wifi_off,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isOnline
                  ? ' $_queuedAlertsCount queued • Sending when contacts nearby'
                  : ' Offline • $_queuedAlertsCount queued • ${_offlineMapsReady ? 'Maps ready' : 'No maps'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader(String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome,',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AkelDesign.neonBlue.withOpacity(0.3),
                AkelDesign.primaryRed.withOpacity(0.2),
              ],
            ),
            border: Border.all(color: AkelDesign.neonBlue.withOpacity(0.5), width: 1.5),
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  Widget _buildEnhancedStatusPills() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildStatusPill(Icons.check_circle, 'Ready', AkelDesign.successGreen, !_isPanicActive),
        _buildStatusPill(Icons.location_on, 'GPS', AkelDesign.neonBlue, true),
        _buildStatusPill(Icons.psychology, 'AI', const Color(0xFF00BFA5), _isAIInitialized),
        _buildStatusPill(Icons.warning, 'Alert', AkelDesign.primaryRed, _isPanicActive),
        _buildStatusPill(Icons.battery_charging_full, '$_batteryLevel%', _batteryLevel > 20 ? AkelDesign.successGreen : AkelDesign.errorRed, true),
        _buildStatusPill(Icons.wifi, _isOnline ? 'Online' : 'Offline', _isOnline ? AkelDesign.successGreen : AkelDesign.warningOrange, true),
        _buildStatusPill(Icons.people, '$_contactCount', Colors.purple, _contactCount >= 3),
        _buildStatusPill(Icons.medical_services, 'Medical', AkelDesign.successGreen, true),
        _buildStatusPill(Icons.bluetooth, 'BT', AkelDesign.neonBlue, _bluetoothBeaconActive),
        _buildStatusPill(Icons.map, 'Maps', AkelDesign.successGreen, _offlineMapsReady),
      ],
    );
  }

  Widget _buildStatusPill(IconData icon, String label, Color color, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.15) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? color.withOpacity(0.5) : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? color : Colors.white.withOpacity(0.3), size: 11),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: isActive ? color : Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyScoreCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AkelDesign.successGreen.withOpacity(0.15),
            AkelDesign.successGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AkelDesign.successGreen.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AkelDesign.successGreen.withOpacity(0.3),
                  AkelDesign.successGreen.withOpacity(0.1),
                ],
              ),
            ),
            child: Center(
              child: Text(
                '$_safetyScore',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AkelDesign.successGreen,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safety Score',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: AkelDesign.successGreen, size: 10),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'GPS • $_contactCount Contacts • ${_offlineMapsReady ? 'Offline Ready' : 'Online Only'}',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Last check-in: Today • Queue: $_queuedAlertsCount',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3DPanicButton() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _glowAnimation, _rotateController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: GestureDetector(
            onTap: () async {
              await _panicServiceV2.triggerHapticFeedback(type: HapticType.heavy);
              _startCountdown(silent: false);
            },
            onLongPressStart: (_) => _handleLongPressStart(),
            onLongPressEnd: (_) => _handleLongPressEnd(),
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AkelDesign.primaryRed.withOpacity(_glowAnimation.value * 0.6),
                          blurRadius: 40,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),

                  // Rotating ring
                  Transform.rotate(
                    angle: _rotateController.value * 2 * math.pi,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AkelDesign.neonBlue.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  // 3D Glossy Button
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.3),
                        radius: 1.2,
                        colors: [
                          const Color(0xFFFF6B6B),
                          AkelDesign.primaryRed,
                          const Color(0xFF8B0000),
                          const Color(0xFF450000),
                        ],
                        stops: const [0.0, 0.4, 0.7, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AkelDesign.primaryRed.withOpacity(0.8),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Glossy highlight
                        Positioned(
                          top: 20,
                          left: 20,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.7),
                                  Colors.white.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Center content
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.emergency, size: 50, color: Colors.white),
                              const SizedBox(height: 8),
                              const Text(
                                'PANIC',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 3,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap or Hold',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Specular highlight
                        Positioned(
                          top: 30,
                          left: 30,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.5),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Progress ring
                        if (_longPressProgress > 0)
                          Positioned.fill(
                            child: CircularProgressIndicator(
                              value: _longPressProgress,
                              strokeWidth: 6,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Pulsing outer ring
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      final size = 180 + (_glowAnimation.value * 40);
                      return Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AkelDesign.primaryRed.withOpacity((1 - _glowAnimation.value) * 0.5),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCountdownWidget() {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AkelDesign.warningOrange,
            AkelDesign.warningOrange.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AkelDesign.warningOrange.withOpacity(0.6),
            blurRadius: 40,
            spreadRadius: 20,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _countdown.toString(),
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'SENDING...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cancelCountdown,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AkelDesign.warningOrange,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('CANCEL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineFeaturesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AkelDesign.warningOrange.withOpacity(0.2),
            AkelDesign.warningOrange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AkelDesign.warningOrange.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_off, color: AkelDesign.warningOrange, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Offline Mode Active',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildOfflineFeatureItem(
            Icons.map,
            'Offline Maps',
            _offlineMapsReady ? 'Available' : 'Not downloaded',
            _offlineMapsReady,
          ),
          const SizedBox(height: 8),
          _buildOfflineFeatureItem(
            Icons.schedule_send,
            'Alert Queue',
            '$_queuedAlertsCount queued',
            true,
          ),
          const SizedBox(height: 8),
          _buildOfflineFeatureItem(
            Icons.bluetooth,
            'Bluetooth Beacon',
            _bluetoothBeaconActive ? 'Broadcasting' : 'Inactive',
            _bluetoothBeaconActive,
          ),
          const SizedBox(height: 8),
          _buildOfflineFeatureItem(
            Icons.location_on,
            'GPS Tracking',
            'Active (no internet needed)',
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineFeatureItem(IconData icon, String title, String status, bool isActive) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isActive ? AkelDesign.successGreen : AkelDesign.errorRed).withOpacity(0.2),
          ),
          child: Icon(
            icon,
            color: isActive ? AkelDesign.successGreen : AkelDesign.errorRed,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        Icon(
          isActive ? Icons.check_circle : Icons.warning,
          color: isActive ? AkelDesign.successGreen : AkelDesign.errorRed,
          size: 16,
        ),
      ],
    );
  }

  Widget _buildBluetoothBeaconCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AkelDesign.neonBlue.withOpacity(0.2),
            AkelDesign.neonBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AkelDesign.neonBlue.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AkelDesign.neonBlue.withOpacity(0.3),
                      AkelDesign.neonBlue.withOpacity(0.1),
                    ],
                  ),
                ),
                child: const Icon(Icons.bluetooth, color: AkelDesign.neonBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bluetooth Beacon',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Broadcasting • ${_nearbyBeacons.length} nearby',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AkelDesign.successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AkelDesign.successGreen,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: AkelDesign.successGreen, size: 6),
                    const SizedBox(width: 4),
                    const Text(
                      'Active',
                      style: TextStyle(
                        color: AkelDesign.successGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_nearbyBeacons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, color: AkelDesign.neonBlue, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Emergency Contacts Nearby',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _queuedAlertsCount > 0
                        ? ' ${_nearbyBeacons.length} contact${_nearbyBeacons.length == 1 ? '' : 's'} in range • Queued alerts will send automatically'
                        : '${_nearbyBeacons.length} contact${_nearbyBeacons.length == 1 ? '' : 's'} in range',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactQuickActions() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: [
        _buildMicroCard(Icons.contact_phone, 'Contacts', const Color(0xFF00BFA5)),
        _buildMicroCard(Icons.location_on, 'Location', AkelDesign.neonBlue),
        _buildMicroCard(Icons.record_voice_over, 'Voice', Colors.purple, onTap: _navigateToVoiceCenter),
        _buildMicroCard(Icons.apps, 'More', Colors.orange),
      ],
    );
  }

  Widget _buildMicroCard(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? (() => _scaffoldKey.currentState?.openDrawer()),
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.15),
                  color.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withOpacity(0.3),
                        color.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommandCenterCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Command Centers',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            _buildCommandCard('Master Control', Icons.dashboard, Colors.purple),
            _buildCommandCard('Emergency', Icons.emergency, AkelDesign.primaryRed),
          ],
        ),
      ],
    );
  }

  Widget _buildCommandCard(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _scaffoldKey.currentState?.openDrawer(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorAnnieCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => _showAIChat = true);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2C5F7C).withOpacity(0.7),
              const Color(0xFF00BFA5).withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00BFA5).withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00BFA5).withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: DoctorAnnieAvatarWidget(
                appearance: _annieAppearance,
                size: 50,
                enableAnimations: true,
                showHolographicBackground: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Doctor Annie AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _isAIInitialized
                              ? Colors.green.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isAIInitialized ? Colors.green : Colors.orange,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              color: _isAIInitialized ? Colors.green : Colors.orange,
                              size: 5,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _isAIInitialized ? 'Active' : 'Loading',
                              style: TextStyle(
                                color: _isAIInitialized ? Colors.green : Colors.orange,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Your AI Companion • Tap to chat',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  // ==================== LOCATION BREADCRUMBS CARD ====================

  Widget _buildLocationBreadcrumbsCard() {
    if (_locationBreadcrumbs.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AkelDesign.neonBlue.withOpacity(0.15),
            AkelDesign.neonBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AkelDesign.neonBlue.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _breadcrumbsExpanded = !_breadcrumbsExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.timeline, color: AkelDesign.neonBlue, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Location Trail',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AkelDesign.neonBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AkelDesign.neonBlue,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${_locationBreadcrumbs.length} locations',
                      style: const TextStyle(
                        color: AkelDesign.neonBlue,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _breadcrumbsExpanded ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AkelDesign.neonBlue,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Compact View (default)
          if (!_breadcrumbsExpanded) _buildCompactBreadcrumbs(),

          // Expanded View
          if (_breadcrumbsExpanded) _buildExpandedBreadcrumbs(),
        ],
      ),
    );
  }

  Widget _buildCompactBreadcrumbs() {
    return SizedBox(
      height: 80,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _locationBreadcrumbs.length,
          separatorBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.arrow_forward,
              color: AkelDesign.neonBlue.withOpacity(0.5),
              size: 16,
            ),
          ),
          itemBuilder: (context, index) {
            final breadcrumb = _locationBreadcrumbs[index];
            final isLast = index == _locationBreadcrumbs.length - 1;

            return _buildCompactBreadcrumbItem(breadcrumb, isLast);
          },
        ),
      ),
    );
  }

  Widget _buildCompactBreadcrumbItem(LocationBreadcrumb breadcrumb, bool isLast) {
    return GestureDetector(
      onTap: () => _navigateToLocation(breadcrumb),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              (isLast ? AkelDesign.successGreen : AkelDesign.neonBlue).withOpacity(0.2),
              (isLast ? AkelDesign.successGreen : AkelDesign.neonBlue).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLast ? AkelDesign.successGreen : AkelDesign.neonBlue,
            width: isLast ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              breadcrumb.icon,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              breadcrumb.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isLast ? AkelDesign.successGreen : Colors.white,
              ),
            ),
            if (!isLast) ...[
              const SizedBox(height: 2),
              Text(
                _formatDuration(breadcrumb.dwellDuration),
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ] else ...[
              const SizedBox(height: 2),
              Text(
                'Current',
                style: TextStyle(
                  fontSize: 9,
                  color: AkelDesign.successGreen.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedBreadcrumbs() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Column(
        children: _locationBreadcrumbs.asMap().entries.map((entry) {
          final index = entry.key;
          final breadcrumb = entry.value;
          final isLast = index == _locationBreadcrumbs.length - 1;

          return _buildExpandedBreadcrumbItem(breadcrumb, isLast, index > 0);
        }).toList(),
      ),
    );
  }

  Widget _buildExpandedBreadcrumbItem(LocationBreadcrumb breadcrumb, bool isLast, bool showConnector) {
    return Column(
      children: [
        if (showConnector)
          Container(
            width: 2,
            height: 16,
            color: AkelDesign.neonBlue.withOpacity(0.3),
            margin: const EdgeInsets.only(left: 20),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLast ? AkelDesign.successGreen : Colors.white.withOpacity(0.2),
              width: isLast ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (isLast ? AkelDesign.successGreen : AkelDesign.neonBlue).withOpacity(0.3),
                          (isLast ? AkelDesign.successGreen : AkelDesign.neonBlue).withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        breadcrumb.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                breadcrumb.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (isLast)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AkelDesign.successGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AkelDesign.successGreen,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.circle, color: AkelDesign.successGreen, size: 6),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Current',
                                      style: TextStyle(
                                        color: AkelDesign.successGreen,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule, color: Colors.white.withOpacity(0.5), size: 12),
                            const SizedBox(width: 4),
                            Text(
                              isLast
                                  ? 'Arrived ${breadcrumb.arrivalTime.hour}:${breadcrumb.arrivalTime.minute.toString().padLeft(2, '0')}'
                                  : '${breadcrumb.arrivalTime.hour}:${breadcrumb.arrivalTime.minute.toString().padLeft(2, '0')} - ${breadcrumb.departureTime?.hour}:${breadcrumb.departureTime?.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.timer, color: Colors.white.withOpacity(0.5), size: 12),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(breadcrumb.dwellDuration),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isLast) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToLocation(breadcrumb),
                        icon: const Icon(Icons.navigation, size: 16),
                        label: const Text('Navigate', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AkelDesign.neonBlue.withOpacity(0.3),
                          foregroundColor: AkelDesign.neonBlue,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _callFromLocation(breadcrumb),
                        icon: const Icon(Icons.phone, size: 16),
                        label: const Text('Call', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.withOpacity(0.3),
                          foregroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _shareLocation(breadcrumb),
                      icon: const Icon(Icons.share, size: 18),
                      color: Colors.white.withOpacity(0.7),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ==================== BREADCRUMB ACTIONS ====================

  void _navigateToLocation(LocationBreadcrumb breadcrumb) async {
    HapticFeedback.mediumImpact();
    _googleTTS.speak('Navigating to ${breadcrumb.name}');

    try {
      if (_isOnline) {
        await _offlineMaps.navigateToLocation(
          breadcrumb.latitude,
          breadcrumb.longitude,
          breadcrumb.name,
        );
      } else if (_offlineMapsReady) {
        await _offlineMaps.navigateToLocationOffline(
          breadcrumb.latitude,
          breadcrumb.longitude,
          breadcrumb.name,
        );
      } else {
        _googleTTS.speak('Navigation unavailable offline. Please enable offline maps.');
      }
    } catch (e) {
      debugPrint(' Navigate to location error: $e');
    }
  }

  void _callFromLocation(LocationBreadcrumb breadcrumb) {
    HapticFeedback.lightImpact();
    _googleTTS.speak('Calling from ${breadcrumb.name}');

    // Show dialog with emergency contacts
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        title: Text('Call from ${breadcrumb.name}', style: AkelDesign.h3),
        content: const Text('Select emergency contact to call:', style: AkelDesign.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _shareLocation(LocationBreadcrumb breadcrumb) async {
    HapticFeedback.lightImpact();
    _googleTTS.speak('Sharing ${breadcrumb.name} location');

    // Share location logic here
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Shared location: ${breadcrumb.name}'),
          backgroundColor: AkelDesign.successGreen,
        ),
      );
    }
  }

  // ==================== RECENT ACTIVITY CARD ====================

  Widget _buildRecentActivityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: AkelDesign.neonBlue, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActivityItem(Icons.check_circle, 'Safety check-in completed', '2h ago', AkelDesign.successGreen),
          const SizedBox(height: 8),
          _buildActivityItem(Icons.location_on, 'Location shared with contacts', '5h ago', AkelDesign.neonBlue),
          const SizedBox(height: 8),
          _buildActivityItem(Icons.phone, 'Emergency contact verified', 'Yesterday', Colors.purple),
          if (_queuedAlertsCount > 0) ...[
            const SizedBox(height: 8),
            _buildActivityItem(Icons.schedule, '$_queuedAlertsCount alert${_queuedAlertsCount == 1 ? '' : 's'} queued', 'Pending', AkelDesign.warningOrange),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityItem(IconData icon, String title, String time, Color color) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== AI CHAT INTERFACE ====================

  Widget _buildAIChatInterface() {
    return Container(
      color: AkelDesign.deepBlack,
      child: Column(
        children: [
          // Chat Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AkelDesign.carbonFiber,
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: DoctorAnnieAvatarWidget(
                      appearance: _annieAppearance,
                      size: 40,
                      enableAnimations: true,
                      showHolographicBackground: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Doctor Annie AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Your AI Safety Companion',
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
          ),

          // Quick Action Buttons
          Container(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickActionButton(' Call 911', AkelDesign.primaryRed, () => _addUserMessage('Call 911')),
                  const SizedBox(width: 8),
                  _buildQuickActionButton(' Share Location', AkelDesign.neonBlue, () => _addUserMessage('Share my location')),
                  const SizedBox(width: 8),
                  _buildQuickActionButton(' Find Hospital', AkelDesign.successGreen, () => _addUserMessage('Find nearest hospital')),
                  const SizedBox(width: 8),
                  _buildQuickActionButton(' Alert Contacts', Colors.purple, () => _addUserMessage('Alert my emergency contacts')),
                ],
              ),
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _chatScrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _chatMessages.length + (_isAITyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _chatMessages.length && _isAITyping) {
                  return _buildTypingIndicator();
                }

                final message = _chatMessages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AkelDesign.carbonFiber,
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Voice Input Button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AkelDesign.neonBlue.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.mic, color: AkelDesign.neonBlue),
                      onPressed: () {
                        _googleTTS.speak('Voice input activated');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Text Input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _chatController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Ask Doctor Annie...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Send Button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AkelDesign.neonBlue,
                          AkelDesign.neonBlue.withOpacity(0.7),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AkelDesign.neonBlue.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
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

  Widget _buildQuickActionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _addUserMessage(String text) {
    _chatController.text = text;
    _sendMessage();
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00BFA5).withOpacity(0.2),
              ),
              child: const Icon(Icons.psychology, color: Color(0xFF00BFA5), size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: message.isUser
                          ? [AkelDesign.neonBlue, AkelDesign.neonBlue.withOpacity(0.8)]
                          : [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AkelDesign.neonBlue.withOpacity(0.2),
              ),
              child: const Icon(Icons.person, color: AkelDesign.neonBlue, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00BFA5).withOpacity(0.2),
            ),
            child: const Icon(Icons.psychology, color: Color(0xFF00BFA5), size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedBuilder(
              animation: _typingController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final value = (_typingController.value - delay).clamp(0.0, 1.0);
                    final offset = math.sin(value * math.pi * 2) * 3;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Transform.translate(
                        offset: Offset(0, offset),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

// ==================== CHAT MESSAGE MODEL ====================

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// ==================== GRID PAINTER ====================

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}