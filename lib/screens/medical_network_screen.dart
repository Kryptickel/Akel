import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../core/constants/themes/utils/akel_design_system.dart';
import '../widgets/futuristic_widgets.dart';
import '../providers/auth_provider.dart';
import '../services/medical_intelligence_service.dart';

/// ==================== MEDICAL NETWORK SCREEN ====================
///
/// HOUR 6 - MEDICAL NETWORK UI
/// Built on top of MedicalIntelligenceService
/// - Tab 1: Medical ID Card (view, edit, share)
/// - Tab 2: Medications (list, add, mark taken/missed)
/// - Tab 3: Health Vitals (record, view trends)
/// - Tab 4: Hospital Network (nearby, call, directions)
/// - Tab 5: Doctor Annie AI (symptom checker, advice)
///
/// ================================================================

class MedicalNetworkScreen extends StatefulWidget {
  const MedicalNetworkScreen({Key? key}) : super(key: key);

  @override
  State<MedicalNetworkScreen> createState() => _MedicalNetworkScreenState();
}

class _MedicalNetworkScreenState extends State<MedicalNetworkScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MedicalIntelligenceService _service = MedicalIntelligenceService();
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initService();
  }

  Future<void> _initService() async {
    await _service.initialize();
    if (mounted) setState(() => _isInitializing = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _service.dispose();
    super.dispose();
  }

  String? get _userId {
    final auth = FirebaseAuth.instance.currentUser;
    return auth?.uid;
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
              FuturisticLoadingIndicator(size: 60, color: Colors.red),
              SizedBox(height: AkelDesign.xl),
              Text('Loading Medical Network...', style: TextStyle(color: Colors.white70, fontSize: 16)),
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
            Text('MEDICAL NETWORK', style: AkelDesign.h3.copyWith(fontSize: 16)),
            Text('Health Intelligence System', style: AkelDesign.caption.copyWith(fontSize: 10)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.red,
          labelColor: Colors.red,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.badge), text: 'Medical ID'),
            Tab(icon: Icon(Icons.medication), text: 'Medications'),
            Tab(icon: Icon(Icons.monitor_heart), text: 'Vitals'),
            Tab(icon: Icon(Icons.local_hospital), text: 'Hospitals'),
            Tab(icon: Icon(Icons.psychology), text: 'Dr. Annie'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MedicalIDTab(service: _service, userId: _userId),
          _MedicationsTab(service: _service, userId: _userId),
          _VitalsTab(service: _service, userId: _userId),
          _HospitalsTab(service: _service),
          _DoctorAnnieTab(service: _service, userId: _userId),
        ],
      ),
    );
  }
}

// ==================== TAB 1: MEDICAL ID ====================

class _MedicalIDTab extends StatefulWidget {
  final MedicalIntelligenceService service;
  final String? userId;
  const _MedicalIDTab({required this.service, required this.userId});

  @override
  State<_MedicalIDTab> createState() => _MedicalIDTabState();
}

class _MedicalIDTabState extends State<_MedicalIDTab> {
  MedicalIDCard? _medicalId;
  bool _isLoading = true;
  bool _isEditing = false;

  final _nameController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _insuranceController = TextEditingController();
  final _insuranceNumberController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _dateOfBirth = DateTime(1990, 1, 1);
  String _organDonor = 'No';

  static const List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'];
  static const List<String> _organDonorOptions = ['Yes', 'No', 'Undecided'];

