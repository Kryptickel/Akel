import 'package:flutter/material.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import '../widgets/futuristic_widgets.dart';
import '../services/shake_detection_service.dart';

/// ==================== SHAKE DETECTION SETTINGS SCREEN ====================
///
/// SHAKE-TO-ALERT CONFIGURATION
/// Complete shake detection settings interface:
/// - Enable/disable shake detection
/// - Sensitivity controls
/// - Test shake detection
/// - Calibration tool
/// - Shake history
/// - Statistics
///
/// 6-HOUR SPRINT - HOUR 1
/// ================================================================

class ShakeDetectionSettingsScreen extends StatefulWidget {
  const ShakeDetectionSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ShakeDetectionSettingsScreen> createState() =>
      _ShakeDetectionSettingsScreenState();
}

class _ShakeDetectionSettingsScreenState
    extends State<ShakeDetectionSettingsScreen>
    with TickerProviderStateMixin {
  final ShakeDetectionService _shakeService = ShakeDetectionService();

  late AnimationController _pulseController;

  bool _isInitializing = true;
  bool _isEnabled = false;
  bool _isMonitoring = false;
  ShakeSensitivity _selectedSensitivity = ShakeSensitivity.medium;
  Map<String, dynamic> _statistics = {};
  List<ShakeEvent> _shakeHistory = [];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _shakeService.onShakeDetected = () {
      _showShakeDetectedDialog();
    };

    _shakeService.onLog = (message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
        );
      }
    };

    _initializeScreen();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeService.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    setState(() => _isInitializing = true);

    try {
      await _shakeService.initialize();
      await _loadData();

      setState(() => _isInitializing = false);
    } catch (e) {
      debugPrint(' Screen initialization error: $e');
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isEnabled = _shakeService.isEnabled();
      _isMonitoring = _shakeService.isMonitoring();
      _selectedSensitivity = _shakeService.getSensitivity();
      _statistics = _shakeService.getStatistics();
      _shakeHistory = _shakeService.getShakeHistory();
    });
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
              FuturisticLoadingIndicator(size: 60, color: Colors.orange),
              SizedBox(height: AkelDesign.xl),
              Text(
                'Loading Shake Detection...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
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
              'SHAKE DETECTION',
              style: AkelDesign.h3.copyWith(fontSize: 16),
            ),
            Row(
              children: [
                if (_isMonitoring)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.orange,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange,
                              blurRadius: 5 + (_pulseController.value * 3),
                              spreadRadius: 1 + (_pulseController.value * 2),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                if (_isMonitoring) const SizedBox(width: 6),
                Text(
                  _isMonitoring ? 'Monitoring Active' : 'Monitoring Inactive',
                  style: AkelDesign.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        actions: [
          FuturisticIconButton(
            icon: Icons.refresh,
            onPressed: _handleRefresh,
            size: 40,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AkelDesign.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(),

            const SizedBox(height: AkelDesign.xl),

            // Enable Toggle
            Text('SHAKE-TO-ALERT', style: AkelDesign.subtitle),
            const SizedBox(height: AkelDesign.md),

            _buildEnableToggle(),

            if (_isEnabled) ...[
              const SizedBox(height: AkelDesign.xl),

              // Sensitivity Selection
              Text('SENSITIVITY LEVEL', style: AkelDesign.subtitle),
              const SizedBox(height: AkelDesign.md),

              ...ShakeSensitivity.values
                  .where((s) => s != ShakeSensitivity.disabled)
                  .map((sensitivity) => Padding(
                padding: const EdgeInsets.only(bottom: AkelDesign.sm),
                child: _buildSensitivityOption(sensitivity),
              )),

              const SizedBox(height: AkelDesign.xl),

              // Actions
              Text('ACTIONS', style: AkelDesign.subtitle),
              const SizedBox(height: AkelDesign.md),

              FuturisticButton(
                text: 'TEST SHAKE DETECTION',
                icon: Icons.play_arrow,
                onPressed: _handleTest,
                color: Colors.orange,
                isFullWidth: true,
              ),

              const SizedBox(height: AkelDesign.sm),

              FuturisticButton(
                text: 'CALIBRATE SENSITIVITY',
                icon: Icons.tune,
                onPressed: _handleCalibrate,
                color: Colors.blue,
                isOutlined: true,
                isFullWidth: true,
              ),

              const SizedBox(height: AkelDesign.xl),

              // Statistics
              Text('STATISTICS', style: AkelDesign.subtitle),
              const SizedBox(height: AkelDesign.md),

              _buildStatisticsGrid(),

              const SizedBox(height: AkelDesign.xl),

              // History
              Text('RECENT SHAKES', style: AkelDesign.subtitle),
              const SizedBox(height: AkelDesign.md),

              if (_shakeHistory.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AkelDesign.xl),
                    child: Text(
                      'No shake events recorded',
                      style: AkelDesign.caption.copyWith(color: Colors.white38),
                    ),
                  ),
                )
              else
                ..._shakeHistory.take(5).map((event) => Padding(
                  padding: const EdgeInsets.only(bottom: AkelDesign.sm),
                  child: _buildShakeEventCard(event),
                )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.xl),
      hasGlow: _isMonitoring,
      glowColor: Colors.orange,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.05),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.orange,
                        Colors.orange.withOpacity(0.5),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.vibration, size: 40, color: Colors.white),
                ),
              );
            },
          ),

          const SizedBox(height: AkelDesign.lg),

          Text(
            _isMonitoring ? 'MONITORING ACTIVE' : 'MONITORING INACTIVE',
            style: AkelDesign.h3.copyWith(
              color: _isMonitoring ? Colors.orange : Colors.grey,
              fontSize: 20,
            ),
          ),

          const SizedBox(height: AkelDesign.sm),

          Text(
            _isMonitoring
                ? 'Shake your device to trigger panic alert'
                : 'Enable shake detection to get started',
            style: AkelDesign.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnableToggle() {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AkelDesign.md),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
            ),
            child: const Icon(Icons.vibration, color: Colors.orange, size: 32),
          ),
          const SizedBox(width: AkelDesign.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shake-to-Alert',
                  style: AkelDesign.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEnabled ? 'Enabled' : 'Disabled',
                  style: AkelDesign.caption.copyWith(
                    color: _isEnabled ? AkelDesign.successGreen : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isEnabled,
            onChanged: _handleToggle,
            activeColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSensitivityOption(ShakeSensitivity sensitivity) {
    final isSelected = _selectedSensitivity == sensitivity;

    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.md),
      hasGlow: isSelected,
      glowColor: sensitivity.color,
      child: InkWell(
        onTap: () => _handleSensitivityChange(sensitivity),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? sensitivity.color : Colors.white60,
              size: 20,
            ),
            const SizedBox(width: AkelDesign.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sensitivity.displayName,
                    style: AkelDesign.body.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sensitivity.description,
                    style: AkelDesign.caption.copyWith(fontSize: 11),
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
                color: sensitivity.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
              ),
              child: Text(
                '${sensitivity.threshold.toInt()}',
                style: AkelDesign.caption.copyWith(
                  color: sensitivity.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Shakes',
                '${_statistics['totalShakes'] ?? 0}',
                Icons.vibration,
                Colors.orange,
              ),
            ),
            const SizedBox(width: AkelDesign.md),
            Expanded(
              child: _buildStatCard(
                'Triggered',
                '${_statistics['triggeredPanics'] ?? 0}',
                Icons.emergency,
                AkelDesign.primaryRed,
              ),
            ),
          ],
        ),
        const SizedBox(height: AkelDesign.md),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Sensitivity',
                _selectedSensitivity.toString().split('.').last.toUpperCase(),
                Icons.tune,
                Colors.blue,
              ),
            ),
            const SizedBox(width: AkelDesign.md),
            Expanded(
              child: _buildStatCard(
                'Avg Magnitude',
                '${(_statistics['averageMagnitude'] ?? 0).toStringAsFixed(1)}',
                Icons.trending_up,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.md),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AkelDesign.sm),
          Text(
            value,
            style: AkelDesign.body.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: AkelDesign.caption.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShakeEventCard(ShakeEvent event) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.md),
      child: Row(
        children: [
          Icon(
            Icons.vibration,
            color: event.triggeredPanic ? AkelDesign.primaryRed : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: AkelDesign.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Magnitude: ${event.magnitude.toStringAsFixed(2)}',
                  style: AkelDesign.body.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  _formatTimestamp(event.timestamp),
                  style: AkelDesign.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          if (event.triggeredPanic)
            const Icon(Icons.warning, color: AkelDesign.primaryRed, size: 18),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // ==================== HANDLERS ====================

  Future<void> _handleToggle(bool value) async {
    if (value) {
      await _shakeService.enable();
    } else {
      await _shakeService.disable();
    }
    await _loadData();
  }

  Future<void> _handleSensitivityChange(ShakeSensitivity sensitivity) async {
    await _shakeService.setSensitivity(sensitivity);
    await _loadData();
  }

  Future<void> _handleTest() async {
    await _shakeService.testShake();
  }

  Future<void> _handleCalibrate() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        title: Text('Calibration', style: AkelDesign.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FuturisticLoadingIndicator(size: 40, color: Colors.orange),
            const SizedBox(height: AkelDesign.lg),
            Text(
              'Shake your device normally 3 times',
              style: AkelDesign.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    await _shakeService.calibrate();
    if (mounted) {
      Navigator.pop(context);
      await _loadData();
    }
  }

  Future<void> _handleRefresh() async {
    await _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(' Refreshed'),
        backgroundColor: AkelDesign.successGreen,
      ),
    );
  }

  void _showShakeDetectedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        title: Row(
          children: [
            const Icon(Icons.vibration, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Text('Shake Detected!', style: AkelDesign.h3),
          ],
        ),
        content: Text(
          'Shake detection triggered successfully!',
          style: AkelDesign.body,
        ),
        actions: [
          FuturisticButton(
            text: 'OK',
            onPressed: () {
              Navigator.pop(context);
              _loadData();
            },
            color: Colors.orange,
            isSmall: true,
          ),
        ],
      ),
    );
  }
}