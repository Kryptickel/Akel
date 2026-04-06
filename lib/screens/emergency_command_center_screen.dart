import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/fire_service.dart';
import '../services/police_service.dart';
import '../services/ambulance_service.dart';
import '../services/panic_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import '../widgets/futuristic_widgets.dart';
import 'fire_emergency_screen.dart';
import 'police_emergency_screen.dart';
import 'ambulance_emergency_screen.dart';

class EmergencyCommandCenterScreen extends StatefulWidget {
  const EmergencyCommandCenterScreen({super.key});

  @override
  State<EmergencyCommandCenterScreen> createState() => _EmergencyCommandCenterScreenState();
}

class _EmergencyCommandCenterScreenState extends State<EmergencyCommandCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final FireService _fireService = FireService();
  final PoliceService _policeService = PoliceService();
  final AmbulanceService _ambulanceService = AmbulanceService();
  final PanicService _panicService = PanicService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();

  bool _isSirenActive = false;
  bool _isMorseCodeActive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (_isSirenActive) {
      _soundService.dispose();
    }
    super.dispose();
  }

  // ==================== EMERGENCY ACTIONS ====================

  Future<void> _call911() async {
    await _vibrationService.panic();
    await _soundService.playWarning();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
        ),
        title: Row(
          children: [
            const Icon(Icons.phone_in_talk, color: AkelDesign.primaryRed, size: 32),
            const SizedBox(width: 12),
            Text('Call 911?', style: AkelDesign.h3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This will call emergency services immediately.',
              style: AkelDesign.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FuturisticCard(
              padding: const EdgeInsets.all(12),
              hasGlow: true,
              glowColor: AkelDesign.primaryRed,
              child: Text(
                ' Only use for real emergencies',
                style: AkelDesign.body.copyWith(
                  color: AkelDesign.primaryRed,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          FuturisticButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
            isOutlined: true,
            isSmall: true,
          ),
          const SizedBox(width: 8),
          FuturisticButton(
            text: 'CALL 911',
            icon: Icons.phone,
            onPressed: () => Navigator.pop(context, true),
            color: AkelDesign.primaryRed,
            isSmall: true,
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uri = Uri.parse('tel:911');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<void> _callFireDepartment() async {
    await _vibrationService.light();
    await _soundService.playClick();
    await _fireService.callFireDepartment();
  }

  Future<void> _callPolice() async {
    await _vibrationService.light();
    await _soundService.playClick();
    await _policeService.callPolice();
  }

  Future<void> _callAmbulance() async {
    await _vibrationService.light();
    await _soundService.playClick();
    await _ambulanceService.callAmbulance();
  }

  void _toggleSiren() {
    setState(() {
      _isSirenActive = !_isSirenActive;
    });

    if (_isSirenActive) {
      _vibrationService.panic();
      _soundService.playPanicSiren();
    } else {
      _soundService.dispose();
    }
  }

  void _toggleMorseCode() {
    setState(() {
      _isMorseCodeActive = !_isMorseCodeActive;
    });

    if (_isMorseCodeActive) {
      _startMorseCodeSOS();
    }
  }

  void _startMorseCodeSOS() async {
    // SOS in Morse: ... --- ...
    // Dot = 200ms, Dash = 600ms, Gap = 200ms
    while (_isMorseCodeActive && mounted) {
      // S (...)
      for (int i = 0; i < 3; i++) {
        if (!_isMorseCodeActive) break;
        await _vibrationService.light();
        await Future.delayed(const Duration(milliseconds: 200));
      }
      await Future.delayed(const Duration(milliseconds: 400));

      // O (---)
      for (int i = 0; i < 3; i++) {
        if (!_isMorseCodeActive) break;
        await _vibrationService.medium();
        await Future.delayed(const Duration(milliseconds: 600));
      }
      await Future.delayed(const Duration(milliseconds: 400));

      // S (...)
      for (int i = 0; i < 3; i++) {
        if (!_isMorseCodeActive) break;
        await _vibrationService.light();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Future<void> _broadcastAlert() async {
    await _vibrationService.panic();
    await _soundService.playWarning();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final userName = authProvider.userProfile?['name'] ?? 'User';

    if (user == null) {
      _showError('Not logged in');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
        ),
        title: Row(
          children: [
            const Icon(Icons.campaign, color: AkelDesign.warningOrange, size: 32),
            const SizedBox(width: 12),
            Expanded(child: Text('Broadcast Alert?', style: AkelDesign.h3)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This will send an emergency alert to ALL your contacts immediately.',
              style: AkelDesign.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FuturisticCard(
              padding: const EdgeInsets.all(12),
              hasGlow: true,
              glowColor: AkelDesign.warningOrange,
              child: Text(
                ' Mass emergency notification',
                style: AkelDesign.body.copyWith(
                  color: AkelDesign.warningOrange,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          FuturisticButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
            isOutlined: true,
            isSmall: true,
          ),
          const SizedBox(width: 8),
          FuturisticButton(
            text: 'BROADCAST',
            icon: Icons.campaign,
            onPressed: () => Navigator.pop(context, true),
            color: AkelDesign.warningOrange,
            isSmall: true,
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _panicService.triggerPanic(user.uid, userName);

      if (mounted) {
        if (result['success'] == true) {
          await _vibrationService.success();
          await _soundService.playSuccess();
          _showSuccess('Alert broadcasted to ${result['contactsNotified']} contacts');
        } else {
          await _vibrationService.error();
          await _soundService.playError();
          _showError(result['error'] ?? 'Failed to broadcast alert');
        }
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AkelDesign.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AkelDesign.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
        ),
      ),
    );
  }

  // ==================== BUILD UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AkelDesign.deepBlack,
      appBar: AppBar(
        backgroundColor: AkelDesign.carbonFiber,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EMERGENCY COMMAND', style: AkelDesign.h3.copyWith(fontSize: 16)),
            Text('All Services', style: AkelDesign.caption.copyWith(fontSize: 10)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AkelDesign.primaryRed,
          labelColor: AkelDesign.primaryRed,
          unselectedLabelColor: AkelDesign.metalChrome,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Home'),
            Tab(icon: Icon(Icons.local_fire_department), text: 'Fire'),
            Tab(icon: Icon(Icons.local_police), text: 'Police'),
            Tab(icon: Icon(Icons.local_hospital), text: 'Medical'),
            Tab(icon: Icon(Icons.phone_in_talk), text: '911'),
            Tab(icon: Icon(Icons.flashlight_on), text: 'SOS'),
            Tab(icon: Icon(Icons.campaign), text: 'Broadcast'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomeTab(),
          _buildFireTab(),
          _buildPoliceTab(),
          _buildMedicalTab(),
          _build911Tab(),
          _buildSOSTab(),
          _buildBroadcastTab(),
        ],
      ),
    );
  }

  // ==================== HOME TAB ====================

  Widget _buildHomeTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            AkelDesign.carbonFiber,
            AkelDesign.deepBlack,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AkelDesign.lg),
        child: Column(
          children: [
            const SizedBox(height: AkelDesign.xl),

            // Main 911 Button
            FuturisticCard(
              padding: const EdgeInsets.all(AkelDesign.xl),
              hasGlow: true,
              glowColor: AkelDesign.primaryRed,
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AkelDesign.primaryRed,
                          AkelDesign.primaryRed.withValues(alpha: 0.6),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AkelDesign.primaryRed.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.phone_in_talk,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AkelDesign.lg),
                  Text('CALL 911', style: AkelDesign.h1.copyWith(fontSize: 32)),
                  const SizedBox(height: AkelDesign.sm),
                  Text(
                    'Immediate Emergency Response',
                    style: AkelDesign.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AkelDesign.lg),
                  FuturisticButton(
                    text: 'CALL NOW',
                    icon: Icons.phone,
                    onPressed: _call911,
                    color: AkelDesign.primaryRed,
                    isFullWidth: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AkelDesign.xl),

            // Quick Access Services
            Text('QUICK ACCESS', style: AkelDesign.subtitle),
            const SizedBox(height: AkelDesign.md),

            Row(
              children: [
                Expanded(
                  child: _buildQuickServiceCard(
                    icon: Icons.local_fire_department,
                    label: 'Fire',
                    color: Colors.deepOrange,
                    onTap: () => _tabController.animateTo(1),
                  ),
                ),
                const SizedBox(width: AkelDesign.md),
                Expanded(
                  child: _buildQuickServiceCard(
                    icon: Icons.local_police,
                    label: 'Police',
                    color: Colors.blue,
                    onTap: () => _tabController.animateTo(2),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AkelDesign.md),

            Row(
              children: [
                Expanded(
                  child: _buildQuickServiceCard(
                    icon: Icons.local_hospital,
                    label: 'Medical',
                    color: AkelDesign.successGreen,
                    onTap: () => _tabController.animateTo(3),
                  ),
                ),
                const SizedBox(width: AkelDesign.md),
                Expanded(
                  child: _buildQuickServiceCard(
                    icon: Icons.campaign,
                    label: 'Broadcast',
                    color: AkelDesign.warningOrange,
                    onTap: () => _tabController.animateTo(6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickServiceCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
      child: FuturisticCard(
        padding: const EdgeInsets.all(AkelDesign.lg),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AkelDesign.md),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: AkelDesign.sm),
            Text(
              label,
              style: AkelDesign.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== FIRE TAB ====================

  Widget _buildFireTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        children: [
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.lg),
            hasGlow: true,
            glowColor: Colors.deepOrange,
            child: Column(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  size: 80,
                  color: Colors.deepOrange,
                ),
                const SizedBox(height: AkelDesign.md),
                Text('FIRE EMERGENCY', style: AkelDesign.h2),
                const SizedBox(height: AkelDesign.sm),
                Text(
                  'Report fires and call fire department',
                  style: AkelDesign.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AkelDesign.lg),
                FuturisticButton(
                  text: 'CALL FIRE DEPARTMENT',
                  icon: Icons.phone,
                  onPressed: _callFireDepartment,
                  color: Colors.deepOrange,
                  isFullWidth: true,
                ),
                const SizedBox(height: AkelDesign.md),
                FuturisticButton(
                  text: 'REPORT FIRE',
                  icon: Icons.edit,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FireEmergencyScreen(),
                      ),
                    );
                  },
                  isOutlined: true,
                  isFullWidth: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.lg),

          _buildInfoCard(
            'Fire Safety Tips',
            FireService.getFireSafetyTips('building'),
            Colors.deepOrange,
          ),
        ],
      ),
    );
  }

  // ==================== POLICE TAB ====================

  Widget _buildPoliceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        children: [
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.lg),
            hasGlow: true,
            glowColor: Colors.blue,
            child: Column(
              children: [
                const Icon(
                  Icons.local_police,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: AkelDesign.md),
                Text('POLICE EMERGENCY', style: AkelDesign.h2),
                const SizedBox(height: AkelDesign.sm),
                Text(
                  'Report crimes and call police',
                  style: AkelDesign.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AkelDesign.lg),
                FuturisticButton(
                  text: 'CALL POLICE',
                  icon: Icons.phone,
                  onPressed: _callPolice,
                  color: Colors.blue,
                  isFullWidth: true,
                ),
                const SizedBox(height: AkelDesign.md),
                FuturisticButton(
                  text: 'REPORT INCIDENT',
                  icon: Icons.edit,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PoliceEmergencyScreen(),
                      ),
                    );
                  },
                  isOutlined: true,
                  isFullWidth: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.lg),

          _buildInfoCard(
            'When to Call Police',
            [
              ' Crime in progress',
              ' Suspicious activity',
              ' Accident with injuries',
              ' Break-in or theft',
              ' Threat to safety',
            ],
            Colors.blue,
          ),
        ],
      ),
    );
  }

  // ==================== MEDICAL TAB ====================

  Widget _buildMedicalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        children: [
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.lg),
            hasGlow: true,
            glowColor: AkelDesign.successGreen,
            child: Column(
              children: [
                const Icon(
                  Icons.local_hospital,
                  size: 80,
                  color: AkelDesign.successGreen,
                ),
                const SizedBox(height: AkelDesign.md),
                Text('MEDICAL EMERGENCY', style: AkelDesign.h2),
                const SizedBox(height: AkelDesign.sm),
                Text(
                  'Call ambulance for medical emergencies',
                  style: AkelDesign.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AkelDesign.lg),
                FuturisticButton(
                  text: 'CALL AMBULANCE',
                  icon: Icons.phone,
                  onPressed: _callAmbulance,
                  color: AkelDesign.successGreen,
                  isFullWidth: true,
                ),
                const SizedBox(height: AkelDesign.md),
                FuturisticButton(
                  text: 'REPORT MEDICAL EMERGENCY',
                  icon: Icons.edit,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AmbulanceEmergencyScreen(),
                      ),
                    );
                  },
                  isOutlined: true,
                  isFullWidth: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.lg),

          _buildInfoCard(
            'Medical Emergencies',
            [
              ' Chest pain or heart attack',
              ' Stroke symptoms',
              ' Severe bleeding',
              ' Loss of consciousness',
              ' Serious injuries',
            ],
            AkelDesign.successGreen,
          ),
        ],
      ),
    );
  }

  // ==================== 911 TAB ====================

  Widget _build911Tab() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            AkelDesign.primaryRed.withValues(alpha: 0.2),
            AkelDesign.deepBlack,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AkelDesign.xl),
          child: FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.xxl),
            hasGlow: true,
            glowColor: AkelDesign.primaryRed,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AkelDesign.primaryRed,
                        AkelDesign.primaryRed.withValues(alpha: 0.5),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AkelDesign.primaryRed.withValues(alpha: 0.6),
                        blurRadius: 40,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '911',
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AkelDesign.xxl),
                Text(
                  'EMERGENCY SERVICES',
                  style: AkelDesign.h1.copyWith(fontSize: 28),
                ),
                const SizedBox(height: AkelDesign.md),
                Text(
                  'Fire • Police • Medical',
                  style: AkelDesign.caption,
                ),
                const SizedBox(height: AkelDesign.xxl),
                FuturisticButton(
                  text: 'CALL 911 NOW',
                  icon: Icons.phone,
                  onPressed: _call911,
                  color: AkelDesign.primaryRed,
                  isFullWidth: true,
                ),
                const SizedBox(height: AkelDesign.lg),
                FuturisticCard(
                  padding: const EdgeInsets.all(AkelDesign.md),
                  child: Text(
                    ' Only use for real emergencies\nFalse reports are illegal',
                    style: AkelDesign.caption.copyWith(
                      color: AkelDesign.warningOrange,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== SOS TAB ====================

  Widget _buildSOSTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        children: [
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.lg),
            hasGlow: _isMorseCodeActive,
            glowColor: AkelDesign.warningOrange,
            child: Column(
              children: [
                const Icon(
                  Icons.flashlight_on,
                  size: 80,
                  color: AkelDesign.warningOrange,
                ),
                const SizedBox(height: AkelDesign.md),
                Text('SOS MORSE CODE', style: AkelDesign.h2),
                const SizedBox(height: AkelDesign.sm),
                Text(
                  _isMorseCodeActive ? 'ACTIVE: ... --- ...' : 'Signal for help with vibration',
                  style: AkelDesign.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AkelDesign.lg),
                FuturisticButton(
                  text: _isMorseCodeActive ? 'STOP SOS' : 'START SOS',
                  icon: _isMorseCodeActive ? Icons.stop : Icons.play_arrow,
                  onPressed: _toggleMorseCode,
                  color: _isMorseCodeActive ? AkelDesign.errorRed : AkelDesign.warningOrange,
                  isFullWidth: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.lg),

          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.lg),
            hasGlow: _isSirenActive,
            glowColor: AkelDesign.primaryRed,
            child: Column(
              children: [
                const Icon(
                  Icons.volume_up,
                  size: 80,
                  color: AkelDesign.primaryRed,
                ),
                const SizedBox(height: AkelDesign.md),
                Text('PANIC SIREN', style: AkelDesign.h2),
                const SizedBox(height: AkelDesign.sm),
                Text(
                  _isSirenActive ? 'SIREN ACTIVE' : 'Activate loud alarm',
                  style: AkelDesign.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AkelDesign.lg),
                FuturisticButton(
                  text: _isSirenActive ? 'STOP SIREN' : 'START SIREN',
                  icon: _isSirenActive ? Icons.volume_off : Icons.volume_up,
                  onPressed: _toggleSiren,
                  color: _isSirenActive ? AkelDesign.errorRed : AkelDesign.primaryRed,
                  isFullWidth: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.lg),

          _buildInfoCard(
            'SOS Information',
            [
              ' Morse Code: ... --- ... (SOS)',
              ' Panic siren alerts nearby people',
              ' Use in dangerous situations',
              ' Attracts attention quickly',
              ' Universal distress signal',
            ],
            AkelDesign.warningOrange,
          ),
        ],
      ),
    );
  }

  // ==================== BROADCAST TAB ====================

  Widget _buildBroadcastTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AkelDesign.xl),
        child: FuturisticCard(
          padding: const EdgeInsets.all(AkelDesign.xxl),
          hasGlow: true,
          glowColor: AkelDesign.warningOrange,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AkelDesign.warningOrange,
                      AkelDesign.warningOrange.withValues(alpha: 0.5),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AkelDesign.warningOrange.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.campaign,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AkelDesign.xl),
              Text('BROADCAST ALERT', style: AkelDesign.h1.copyWith(fontSize: 28)),
              const SizedBox(height: AkelDesign.md),
              Text(
                'Send emergency alert to ALL contacts',
                style: AkelDesign.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AkelDesign.xl),
              FuturisticButton(
                text: 'SEND BROADCAST',
                icon: Icons.campaign,
                onPressed: _broadcastAlert,
                color: AkelDesign.warningOrange,
                isFullWidth: true,
              ),
              const SizedBox(height: AkelDesign.lg),
              FuturisticCard(
                padding: const EdgeInsets.all(AkelDesign.md),
                child: Column(
                  children: [
                    Text(
                      'This will notify:',
                      style: AkelDesign.body.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AkelDesign.sm),
                    Text(
                      '• All emergency contacts\n'
                          '• With your location\n'
                          '• Medical information\n'
                          '• Timestamp',
                      style: AkelDesign.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildInfoCard(String title, List<String> items, Color color) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AkelDesign.xs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
                ),
                child: Icon(Icons.info_outline, color: color, size: 20),
              ),
              const SizedBox(width: AkelDesign.sm),
              Expanded(
                child: Text(
                  title,
                  style: AkelDesign.subtitle.copyWith(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: AkelDesign.md),
          ...items.map(
                (item) => Padding(
              padding: const EdgeInsets.only(bottom: AkelDesign.xs),
              child: Text(item, style: AkelDesign.body.copyWith(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}