  @override
  void initState() {
    super.initState();
    _loadMedicalId();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _medicationsController.dispose();
    _insuranceController.dispose();
    _insuranceNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicalId() async {
    if (widget.userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final id = await widget.service.getMedicalID(widget.userId!);
    if (mounted) {
      setState(() {
        _medicalId = id;
        _isLoading = false;
        if (id != null) _populateControllers(id);
      });
    }
  }

  void _populateControllers(MedicalIDCard id) {
    _nameController.text = id.fullName;
    _bloodTypeController.text = id.bloodType;
    _allergiesController.text = id.allergies.join(', ');
    _conditionsController.text = id.medicalConditions.join(', ');
    _medicationsController.text = id.medications.join(', ');
    _insuranceController.text = id.insuranceProvider ?? '';
    _insuranceNumberController.text = id.insuranceNumber ?? '';
    _notesController.text = id.additionalNotes ?? '';
    _dateOfBirth = id.dateOfBirth;
    _organDonor = id.organDonor ?? 'No';
  }

  Future<void> _saveMedicalId() async {
    if (widget.userId == null) return;
    try {
      await widget.service.saveMedicalID(
        userId: widget.userId!,
        fullName: _nameController.text.trim(),
        dateOfBirth: _dateOfBirth,
        bloodType: _bloodTypeController.text.trim(),
        allergies: _allergiesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        medicalConditions: _conditionsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        medications: _medicationsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        emergencyContacts: _medicalId?.emergencyContacts ?? [],
        organDonor: _organDonor,
        insuranceProvider: _insuranceController.text.trim().isEmpty ? null : _insuranceController.text.trim(),
        insuranceNumber: _insuranceNumberController.text.trim().isEmpty ? null : _insuranceNumberController.text.trim(),
        additionalNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      await _loadMedicalId();
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medical ID saved'), backgroundColor: AkelDesign.successGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ' + e.toString()), backgroundColor: AkelDesign.errorRed),
        );
      }
    }
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark(),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: FuturisticLoadingIndicator(size: 40, color: Colors.red));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: _isEditing ? _buildEditForm() : _buildIdCard(),
    );
  }

  Widget _buildIdCard() {
    if (_medicalId == null) {
      return Column(
        children: [
          const SizedBox(height: AkelDesign.xl),
          const Icon(Icons.badge, size: 80, color: Colors.white24),
          const SizedBox(height: AkelDesign.lg),
          Text('No Medical ID', style: AkelDesign.h3.copyWith(color: Colors.white60)),
          const SizedBox(height: AkelDesign.sm),
          Text('Create your digital medical ID for emergencies', style: AkelDesign.caption, textAlign: TextAlign.center),
          const SizedBox(height: AkelDesign.xl),
          FuturisticButton(
            text: 'CREATE MEDICAL ID',
            icon: Icons.add,
            onPressed: () => setState(() => _isEditing = true),
            color: Colors.red,
            isFullWidth: true,
          ),
        ],
      );
    }

    final id = _medicalId!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ID Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AkelDesign.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[900]!, Colors.red[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
            boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.medical_services, color: Colors.white, size: 28),
                  const SizedBox(width: AkelDesign.sm),
                  Text('MEDICAL ID', style: AkelDesign.h3.copyWith(color: Colors.white, letterSpacing: 2)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AkelDesign.sm, vertical: AkelDesign.xs),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
                    ),
                    child: Text(id.bloodType, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: AkelDesign.lg),
              Text(id.fullName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text('Age: ' + id.age.toString() + ' | DOB: ' + _formatDate(id.dateOfBirth), style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
              const SizedBox(height: AkelDesign.lg),
              if (id.allergies.isNotEmpty) ...[
                _buildIdRow('ALLERGIES', id.allergies.join(', '), Colors.yellow),
              ],
              if (id.medicalConditions.isNotEmpty) ...[
                const SizedBox(height: AkelDesign.sm),
                _buildIdRow('CONDITIONS', id.medicalConditions.join(', '), Colors.orange),
              ],
              const SizedBox(height: AkelDesign.md),
              Row(
                children: [
                  const Icon(Icons.volunteer_activism, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text('Organ Donor: ' + (id.organDonor ?? 'Not specified'), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AkelDesign.lg),

        Row(
          children: [
            Expanded(
              child: FuturisticButton(
                text: 'EDIT ID',
                icon: Icons.edit,
                onPressed: () => setState(() => _isEditing = true),
                color: Colors.red,
                isOutlined: true,
              ),
            ),
            const SizedBox(width: AkelDesign.md),
            Expanded(
              child: FuturisticButton(
                text: 'SHARE',
                icon: Icons.share,
                onPressed: _shareId,
                color: Colors.orange,
                isOutlined: true,
              ),
            ),
          ],
        ),

        const SizedBox(height: AkelDesign.xl),

        if (id.medications.isNotEmpty) ...[
          Text('CURRENT MEDICATIONS', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),
          Wrap(
            spacing: AkelDesign.sm,
            runSpacing: AkelDesign.sm,
            children: id.medications.map((m) => _buildChip(m, Colors.blue)).toList(),
          ),
          const SizedBox(height: AkelDesign.lg),
        ],

        if (id.insuranceProvider != null) ...[
          Text('INSURANCE', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.md),
            child: Row(
              children: [
                const Icon(Icons.health_and_safety, color: Colors.green, size: 24),
                const SizedBox(width: AkelDesign.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(id.insuranceProvider!, style: AkelDesign.body.copyWith(fontWeight: FontWeight.bold)),
                    if (id.insuranceNumber != null)
                      Text('ID: ' + id.insuranceNumber!, style: AkelDesign.caption),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AkelDesign.lg),
        ],

        if (id.additionalNotes != null && id.additionalNotes!.isNotEmpty) ...[
          Text('NOTES', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.md),
          FuturisticCard(
            padding: const EdgeInsets.all(AkelDesign.md),
            child: Text(id.additionalNotes!, style: AkelDesign.body),
          ),
        ],
      ],
    );
  }

  Widget _buildIdRow(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AkelDesign.md, vertical: AkelDesign.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('EDIT MEDICAL ID', style: AkelDesign.subtitle),
        const SizedBox(height: AkelDesign.lg),

        _buildField('Full Name', _nameController, Icons.person),
        const SizedBox(height: AkelDesign.md),

        // Date of birth picker
        GestureDetector(
          onTap: _pickDateOfBirth,
          child: Container(
            padding: const EdgeInsets.all(AkelDesign.md),
            decoration: BoxDecoration(
              color: AkelDesign.darkPanel,
              borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake, color: Colors.white54, size: 20),
                const SizedBox(width: AkelDesign.md),
                Text('Date of Birth: ' + _formatDate(_dateOfBirth), style: AkelDesign.body),
                const Spacer(),
                const Icon(Icons.edit, color: Colors.white38, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: AkelDesign.md),

        // Blood type dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AkelDesign.md),
          decoration: BoxDecoration(
            color: AkelDesign.darkPanel,
            borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
            border: Border.all(color: Colors.white24),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _bloodTypes.contains(_bloodTypeController.text) ? _bloodTypeController.text : 'Unknown',
              dropdownColor: AkelDesign.darkPanel,
              isExpanded: true,
              hint: const Text('Blood Type', style: TextStyle(color: Colors.white54)),
              items: _bloodTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: AkelDesign.body))).toList(),
              onChanged: (val) => setState(() => _bloodTypeController.text = val ?? 'Unknown'),
            ),
          ),
        ),
        const SizedBox(height: AkelDesign.md),

        _buildField('Allergies (comma separated)', _allergiesController, Icons.warning, maxLines: 2),
        const SizedBox(height: AkelDesign.md),
        _buildField('Medical Conditions (comma separated)', _conditionsController, Icons.medical_services, maxLines: 2),
        const SizedBox(height: AkelDesign.md),
        _buildField('Current Medications (comma separated)', _medicationsController, Icons.medication, maxLines: 2),
        const SizedBox(height: AkelDesign.md),
        _buildField('Insurance Provider', _insuranceController, Icons.health_and_safety),
        const SizedBox(height: AkelDesign.md),
        _buildField('Insurance Number', _insuranceNumberController, Icons.numbers),
        const SizedBox(height: AkelDesign.md),

        // Organ donor dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AkelDesign.md),
          decoration: BoxDecoration(
            color: AkelDesign.darkPanel,
            borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
            border: Border.all(color: Colors.white24),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _organDonor,
              dropdownColor: AkelDesign.darkPanel,
              isExpanded: true,
              hint: const Text('Organ Donor', style: TextStyle(color: Colors.white54)),
              items: _organDonorOptions.map((o) => DropdownMenuItem(value: o, child: Text(o, style: AkelDesign.body))).toList(),
              onChanged: (val) => setState(() => _organDonor = val ?? 'No'),
            ),
          ),
        ),
        const SizedBox(height: AkelDesign.md),
        _buildField('Additional Notes', _notesController, Icons.note, maxLines: 3),
        const SizedBox(height: AkelDesign.xl),

        Row(
          children: [
            Expanded(
              child: FuturisticButton(
                text: 'CANCEL',
                onPressed: () => setState(() => _isEditing = false),
                isOutlined: true,
              ),
            ),
            const SizedBox(width: AkelDesign.md),
            Expanded(
              child: FuturisticButton(
                text: 'SAVE ID',
                icon: Icons.save,
                onPressed: _saveMedicalId,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: AkelDesign.xl),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: AkelDesign.body,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AkelDesign.caption,
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: AkelDesign.darkPanel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AkelDesign.radiusMd), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AkelDesign.radiusMd), borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AkelDesign.radiusMd), borderSide: const BorderSide(color: Colors.red)),
      ),
    );
  }

  void _shareId() async {
    if (widget.userId == null) return;
    final data = await widget.service.exportMedicalIDForEmergency(widget.userId!);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        title: Text('Emergency Medical Info', style: AkelDesign.h3),
        content: SingleChildScrollView(
          child: Text(
            'Name: ' + (data['fullName'] ?? '') + '\n' +
                'Blood Type: ' + (_medicalId?.bloodType ?? '') + '\n' +
                'Allergies: ' + ((_medicalId?.allergies ?? []).join(', ')) + '\n' +
                'Conditions: ' + ((_medicalId?.medicalConditions ?? []).join(', ')),
            style: AkelDesign.body,
          ),
        ),
        actions: [
          FuturisticButton(text: 'CLOSE', onPressed: () => Navigator.pop(context), isSmall: true),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return date.day.toString().padLeft(2, '0') + '/' + date.month.toString().padLeft(2, '0') + '/' + date.year.toString();
  }
}

