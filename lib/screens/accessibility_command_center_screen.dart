import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import '../widgets/futuristic_widgets.dart';
import '../services/ai_voice_navigation_service.dart';
import '../services/screen_reader_integration_service.dart';
import '../services/ai_image_description_service.dart';
import '../providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ==================== ACCESSIBILITY COMMAND CENTER ====================
///
/// COMPLETE ACCESSIBILITY CONTROL HUB
/// Unified accessibility management interface:
/// - Voice navigation controls
/// - Screen reader settings
/// - Image description settings
/// - High contrast mode
/// - Font size controls
/// - Color blind modes
/// - Gesture tutorials
/// - Voice command reference
/// - Quick accessibility toggles
///
/// 24-HOUR MARATHON - PHASE 6 (HOUR 24) - FINAL HOUR!
/// ================================================================

class AccessibilityCommandCenterScreen extends StatefulWidget {
  const AccessibilityCommandCenterScreen({Key? key}) : super(key: key);

  @override
  State<AccessibilityCommandCenterScreen> createState() =>
      _AccessibilityCommandCenterScreenState();
}

class _AccessibilityCommandCenterScreenState
    extends State<AccessibilityCommandCenterScreen>
    with TickerProviderStateMixin {
  // Services
  late AIVoiceNavigationService _voiceService;
  late ScreenReaderIntegrationService _screenReaderService;
  late AIImageDescriptionService _imageService;

  late TabController _tabController;
  late AnimationController _pulseController;

  bool _isInitializing = true;

  // Settings
  bool _voiceNavigationEnabled = false;
  bool _screenReaderEnabled = false;
  bool _imageDescriptionEnabled = false;
  bool _highContrastMode = false;
  bool _reduceMotion = false;

  double _fontSize = 1.0;
  double _voiceRate = 0.5;
  double _voicePitch = 1.0;
  double _voiceVolume = 1.0;

  String _selectedColorBlindMode = 'none';
  String _selectedLanguage = 'en-US';

  final List<String> _colorBlindModes = [
    'none',
    'protanopia',
    'deuteranopia',
    'tritanopia',
    'monochromacy',
  ];

  @override
  void initState() {
    super.initState();

    _voiceService = AIVoiceNavigationService();
    _screenReaderService = ScreenReaderIntegrationService(_voiceService);
    _imageService = AIImageDescriptionService(voiceService: _voiceService);

    _tabController = TabController(length: 5, vsync: this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initializeCenter();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _voiceService.dispose();
    _screenReaderService.dispose();
    _imageService.dispose();
    super.dispose();
  }

  Future<void> _initializeCenter() async {
    setState(() => _isInitializing = true);

    try {
      await _voiceService.initialize();
      await _screenReaderService.initialize();
      await _imageService.initialize();

      await _loadSettings();

      setState(() => _isInitializing = false);
    } catch (e) {
      debugPrint(' Center initialization error: $e');
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _voiceNavigationEnabled = _voiceService.isEnabled();
      _screenReaderEnabled = _screenReaderService.isEnabled();
      _imageDescriptionEnabled = _imageService.isEnabled();

      _highContrastMode = prefs.getBool('high_contrast_mode') ?? false;
      _reduceMotion = prefs.getBool('reduce_motion') ?? false;
      _fontSize = prefs.getDouble('font_size') ?? 1.0;

      _voiceRate = _voiceService.getSettings().rate;
      _voicePitch = _voiceService.getSettings().pitch;
      _voiceVolume = _voiceService.getSettings().volume;
      _selectedLanguage = _voiceService.getSettings().language;

      _selectedColorBlindMode = prefs.getString('color_blind_mode') ?? 'none';
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
              FuturisticLoadingIndicator(
                size: 60,
                color: Colors.purple,
              ),
              SizedBox(height: AkelDesign.xl),
              Text(
                'Initializing Accessibility Center...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _highContrastMode ? Colors.black : AkelDesign.deepBlack,
      appBar: AppBar(
        backgroundColor: _highContrastMode ? Colors.black : AkelDesign.carbonFiber,
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
              'ACCESSIBILITY CENTER',
              style: AkelDesign.h3.copyWith(
                fontSize: 16 * _fontSize,
                color: _highContrastMode ? Colors.white : null,
              ),
            ),
            Text(
              'Universal Access Controls',
              style: AkelDesign.caption.copyWith(
                fontSize: 10 * _fontSize,
                color: _highContrastMode ? Colors.white70 : null,
              ),
            ),
          ],
        ),
        actions: [
          FuturisticIconButton(
            icon: Icons.accessibility_new,
            onPressed: _showQuickActions,
            size: 40,
            tooltip: 'Quick Actions',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.purple,
          labelColor: Colors.purple,
          unselectedLabelColor: _highContrastMode ? Colors.white60 : Colors.white60,
          labelStyle: TextStyle(fontSize: 12 * _fontSize),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Voice'),
            Tab(text: 'Visual'),
            Tab(text: 'Gestures'),
            Tab(text: 'Help'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildVoiceTab(),
          _buildVisualTab(),
          _buildGesturesTab(),
          _buildHelpTab(),
        ],
      ),
    );
  }

  // ==================== TAB 1: OVERVIEW ====================

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          _buildStatusCard(),

          const SizedBox(height: AkelDesign.xl),

          // Quick Toggles
          Text(
            'QUICK TOGGLES',
            style: AkelDesign.subtitle.copyWith(
              fontSize: 14 * _fontSize,
              color: _highContrastMode ? Colors.white : null,
            ),
          ),
          const SizedBox(height: AkelDesign.md),

          _buildToggleCard(
            'Voice Navigation',
            Icons.mic,
            _voiceNavigationEnabled,
                (value) => _handleVoiceNavigation(value),
            Colors.purple,
          ),

          const SizedBox(height: AkelDesign.sm),

          _buildToggleCard(
            'Screen Reader',
            Icons.speaker_notes,
            _screenReaderEnabled,
                (value) => _handleScreenReader(value),
            Colors.blue,
          ),

          const SizedBox(height: AkelDesign.sm),

          _buildToggleCard(
            'Image Description',
            Icons.image,
            _imageDescriptionEnabled,
                (value) => _handleImageDescription(value),
            Colors.green,
          ),

          const SizedBox(height: AkelDesign.sm),

          _buildToggleCard(
            'High Contrast Mode',
            Icons.contrast,
            _highContrastMode,
                (value) => _handleHighContrast(value),
            Colors.orange,
          ),

          const SizedBox(height: AkelDesign.sm),

          _buildToggleCard(
            'Reduce Motion',
            Icons.motion_photos_off,
            _reduceMotion,
                (value) => _handleReduceMotion(value),
            Colors.red,
          ),

          const SizedBox(height: AkelDesign.xl),

          // Statistics
          Text(
            'USAGE STATISTICS',
            style: AkelDesign.subtitle.copyWith(
              fontSize: 14 * _fontSize,
              color: _highContrastMode ? Colors.white : null,
            ),
          ),
          const SizedBox(height: AkelDesign.md),

          _buildStatisticsGrid(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final featuresEnabled = [
      _voiceNavigationEnabled,
      _screenReaderEnabled,
      _imageDescriptionEnabled,
    ].where((e) => e).length;

    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.xl),
      hasGlow: featuresEnabled > 0,
      glowColor: Colors.purple,
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
                        Colors.purple,
                        Colors.purple.withOpacity(0.5),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.accessibility_new,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AkelDesign.lg),

          Text(
            'ACCESSIBILITY STATUS',
            style: AkelDesign.h3.copyWith(
              color: Colors.purple,
              fontSize: 20 * _fontSize,
            ),
          ),

          const SizedBox(height: AkelDesign.sm),

          Text(
            '$featuresEnabled of 3 features enabled',
            style: AkelDesign.caption.copyWith(
              fontSize: 12 * _fontSize,
              color: _highContrastMode ? Colors.white70 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard(
      String title,
      IconData icon,
      bool value,
      Function(bool) onChanged,
      Color color,
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
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AkelDesign.md),
          Expanded(
            child: Text(
              title,
              style: AkelDesign.body.copyWith(
                fontSize: 14 * _fontSize,
                fontWeight: FontWeight.w600,
                color: _highContrastMode ? Colors.white : null,
              ),
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

  Widget _buildStatisticsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Font Size',
                '${(_fontSize * 100).toInt()}%',
                Icons.text_fields,
                Colors.purple,
              ),
            ),
            const SizedBox(width: AkelDesign.md),
            Expanded(
              child: _buildStatCard(
                'Voice Rate',
                '${(_voiceRate * 100).toInt()}%',
                Icons.speed,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: AkelDesign.md),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Contrast',
                _highContrastMode ? 'High' : 'Normal',
                Icons.contrast,
                Colors.orange,
              ),
            ),
            const SizedBox(width: AkelDesign.md),
            Expanded(
              child: _buildStatCard(
                'Motion',
                _reduceMotion ? 'Reduced' : 'Normal',
                Icons.motion_photos_on,
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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AkelDesign.sm),
          Text(
            value,
            style: AkelDesign.body.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16 * _fontSize,
            ),
          ),
          Text(
            label,
            style: AkelDesign.caption.copyWith(
              fontSize: 10 * _fontSize,
              color: _highContrastMode ? Colors.white70 : null,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== TAB 2: VOICE ====================

  Widget _buildVoiceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VOICE SETTINGS',
            style: AkelDesign.subtitle.copyWith(
              fontSize: 14 * _fontSize,
              color: _highContrastMode ? Colors.white : null,
            ),
          ),
          const SizedBox(height: AkelDesign.md),

          // Voice Rate
          _buildSliderCard(
            'Speech Rate',
            Icons.speed,
            _voiceRate,
            0.1,
            1.0,
                (value) => _handleVoiceRate(value),
            Colors.purple,
          ),

          const SizedBox(height: AkelDesign.md),

          // Voice Pitch
          _buildSliderCard(
            'Speech Pitch',
            Icons.graphic_eq,
            _voicePitch,
            0.5,
            2.0,
                (value) => _handleVoicePitch(value),
            Colors.blue,
          ),

          const SizedBox(height: AkelDesign.md),

          // Voice Volume
          _buildSliderCard(
            'Volume',
            Icons.volume_up,
            _voiceVolume,
            0.0,
            1.0,
                (value) => _handleVoiceVolume(value),
            Colors.green,
          ),

          const SizedBox(height: AkelDesign.xl),

          // Test Voice Button
          FuturisticButton(
            text: 'TEST VOICE',
            icon: Icons.play_arrow,
            onPressed: _handleTestVoice,
            color: Colors.purple,
            isFullWidth: true,
          ),

          const SizedBox(height: AkelDesign.xl),

          // Voice Commands Reference
          Text(
            'VOICE COMMANDS',
            style: AkelDesign.subtitle.copyWith(
              fontSize: 14 * _fontSize,
              color: _highContrastMode ? Colors.white : null,
            ),
          ),
          const SizedBox(height: AkelDesign.md),

          ..._getVoiceCommands().map((cmd) => Padding(
            padding: const EdgeInsets.only(bottom: AkelDesign.sm),
            child: _buildCommandCard(cmd['phrase']!, cmd['description']!),
          )),
        ],
      ),
    );
  }

  Widget _buildSliderCard(
      String label,
      IconData icon,
      double value,
      double min,
      double max,
      Function(double) onChanged,
      Color color,
      ) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AkelDesign.sm),
              Text(
                label,
                style: AkelDesign.body.copyWith(
                  fontSize: 14 * _fontSize,
                  fontWeight: FontWeight.w600,
                  color: _highContrastMode ? Colors.white : null,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).toInt()}%',
                style: AkelDesign.body.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14 * _fontSize,
                ),
              ),
            ],
          ),
          const SizedBox(height: AkelDesign.sm),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildCommandCard(String phrase, String description) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.md),
      child: Row(
        children: [
          const Icon(Icons.mic, color: Colors.purple, size: 18),
          const SizedBox(width: AkelDesign.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phrase,
                  style: AkelDesign.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13 * _fontSize,
                    color: _highContrastMode ? Colors.white : null,
                  ),
                ),
                Text(
                  description,
                  style: AkelDesign.caption.copyWith(
                    fontSize: 11 * _fontSize,
                    color: _highContrastMode ? Colors.white60 : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getVoiceCommands() {
    return [
      {'phrase': '"Help"', 'description': 'Get context-specific help'},
      {'phrase': '"Where am I"', 'description': 'Announce current screen'},
      {'phrase': '"Go home"', 'description': 'Navigate to home screen'},
      {'phrase': '"Trigger panic"', 'description': 'Activate emergency alert'},
      {'phrase': '"Call police"', 'description': 'Call emergency services'},
      {'phrase': '"Read screen"', 'description': 'Read all screen elements'},
    ];
  }

  // ==================== TAB 3: VISUAL ====================

  Widget _buildVisualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VISUAL SETTINGS',
            style: AkelDesign.subtitle.copyWith(
              fontSize: 14 * _fontSize,
              color: _highContrastMode ? Colors.white : null,
            ),
          ),
          const SizedBox(height: AkelDesign.md),

          // Font Size
          _buildSliderCard(
            'Font Size',
            Icons.text_fields,
            _fontSize,
            0.5,
            2.0,
                (value) => _handleFontSize(value),
            Colors.purple,
          ),

          const SizedBox(height: AkelDesign.xl),

          // Color Blind Mode
          Text(
            'COLOR BLIND MODE',
            style: AkelDesign.subtitle.copyWith(
              fontSize: 14 * _fontSize,
              color: _highContrastMode ? Colors.white : null,
            ),
          ),
          const SizedBox(height: AkelDesign.md),

          ..._colorBlindModes.map((mode) => Padding(
            padding: const EdgeInsets.only(bottom: AkelDesign.sm),
            child: _buildColorBlindOption(mode),
          )),

          const SizedBox(height: AkelDesign.xl),

          // Preview
          Text(
            'PREVIEW',
            style: AkelDesign.subtitle.copyWith(
              fontSize: 14 * _fontSize,
              color: _highContrastMode ? Colors.white : null,
            ),
          ),
          const SizedBox(height: AkelDesign.md),

          _buildPreviewCard(),
        ],
      ),
    );
  }

  Widget _buildColorBlindOption(String mode) {
    final isSelected = _selectedColorBlindMode == mode;
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.md),
      hasGlow: isSelected,
      glowColor: Colors.purple,
      child: InkWell(
        onTap: () => _handleColorBlindMode(mode),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Colors.purple : Colors.white60,
              size: 20,
            ),
            const SizedBox(width: AkelDesign.md),
            Expanded(
              child: Text(
                _getColorBlindModeName(mode),
                style: AkelDesign.body.copyWith(
                  fontSize: 14 * _fontSize,
                  color: _highContrastMode ? Colors.white : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getColorBlindModeName(String mode) {
    switch (mode) {
      case 'none':
        return 'None (Normal Vision)';
      case 'protanopia':
        return 'Protanopia (Red-Blind)';
      case 'deuteranopia':
        return 'Deuteranopia (Green-Blind)';
      case 'tritanopia':
        return 'Tritanopia (Blue-Blind)';
      case 'monochromacy':
        return 'Monochromacy (Total Color Blindness)';
      default:
        return mode;
    }
  }

  Widget _buildPreviewCard() {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sample Text Preview',
            style: AkelDesign.h3.copyWith(
              fontSize: 18 * _fontSize,
              color: _highContrastMode ? Colors.white : null,
            ),
          ),
          const SizedBox(height: AkelDesign.sm),
          Text(
            'This is how text will appear with your current settings. '
                'Adjust font size and contrast to your preference.',
            style: AkelDesign.body.copyWith(
              fontSize: 14 * _fontSize,
              color: _highContrastMode ? Colors.white : null,
            ),
          ),
          const SizedBox(height: AkelDesign.md),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('RED', style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
              const SizedBox(width: AkelDesign.sm),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('GREEN', style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
              const SizedBox(width: AkelDesign.sm),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('BLUE', style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== TAB 4: GESTURES ====================

  Widget _buildGesturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GESTURE NAVIGATION',
            style: AkelDesign.subtitle.copyWith(
              fontSize: 14 * _fontSize,
              color: _highContrastMode ? Colors.white : null,
            ),
          ),
          const SizedBox(height: AkelDesign.md),

          ..._getGestures().map((gesture) => Padding(
            padding: const EdgeInsets.only(bottom: AkelDesign.md),
            child: _buildGestureCard(
              gesture['icon'] as IconData,
              gesture['name'] as String,
              gesture['description'] as String,
              gesture['color'] as Color,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildGestureCard(
      IconData icon,
      String name,
      String description,
      Color color,
      ) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AkelDesign.md),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: AkelDesign.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AkelDesign.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14 * _fontSize,
                    color: _highContrastMode ? Colors.white : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AkelDesign.caption.copyWith(
                    fontSize: 12 * _fontSize,
                    color: _highContrastMode ? Colors.white70 : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getGestures() {
    return [
      {
        'icon': Icons.swipe_right,
        'name': 'Swipe Right',
        'description': 'Navigate to next element',
        'color': Colors.blue,
      },
      {
        'icon': Icons.swipe_left,
        'name': 'Swipe Left',
        'description': 'Navigate to previous element',
        'color': Colors.purple,
      },
      {
        'icon': Icons.swipe_down,
        'name': 'Swipe Down',
        'description': 'Move to next section',
        'color': Colors.green,
      },
      {
        'icon': Icons.swipe_up,
        'name': 'Swipe Up',
        'description': 'Move to previous section',
        'color': Colors.orange,
      },
      {
        'icon': Icons.touch_app,
        'name': 'Double Tap',
        'description': 'Activate current element',
        'color': Colors.red,
      },
      {
        'icon': Icons.pan_tool,
        'name': 'Two-Finger Tap',
        'description': 'Stop reading',
        'color': Colors.pink,
      },
      {
        'icon': Icons.front_hand,
        'name': 'Three-Finger Tap',
        'description': 'Read screen from top',
        'color': Colors.cyan,
      },
    ];
  }

  // ==================== TAB 5: HELP ====================

  Widget _buildHelpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACCESSIBILITY HELP',
            style: AkelDesign.subtitle.copyWith(
              fontSize: 14 * _fontSize,
              color: _highContrastMode ? Colors.white : null,
            ),
          ),
          const SizedBox(height: AkelDesign.md),

          _buildHelpCard(
            'Getting Started',
            'Enable features in the Overview tab. Start with Voice Navigation for guided assistance.',
            Icons.play_circle_outline,
            Colors.purple,
          ),

          const SizedBox(height: AkelDesign.sm),

          _buildHelpCard(
            'Voice Navigation',
            'Use voice commands to navigate and control the app. Say "help" anytime for assistance.',
            Icons.mic,
            Colors.blue,
          ),

          const SizedBox(height: AkelDesign.sm),

          _buildHelpCard(
            'Screen Reader',
            'Swipe to navigate between elements. Double tap to activate. Two-finger tap to stop.',
            Icons.speaker_notes,
            Colors.green,
          ),

          const SizedBox(height: AkelDesign.sm),

          _buildHelpCard(
            'Image Description',
            'AI describes images automatically. Enable for full accessibility.',
            Icons.image,
            Colors.orange,
          ),

          const SizedBox(height: AkelDesign.xl),

          // Quick Actions
          FuturisticButton(
            text: 'CONTACT SUPPORT',
            icon: Icons.support_agent,
            onPressed: () {},
            color: Colors.purple,
            isOutlined: true,
            isFullWidth: true,
          ),

          const SizedBox(height: AkelDesign.sm),

          FuturisticButton(
            text: 'WATCH TUTORIAL',
            icon: Icons.play_circle,
            onPressed: () {},
            color: Colors.blue,
            isOutlined: true,
            isFullWidth: true,
          ),

          const SizedBox(height: AkelDesign.sm),

          FuturisticButton(
            text: 'RESET TO DEFAULTS',
            icon: Icons.restore,
            onPressed: _handleResetDefaults,
            color: Colors.red,
            isOutlined: true,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard(
      String title,
      String description,
      IconData icon,
      Color color,
      ) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: AkelDesign.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AkelDesign.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14 * _fontSize,
                    color: _highContrastMode ? Colors.white : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AkelDesign.caption.copyWith(
                    fontSize: 12 * _fontSize,
                    color: _highContrastMode ? Colors.white70 : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HANDLERS ====================

  Future<void> _handleVoiceNavigation(bool value) async {
    setState(() => _voiceNavigationEnabled = value);
    if (value) {
      await _voiceService.enable();
    } else {
      await _voiceService.disable();
    }
  }

  Future<void> _handleScreenReader(bool value) async {
    setState(() => _screenReaderEnabled = value);
    if (value) {
      await _screenReaderService.enable();
    } else {
      await _screenReaderService.disable();
    }
  }

  Future<void> _handleImageDescription(bool value) async {
    setState(() => _imageDescriptionEnabled = value);
    if (value) {
      _imageService.enable();
    } else {
      _imageService.disable();
    }
  }

  Future<void> _handleHighContrast(bool value) async {
    setState(() => _highContrastMode = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('high_contrast_mode', value);
  }

  Future<void> _handleReduceMotion(bool value) async {
    setState(() => _reduceMotion = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reduce_motion', value);
  }

  Future<void> _handleVoiceRate(double value) async {
    setState(() => _voiceRate = value);
    final settings = _voiceService.getSettings().copyWith(rate: value);
    await _voiceService.updateSettings(settings);
  }

  Future<void> _handleVoicePitch(double value) async {
    setState(() => _voicePitch = value);
    final settings = _voiceService.getSettings().copyWith(pitch: value);
    await _voiceService.updateSettings(settings);
  }

  Future<void> _handleVoiceVolume(double value) async {
    setState(() => _voiceVolume = value);
    final settings = _voiceService.getSettings().copyWith(volume: value);
    await _voiceService.updateSettings(settings);
  }

  Future<void> _handleTestVoice() async {
    await _voiceService.testVoice();
  }

  Future<void> _handleFontSize(double value) async {
    setState(() => _fontSize = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', value);
  }

  Future<void> _handleColorBlindMode(String mode) async {
    setState(() => _selectedColorBlindMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('color_blind_mode', mode);
    await _voiceService.speak('Color blind mode set to ${_getColorBlindModeName(mode)}');
  }

  Future<void> _handleResetDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        title: Text('Reset to Defaults?', style: AkelDesign.h3),
        content: Text(
          'This will reset all accessibility settings to default values.',
          style: AkelDesign.body,
        ),
        actions: [
          FuturisticButton(
            text: 'CANCEL',
            onPressed: () => Navigator.pop(context, false),
            isOutlined: true,
            isSmall: true,
          ),
          const SizedBox(width: 8),
          FuturisticButton(
            text: 'RESET',
            onPressed: () => Navigator.pop(context, true),
            color: Colors.red,
            isSmall: true,
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _resetToDefaults();
    }
  }

  Future<void> _resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('high_contrast_mode', false);
    await prefs.setBool('reduce_motion', false);
    await prefs.setDouble('font_size', 1.0);
    await prefs.setString('color_blind_mode', 'none');

    final defaultSettings = TTSSettings();
    await _voiceService.updateSettings(defaultSettings);

    await _loadSettings();

    await _voiceService.speak('Settings reset to defaults');
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AkelDesign.darkPanel,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AkelDesign.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('QUICK ACTIONS', style: AkelDesign.h3),
            const SizedBox(height: AkelDesign.lg),

            FuturisticButton(
              text: 'ENABLE ALL',
              icon: Icons.check_circle,
              onPressed: () {
                _handleVoiceNavigation(true);
                _handleScreenReader(true);
                _handleImageDescription(true);
                Navigator.pop(context);
              },
              color: Colors.green,
              isFullWidth: true,
            ),

            const SizedBox(height: AkelDesign.sm),

            FuturisticButton(
              text: 'DISABLE ALL',
              icon: Icons.cancel,
              onPressed: () {
                _handleVoiceNavigation(false);
                _handleScreenReader(false);
                _handleImageDescription(false);
                Navigator.pop(context);
              },
              color: Colors.red,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}