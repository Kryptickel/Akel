import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/ambulance_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';
import '../providers/auth_provider.dart';

class AmbulanceEmergencyScreen extends StatefulWidget {
  const AmbulanceEmergencyScreen({super.key});

  @override
  State<AmbulanceEmergencyScreen> createState() => _AmbulanceEmergencyScreenState();
}

class _AmbulanceEmergencyScreenState extends State<AmbulanceEmergencyScreen> {
  final AmbulanceService _ambulanceService = AmbulanceService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();
  final _formKey = GlobalKey<FormState>();

  String _selectedEmergencyType = AmbulanceService.emergencyTypes[0];
  String _selectedSeverity = AmbulanceService.severityLevels[0];

  final _descriptionController = TextEditingController();
  final _patientAgeController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _locationController = TextEditingController();

  String _patientGender = 'Unknown';
  bool _isConscious = true;
  bool _isBreathing = true;

  File? _selectedImage;
  bool _isUploading = false;
  bool _isRequesting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _patientAgeController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    _medicalConditionsController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });

        await _vibrationService.success();
        await _soundService.playSuccess();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📸 Photo captured'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Pick image error: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      setState(() => _isUploading = true);

      final fileName = 'ambulance_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('ambulance_photos/$fileName');

      await storageRef.putFile(_selectedImage!);
      final downloadUrl = await storageRef.getDownloadURL();

      debugPrint('✅ Image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Upload image error: $e');
      return null;
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _callEMS() async {
    await _vibrationService.light();
    await _soundService.playClick();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📞 Call Ambulance?'),
        content: Text(
          'This will call ${_ambulanceService.getEMSNumber()}',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('CALL'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _ambulanceService.callEMS();
    }
  }

  Future<void> _requestAmbulance() async {
    if (!_formKey.currentState!.validate()) return;

    if (_descriptionController.text.trim().isEmpty) {
      await _vibrationService.error();
      await _soundService.playError();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please provide a description'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

// Show critical warning if not breathing or not conscious
    if (!_isBreathing || !_isConscious) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.red,
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Text(
                'CRITICAL EMERGENCY',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This is a LIFE-THREATENING emergency!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                '🫀 Start CPR immediately if trained\n'
                    '📞 Call 911 NOW\n'
                    '⏱️ Every second counts',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
              ),
              child: const Text('CALL 911 NOW'),
            ),
          ],
        ),
      );

      if (proceed == true) {
        await _ambulanceService.callEMS();
        return;
      }
    }

    setState(() => _isRequesting = true);

    await _vibrationService.panic();
    await _soundService.playWarning();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      final userName = authProvider.userProfile?['name'] ?? 'User';

      if (user == null) {
        throw Exception('Not logged in');
      }

// Upload image if selected
      String? photoUrl;
      if (_selectedImage != null) {
        photoUrl = await _uploadImage();
      }

