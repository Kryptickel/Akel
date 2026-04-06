import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import '../widgets/futuristic_widgets.dart';
import '../services/smart_detection_service.dart';
import '../services/unified_panic_manager.dart';
import '../providers/auth_provider.dart';

/// ==================== SENSOR INTELLIGENCE SCREEN ====================
///
/// SMART DETECTION DASHBOARD
/// Complete UI for Universal Sensor Intelligence Hub
///
/// Features:
/// - Real-time sensor monitoring
/// - Detection profiles (earthquake, fall, hazard, disaster)
/// - Detection history with filtering
/// - Statistics & analytics
/// - Auto-response configuration
/// - Sensitivity settings
///
/// 24-HOUR MARATHON - PHASE 1 (HOUR 2)
/// ================================================================

class SensorIntelligenceScreen extends StatefulWidget {
  const SensorIntelligenceScreen({Key? key}) : super(key: key);

  @override
  State<SensorIntelligenceScreen> createState() => _SensorIntelligenceScreenState();
}

class _SensorIntelligenceScreenState extends State<SensorIntelligenceScreen>
    with TickerProviderStateMixin {
  final SmartDetectionService _detectionService = SmartDetectionService();
  final UnifiedPanicManager _panicManager = UnifiedPanicManager();

  late TabController _tabController;
  late AnimationController _monitoringAnimController;

  bool _isInitializing = true;
  bool _isMonitoring = false;

  // Detection toggles
  bool _earthquakeEnabled = false;
  bool _fallEnabled = false;
  bool _environmentalEnabled = false;
  bool _disasterEnabled = false;

  // Thresholds
  double _earthquakeThreshold = 5.0;
  double _fallThreshold = 15.0;

  // Auto-response settings
  bool _autoTriggerPanic = false;
  bool _autoStartEvidence = false;
  bool _autoNotifyServices = false;
  bool _autoCommunityAlert = false;

  // Data
  List<DetectionEvent> _detectionHistory = [];
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _monitoringAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _initializeService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _monitoringAnimController.dispose();
    _detectionService.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    setState(() => _isInitializing = true);

    try {
      // Initialize services
      await _detectionService.initialize();
      await _panicManager.initialize();

      // Setup callbacks
      _detectionService.onDetectionTriggered = _handleDetection;
      _detectionService.onEmergencyDetected = _handleEmergency;

      // Load settings
      await _loadSettings();

      // Load data
      await _loadHistory();
      await _loadStatistics();

      setState(() => _isInitializing = false);
    } catch (e) {
      debugPrint(' Initialization error: $e');
      setState(() => _isInitializing = false);
      _showError('Failed to initialize: $e');
    }
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isMonitoring = _detectionService.isMonitoring();
      _earthquakeEnabled = _detectionService.isEarthquakeDetectionEnabled();
      _fallEnabled = _detectionService.isFallDetectionEnabled();
      _environmentalEnabled = _detectionService.isEnvironmentalHazardEnabled();
      _disasterEnabled = _detectionService.isNaturalDisasterEnabled();
      _earthquakeThreshold = _detectionService.getEarthquakeThreshold();
    });

    if (_isMonitoring) {
      _monitoringAnimController.repeat();
    }
  }

  Future<void> _loadHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      final history = await _detectionService.getDetectionHistoryFromFirestore(userId);
      if (mounted) {
        setState(() {
          _detectionHistory = history;
        });
      }
    }
  }

  Future<void> _loadStatistics() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      final stats = await _detectionService.getDetectionStatistics(userId);
      if (mounted) {
        setState(() {
          _statistics = stats;
        });
      }
    }
  }

  void _handleDetection(DetectionEvent event) {
    setState(() {
      _detectionHistory.insert(0, event);
    });

    // Show alert dialog
    _showDetectionAlert(event);

    // Auto-response actions
    if (_autoTriggerPanic && event.severity == EarthquakeSeverity.severe) {
      _triggerAutoPanic(event);
    }
  }

  void _handleEmergency() {
    debugPrint(' EMERGENCY DETECTION - Auto-triggering panic!');
  }

  Future<void> _triggerAutoPanic(DetectionEvent event) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    final userName = authProvider.userProfile?['name'] ?? 'User';

    if (userId != null) {
      await _panicManager.triggerPanic(
        userId: userId,
        userName: userName,
        source: PanicTriggerSource.automatic,
        additionalData: {
          'detectionType': event.type.name,
          'severity': event.severity.name,
          'timestamp': event.timestamp.toIso8601String(),
        },
        autoStartEvidence: _autoStartEvidence,
      );
    }
  }

  void _showDetectionAlert(DetectionEvent event) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
        ),
        icon: Icon(
          _getDetectionIcon(event.type),
          color: event.getSeverityColor(),
          size: 64,
        ),
        title: Text(
          event.getDisplayTitle(),
          style: AkelDesign.h3.copyWith(color: event.getSeverityColor()),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Severity: ${event.getSeverityLabel()}',
              style: AkelDesign.body.copyWith(
                color: event.getSeverityColor(),
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AkelDesign.md),
            Text(
              DateFormat('MMM dd, yyyy - hh:mm:ss a').format(event.timestamp),
              style: AkelDesign.caption,
              textAlign: TextAlign.center,
            ),
            if (event.severity == EarthquakeSeverity.severe) ...[
              const SizedBox(height: AkelDesign.lg),
              Container(
                padding: const EdgeInsets.all(AkelDesign.md),
                decoration: BoxDecoration(
                  color: AkelDesign.primaryRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
                  border: Border.all(color: AkelDesign.primaryRed),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: AkelDesign.primaryRed, size: 20),
                    const SizedBox(width: AkelDesign.sm),
                    Expanded(
                      child: Text(
                        'SEVERE DETECTION - Take immediate action!',
                        style: AkelDesign.caption.copyWith(
                          color: AkelDesign.primaryRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (event.severity == EarthquakeSeverity.severe)
            FuturisticButton(
              text: 'TRIGGER PANIC',
              icon: Icons.emergency,
              onPressed: () {
                Navigator.pop(context);
                _triggerAutoPanic(event);
              },
              color: AkelDesign.primaryRed,
              isSmall: true,
            ),
          FuturisticButton(
            text: 'OK',
            onPressed: () => Navigator.pop(context),
            isSmall: true,
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  IconData _getDetectionIcon(DetectionType type) {
    switch (type) {
      case DetectionType.earthquake:
        return Icons.waves;
      case DetectionType.fall:
        return Icons.personal_injury;
      case DetectionType.environmentalHazard:
        return Icons.warning;
      case DetectionType.naturalDisaster:
        return Icons.thunderstorm;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AkelDesign.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: AkelDesign.deepBlack,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FuturisticLoadingIndicator(
                size: 60,
                color: AkelDesign.neonBlue,
              ),
              SizedBox(height: AkelDesign.xl),
              Text(
                'Initializing Smart Detection...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AkelDesign.deepBlack,
      appBar: AppBar(
        backgroundColor: AkelDesign.carbonFiber,
        elevation: 0,
        leading: FuturisticIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.pop(context),
          size: 40,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SENSOR INTELLIGENCE',
              style: AkelDesign.h3.copyWith(fontSize: 16),
            ),
            Text(
              'Smart Detection System',
              style: AkelDesign.caption.copyWith(fontSize: 10),
            ),
          ],
        ),
        actions: [
          if (_isMonitoring)
            Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedBuilder(
                animation: _monitoringAnimController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.3 + (_monitoringAnimController.value * 0.7),
                    child: const Icon(
                      Icons.sensors,
                      color: AkelDesign.successGreen,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AkelDesign.neonBlue,
          labelColor: AkelDesign.neonBlue,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Profiles'),
            Tab(text: 'History'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildProfilesTab(),
          _buildHistoryTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  // ==================== TAB 1: DASHBOARD ====================

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monitoring Status
          _buildMonitoringStatus(),

          const SizedBox(height: AkelDesign.xxl),

          // Quick Stats
          Text('DETECTION STATISTICS', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),
          _buildQuickStats(),

          const SizedBox(height: AkelDesign.xxl),

          // Active Detections
          Text('ACTIVE DETECTIONS', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),
          _buildActiveDetections(),

          const SizedBox(height: AkelDesign.xxl),

          // Recent Events
          Text('RECENT EVENTS', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),
          _buildRecentEvents(),
        ],
      ),
    );
  }

  Widget _buildMonitoringStatus() {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.xxl),
      hasGlow: _isMonitoring,
      glowColor: _isMonitoring ? AkelDesign.successGreen : AkelDesign.metalChrome,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _monitoringAnimController,
            builder: (context, child) {
              return Transform.scale(
                scale: _isMonitoring ? 1.0 + (_monitoringAnimController.value * 0.1) : 1.0,
                child: Icon(
                  _isMonitoring ? Icons.sensors : Icons.sensors_off,
                  size: 80,
                  color: _isMonitoring ? AkelDesign.successGreen : Colors.white30,
                ),
              );
            },
          ),
          const SizedBox(height: AkelDesign.lg),
          Text(
            _isMonitoring ? 'MONITORING ACTIVE' : 'MONITORING INACTIVE',
            style: AkelDesign.h3.copyWith(
              color: _isMonitoring ? AkelDesign.successGreen : Colors.white60,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AkelDesign.md),
          Text(
            _isMonitoring
                ? 'All sensors are actively monitoring for threats'
                : 'Tap below to start monitoring',
            style: AkelDesign.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AkelDesign.xl),
          FuturisticButton(
            text: _isMonitoring ? 'STOP MONITORING' : 'START MONITORING',
            icon: _isMonitoring ? Icons.stop : Icons.play_arrow,
            onPressed: _toggleMonitoring,
            color: _isMonitoring ? AkelDesign.primaryRed : AkelDesign.successGreen,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMonitoring() async {
    if (_isMonitoring) {
      await _detectionService.stopMonitoring();
      _monitoringAnimController.stop();
    } else {
      await _detectionService.startMonitoring();
      _monitoringAnimController.repeat();
    }

    setState(() {
      _isMonitoring = !_isMonitoring;
    });
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total',
            '${_statistics['total'] ?? 0}',
            Icons.analytics,
            AkelDesign.neonBlue,
          ),
        ),
        const SizedBox(width: AkelDesign.md),
        Expanded(
          child: _buildStatCard(
            'Earthquakes',
            '${_statistics['earthquakes'] ?? 0}',
            Icons.waves,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.md),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AkelDesign.sm),
          Text(
            value,
            style: AkelDesign.h3.copyWith(color: color, fontSize: 24),
          ),
          Text(label, style: AkelDesign.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildActiveDetections() {
    final activeCount = [
      _earthquakeEnabled,
      _fallEnabled,
      _environmentalEnabled,
      _disasterEnabled,
    ].where((e) => e).length;

    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AkelDesign.successGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
            ),
            child: const Icon(
              Icons.check_circle,
              color: AkelDesign.successGreen,
              size: 32,
            ),
          ),
          const SizedBox(width: AkelDesign.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$activeCount Active Profiles',
                  style: AkelDesign.body.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${4 - activeCount} profiles disabled',
                  style: AkelDesign.caption,
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: AkelDesign.neonBlue,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEvents() {
    if (_detectionHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No Events',
        subtitle: 'No detections recorded yet',
      );
    }

    return Column(
      children: _detectionHistory.take(5).map((event) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AkelDesign.sm),
          child: _buildEventCard(event),
        );
      }).toList(),
    );
  }

  Widget _buildEventCard(DetectionEvent event) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.md),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: event.getSeverityColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
            ),
            child: Icon(
              _getDetectionIcon(event.type),
              color: event.getSeverityColor(),
              size: 24,
            ),
          ),
          const SizedBox(width: AkelDesign.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.type.name.toUpperCase(),
                  style: AkelDesign.body.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, hh:mm a').format(event.timestamp),
                  style: AkelDesign.caption,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AkelDesign.sm,
              vertical: AkelDesign.xs,
            ),
            decoration: BoxDecoration(
              color: event.getSeverityColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
              border: Border.all(color: event.getSeverityColor()),
            ),
            child: Text(
              event.getSeverityLabel(),
              style: AkelDesign.caption.copyWith(
                color: event.getSeverityColor(),
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 2: PROFILES ====================

  Widget _buildProfilesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DETECTION PROFILES', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          _buildProfileCard(
            'Earthquake Detection',
            'Accelerometer-based seismic activity monitoring',
            Icons.waves,
            Colors.orange,
            _earthquakeEnabled,
                (value) async {
              await _detectionService.setEarthquakeDetection(value);
              setState(() => _earthquakeEnabled = value);
            },
          ),

          const SizedBox(height: AkelDesign.md),

          _buildProfileCard(
            'Fall Detection',
            'Multi-sensor fall and impact detection',
            Icons.personal_injury,
            Colors.red,
            _fallEnabled,
                (value) async {
              await _detectionService.setFallDetection(value);
              setState(() => _fallEnabled = value);
            },
          ),

          const SizedBox(height: AkelDesign.md),

          _buildProfileCard(
            'Environmental Hazards',
            'Detect smoke, gas, heat, and magnetic anomalies',
            Icons.warning,
            AkelDesign.warningOrange,
            _environmentalEnabled,
                (value) async {
              await _detectionService.setEnvironmentalHazardDetection(value);
              setState(() => _environmentalEnabled = value);
            },
          ),

          const SizedBox(height: AkelDesign.md),

          _buildProfileCard(
            'Natural Disasters',
            'Monitor for tsunamis, hurricanes, and severe weather',
            Icons.thunderstorm,
            Colors.purple,
            _disasterEnabled,
                (value) async {
              await _detectionService.setNaturalDisasterDetection(value);
              setState(() => _disasterEnabled = value);
            },
          ),

          const SizedBox(height: AkelDesign.xxl),

          // Test Buttons
          Text('TEST DETECTIONS', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          FuturisticButton(
            text: 'SIMULATE EARTHQUAKE',
            icon: Icons.waves,
            onPressed: () {
              // Trigger test earthquake
              _detectionService.simulateEnvironmentalHazard('earthquake_test');
            },
            color: Colors.orange,
            isOutlined: true,
            isFullWidth: true,
          ),

          const SizedBox(height: AkelDesign.md),

          FuturisticButton(
            text: 'SIMULATE FIRE HAZARD',
            icon: Icons.local_fire_department,
            onPressed: () {
              _detectionService.simulateEnvironmentalHazard('fire');
            },
            color: AkelDesign.primaryRed,
            isOutlined: true,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      bool value,
      Function(bool) onChanged,
      ) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.md),
      hasGlow: value,
      glowColor: color,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AkelDesign.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AkelDesign.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AkelDesign.body.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: AkelDesign.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }

  // ==================== TAB 3: HISTORY ====================

  Widget _buildHistoryTab() {
    if (_detectionHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No History',
        subtitle: 'No detection events recorded yet',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AkelDesign.lg),
      itemCount: _detectionHistory.length,
      itemBuilder: (context, index) {
        final event = _detectionHistory[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AkelDesign.md),
          child: _buildDetailedEventCard(event),
        );
      },
    );
  }

  Widget _buildDetailedEventCard(DetectionEvent event) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: event.getSeverityColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
                ),
                child: Icon(
                  _getDetectionIcon(event.type),
                  color: event.getSeverityColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: AkelDesign.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.type.name.toUpperCase(),
                      style: AkelDesign.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy - hh:mm:ss a').format(event.timestamp),
                      style: AkelDesign.caption,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AkelDesign.sm,
                  vertical: AkelDesign.xs,
                ),
                decoration: BoxDecoration(
                  color: event.getSeverityColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
                  border: Border.all(color: event.getSeverityColor()),
                ),
                child: Text(
                  event.getSeverityLabel(),
                  style: AkelDesign.caption.copyWith(
                    color: event.getSeverityColor(),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),

          if (event.data.isNotEmpty) ...[
            const SizedBox(height: AkelDesign.md),
            Container(
              padding: const EdgeInsets.all(AkelDesign.sm),
              decoration: BoxDecoration(
                color: AkelDesign.deepBlack,
                borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
                border: Border.all(
                  color: AkelDesign.metalChrome.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: event.data.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: AkelDesign.caption.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== TAB 4: SETTINGS ====================

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SENSITIVITY SETTINGS', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Earthquake Threshold',
                  style: AkelDesign.body.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AkelDesign.md),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _earthquakeThreshold,
                        min: 3.0,
                        max: 10.0,
                        divisions: 14,
                        activeColor: Colors.orange,
                        label: _earthquakeThreshold.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() => _earthquakeThreshold = value);
                        },
                        onChangeEnd: (value) {
                          _detectionService.setEarthquakeThreshold(value);
                        },
                      ),
                    ),
                    Text(
                      '${_earthquakeThreshold.toStringAsFixed(1)} m/s²',
                      style: AkelDesign.body.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.xxl),

          Text('AUTO-RESPONSE ACTIONS', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          _buildAutoResponseCard(
            'Auto-Trigger Panic',
            'Automatically trigger panic on severe detections',
            Icons.emergency,
            AkelDesign.primaryRed,
            _autoTriggerPanic,
                (value) => setState(() => _autoTriggerPanic = value),
          ),

          const SizedBox(height: AkelDesign.sm),

          _buildAutoResponseCard(
            'Auto-Start Evidence',
            'Automatically start recording evidence',
            Icons.videocam,
            Colors.deepOrange,
            _autoStartEvidence,
                (value) => setState(() => _autoStartEvidence = value),
          ),

          const SizedBox(height: AkelDesign.sm),

          _buildAutoResponseCard(
            'Auto-Notify Services',
            'Automatically notify emergency services',
            Icons.phone,
            Colors.blue,
            _autoNotifyServices,
                (value) => setState(() => _autoNotifyServices = value),
          ),

          const SizedBox(height: AkelDesign.sm),

          _buildAutoResponseCard(
            'Community Alert',
            'Send alert to nearby community members',
            Icons.groups,
            Colors.purple,
            _autoCommunityAlert,
                (value) => setState(() => _autoCommunityAlert = value),
          ),

          const SizedBox(height: AkelDesign.xxl),

          FuturisticButton(
            text: 'CLEAR DETECTION HISTORY',
            icon: Icons.delete,
            onPressed: () {
              setState(() {
                _detectionHistory.clear();
              });
            },
            color: AkelDesign.errorRed,
            isOutlined: true,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAutoResponseCard(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      bool value,
      Function(bool) onChanged,
      ) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AkelDesign.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AkelDesign.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AkelDesign.body.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: AkelDesign.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.white24,
          ),
          const SizedBox(height: AkelDesign.lg),
          Text(
            title,
            style: AkelDesign.h3.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: AkelDesign.sm),
          Text(
            subtitle,
            style: AkelDesign.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}