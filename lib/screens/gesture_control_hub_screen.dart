import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import '../widgets/futuristic_widgets.dart';
import '../services/gesture_control_service.dart' as gesture_service;
import '../services/panic_service.dart';
import '../providers/auth_provider.dart';

/// ==================== GESTURE CONTROL HUB SCREEN ====================
///
/// 4-IN-1 GESTURE CONTROL CENTER:
/// 1. Shake Detection - Shake phone to trigger panic
/// 2. Tap Patterns - Secret tap sequences
/// 3. Screen Gestures - Swipe patterns for stealth
/// 4. Motion Detection - Movement-based triggers
///
/// BUILD 55 - HOUR 9
/// ================================================================

class GestureControlHubScreen extends StatefulWidget {
  const GestureControlHubScreen({Key? key}) : super(key: key);

  @override
  State<GestureControlHubScreen> createState() => _GestureControlHubScreenState();
}

class _GestureControlHubScreenState extends State<GestureControlHubScreen>
    with TickerProviderStateMixin {
  final gesture_service.GestureControlService _gestureService = gesture_service.GestureControlService();
  final PanicService _panicService = PanicService();

  late TabController _tabController;
  late AnimationController _shakeAnimController;
  late AnimationController _tapAnimController;

  bool _isInitializing = true;
  bool _shakeEnabled = false;
  bool _tapPatternEnabled = false;
  bool _motionEnabled = false;

  List<int> _currentPattern = [];
  List<int> _secretPattern = [1, 2, 1];
  int _shakeCount = 0;
  bool _isMotionActive = false;

  Map<String, dynamic> _stats = {};
  List<String> _gestureLog = [];

  // Tap detection
  int _consecutiveTaps = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _shakeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _tapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _initializeService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _shakeAnimController.dispose();
    _tapAnimController.dispose();
    _gestureService.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    setState(() => _isInitializing = true);

    try {
      final initialized = await _gestureService.initialize();

      if (!initialized) {
        _showError('Failed to initialize gesture service');
        setState(() => _isInitializing = false);
        return;
      }

      // Setup callbacks
      _gestureService.onShakeDetected = _handleShakePanic;
      _gestureService.onPatternMatched = _handlePatternPanic;
      _gestureService.onMotionDetected = _handleMotionDetected;
      _gestureService.onGestureLog = _addToLog;

      // Load settings
      await _loadSettings();

      // Load stats
      await _loadStats();

      setState(() => _isInitializing = false);
    } catch (e) {
      debugPrint(' Gesture initialization error: $e');
      setState(() => _isInitializing = false);
      _showError('Initialization failed: $e');
    }
  }

  Future<void> _loadSettings() async {
    final shakeEnabled = _gestureService.isShakeEnabled();
    final tapEnabled = _gestureService.isTapPatternEnabled();
    final motionEnabled = _gestureService.isMotionEnabled();
    final pattern = _gestureService.getSecretPattern();

    if (mounted) {
      setState(() {
        _shakeEnabled = shakeEnabled;
        _tapPatternEnabled = tapEnabled;
        _motionEnabled = motionEnabled;
        _secretPattern = pattern;
      });
    }
  }

  Future<void> _loadStats() async {
    final stats = await _gestureService.getGestureStats();
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  void _handleShakePanic() async {
    _shakeAnimController.forward(from: 0.0);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    final userName = authProvider.userProfile?['name'] ?? 'User';

    if (userId != null) {
      await _panicService.triggerPanic(userId, userName);
      await _gestureService.incrementGestureStat('shake');
      await _loadStats();
    }

    if (mounted) {
      _showEmergencyDialog('Shake Panic Activated!', 'Emergency triggered by shake gesture');
    }
  }

  void _handlePatternPanic() async {
    _tapAnimController.forward(from: 0.0);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    final userName = authProvider.userProfile?['name'] ?? 'User';

    if (userId != null) {
      await _panicService.triggerPanic(userId, userName);
      await _gestureService.incrementGestureStat('pattern');
      await _loadStats();
    }

    if (mounted) {
      _showEmergencyDialog('Pattern Panic Activated!', 'Emergency triggered by tap pattern');
    }
  }

  void _handleMotionDetected() {
    setState(() {
      _isMotionActive = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isMotionActive = false;
        });
      }
    });
  }

  void _addToLog(String message) {
    setState(() {
      _gestureLog.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $message');
      if (_gestureLog.length > 20) {
        _gestureLog.removeLast();
      }
    });
  }

  void _handleScreenTap() {
    if (!_tapPatternEnabled) return;

    final now = DateTime.now();

    if (_lastTapTime != null && now.difference(_lastTapTime!) < const Duration(milliseconds: 300)) {
      _consecutiveTaps++;
    } else {
      if (_consecutiveTaps > 0) {
        _gestureService.registerTap(_consecutiveTaps);
        _currentPattern = _gestureService.getCurrentPattern();
        setState(() {});
      }
      _consecutiveTaps = 1;
    }

    _lastTapTime = now;
    _tapAnimController.forward(from: 0.0);
  }

  void _showEmergencyDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
        ),
        icon: const Icon(
          Icons.emergency,
          color: AkelDesign.primaryRed,
          size: 64,
        ),
        title: Text(
          title,
          style: AkelDesign.h3.copyWith(color: AkelDesign.primaryRed),
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          style: AkelDesign.body,
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: FuturisticButton(
              text: 'OK',
              onPressed: () => Navigator.pop(context),
              color: AkelDesign.primaryRed,
              isSmall: true,
            ),
          ),
        ],
      ),
    );
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
                'Initializing Gesture Control...',
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
              'GESTURE CONTROL HUB',
              style: AkelDesign.h3.copyWith(fontSize: 16),
            ),
            Text(
              '4-in-1 Gesture System',
              style: AkelDesign.caption.copyWith(fontSize: 10),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AkelDesign.neonBlue,
          labelColor: AkelDesign.neonBlue,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Shake'),
            Tab(text: 'Tap Pattern'),
            Tab(text: 'Screen Gestures'),
            Tab(text: 'Motion'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildShakeTab(),
          _buildTapPatternTab(),
          _buildScreenGesturesTab(),
          _buildMotionTab(),
        ],
      ),
    );
  }

  // ==================== TAB 1: SHAKE DETECTION ====================

  Widget _buildShakeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.xl),
            hasGlow: _shakeEnabled,
            glowColor: AkelDesign.neonBlue,
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _shakeAnimController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        _shakeAnimController.value * 20 * ((_shakeAnimController.value * 4).floor() % 2 == 0 ? 1 : -1),
                        0,
                      ),
                      child: Icon(
                        _shakeEnabled ? Icons.vibration : Icons.phonelink_off,
                        size: 80,
                        color: _shakeEnabled ? AkelDesign.neonBlue : Colors.white30,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AkelDesign.lg),
                Text(
                  _shakeEnabled ? 'SHAKE DETECTION ACTIVE' : 'SHAKE DETECTION OFF',
                  style: AkelDesign.h3.copyWith(
                    color: _shakeEnabled ? AkelDesign.neonBlue : Colors.white60,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AkelDesign.md),
                Text(
                  _shakeEnabled
                      ? 'Shake your phone 3 times to trigger emergency'
                      : 'Enable shake detection to use this feature',
                  style: AkelDesign.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.xl),

          // Enable/Disable
          _buildSettingCard(
            title: 'Enable Shake Detection',
            subtitle: 'Shake phone 3 times to trigger panic',
            icon: Icons.vibration,
            value: _shakeEnabled,
            onChanged: (value) async {
              await _gestureService.setShakeEnabled(value);
              setState(() {
                _shakeEnabled = value;
              });
            },
          ),

          const SizedBox(height: AkelDesign.xl),

          // Statistics
          Text('SHAKE STATISTICS', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Shake Triggers',
                  '${_stats['shake_triggers'] ?? 0}',
                  Icons.vibration,
                  AkelDesign.neonBlue,
                ),
              ),
              const SizedBox(width: AkelDesign.md),
              Expanded(
                child: _buildStatCard(
                  'Total Gestures',
                  '${_stats['total_gestures'] ?? 0}',
                  Icons.gesture,
                  AkelDesign.successGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: AkelDesign.xl),

          // Instructions
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: AkelDesign.infoBlue, size: 20),
                    const SizedBox(width: AkelDesign.md),
                    Text('HOW IT WORKS', style: AkelDesign.subtitle.copyWith(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: AkelDesign.md),
                _buildInstructionStep('1', 'Enable shake detection'),
                _buildInstructionStep('2', 'Shake your phone rapidly 3 times'),
                _buildInstructionStep('3', 'Emergency panic will be triggered'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 2: TAP PATTERN ====================

  Widget _buildTapPatternTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Demo Area
          GestureDetector(
            onTap: _handleScreenTap,
            child: FuturisticCard(
              padding: const EdgeInsets.all(AkelDesign.xxl),
              hasGlow: _tapPatternEnabled,
              glowColor: AkelDesign.neonBlue,
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _tapAnimController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_tapAnimController.value * 0.2),
                        child: Icon(
                          Icons.touch_app,
                          size: 80,
                          color: _tapPatternEnabled ? AkelDesign.neonBlue : Colors.white30,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AkelDesign.lg),
                  Text(
                    _tapPatternEnabled ? 'TAP HERE TO PRACTICE' : 'TAP PATTERN OFF',
                    style: AkelDesign.h3.copyWith(
                      color: _tapPatternEnabled ? AkelDesign.neonBlue : Colors.white60,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AkelDesign.md),
                  if (_tapPatternEnabled && _currentPattern.isNotEmpty) ...[
                    Text(
                      'Current Pattern: ${_currentPattern.join("-")}',
                      style: AkelDesign.caption,
                    ),
                    const SizedBox(height: AkelDesign.sm),
                    Text(
                      'Secret Pattern: ${_secretPattern.join("-")}',
                      style: AkelDesign.caption.copyWith(color: AkelDesign.successGreen),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: AkelDesign.xl),

          // Enable/Disable
          _buildSettingCard(
            title: 'Enable Tap Pattern',
            subtitle: 'Use secret tap sequence to trigger panic',
            icon: Icons.touch_app,
            value: _tapPatternEnabled,
            onChanged: (value) async {
              await _gestureService.setTapPatternEnabled(value);
              setState(() {
                _tapPatternEnabled = value;
              });
            },
          ),

          const SizedBox(height: AkelDesign.xl),

          // Pattern Selector
          Text('SELECT PATTERN', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          ...gesture_service.TapPattern.getPresetPatterns().map((pattern) {
            final isSelected = _secretPattern.join(',') == pattern.pattern.join(',');

            return Padding(
              padding: const EdgeInsets.only(bottom: AkelDesign.sm),
              child: FuturisticCard(
                padding: const EdgeInsets.all(AkelDesign.md),
                hasGlow: isSelected,
                glowColor: AkelDesign.neonBlue,
                child: InkWell(
                  onTap: () async {
                    await _gestureService.setSecretPattern(pattern.pattern);
                    setState(() {
                      _secretPattern = pattern.pattern;
                    });
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: (isSelected ? AkelDesign.neonBlue : Colors.white30).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
                        ),
                        child: Center(
                          child: Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected ? AkelDesign.neonBlue : Colors.white60,
                          ),
                        ),
                      ),
                      const SizedBox(width: AkelDesign.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pattern.name,
                              style: AkelDesign.body.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pattern.description,
                              style: AkelDesign.caption,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pattern: ${pattern.pattern.join("-")}',
                              style: AkelDesign.caption.copyWith(
                                color: AkelDesign.neonBlue,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: AkelDesign.xl),

          // Info
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.md),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AkelDesign.infoBlue, size: 20),
                const SizedBox(width: AkelDesign.md),
                Expanded(
                  child: Text(
                    'Tap numbers represent: 1=single tap, 2=double tap, 3=triple tap',
                    style: AkelDesign.caption,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 3: SCREEN GESTURES ====================

  Widget _buildScreenGesturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Swipe Demo
          GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! < -1000) {
                _addToLog('Fast upward swipe detected');
                _showEmergencyDialog(
                  'Emergency Swipe!',
                  'Fast upward swipe can trigger panic (Demo only)',
                );
              }
            },
            child: FuturisticCard(
              padding: const EdgeInsets.all(AkelDesign.xxl),
              hasGlow: true,
              glowColor: AkelDesign.successGreen,
              child: Column(
                children: [
                  const Icon(
                    Icons.swipe_up,
                    size: 80,
                    color: AkelDesign.successGreen,
                  ),
                  const SizedBox(height: AkelDesign.lg),
                  Text(
                    'SWIPE UP QUICKLY',
                    style: AkelDesign.h3.copyWith(
                      color: AkelDesign.successGreen,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: AkelDesign.md),
                  Text(
                    'Swipe up fast to demo emergency gesture',
                    style: AkelDesign.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AkelDesign.xl),

          // Gesture Types
          Text('SUPPORTED GESTURES', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          _buildGestureTypeCard(
            'Emergency Swipe',
            'Fast upward swipe',
            Icons.swipe_up,
            AkelDesign.successGreen,
          ),

          _buildGestureTypeCard(
            'Secret Tap Zone',
            'Tap specific screen area',
            Icons.crop_square,
            AkelDesign.warningOrange,
          ),

          _buildGestureTypeCard(
            'Draw Pattern',
            'Draw emergency symbol',
            Icons.draw,
            AkelDesign.infoBlue,
          ),

          _buildGestureTypeCard(
            'Multi-Touch',
            'Three-finger press',
            Icons.touch_app,
            Colors.purple,
          ),

          const SizedBox(height: AkelDesign.xl),

          // Status
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.md),
            child: Row(
              children: [
                const Icon(Icons.construction, color: AkelDesign.warningOrange, size: 20),
                const SizedBox(width: AkelDesign.md),
                Expanded(
                  child: Text(
                    'Additional gesture patterns coming soon',
                    style: AkelDesign.caption.copyWith(color: AkelDesign.warningOrange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 4: MOTION DETECTION ====================

  Widget _buildMotionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.xl),
            hasGlow: _motionEnabled,
            glowColor: _isMotionActive ? AkelDesign.successGreen : AkelDesign.neonBlue,
            child: Column(
              children: [
                Icon(
                  _isMotionActive ? Icons.directions_run : Icons.directions_walk,
                  size: 80,
                  color: _isMotionActive
                      ? AkelDesign.successGreen
                      : (_motionEnabled ? AkelDesign.neonBlue : Colors.white30),
                ),
                const SizedBox(height: AkelDesign.lg),
                Text(
                  _isMotionActive
                      ? 'MOTION DETECTED!'
                      : (_motionEnabled ? 'MOTION MONITORING ACTIVE' : 'MOTION DETECTION OFF'),
                  style: AkelDesign.h3.copyWith(
                    color: _isMotionActive
                        ? AkelDesign.successGreen
                        : (_motionEnabled ? AkelDesign.neonBlue : Colors.white60),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AkelDesign.md),
                Text(
                  _motionEnabled
                      ? 'Movement is being monitored'
                      : 'Enable motion detection to monitor movement',
                  style: AkelDesign.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.xl),

          // Enable/Disable
          _buildSettingCard(
            title: 'Enable Motion Detection',
            subtitle: 'Monitor device movement',
            icon: Icons.directions_run,
            value: _motionEnabled,
            onChanged: (value) async {
              await _gestureService.setMotionEnabled(value);
              setState(() {
                _motionEnabled = value;
              });
            },
          ),

          const SizedBox(height: AkelDesign.xl),

          // Statistics
          Text('MOTION STATISTICS', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          _buildStatCard(
            'Motion Events',
            '${_stats['motion_triggers'] ?? 0}',
            Icons.timeline,
            AkelDesign.successGreen,
          ),

          const SizedBox(height: AkelDesign.xl),

          // Info
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: AkelDesign.infoBlue, size: 20),
                    const SizedBox(width: AkelDesign.md),
                    Text('MOTION DETECTION', style: AkelDesign.subtitle.copyWith(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: AkelDesign.md),
                Text(
                  'Motion detection monitors device movement and can be used for fall detection or suspicious activity alerts.',
                  style: AkelDesign.caption,
                ),
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.xl),

          // Gesture Log
          if (_gestureLog.isNotEmpty) ...[
            Text('RECENT ACTIVITY', style: AkelDesign.subtitle),
            const SizedBox(height: AkelDesign.md),
            FuturisticCard(
              padding: const EdgeInsets.all(AkelDesign.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _gestureLog.take(10).map((log) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AkelDesign.sm),
                    child: Text(
                      log,
                      style: AkelDesign.caption.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
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

  // ==================== HELPER WIDGETS ====================

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.md),
      hasGlow: value,
      glowColor: AkelDesign.successGreen,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AkelDesign.sm),
            decoration: BoxDecoration(
              color: (value ? AkelDesign.successGreen : Colors.white30).withOpacity(0.2),
              borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
            ),
            child: Icon(
              icon,
              color: value ? AkelDesign.successGreen : Colors.white60,
              size: 24,
            ),
          ),
          const SizedBox(width: AkelDesign.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AkelDesign.body.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: AkelDesign.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AkelDesign.successGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: AkelDesign.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AkelDesign.h3.copyWith(color: color, fontSize: 24),
                ),
                Text(label, style: AkelDesign.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AkelDesign.sm),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AkelDesign.neonBlue.withOpacity(0.2),
              border: Border.all(color: AkelDesign.neonBlue, width: 1),
            ),
            child: Center(
              child: Text(
                number,
                style: AkelDesign.caption.copyWith(
                  color: AkelDesign.neonBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: AkelDesign.md),
          Expanded(
            child: Text(text, style: AkelDesign.caption),
          ),
        ],
      ),
    );
  }

  Widget _buildGestureTypeCard(String title, String subtitle, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AkelDesign.sm),
      child: FuturisticCard(
        padding: const EdgeInsets.all(AkelDesign.md),
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
                  Text(title, style: AkelDesign.body.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AkelDesign.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}