// Request ambulance
      final result = await _ambulanceService.requestAmbulance(
        userId: user.uid,
        userName: userName,
        emergencyType: _selectedEmergencyType,
        severity: _selectedSeverity,
        description: _descriptionController.text.trim(),
        patientAge: _patientAgeController.text.trim().isEmpty
            ? null
            : _patientAgeController.text.trim(),
        patientGender: _patientGender,
        isConscious: _isConscious,
        isBreathing: _isBreathing,
        medications: _medicationsController.text.trim().isEmpty
            ? null
            : _medicationsController.text.trim(),
        allergies: _allergiesController.text.trim().isEmpty
            ? null
            : _allergiesController.text.trim(),
        medicalConditions: _medicalConditionsController.text.trim().isEmpty
            ? null
            : _medicalConditionsController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        photoUrl: photoUrl,
      );

      if (mounted) {
        setState(() => _isRequesting = false);

        if (result['success'] == true) {
          await _vibrationService.success();
          await _soundService.playSuccess();
          _showSuccessDialog(result);
        } else {
          await _vibrationService.error();
          await _soundService.playError();
          _showErrorDialog(result['error'] ?? 'Failed to request ambulance');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRequesting = false);
        await _vibrationService.error();
        await _soundService.playError();
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🚑 Ambulance Dispatched'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '✅ Ambulance is on the way',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.local_hospital, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'EMS Information',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('📞 EMS Number: ${result['emsNumber']}'),
                    const SizedBox(height: 4),
                    Text('⏱️ ETA: ${result['eta']}'),
                    const SizedBox(height: 4),
                    Text(
                      '📋 Request ID: ${result['requestId']}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '🩺 First Aid Instructions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...AmbulanceService.getFirstAidInstructions(_selectedEmergencyType).map(
                    (instruction) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    instruction,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _ambulanceService.callEMS();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.phone),
            label: const Text('CALL NOW'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❌ Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚑 Medical Emergency'),
        backgroundColor: Colors.red,
      ),
      body: _isRequesting
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 24),
            Text(
              '🚑 Requesting ambulance...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      )
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
// Emergency Call Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _callEMS,
                icon: const Icon(Icons.phone, size: 28),
                label: Text(
                  'CALL AMBULANCE (${_ambulanceService.getEMSNumber()})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

// Critical Status Indicators
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (!_isBreathing || !_isConscious)
                    ? Colors.red.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (!_isBreathing || !_isConscious)
                      ? Colors.red
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text(
                            'Patient Conscious?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          value: _isConscious,
                          onChanged: (value) {
                            setState(() => _isConscious = value ?? true);
                          },
                          activeColor: Colors.green,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text(
                            'Patient Breathing?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          value: _isBreathing,
                          onChanged: (value) {
                            setState(() => _isBreathing = value ?? true);
                          },
                          activeColor: Colors.green,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  if (!_isBreathing || !_isConscious)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.white),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'CRITICAL - Call 911 immediately!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

// Emergency Type
            const Text(
              'Medical Emergency Type *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedEmergencyType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.medical_services, color: Colors.red),
              ),
              items: AmbulanceService.emergencyTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedEmergencyType = value);
                }
              },
            ),

            const SizedBox(height: 16),

// Severity
            const Text(
              'Severity Level *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSeverity,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.priority_high, color: Colors.orange),
              ),
              items: AmbulanceService.severityLevels.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(level),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSeverity = value);
                }
              },
            ),

            const SizedBox(height: 16),

// Description
            const Text(
              'Symptoms/Description *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe symptoms, what happened, when it started...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

// Patient Info
            const Text(
              '👤 Patient Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _patientAgeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.cake),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _patientGender,
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Unknown', child: Text('Unknown')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _patientGender = value);
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

// Medical History
            const Text(
              'Current Medications',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _medicationsController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'List all medications currently taking...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.medication),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Allergies',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _allergiesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Drug allergies, food allergies...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.warning_amber, color: Colors.orange),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Medical Conditions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _medicalConditionsController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Diabetes, heart disease, asthma...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.local_hospital),
              ),
            ),

            const SizedBox(height: 16),

// Location
            const Text(
              'Specific Location',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Additional location details (floor, room, etc.)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.location_on),
              ),
            ),

            const SizedBox(height: 16),

// Photo Upload
            const Text(
              'Photo (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_selectedImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () {
                        setState(() => _selectedImage = null);
                      },
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 120,
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt, size: 32),
                  label: const Text('Take Photo'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

// Request Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _requestAmbulance,
                icon: _isUploading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.local_hospital, size: 24),
                label: Text(
                  _isUploading
                      ? 'Uploading Photo...'
                      : 'REQUEST AMBULANCE',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

// Info Text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Important Information',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Paramedics will be dispatched immediately\n'
                        '• Your location and medical info will be shared\n'
                        '• Stay calm and follow first aid instructions\n'
                        '• Keep phone nearby for paramedic contact',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}