// ==================== TAB 2: MEDICATIONS ====================

class _MedicationsTab extends StatefulWidget {
  final MedicalIntelligenceService service;
  final String? userId;
  const _MedicationsTab({required this.service, required this.userId});

  @override
  State<_MedicationsTab> createState() => _MedicationsTabState();
}

class _MedicationsTabState extends State<_MedicationsTab> {
  List<Medication> _medications = [];
  bool _isLoading = true;

  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _purposeController = TextEditingController();
  final _prescribedByController = TextEditingController();
  String _frequency = 'Once daily';

  static const List<String> _frequencies = [
    'Once daily', 'Twice daily', 'Three times daily',
    'Four times daily', 'Every 8 hours', 'Every 12 hours',
    'Weekly', 'As needed'
  ];

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _purposeController.dispose();
    _prescribedByController.dispose();
    super.dispose();
  }

  Future<void> _loadMedications() async {
    if (widget.userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final meds = await widget.service.getMedications(widget.userId!);
    if (mounted) setState(() { _medications = meds; _isLoading = false; });
  }

  Future<void> _addMedication() async {
    if (widget.userId == null || _nameController.text.trim().isEmpty) return;
    await widget.service.addMedication(
      userId: widget.userId!,
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      frequency: _frequency,
      reminderTimes: ['08:00', '20:00'],
      purpose: _purposeController.text.trim().isEmpty ? null : _purposeController.text.trim(),
      prescribedBy: _prescribedByController.text.trim().isEmpty ? null : _prescribedByController.text.trim(),
    );
    _nameController.clear();
    _dosageController.clear();
    _purposeController.clear();
    _prescribedByController.clear();
    Navigator.pop(context);
    await _loadMedications();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        title: Text('Add Medication', style: AkelDesign.h3),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField('Medication Name *', _nameController, Icons.medication),
              const SizedBox(height: AkelDesign.md),
              _buildDialogField('Dosage (e.g. 10mg)', _dosageController, Icons.science),
              const SizedBox(height: AkelDesign.md),
              _buildDialogField('Purpose', _purposeController, Icons.info_outline),
              const SizedBox(height: AkelDesign.md),
              _buildDialogField('Prescribed By', _prescribedByController, Icons.person),
              const SizedBox(height: AkelDesign.md),
              StatefulBuilder(
                builder: (context, setDropState) => DropdownButtonFormField<String>(
                  value: _frequency,
                  dropdownColor: AkelDesign.darkPanel,
                  style: AkelDesign.body,
                  decoration: InputDecoration(
                    labelText: 'Frequency',
                    labelStyle: AkelDesign.caption,
                    prefixIcon: const Icon(Icons.schedule, color: Colors.white38, size: 20),
                    filled: true,
                    fillColor: AkelDesign.carbonFiber,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AkelDesign.radiusMd), borderSide: BorderSide.none),
                  ),
                  items: _frequencies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (val) { setDropState(() {}); setState(() => _frequency = val ?? _frequency); },
                ),
              ),
            ],
          ),
        ),
        actions: [
          FuturisticButton(text: 'CANCEL', onPressed: () => Navigator.pop(context), isOutlined: true, isSmall: true),
          FuturisticButton(text: 'ADD', icon: Icons.add, onPressed: _addMedication, color: Colors.blue, isSmall: true),
        ],
      ),
    );
  }

  TextField _buildDialogField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      style: AkelDesign.body,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AkelDesign.caption,
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: AkelDesign.carbonFiber,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AkelDesign.radiusMd), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: FuturisticLoadingIndicator(size: 40, color: Colors.blue));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MY MEDICATIONS', style: AkelDesign.subtitle),
              FuturisticIconButton(icon: Icons.add, onPressed: _showAddDialog, size: 36),
            ],
          ),
          const SizedBox(height: AkelDesign.lg),

          if (_medications.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: AkelDesign.xl),
                  const Icon(Icons.medication_liquid, size: 64, color: Colors.white24),
                  const SizedBox(height: AkelDesign.md),
                  Text('No medications added', style: AkelDesign.caption),
                  const SizedBox(height: AkelDesign.lg),
                  FuturisticButton(text: 'ADD MEDICATION', icon: Icons.add, onPressed: _showAddDialog, color: Colors.blue),
                ],
              ),
            )
          else
            ..._medications.map((med) {
              final adherence = med.adherenceRate;
              final adherenceColor = adherence >= 80 ? Colors.green : adherence >= 50 ? Colors.orange : Colors.red;
              return Padding(
                padding: const EdgeInsets.only(bottom: AkelDesign.md),
                child: FuturisticCard(
                  padding: const EdgeInsets.all(AkelDesign.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AkelDesign.sm),
                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.medication, color: Colors.blue, size: 24),
                          ),
                          const SizedBox(width: AkelDesign.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(med.name, style: AkelDesign.body.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(med.dosage + ' — ' + med.frequency, style: AkelDesign.caption),
                                if (med.purpose != null) Text(med.purpose!, style: AkelDesign.caption.copyWith(color: Colors.blue)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(adherence.toStringAsFixed(0) + '%', style: AkelDesign.body.copyWith(color: adherenceColor, fontWeight: FontWeight.bold)),
                              Text('adherence', style: AkelDesign.caption.copyWith(fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AkelDesign.md),
                      LinearProgressIndicator(
                        value: adherence / 100,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(adherenceColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: AkelDesign.md),
                      Row(
                        children: [
                          Expanded(
                            child: FuturisticButton(
                              text: 'TAKEN',
                              icon: Icons.check_circle,
                              onPressed: () async {
                                await widget.service.recordMedicationTaken(med.id);
                                await _loadMedications();
                              },
                              color: Colors.green,
                              isSmall: true,
                              isOutlined: true,
                            ),
                          ),
                          const SizedBox(width: AkelDesign.sm),
                          Expanded(
                            child: FuturisticButton(
                              text: 'MISSED',
                              icon: Icons.cancel,
                              onPressed: () async {
                                await widget.service.recordMedicationMissed(med.id);
                                await _loadMedications();
                              },
                              color: Colors.red,
                              isSmall: true,
                              isOutlined: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

// ==================== TAB 3: VITALS ====================

class _VitalsTab extends StatefulWidget {
  final MedicalIntelligenceService service;
  final String? userId;
  const _VitalsTab({required this.service, required this.userId});

  @override
  State<_VitalsTab> createState() => _VitalsTabState();
}

class _VitalsTabState extends State<_VitalsTab> {
  List<HealthVital> _vitals = [];
  bool _isLoading = true;
  VitalType _selectedType = VitalType.heartRate;
  final _valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVitals();
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _loadVitals() async {
    if (widget.userId == null) { setState(() => _isLoading = false); return; }
    final vitals = await widget.service.getHealthVitals(widget.userId!);
    if (mounted) setState(() { _vitals = vitals; _isLoading = false; });
  }

  Future<void> _recordVital() async {
    if (widget.userId == null || _valueController.text.trim().isEmpty) return;
    final value = double.tryParse(_valueController.text.trim());
    if (value == null) return;

    await widget.service.recordHealthVital(
      userId: widget.userId!,
      type: _selectedType,
      value: value,
    );
    _valueController.clear();
    Navigator.pop(context);
    await _loadVitals();
  }

  void _showRecordDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AkelDesign.darkPanel,
          title: Text('Record Vital', style: AkelDesign.h3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<VitalType>(
                value: _selectedType,
                dropdownColor: AkelDesign.darkPanel,
                style: AkelDesign.body,
                decoration: InputDecoration(
                  labelText: 'Vital Type',
                  labelStyle: AkelDesign.caption,
                  filled: true,
                  fillColor: AkelDesign.carbonFiber,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AkelDesign.radiusMd), borderSide: BorderSide.none),
                ),
                items: VitalType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
                onChanged: (val) { setDialogState(() {}); setState(() => _selectedType = val ?? _selectedType); },
              ),
              const SizedBox(height: AkelDesign.md),
              TextField(
                controller: _valueController,
                keyboardType: TextInputType.number,
                style: AkelDesign.body,
                decoration: InputDecoration(
                  labelText: 'Value (' + _selectedType.defaultUnit + ')',
                  labelStyle: AkelDesign.caption,
                  prefixIcon: Icon(_selectedType.icon, color: Colors.white38, size: 20),
                  filled: true,
                  fillColor: AkelDesign.carbonFiber,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AkelDesign.radiusMd), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            FuturisticButton(text: 'CANCEL', onPressed: () => Navigator.pop(context), isOutlined: true, isSmall: true),
            FuturisticButton(text: 'RECORD', icon: Icons.save, onPressed: _recordVital, color: Colors.teal, isSmall: true),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: FuturisticLoadingIndicator(size: 40, color: Colors.teal));

    // Get latest reading per vital type
    final latestVitals = <VitalType, HealthVital>{};
    for (final v in _vitals) {
      if (!latestVitals.containsKey(v.type)) latestVitals[v.type] = v;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('HEALTH VITALS', style: AkelDesign.subtitle),
              FuturisticIconButton(icon: Icons.add, onPressed: _showRecordDialog, size: 36),
            ],
          ),
          const SizedBox(height: AkelDesign.lg),

          // Vitals grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AkelDesign.md,
            mainAxisSpacing: AkelDesign.md,
            childAspectRatio: 1.4,
            children: VitalType.values.map((type) {
              final latest = latestVitals[type];
              final color = _getVitalColor(type);
              return FuturisticCard(
                padding: const EdgeInsets.all(AkelDesign.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(type.icon, color: color, size: 24),
                    const SizedBox(height: AkelDesign.xs),
                    Text(
                      latest != null ? latest.value.toStringAsFixed(0) + ' ' + latest.unit : '--',
                      style: AkelDesign.body.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(type.displayName, style: AkelDesign.caption.copyWith(fontSize: 10), textAlign: TextAlign.center),
                  ],
                ),
              );
            }).toList(),
          ),

          if (_vitals.isNotEmpty) ...[
            const SizedBox(height: AkelDesign.xl),
            Text('RECENT READINGS', style: AkelDesign.subtitle),
            const SizedBox(height: AkelDesign.md),
            ..._vitals.take(10).map((v) => Padding(
              padding: const EdgeInsets.only(bottom: AkelDesign.sm),
              child: FuturisticCard(
                padding: const EdgeInsets.all(AkelDesign.md),
                child: Row(
                  children: [
                    Icon(v.type.icon, color: _getVitalColor(v.type), size: 20),
                    const SizedBox(width: AkelDesign.md),
                    Expanded(child: Text(v.type.displayName, style: AkelDesign.body)),
                    Text(v.value.toStringAsFixed(1) + ' ' + v.unit, style: AkelDesign.body.copyWith(color: _getVitalColor(v.type), fontWeight: FontWeight.bold)),
                    const SizedBox(width: AkelDesign.md),
                    Text(_formatTime(v.timestamp), style: AkelDesign.caption.copyWith(fontSize: 10)),
                  ],
                ),
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Color _getVitalColor(VitalType type) {
    switch (type) {
      case VitalType.heartRate: return Colors.red;
      case VitalType.bloodPressureSystolic: case VitalType.bloodPressureDiastolic: return Colors.orange;
      case VitalType.temperature: return Colors.yellow;
      case VitalType.oxygenSaturation: return Colors.blue;
      case VitalType.bloodSugar: return Colors.purple;
      case VitalType.weight: return Colors.teal;
      case VitalType.height: return Colors.green;
    }
  }

  String _formatTime(DateTime dt) {
    return dt.hour.toString().padLeft(2, '0') + ':' + dt.minute.toString().padLeft(2, '0');
  }
}

// ==================== TAB 4: HOSPITALS ====================

class _HospitalsTab extends StatefulWidget {
  final MedicalIntelligenceService service;
  const _HospitalsTab({required this.service});

  @override
  State<_HospitalsTab> createState() => _HospitalsTabState();
}

class _HospitalsTabState extends State<_HospitalsTab> {
  List<Hospital> _hospitals = [];
  bool _isSearching = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _findHospitals();
  }

  Future<void> _findHospitals() async {
    setState(() => _isSearching = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      _currentPosition = await Geolocator.getCurrentPosition();
      final hospitals = await widget.service.findNearbyHospitals(position: _currentPosition!);
      if (mounted) setState(() { _hospitals = hospitals; _isSearching = false; });
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _callHospital(String phone) async {
    final uri = Uri.parse('tel:' + phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openDirections(Hospital hospital) async {
    final uri = Uri.parse('https://maps.google.com/?q=' + hospital.latitude.toString() + ',' + hospital.longitude.toString());
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AkelDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEARBY HOSPITALS', style: AkelDesign.subtitle),
          const SizedBox(height: AkelDesign.sm),
          Text('Find emergency care near your location', style: AkelDesign.caption),
          const SizedBox(height: AkelDesign.lg),

          FuturisticButton(
            text: _isSearching ? 'SEARCHING...' : 'REFRESH NEARBY',
            icon: Icons.refresh,
            onPressed: _isSearching ? () {} : _findHospitals,
            color: Colors.red,
            isOutlined: true,
            isFullWidth: true,
          ),

          const SizedBox(height: AkelDesign.lg),

          if (_isSearching)
            const Center(child: FuturisticLoadingIndicator(size: 40, color: Colors.red))
          else if (_hospitals.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: AkelDesign.xl),
                  const Icon(Icons.local_hospital, size: 64, color: Colors.white24),
                  const SizedBox(height: AkelDesign.md),
                  Text('No hospitals found', style: AkelDesign.caption),
                ],
              ),
            )
          else
            ..._hospitals.map((hospital) => Padding(
              padding: const EdgeInsets.only(bottom: AkelDesign.md),
              child: FuturisticCard(
                padding: const EdgeInsets.all(AkelDesign.lg),
                hasGlow: hospital.hasEmergency,
                glowColor: Colors.red,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AkelDesign.sm),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.local_hospital, color: Colors.red, size: 24),
                        ),
                        const SizedBox(width: AkelDesign.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(hospital.name, style: AkelDesign.body.copyWith(fontWeight: FontWeight.bold)),
                              Text(hospital.address, style: AkelDesign.caption),
                            ],
                          ),
                        ),
                        if (hospital.hasEmergency)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AkelDesign.xs, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red)),
                            child: const Text('ER', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: AkelDesign.md),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.yellow, size: 16),
                        const SizedBox(width: 4),
                        Text(hospital.rating.toStringAsFixed(1), style: AkelDesign.caption),
                        const SizedBox(width: AkelDesign.md),
                        if (hospital.waitTime != null) ...[
                          const Icon(Icons.timer, color: Colors.orange, size: 14),
                          const SizedBox(width: 4),
                          Text(hospital.waitTime! + ' wait', style: AkelDesign.caption),
                        ],
                        if (_currentPosition != null) ...[
                          const Spacer(),
                          Text(hospital.formatDistance(_currentPosition!), style: AkelDesign.caption.copyWith(color: Colors.blue)),
                        ],
                      ],
                    ),
                    const SizedBox(height: AkelDesign.sm),
                    Wrap(
                      spacing: AkelDesign.xs,
                      children: hospital.specialties.map((s) => Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: AkelDesign.sm, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.withOpacity(0.3))),
                        child: Text(s, style: const TextStyle(color: Colors.blue, fontSize: 10)),
                      )).toList(),
                    ),
                    const SizedBox(height: AkelDesign.md),
                    Row(
                      children: [
                        Expanded(
                          child: FuturisticButton(
                            text: 'CALL',
                            icon: Icons.phone,
                            onPressed: () => _callHospital(hospital.phone),
                            color: Colors.green,
                            isSmall: true,
                            isOutlined: true,
                          ),
                        ),
                        const SizedBox(width: AkelDesign.sm),
                        Expanded(
                          child: FuturisticButton(
                            text: 'DIRECTIONS',
                            icon: Icons.directions,
                            onPressed: () => _openDirections(hospital),
                            color: Colors.blue,
                            isSmall: true,
                            isOutlined: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )).toList(),
        ],
      ),
    );
  }
}

// ==================== TAB 5: DOCTOR ANNIE AI ====================

class _DoctorAnnieTab extends StatefulWidget {
  final MedicalIntelligenceService service;
  final String? userId;
  const _DoctorAnnieTab({required this.service, required this.userId});

  @override
  State<_DoctorAnnieTab> createState() => _DoctorAnnieTabState();
}

class _DoctorAnnieTabState extends State<_DoctorAnnieTab> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isThinking = false;
  final List<String> _selectedSymptoms = [];

  static const List<String> _commonSymptoms = [
    'Fever', 'Headache', 'Chest pain', 'Shortness of breath',
    'Nausea', 'Dizziness', 'Back pain', 'Fatigue',
    'Cough', 'Sore throat', 'Stomach pain', 'Rash',
  ];

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add({
      'role': 'annie',
      'text': 'Hi, I\'m Doctor Annie, your AI health assistant. I can help with general health questions and symptom guidance.\n\nPlease note I cannot diagnose conditions or replace professional medical advice. In an emergency always call 911.',
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || widget.userId == null) return;

    setState(() {
      _messages.add({'role': 'user', 'text': question});
      _isThinking = true;
    });

    _questionController.clear();
    _scrollToBottom();

    final response = await widget.service.askDoctorAnnie(
      userId: widget.userId!,
      question: question,
      symptoms: _selectedSymptoms.isEmpty ? null : List<String>.from(_selectedSymptoms),
    );

    if (mounted) {
      setState(() {
        _messages.add({'role': 'annie', 'text': response});
        _isThinking = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Symptom chips
        Container(
          padding: const EdgeInsets.all(AkelDesign.md),
          color: AkelDesign.carbonFiber,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SELECT SYMPTOMS (optional)', style: AkelDesign.caption.copyWith(letterSpacing: 1)),
              const SizedBox(height: AkelDesign.sm),
              Wrap(
                spacing: AkelDesign.xs,
                runSpacing: AkelDesign.xs,
                children: _commonSymptoms.map((s) {
                  final isSelected = _selectedSymptoms.contains(s);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (isSelected) _selectedSymptoms.remove(s);
                      else _selectedSymptoms.add(s);
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AkelDesign.sm, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red.withOpacity(0.3) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? Colors.red : Colors.white24),
                      ),
                      child: Text(s, style: TextStyle(color: isSelected ? Colors.red : Colors.white60, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Chat messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AkelDesign.md),
            itemCount: _messages.length + (_isThinking ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isThinking && index == _messages.length) {
                return _buildThinkingBubble();
              }
              final message = _messages[index];
              final isAnnie = message['role'] == 'annie';
              return _buildMessageBubble(message['text'] as String, isAnnie);
            },
          ),
        ),

        // Input bar
        Container(
          padding: const EdgeInsets.all(AkelDesign.md),
          color: AkelDesign.carbonFiber,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questionController,
                  style: AkelDesign.body,
                  maxLines: null,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Ask Doctor Annie...',
                    hintStyle: AkelDesign.caption,
                    filled: true,
                    fillColor: AkelDesign.darkPanel,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AkelDesign.md, vertical: AkelDesign.sm),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: AkelDesign.sm),
              GestureDetector(
                onTap: _isThinking ? null : _sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isThinking ? Colors.grey : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(String text, bool isAnnie) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AkelDesign.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isAnnie ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isAnnie) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.psychology, color: Colors.red, size: 18),
            ),
            const SizedBox(width: AkelDesign.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AkelDesign.md),
              decoration: BoxDecoration(
                color: isAnnie ? AkelDesign.darkPanel : Colors.red.withOpacity(0.3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isAnnie ? 4 : AkelDesign.radiusMd),
                  topRight: Radius.circular(isAnnie ? AkelDesign.radiusMd : 4),
                  bottomLeft: const Radius.circular(AkelDesign.radiusMd),
                  bottomRight: const Radius.circular(AkelDesign.radiusMd),
                ),
                border: isAnnie ? Border.all(color: Colors.white10) : null,
              ),
              child: Text(text, style: AkelDesign.body.copyWith(fontSize: 13, height: 1.5)),
            ),
          ),
          if (!isAnnie) const SizedBox(width: AkelDesign.sm),
        ],
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AkelDesign.md),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.psychology, color: Colors.red, size: 18),
          ),
          const SizedBox(width: AkelDesign.sm),
          Container(
            padding: const EdgeInsets.all(AkelDesign.md),
            decoration: BoxDecoration(color: AkelDesign.darkPanel, borderRadius: BorderRadius.circular(AkelDesign.radiusMd), border: Border.all(color: Colors.white10)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40,
                  height: 20,
                  child: FuturisticLoadingIndicator(size: 20, color: Colors.red),
                ),
                const SizedBox(width: AkelDesign.sm),
                Text('Doctor Annie is thinking...', style: AkelDesign.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}