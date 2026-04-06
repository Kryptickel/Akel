import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/police_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';
import '../providers/auth_provider.dart';

class PoliceEmergencyScreen extends StatefulWidget {
  const PoliceEmergencyScreen({super.key});

  @override
  State<PoliceEmergencyScreen> createState() => _PoliceEmergencyScreenState();
}

class _PoliceEmergencyScreenState extends State<PoliceEmergencyScreen> {
  final PoliceService _policeService = PoliceService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();
  final _formKey = GlobalKey<FormState>();

  String _selectedEmergencyType = PoliceService.emergencyTypes[0];
  String _selectedPriority = PoliceService.priorityLevels[0];

  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _suspectController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _weaponsController = TextEditingController();

  bool _injuriesReported = false;
  File? _selectedImage;
  bool _isUploading = false;
  bool _isReporting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _suspectController.dispose();
    _vehicleController.dispose();
    _weaponsController.dispose();
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
              content: Text(' Photo captured'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint(' Pick image error: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      setState(() => _isUploading = true);

      final fileName = 'police_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('police_photos/$fileName');

      await storageRef.putFile(_selectedImage!);
      final downloadUrl = await storageRef.getDownloadURL();

      debugPrint(' Image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint(' Upload image error: $e');
      return null;
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _callPolice() async {
    await _vibrationService.light();
    await _soundService.playClick();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(' Call Police?'),
        content: Text(
          'This will call ${_policeService.getPoliceEmergencyNumber()}',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('CALL'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _policeService.callPolice();
    }
  }

  Future<void> _reportEmergency() async {
    if (!_formKey.currentState!.validate()) return;

    if (_descriptionController.text.trim().isEmpty) {
      await _vibrationService.error();
      await _soundService.playError();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Please provide a description'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isReporting = true);

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

      // Report emergency
      final result = await _policeService.reportPoliceEmergency(
        userId: user.uid,
        userName: userName,
        emergencyType: _selectedEmergencyType,
        priority: _selectedPriority,
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        suspectDescription: _suspectController.text.trim().isEmpty
            ? null
            : _suspectController.text.trim(),
        vehicleDescription: _vehicleController.text.trim().isEmpty
            ? null
            : _vehicleController.text.trim(),
        weaponsInvolved: _weaponsController.text.trim().isEmpty
            ? null
            : _weaponsController.text.trim(),
        injuriesReported: _injuriesReported,
        photoUrl: photoUrl,
      );

      if (mounted) {
        setState(() => _isReporting = false);

        if (result['success'] == true) {
          await _vibrationService.success();
          await _soundService.playSuccess();
          _showSuccessDialog(result);
        } else {
          await _vibrationService.error();
          await _soundService.playError();
          _showErrorDialog(result['error'] ?? 'Failed to report emergency');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isReporting = false);
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
        title: const Text(' Police Notified'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                ' Police have been dispatched',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(' Emergency Number: ${result['policeNumber']}'),
                    const SizedBox(height: 4),
                    Text(' ETA: ${result['responseTime']}'),
                    const SizedBox(height: 4),
                    Text(
                      ' Report ID: ${result['reportId']}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                ' Safety Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...PoliceService.getSafetyTips(_selectedEmergencyType).map(
                    (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(tip, style: const TextStyle(fontSize: 13)),
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
              await _policeService.callPolice();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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
        title: const Text(' Error'),
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
        title: const Text(' Police Emergency'),
        backgroundColor: Colors.blue,
      ),
      body: _isReporting
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 24),
            Text(
              ' Contacting police...',
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
                onPressed: _callPolice,
                icon: const Icon(Icons.phone, size: 28),
                label: Text(
                  'CALL POLICE (${_policeService.getPoliceEmergencyNumber()})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Emergency Type
            const Text(
              'Emergency Type *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedEmergencyType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.warning, color: Colors.blue),
              ),
              items: PoliceService.emergencyTypes.map((type) {
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

            // Priority
            const Text(
              'Priority Level *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.priority_high, color: Colors.red),
              ),
              items: PoliceService.priorityLevels.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(level),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPriority = value);
                }
              },
            ),

            const SizedBox(height: 16),

            // Description
            const Text(
              'Description *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'What happened? Provide details...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                hintText: 'Additional location details',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.location_on),
              ),
            ),

            const SizedBox(height: 16),

            // Suspect Description
            const Text(
              'Suspect Description',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _suspectController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Height, build, clothing, features...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person_search),
              ),
            ),

            const SizedBox(height: 16),

            // Vehicle Description
            const Text(
              'Vehicle Description',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _vehicleController,
              decoration: InputDecoration(
                hintText: 'Make, model, color, license plate...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.directions_car),
              ),
            ),

            const SizedBox(height: 16),

            // Weapons Involved
            const Text(
              'Weapons Involved',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _weaponsController,
              decoration: InputDecoration(
                hintText: 'Type of weapons (if any)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.gpp_bad, color: Colors.red),
              ),
            ),

            const SizedBox(height: 16),

            // Injuries Reported
            CheckboxListTile(
              title: const Text('Injuries Reported'),
              subtitle: const Text('Check if anyone is injured'),
              value: _injuriesReported,
              onChanged: (value) {
                setState(() => _injuriesReported = value ?? false);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
            ),

            const SizedBox(height: 16),

            // Photo Upload
            const Text(
              'Photo Evidence (Optional)',
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

            // Report Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _reportEmergency,
                icon: _isUploading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.send, size: 24),
                label: Text(
                  _isUploading
                      ? 'Uploading Photo...'
                      : 'REPORT TO POLICE',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}