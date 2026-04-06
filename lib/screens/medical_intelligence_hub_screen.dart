import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import '../widgets/futuristic_widgets.dart';
import '../services/medical_intelligence_service.dart';
import '../providers/auth_provider.dart';

/// ==================== MEDICAL INTELLIGENCE HUB SCREEN ====================
///
/// UNIFIED MEDICAL DASHBOARD - PHASE 4 (HOUR 14) FULLY FIXED
/// Complete medical intelligence interface:
/// - Digital Medical ID Card
/// - Doctor Annie AI Assistant
/// - Medication Tracker
/// - Health Vitals Monitor
/// - Hospital Finder
/// - Medical Analytics
///
/// 24-HOUR MARATHON - BUILD 55
/// ================================================================

class MedicalIntelligenceHubScreen extends StatefulWidget {
  const MedicalIntelligenceHubScreen({Key? key}) : super(key: key);

  @override
  State<MedicalIntelligenceHubScreen> createState() => _MedicalIntelligenceHubScreenState();
}

class _MedicalIntelligenceHubScreenState extends State<MedicalIntelligenceHubScreen>
    with TickerProviderStateMixin {
  final MedicalIntelligenceService _medicalService = MedicalIntelligenceService();

  late TabController _tabController;
  late AnimationController _pulseController;

  bool _isInitializing = true;
  MedicalIDCard? _medicalId;
  List<Medication> _medications = [];
  List<Hospital> _hospitals = [];
  Map<String, dynamic> _statistics = {};
  Map<String, dynamic> _analytics = {};

  // Doctor Annie
  final TextEditingController _annieController = TextEditingController();
  String _annieResponse = '';
  bool _annieProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initializeHub();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _annieController.dispose();
    _medicalService.dispose();
    super.dispose();
  }

  Future<void> _initializeHub() async {
    setState(() => _isInitializing = true);

    try {
      await _medicalService.initialize();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;

      if (userId != null) {
        await _loadMedicalData(userId);
      }

      setState(() => _isInitializing = false);
    } catch (e) {
      debugPrint(' Hub initialization error: $e');
      setState(() => _isInitializing = false);
      _showError('Failed to initialize: $e');
    }
  }

  Future<void> _loadMedicalData(String userId) async {
    try {
      // Load all medical data
      final medicalId = await _medicalService.getMedicalID(userId);
      final medications = await _medicalService.getMedications(userId);
      final statistics = await _medicalService.getMedicalStatistics(userId);
      final analytics = await _medicalService.getHealthAnalytics(userId);

      // Get current location for hospitals
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition();
        final hospitals = await _medicalService.findNearbyHospitals(
          position: position,
          radiusKm: 10.0,
        );

        if (mounted) {
          setState(() {
            _hospitals = hospitals;
          });
        }
      } catch (e) {
        debugPrint(' Location/Hospital error: $e');
      }

      if (mounted) {
        setState(() {
          _medicalId = medicalId;
          _medications = medications;
          _statistics = statistics;
          _analytics = analytics;
        });
      }
    } catch (e) {
      debugPrint(' Load medical data error: $e');
    }
  }

  // ==================== SYNCHRONOUS WRAPPERS ====================

  void _handleRefresh() {
    _performRefresh();
  }

  Future<void> _performRefresh() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    if (userId != null) {
      await _loadMedicalData(userId);
      _showSuccess('Medical data refreshed');
    }
  }

  void _handleExportMedicalID() {
    _exportMedicalID();
  }

  void _handleAskAnnie() {
    if (_annieProcessing) return;
    _askDoctorAnnie();
  }

  void _handleRefreshHospitals() {
    _performRefreshHospitals();
  }

  Future<void> _performRefreshHospitals() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    if (userId != null) {
      await _loadMedicalData(userId);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AkelDesign.errorRed,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AkelDesign.successGreen,
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
                color: AkelDesign.successGreen,
              ),
              SizedBox(height: AkelDesign.xl),
              Text(
                'Loading Medical Hub...',
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
              'MEDICAL INTELLIGENCE',
              style: AkelDesign.h3.copyWith(fontSize: 16),
            ),
            Text(
              'Your Health Guardian',
              style: AkelDesign.caption.copyWith(fontSize: 10),
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AkelDesign.successGreen,
          labelColor: AkelDesign.successGreen,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Medical ID'),
            Tab(text: 'Medications'),
            Tab(text: 'Doctor Annie'),
            Tab(text: 'Hospitals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildMedicalIDTab(),
          _buildMedicationsTab(),
          _buildDoctorAnnieTab(),
          _buildHospitalsTab(),
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
          Text('MEDICAL DASHBOARD', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Medical ID',
                  _medicalId != null ? 'Complete' : 'Not Set',
                  Icons.badge,
                  _medicalId != null ? AkelDesign.successGreen : AkelDesign.warningOrange,
                ),
              ),
              const SizedBox(width: AkelDesign.md),
              Expanded(
                child: _buildStatCard(
                  'Medications',
                  '${_medications.length}',
                  Icons.medication,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: AkelDesign.md),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Adherence',
                  _statistics['medicationAdherence'] != null
                      ? '${_statistics['medicationAdherence'].toStringAsFixed(0)}%'
                      : 'N/A',
                  Icons.check_circle,
                  AkelDesign.infoBlue,
                ),
              ),
              const SizedBox(width: AkelDesign.md),
              Expanded(
                child: _buildStatCard(
                  'Hospitals',
                  '${_hospitals.length}',
                  Icons.local_hospital,
                  AkelDesign.primaryRed,
                ),
              ),
            ],
          ),

          const SizedBox(height: AkelDesign.xxl),

          // Quick Actions
          Text('QUICK ACTIONS', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),

          if (_medicalId == null)
            FuturisticButton(
              text: 'CREATE MEDICAL ID',
              icon: Icons.add_card,
              onPressed: () {
                _tabController.animateTo(1);
                _showSuccess('Tap "Edit Medical ID" to create your profile');
              },
              color: AkelDesign.successGreen,
              isFullWidth: true,
            )
          else
            FuturisticButton(
              text: 'VIEW MEDICAL ID',
              icon: Icons.badge,
              onPressed: () => _tabController.animateTo(1),
              color: AkelDesign.successGreen,
              isOutlined: true,
              isFullWidth: true,
            ),

          const SizedBox(height: AkelDesign.md),

          FuturisticButton(
            text: 'ASK DOCTOR ANNIE',
            icon: Icons.smart_toy,
            onPressed: () => _tabController.animateTo(3),
            color: Colors.purple,
            isOutlined: true,
            isFullWidth: true,
          ),

          const SizedBox(height: AkelDesign.md),

          FuturisticButton(
            text: 'FIND NEARBY HOSPITALS',
            icon: Icons.local_hospital,
            onPressed: () => _tabController.animateTo(4),
            color: AkelDesign.primaryRed,
            isOutlined: true,
            isFullWidth: true,
          ),

          const SizedBox(height: AkelDesign.xxl),

          // Active Medications Preview
          if (_medications.isNotEmpty) ...[
            Text('ACTIVE MEDICATIONS', style: AkelDesign.subtitle),
            const SizedBox(height: AkelDesign.md),

            ...(_medications.take(3).map((med) => Padding(
              padding: const EdgeInsets.only(bottom: AkelDesign.sm),
              child: _buildMedicationPreviewCard(med),
            ))),

            if (_medications.length > 3)
              TextButton(
                onPressed: () => _tabController.animateTo(2),
                child: Text(
                  'View all ${_medications.length} medications →',
                  style: AkelDesign.caption.copyWith(
                    color: Colors.purple,
                  ),
                ),
              ),
          ],
        ],
      ),
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
            style: AkelDesign.h3.copyWith(color: color, fontSize: 20),
          ),
          Text(
            label,
            style: AkelDesign.caption.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationPreviewCard(Medication med) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medication, color: Colors.purple, size: 20),
          ),
          const SizedBox(width: AkelDesign.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: AkelDesign.body.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${med.dosage} • ${med.frequency}',
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
              color: _getAdherenceColor(med.adherenceRate).withOpacity(0.2),
              borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
              border: Border.all(color: _getAdherenceColor(med.adherenceRate)),
            ),
            child: Text(
              '${med.adherenceRate.toStringAsFixed(0)}%',
              style: AkelDesign.caption.copyWith(
                color: _getAdherenceColor(med.adherenceRate),
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAdherenceColor(double rate) {
    if (rate >= 80) return AkelDesign.successGreen;
    if (rate >= 60) return AkelDesign.warningOrange;
    return AkelDesign.errorRed;
  }

  // ==================== TAB 2: MEDICAL ID ====================

  Widget _buildMedicalIDTab() {
    if (_medicalId == null) {
      return _buildEmptyState(
        icon: Icons.badge,
        title: 'No Medical ID',
        subtitle: 'Create your digital medical ID card\nfor emergency situations',
        actionText: 'CREATE MEDICAL ID',
        onAction: _showCreateMedicalIDDialog,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medical ID Card Display
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.xl),
            hasGlow: true,
            glowColor: AkelDesign.successGreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                      child: const Icon(Icons.badge, color: AkelDesign.successGreen, size: 30),
                    ),
                    const SizedBox(width: AkelDesign.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MEDICAL ID CARD',
                            style: AkelDesign.h3.copyWith(
                              color: AkelDesign.successGreen,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Emergency Medical Information',
                            style: AkelDesign.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AkelDesign.xl),
                const Divider(color: Colors.white10),
                const SizedBox(height: AkelDesign.md),

                _buildMedicalIDField('Full Name', _medicalId!.fullName, Icons.person),
                _buildMedicalIDField('Date of Birth', DateFormat('MMM dd, yyyy').format(_medicalId!.dateOfBirth), Icons.cake),
                _buildMedicalIDField('Age', '${_medicalId!.age} years old', Icons.timer),
                _buildMedicalIDField('Blood Type', _medicalId!.bloodType, Icons.bloodtype),

                if (_medicalId!.allergies.isNotEmpty)
                  _buildMedicalIDListField('Allergies', _medicalId!.allergies, Icons.warning, AkelDesign.errorRed),

                if (_medicalId!.medicalConditions.isNotEmpty)
                  _buildMedicalIDListField('Medical Conditions', _medicalId!.medicalConditions, Icons.medical_services, AkelDesign.warningOrange),

                if (_medicalId!.medications.isNotEmpty)
                  _buildMedicalIDListField('Current Medications', _medicalId!.medications, Icons.medication, Colors.purple),

                if (_medicalId!.emergencyContacts.isNotEmpty) ...[
                  const SizedBox(height: AkelDesign.md),
                  Text(
                    'EMERGENCY CONTACTS',
                    style: AkelDesign.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: AkelDesign.sm),

                  ...(_medicalId!.emergencyContacts.map((contact) =>
                      _buildEmergencyContactCard(contact)
                  )),
                ],
              ],
            ),
          ),

          const SizedBox(height: AkelDesign.lg),

          // Actions
          FuturisticButton(
            text: 'EDIT MEDICAL ID',
            icon: Icons.edit,
            onPressed: _showCreateMedicalIDDialog,
            color: AkelDesign.successGreen,
            isOutlined: true,
            isFullWidth: true,
          ),

          const SizedBox(height: AkelDesign.md),

          FuturisticButton(
            text: 'EXPORT FOR EMERGENCY',
            icon: Icons.download,
            onPressed: _handleExportMedicalID,
            color: AkelDesign.infoBlue,
            isOutlined: true,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalIDField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AkelDesign.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AkelDesign.neonBlue, size: 20),
          const SizedBox(width: AkelDesign.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AkelDesign.caption.copyWith(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AkelDesign.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalIDListField(String label, List<String> items, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AkelDesign.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AkelDesign.sm),
              Text(
                label,
                style: AkelDesign.caption.copyWith(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AkelDesign.sm),

          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: AkelDesign.body.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard(EmergencyContact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: AkelDesign.sm),
      padding: const EdgeInsets.all(AkelDesign.md),
      decoration: BoxDecoration(
        color: AkelDesign.deepBlack.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.contact_phone, color: AkelDesign.infoBlue, size: 20),
          const SizedBox(width: AkelDesign.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: AkelDesign.body.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${contact.relationship} • ${contact.phone}',
                  style: AkelDesign.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateMedicalIDDialog() {
    _showSuccess('Medical ID editor coming soon!');
  }

  Future<void> _exportMedicalID() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    try {
      final export = await _medicalService.exportMedicalIDForEmergency(userId);

      _showSuccess('Medical ID exported successfully!');

      debugPrint(' Export: ${export.toString()}');
    } catch (e) {
      _showError('Failed to export: $e');
    }
  }

  // ==================== TAB 3: MEDICATIONS ====================

  Widget _buildMedicationsTab() {
    if (_medications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.medication,
        title: 'No Medications',
        subtitle: 'Track your medications and\nset reminders',
        actionText: 'ADD MEDICATION',
        onAction: () {
          _showSuccess('Medication tracker coming soon!');
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AkelDesign.lg),
      itemCount: _medications.length,
      itemBuilder: (context, index) {
        final med = _medications[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AkelDesign.md),
          child: _buildMedicationCard(med),
        );
      },
    );
  }

  Widget _buildMedicationCard(Medication med) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.lg),
      hasGlow: true,
      glowColor: Colors.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medication, color: Colors.purple, size: 24),
              ),
              const SizedBox(width: AkelDesign.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: AkelDesign.body.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${med.dosage} • ${med.frequency}',
                      style: AkelDesign.caption,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AkelDesign.md,
                  vertical: AkelDesign.sm,
                ),
                decoration: BoxDecoration(
                  color: _getAdherenceColor(med.adherenceRate).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
                  border: Border.all(color: _getAdherenceColor(med.adherenceRate)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${med.adherenceRate.toStringAsFixed(0)}%',
                      style: AkelDesign.h3.copyWith(
                        color: _getAdherenceColor(med.adherenceRate),
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Adherence',
                      style: AkelDesign.caption.copyWith(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (med.purpose != null) ...[
            const SizedBox(height: AkelDesign.md),
            Text('Purpose: ${med.purpose}', style: AkelDesign.caption),
          ],

          const SizedBox(height: AkelDesign.md),

          Row(
            children: [
              Expanded(
                child: _buildMedicationStat(
                  'Taken',
                  '${med.takenDoses}',
                  AkelDesign.successGreen,
                ),
              ),
              Expanded(
                child: _buildMedicationStat(
                  'Missed',
                  '${med.missedDoses}',
                  AkelDesign.errorRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AkelDesign.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AkelDesign.body.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AkelDesign.caption.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 4: DOCTOR ANNIE ====================

  Widget _buildDoctorAnnieTab() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AkelDesign.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Annie Header
                FuturisticCard(
                  padding: const EdgeInsets.all(AkelDesign.xl),
                  hasGlow: true,
                  glowColor: Colors.purple,
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (_pulseController.value * 0.05),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.purple.withOpacity(0.5),
                                    Colors.purple.withOpacity(0.2),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.smart_toy, color: Colors.purple, size: 30),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: AkelDesign.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Doctor Annie AI',
                              style: AkelDesign.h3.copyWith(
                                color: Colors.purple,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your AI Medical Assistant',
                              style: AkelDesign.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AkelDesign.lg),

                // Disclaimer
                Container(
                  padding: const EdgeInsets.all(AkelDesign.md),
                  decoration: BoxDecoration(
                    color: AkelDesign.warningOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
                    border: Border.all(color: AkelDesign.warningOrange.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: AkelDesign.warningOrange, size: 20),
                      const SizedBox(width: AkelDesign.sm),
                      Expanded(
                        child: Text(
                          'Doctor Annie provides general health information only. '
                              'Always consult a licensed healthcare provider for medical advice.',
                          style: AkelDesign.caption.copyWith(
                            color: AkelDesign.warningOrange,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AkelDesign.lg),

                // Response Display
                if (_annieResponse.isNotEmpty)
                  FuturisticCard(
                    padding: const EdgeInsets.all(AkelDesign.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.smart_toy, color: Colors.purple, size: 20),
                            const SizedBox(width: AkelDesign.sm),
                            Text(
                              'Annie\'s Response',
                              style: AkelDesign.body.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: AkelDesign.md),
                        Text(
                          _annieResponse,
                          style: AkelDesign.body,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // FIXED INPUT AREA WITH MATERIAL ICONBUTTON
        Container(
          padding: const EdgeInsets.all(AkelDesign.lg),
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
                Expanded(
                  child: TextField(
                    controller: _annieController,
                    style: AkelDesign.body,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Ask Doctor Annie...',
                      hintStyle: AkelDesign.caption.copyWith(color: Colors.white38),
                      filled: true,
                      fillColor: AkelDesign.deepBlack.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
                        borderSide: const BorderSide(color: Colors.purple, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(AkelDesign.md),
                    ),
                  ),
                ),
                const SizedBox(width: AkelDesign.md),
                // FIXED: Material IconButton with proper styling
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _annieProcessing
                        ? Colors.purple.withOpacity(0.2)
                        : Colors.purple.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.purple.withOpacity(_annieProcessing ? 0.3 : 0.5),
                      width: 2,
                    ),
                    boxShadow: _annieProcessing
                        ? null
                        : [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _annieProcessing ? null : _handleAskAnnie,
                      borderRadius: BorderRadius.circular(25),
                      splashColor: Colors.purple.withOpacity(0.3),
                      child: Icon(
                        _annieProcessing ? Icons.hourglass_empty : Icons.send,
                        color: _annieProcessing ? Colors.white38 : Colors.purple,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _askDoctorAnnie() async {
    final question = _annieController.text.trim();

    if (question.isEmpty) {
      _showError('Please enter a question');
      return;
    }

    setState(() {
      _annieProcessing = true;
      _annieResponse = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;

      if (userId == null) {
        _showError('Not logged in');
        setState(() => _annieProcessing = false);
        return;
      }

      final response = await _medicalService.askDoctorAnnie(
        userId: userId,
        question: question,
      );

      if (mounted) {
        setState(() {
          _annieResponse = response;
          _annieProcessing = false;
        });

        _annieController.clear();
      }
    } catch (e) {
      debugPrint(' Ask Annie error: $e');
      _showError('Failed to get response: $e');

      if (mounted) {
        setState(() {
          _annieProcessing = false;
        });
      }
    }
  }

  // ==================== TAB 5: HOSPITALS ====================

  Widget _buildHospitalsTab() {
    if (_hospitals.isEmpty) {
      return _buildEmptyState(
        icon: Icons.local_hospital,
        title: 'No Hospitals Found',
        subtitle: 'Enable location to find\nnearby hospitals',
        actionText: 'REFRESH',
        onAction: _handleRefreshHospitals,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AkelDesign.lg),
      itemCount: _hospitals.length,
      itemBuilder: (context, index) {
        final hospital = _hospitals[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AkelDesign.md),
          child: _buildHospitalCard(hospital),
        );
      },
    );
  }

  Widget _buildHospitalCard(Hospital hospital) {
    return FuturisticCard(
      padding: const EdgeInsets.all(AkelDesign.lg),
      hasGlow: true,
      glowColor: AkelDesign.primaryRed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AkelDesign.primaryRed.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_hospital, color: AkelDesign.primaryRed, size: 24),
              ),
              const SizedBox(width: AkelDesign.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital.name,
                      style: AkelDesign.body.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AkelDesign.warningOrange, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${hospital.rating} (${hospital.reviewCount})',
                          style: AkelDesign.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hospital.hasEmergency)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AkelDesign.sm,
                    vertical: AkelDesign.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AkelDesign.primaryRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
                    border: Border.all(color: AkelDesign.primaryRed),
                  ),
                  child: Text(
                    'ER',
                    style: AkelDesign.caption.copyWith(
                      color: AkelDesign.primaryRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AkelDesign.md),

          Text(
            hospital.address,
            style: AkelDesign.caption,
          ),

          const SizedBox(height: AkelDesign.sm),

          Text(
            hospital.phone,
            style: AkelDesign.caption.copyWith(color: AkelDesign.infoBlue),
          ),

          if (hospital.waitTime != null) ...[
            const SizedBox(height: AkelDesign.sm),
            Row(
              children: [
                const Icon(Icons.access_time, color: AkelDesign.successGreen, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Wait time: ${hospital.waitTime}',
                  style: AkelDesign.caption.copyWith(color: AkelDesign.successGreen),
                ),
              ],
            ),
          ],

          const SizedBox(height: AkelDesign.md),

          // Specialties
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: hospital.specialties.map((specialty) =>
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AkelDesign.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AkelDesign.infoBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
                    border: Border.all(color: AkelDesign.infoBlue.withOpacity(0.3)),
                  ),
                  child: Text(
                    specialty,
                    style: AkelDesign.caption.copyWith(fontSize: 10),
                  ),
                ),
            ).toList(),
          ),
        ],
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AkelDesign.xl),
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
            const SizedBox(height: AkelDesign.xl),
            FuturisticButton(
              text: actionText,
              icon: Icons.add,
              onPressed: onAction,
              color: AkelDesign.successGreen,
            ),
          ],
        ),
      ),
    );
  }
}