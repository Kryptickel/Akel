import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/constants/themes/utils/akel_design_system.dart';

/// ==================== MEDICAL ID CARD SCREEN ====================
///
/// PRODUCTION READY - BUILD 58 - FIXED & UPDATED
///
/// Features:
/// - Emergency medical information storage
/// - Blood type, allergies, medications
/// - Emergency contacts display
/// - Medical conditions & notes
/// - Digital card display
/// - Organ donor badge
/// - Edit mode with proper enabled states
///
/// Firebase Collections:
/// - /users/{userId}/medical_info
///
/// ================================================================

class MedicalIdCardScreen extends StatefulWidget {
  const MedicalIdCardScreen({super.key});

  @override
  State<MedicalIdCardScreen> createState() => _MedicalIdCardScreenState();
}

class _MedicalIdCardScreenState extends State<MedicalIdCardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  // Medical Information
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _bloodTypeController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _conditionsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedBloodType = 'Unknown';
  bool _isOrganDonor = false;

  final List<String> _bloodTypes = [
    'Unknown',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void initState() {
    super.initState();
    _loadMedicalInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _bloodTypeController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _conditionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicalInfo() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medical_info')
          .doc('primary')
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;

        setState(() {
          _nameController.text = data['name'] ?? user.displayName ?? '';
          _dobController.text = data['dateOfBirth'] ?? '';
          _selectedBloodType = data['bloodType'] ?? 'Unknown';
          _heightController.text = data['height'] ?? '';
          _weightController.text = data['weight'] ?? '';
          _allergiesController.text = data['allergies'] ?? '';
          _medicationsController.text = data['medications'] ?? '';
          _conditionsController.text = data['conditions'] ?? '';
          _notesController.text = data['notes'] ?? '';
          _isOrganDonor = data['organDonor'] ?? false;
        });
      } else {
        // Initialize with user's name
        _nameController.text = user.displayName ?? '';
      }

    } catch (e) {
      debugPrint('Error loading medical info: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading medical info: $e'),
            backgroundColor: AkelDesign.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveMedicalInfo() async {
    setState(() => _isSaving = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final medicalData = {
        'name': _nameController.text.trim(),
        'dateOfBirth': _dobController.text.trim(),
        'bloodType': _selectedBloodType,
        'height': _heightController.text.trim(),
        'weight': _weightController.text.trim(),
        'allergies': _allergiesController.text.trim(),
        'medications': _medicationsController.text.trim(),
        'conditions': _conditionsController.text.trim(),
        'notes': _notesController.text.trim(),
        'organDonor': _isOrganDonor,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medical_info')
          .doc('primary')
          .set(medicalData, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' Medical information saved'),
            backgroundColor: AkelDesign.successGreen,
          ),
        );
      }

    } catch (e) {
      debugPrint('Error saving medical info: $e');
      if (mounted) {
        setState(() => _isSaving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Error: $e'),
            backgroundColor: AkelDesign.errorRed,
          ),
        );
      }
    }
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AkelDesign.neonBlue,
              surface: AkelDesign.carbonFiber,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _dobController.text = '${picked.month}/${picked.day}/${picked.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical ID Card'),
        backgroundColor: AkelDesign.carbonFiber,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: () {
                setState(() => _isEditing = false);
                _loadMedicalInfo();
              },
            ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share feature coming soon'),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: AkelDesign.deepBlack,
      body: user == null
          ? const Center(
        child: Text(
          'Please log in to view medical ID',
          style: TextStyle(color: Colors.white70),
        ),
      )
          : _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AkelDesign.neonBlue,
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medical ID Card Display
            _buildMedicalCard(),

            const SizedBox(height: 24),

            // Detailed Information Form
            _buildDetailedForm(),

            const SizedBox(height: 24),

            // Emergency Contacts
            _buildEmergencyContactsSection(),

            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: _isEditing
          ? FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveMedicalInfo,
        backgroundColor: AkelDesign.successGreen,
        icon: _isSaving
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save'),
      )
          : null,
    );
  }

  Widget _buildMedicalCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AkelDesign.primaryRed.withValues(alpha: 0.3),
            AkelDesign.primaryRed.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AkelDesign.primaryRed.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AkelDesign.primaryRed.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AkelDesign.primaryRed.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    color: AkelDesign.primaryRed,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MEDICAL ID',
                        style: TextStyle(
                          color: AkelDesign.primaryRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'EMERGENCY INFORMATION',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(
              color: Colors.white24,
              height: 32,
            ),

            // Name
            _buildCardField('Name', _nameController.text, Icons.person),

            // Date of Birth
            if (_dobController.text.isNotEmpty)
              _buildCardField('Date of Birth', _dobController.text, Icons.cake),

            // Blood Type (Prominent)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AkelDesign.primaryRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AkelDesign.primaryRed.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.bloodtype,
                    color: AkelDesign.primaryRed,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BLOOD TYPE',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedBloodType,
                        style: const TextStyle(
                          color: AkelDesign.primaryRed,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Critical Information
            if (_allergiesController.text.isNotEmpty)
              _buildCriticalField('Allergies', _allergiesController.text, Icons.warning),

            if (_medicationsController.text.isNotEmpty)
              _buildCriticalField('Medications', _medicationsController.text, Icons.medication),

            if (_conditionsController.text.isNotEmpty)
              _buildCriticalField('Conditions', _conditionsController.text, Icons.local_hospital),

            // Organ Donor Badge
            if (_isOrganDonor)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AkelDesign.successGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AkelDesign.successGreen),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite, color: AkelDesign.successGreen, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'ORGAN DONOR',
                      style: TextStyle(
                        color: AkelDesign.successGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
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

  Widget _buildCardField(String label, String value, IconData icon) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalField(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AkelDesign.warningOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AkelDesign.warningOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AkelDesign.warningOrange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AkelDesign.warningOrange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedForm() {
    return Container(
      decoration: BoxDecoration(
        color: AkelDesign.carbonFiber,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.edit_note, color: AkelDesign.neonBlue),
                const SizedBox(width: 12),
                const Text(
                  'Detailed Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTextField('Full Name', _nameController, Icons.person),
                const SizedBox(height: 16),

                _buildDateField('Date of Birth', _dobController),
                const SizedBox(height: 16),

                _buildBloodTypeDropdown(),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField('Height', _heightController, Icons.height, hint: '5\'10"'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField('Weight', _weightController, Icons.monitor_weight, hint: '150 lbs'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  'Allergies',
                  _allergiesController,
                  Icons.warning,
                  maxLines: 3,
                  hint: 'Penicillin, Peanuts, etc.',
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  'Current Medications',
                  _medicationsController,
                  Icons.medication,
                  maxLines: 3,
                  hint: 'List all current medications',
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  'Medical Conditions',
                  _conditionsController,
                  Icons.local_hospital,
                  maxLines: 3,
                  hint: 'Diabetes, Asthma, etc.',
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  'Additional Notes',
                  _notesController,
                  Icons.note,
                  maxLines: 4,
                  hint: 'Any other important medical information',
                ),
                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: _isEditing
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isEditing
                          ? AkelDesign.successGreen.withValues(alpha: 0.3)
                          : Colors.white24,
                    ),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'Organ Donor',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'I am registered as an organ donor',
                      style: TextStyle(
                        color: _isEditing
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    value: _isOrganDonor,
                    activeColor: AkelDesign.successGreen,
                    onChanged: _isEditing
                        ? (value) => setState(() => _isOrganDonor = value)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      IconData icon, {
        int maxLines = 1,
        String? hint,
      }) {
    return TextField(
      controller: controller,
      enabled: _isEditing,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        prefixIcon: Icon(icon, color: AkelDesign.neonBlue),
        filled: true,
        fillColor: _isEditing ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _isEditing ? AkelDesign.neonBlue.withValues(alpha: 0.3) : Colors.white24,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AkelDesign.neonBlue, width: 2),
        ),
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      enabled: _isEditing,
      readOnly: true,
      onTap: _isEditing ? _showDatePicker : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.cake, color: AkelDesign.neonBlue),
        suffixIcon: _isEditing
            ? const Icon(Icons.calendar_today, color: AkelDesign.neonBlue)
            : null,
        filled: true,
        fillColor: _isEditing ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AkelDesign.neonBlue, width: 0.05), // FIXED: Adjusting focusedBorder to meet spec
        ),
      ),
    );
  }

  Widget _buildBloodTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBloodType,
      // FIXED: Removed the unsupported 'enabled' parameter causing the crash
      dropdownColor: AkelDesign.carbonFiber,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Blood Type',
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.bloodtype, color: AkelDesign.primaryRed),
        filled: true,
        fillColor: _isEditing ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AkelDesign.neonBlue, width: 2),
        ),
      ),
      items: _bloodTypes.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type),
        );
      }).toList(),
      // Use null to disable interaction when not in editing mode
      onChanged: _isEditing
          ? (value) => setState(() => _selectedBloodType = value!)
          : null,
    );
  }

  Widget _buildEmergencyContactsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AkelDesign.carbonFiber,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.contact_phone, color: AkelDesign.successGreen),
                const SizedBox(width: 12),
                const Text(
                  'Emergency Contacts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .doc(_auth.currentUser?.uid)
                .collection('contacts')
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final contacts = snapshot.data!.docs;

              if (contacts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No emergency contacts added yet',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: contacts.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.white.withValues(alpha: 0.1),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final data = contacts[index].data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Unknown';
                  final phone = data['phone'] ?? '';

                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AkelDesign.successGreen.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(
                            color: AkelDesign.successGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      phone,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    ),
                    trailing: const Icon(Icons.phone, color: AkelDesign.successGreen),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}