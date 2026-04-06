import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/vibration_service.dart';

class SecurityMedicalModesScreen extends StatefulWidget {
  const SecurityMedicalModesScreen({super.key});

  @override
  State<SecurityMedicalModesScreen> createState() =>
      _SecurityMedicalModesScreenState();
}

class _SecurityMedicalModesScreenState
    extends State<SecurityMedicalModesScreen>
    with SingleTickerProviderStateMixin {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final VibrationService _vibrationService = VibrationService();

  late TabController _tabController;

  // Security Mode State
  bool _stealthModeEnabled = false;
  bool _decoyScreenEnabled = false;
  bool _intruderDetectionEnabled = false;
  bool _shakeToCallEnabled = false;
  bool _covertRecordingEnabled = false;
  String _decoyAppName = 'Calculator';
  String _emergencyCallNumber = '';
  int _wrongPinCount = 0;

  // Medical Mode State
  bool _medicalIdEnabled = false;
  bool _autoShareMedicalEnabled = false;
  bool _medicationRemindersEnabled = false;
  bool _isLoading = true;

  // Medical Info
  String _bloodType = '';
  String _allergies = '';
  String _conditions = '';
  String _medications = '';
  String _emergencyNotes = '';
  String _doctorName = '';
  String _doctorPhone = '';
  String _hospital = '';

  // Medication Reminders
  List<Map<String, dynamic>> _medicationReminders = [];

  final TextEditingController _callNumberController = TextEditingController();
  final TextEditingController _decoyNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _callNumberController.dispose();
    _decoyNameController.dispose();
    super.dispose();
  }

  // ==================== LOAD SETTINGS ====================

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _auth.currentUser;

    if (mounted) {
      setState(() {
        _stealthModeEnabled = prefs.getBool('stealth_mode_enabled') ?? false;
        _decoyScreenEnabled = prefs.getBool('decoy_screen_enabled') ?? false;
        _intruderDetectionEnabled = prefs.getBool('intruder_detection_enabled') ?? false;
        _shakeToCallEnabled = prefs.getBool('shake_to_call_enabled') ?? false;
        _covertRecordingEnabled = prefs.getBool('covert_recording_enabled') ?? false;
        _decoyAppName = prefs.getString('decoy_app_name') ?? 'Calculator';
        _emergencyCallNumber = prefs.getString('emergency_call_number') ?? '';
        _medicalIdEnabled = prefs.getBool('medical_id_enabled') ?? false;
        _autoShareMedicalEnabled = prefs.getBool('auto_share_medical_enabled') ?? false;
        _medicationRemindersEnabled = prefs.getBool('medication_reminders_enabled') ?? false;
        _callNumberController.text = _emergencyCallNumber;
        _decoyNameController.text = _decoyAppName;
      });
    }

    if (user != null) {
      try {
        final medicalDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('medical_info')
            .doc('emergency')
            .get();

        if (medicalDoc.exists && mounted) {
          final data = medicalDoc.data()!;
          setState(() {
            _bloodType = data['bloodType'] ?? '';
            _allergies = data['allergies'] ?? '';
            _conditions = data['conditions'] ?? '';
            _medications = data['medications'] ?? '';
            _emergencyNotes = data['emergencyNotes'] ?? '';
            _doctorName = data['doctorName'] ?? '';
            _doctorPhone = data['doctorPhone'] ?? '';
            _hospital = data['hospital'] ?? '';
          });
        }

        final remindersSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('medication_reminders')
            .orderBy('createdAt', descending: false)
            .get();

        if (mounted) {
          setState(() {
            _medicationReminders = remindersSnapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();
          });
        }
      } catch (e) {
        debugPrint('Load medical info error: ' + e.toString());
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  // ==================== SECURITY ACTIONS ====================

  Future<void> _saveMedicalInfo() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medical_info')
          .doc('emergency')
          .set({
        'bloodType': _bloodType,
        'allergies': _allergies,
        'conditions': _conditions,
        'medications': _medications,
        'emergencyNotes': _emergencyNotes,
        'doctorName': _doctorName,
        'doctorPhone': _doctorPhone,
        'hospital': _hospital,
        'updatedAt': FieldValue.serverTimestamp(),
        'isPublic': _autoShareMedicalEnabled,
      }, SetOptions(merge: true));

      _showSnackBar('Medical info saved', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to save medical info: ' + e.toString(), Colors.red);
    }
  }

  Future<void> _addMedicationReminder() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    List<bool> selectedDays = List.filled(7, true);
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            'Add Medication Reminder',
            style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Medication Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dosageController,
                  decoration: InputDecoration(
                    labelText: 'Dosage (e.g. 10mg)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: Text(
                    'Time: ' + selectedTime.format(context),
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setDialogState(() => selectedTime = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Days:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: List.generate(7, (index) {
                    return FilterChip(
                      label: Text(dayNames[index], style: const TextStyle(fontSize: 12)),
                      selected: selectedDays[index],
                      onSelected: (val) => setDialogState(() => selectedDays[index] = val),
                      selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(context);

                try {
                  final docRef = await _firestore
                      .collection('users')
                      .doc(user.uid)
                      .collection('medication_reminders')
                      .add({
                    'name': nameController.text.trim(),
                    'dosage': dosageController.text.trim(),
                    'hour': selectedTime.hour,
                    'minute': selectedTime.minute,
                    'days': selectedDays,
                    'active': true,
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  if (mounted) {
                    setState(() {
                      _medicationReminders.add({
                        'id': docRef.id,
                        'name': nameController.text.trim(),
                        'dosage': dosageController.text.trim(),
                        'hour': selectedTime.hour,
                        'minute': selectedTime.minute,
                        'days': selectedDays,
                        'active': true,
                      });
                    });
                  }

                  _showSnackBar('Reminder added for ' + nameController.text.trim(), Colors.green);
                } catch (e) {
                  _showSnackBar('Failed to add reminder: ' + e.toString(), Colors.red);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMedicationReminder(String reminderId, String name) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medication_reminders')
          .doc(reminderId)
          .delete();

      if (mounted) {
        setState(() {
          _medicationReminders.removeWhere((r) => r['id'] == reminderId);
        });
      }

      _showSnackBar(name + ' reminder removed', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to remove reminder: ' + e.toString(), Colors.red);
    }
  }

  Future<void> _toggleMedicationReminder(String reminderId, bool active) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medication_reminders')
          .doc(reminderId)
          .update({'active': active});

      if (mounted) {
        setState(() {
          final index = _medicationReminders.indexWhere((r) => r['id'] == reminderId);
          if (index != -1) {
            _medicationReminders[index]['active'] = active;
          }
        });
      }
    } catch (e) {
      debugPrint('Toggle reminder error: ' + e.toString());
    }
  }

  void _showMedicalEmergencyChecklist() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setSheetState) {
            final List<Map<String, dynamic>> checklist = [
              {'label': 'Call emergency services (911)', 'checked': false, 'icon': Icons.call, 'color': Colors.red},
              {'label': 'Stay calm and assess situation', 'checked': false, 'icon': Icons.psychology, 'color': Colors.blue},
              {'label': 'Check if person is conscious', 'checked': false, 'icon': Icons.visibility, 'color': Colors.orange},
              {'label': 'Check for breathing', 'checked': false, 'icon': Icons.air, 'color': Colors.teal},
              {'label': 'Do not move if spinal injury suspected', 'checked': false, 'icon': Icons.warning_amber, 'color': Colors.red},
              {'label': 'Apply pressure to bleeding wounds', 'checked': false, 'icon': Icons.healing, 'color': Colors.red},
              {'label': 'Share medical ID with responders', 'checked': false, 'icon': Icons.medical_services, 'color': Colors.purple},
              {'label': 'Note time of incident', 'checked': false, 'icon': Icons.timer, 'color': Colors.indigo},
              {'label': 'Keep person warm', 'checked': false, 'icon': Icons.thermostat, 'color': Colors.orange},
              {'label': 'Do not give food or water', 'checked': false, 'icon': Icons.no_food, 'color': Colors.grey},
            ];

            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.checklist, color: Colors.red, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Medical Emergency Checklist',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Follow these steps in order during a medical emergency',
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  const SizedBox(height: 16),

                  ...checklist.asMap().entries.map((entry) {
                    final item = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: CheckboxListTile(
                        secondary: CircleAvatar(
                          backgroundColor: (item['color'] as Color).withOpacity(0.2),
                          child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                        ),
                        title: Text(
                          item['label'] as String,
                          style: TextStyle(
                            decoration: item['checked'] as bool ? TextDecoration.lineThrough : null,
                            color: item['checked'] as bool
                                ? Theme.of(context).textTheme.bodySmall?.color
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        value: item['checked'] as bool,
                        onChanged: (val) {
                          setSheetState(() => checklist[entry.key]['checked'] = val ?? false);
                        },
                        activeColor: Colors.green,
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 16),

                  if (_bloodType.isNotEmpty || _allergies.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.medical_services, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'CRITICAL MEDICAL INFO',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_bloodType.isNotEmpty)
                            _buildMedicalInfoRow('Blood Type', _bloodType, Colors.red),
                          if (_allergies.isNotEmpty)
                            _buildMedicalInfoRow('Allergies', _allergies, Colors.orange),
                          if (_conditions.isNotEmpty)
                            _buildMedicalInfoRow('Conditions', _conditions, Colors.purple),
                          if (_medications.isNotEmpty)
                            _buildMedicalInfoRow('Medications', _medications, Colors.blue),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showMedicalID() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.red[900]!, Colors.red[700]!],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.medical_services, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MEDICAL ID',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'Emergency Medical Information',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white30),
              const SizedBox(height: 12),
              if (_bloodType.isNotEmpty)
                _buildMedicalIDRow('Blood Type', _bloodType),
              if (_allergies.isNotEmpty)
                _buildMedicalIDRow('Allergies', _allergies),
              if (_conditions.isNotEmpty)
                _buildMedicalIDRow('Conditions', _conditions),
              if (_medications.isNotEmpty)
                _buildMedicalIDRow('Medications', _medications),
              if (_doctorName.isNotEmpty)
                _buildMedicalIDRow('Doctor', _doctorName),
              if (_doctorPhone.isNotEmpty)
                _buildMedicalIDRow('Doctor Phone', _doctorPhone),
              if (_hospital.isNotEmpty)
                _buildMedicalIDRow('Hospital', _hospital),
              if (_emergencyNotes.isNotEmpty)
                _buildMedicalIDRow('Notes', _emergencyNotes),
              const SizedBox(height: 16),
              const Divider(color: Colors.white30),
              const SizedBox(height: 8),
              const Text(
                'In case of emergency, please share this information with medical personnel.',
                style: TextStyle(color: Colors.white70, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red[900],
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalIDRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDecoyScreen() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Decoy Screen Preview',
          style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calculate, color: Colors.white, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    _decoyAppName,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '0',
                    style: TextStyle(color: Colors.white, fontSize: 48),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This is what others will see when they open the app. Hold volume up + volume down simultaneously to reveal the real app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showIntruderLog() {
    final user = _auth.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.red),
                  const SizedBox(width: 12),
                  const Text(
                    'Intruder Log',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('intruder_log')
                    .orderBy('timestamp', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  final logs = snapshot.data?.docs ?? [];

                  if (logs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'No intruder attempts detected',
                            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index].data() as Map<String, dynamic>;
                      final timestamp = log['timestamp'] as Timestamp?;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.red,
                            child: Icon(Icons.warning_amber, color: Colors.white, size: 20),
                          ),
                          title: Text(
                            'Failed PIN Attempt',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.headlineMedium?.color,
                            ),
                          ),
                          subtitle: Text(
                            timestamp?.toDate().toString().substring(0, 19) ?? 'Unknown time',
                            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                          trailing: const Icon(Icons.camera_alt, color: Colors.grey),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  String _formatTime(int hour, int minute) {
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    return h.toString() + ':' + m + ' ' + period;
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Security & Medical Modes')),
        body: Center(
          child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security & Medical Modes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.security), text: 'Security'),
            Tab(icon: Icon(Icons.medical_services), text: 'Medical'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSecurityTab(),
          _buildMedicalTab(),
        ],
      ),
    );
  }

  // ==================== SECURITY TAB ====================

  Widget _buildSecurityTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        _buildSectionHeader('STEALTH MODE', Icons.visibility_off, Colors.indigo),
        const SizedBox(height: 8),

        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.visibility_off, color: Colors.indigo),
                title: Text(
                  'Stealth Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                  ),
                ),
                subtitle: Text(
                  'Hide that this is a panic app',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                ),
                value: _stealthModeEnabled,
                onChanged: (val) async {
                  await _vibrationService.light();
                  setState(() => _stealthModeEnabled = val);
                  await _saveSetting('stealth_mode_enabled', val);
                  _showSnackBar(val ? 'Stealth mode enabled' : 'Stealth mode disabled', Colors.indigo);
                },
              ),
              if (_stealthModeEnabled) ...[
                const Divider(height: 1),
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.indigo.withOpacity(0.05),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.indigo, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'App icon and name are hidden. Use volume up + volume down to access the app.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        _buildSectionHeader('DECOY SCREEN', Icons.phonelink_lock, Colors.purple),
        const SizedBox(height: 8),

        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.phonelink_lock, color: Colors.purple),
                title: Text(
                  'Decoy Screen',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                  ),
                ),
                subtitle: Text(
                  'Show a fake app screen to others',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                ),
                value: _decoyScreenEnabled,
                onChanged: (val) async {
                  await _vibrationService.light();
                  setState(() => _decoyScreenEnabled = val);
                  await _saveSetting('decoy_screen_enabled', val);
                },
              ),
              if (_decoyScreenEnabled) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _decoyNameController,
                        decoration: InputDecoration(
                          labelText: 'Decoy App Name',
                          hintText: 'e.g. Calculator, Notes, Weather',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.edit),
                        ),
                        onChanged: (val) async {
                          setState(() => _decoyAppName = val);
                          await _saveSetting('decoy_app_name', val);
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.preview),
                          label: const Text('Preview Decoy Screen'),
                          onPressed: _showDecoyScreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        _buildSectionHeader('INTRUDER DETECTION', Icons.camera_alt, Colors.red),
        const SizedBox(height: 8),

        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.camera_alt, color: Colors.red),
                title: Text(
                  'Intruder Detection',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                  ),
                ),
                subtitle: Text(
                  'Log failed PIN attempts and alert you',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                ),
                value: _intruderDetectionEnabled,
                onChanged: (val) async {
                  await _vibrationService.light();
                  setState(() => _intruderDetectionEnabled = val);
                  await _saveSetting('intruder_detection_enabled', val);
                },
              ),
              if (_intruderDetectionEnabled) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.grey),
                  title: Text(
                    'View Intruder Log',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  subtitle: Text(
                    'See failed access attempts',
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showIntruderLog,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        _buildSectionHeader('SHAKE TO CALL', Icons.phone, Colors.green),
        const SizedBox(height: 8),

        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.phone, color: Colors.green),
                title: Text(
                  'Shake to Call',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                  ),
                ),
                subtitle: Text(
                  'Shake device to call emergency number directly',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                ),
                value: _shakeToCallEnabled,
                onChanged: (val) async {
                  await _vibrationService.light();
                  setState(() => _shakeToCallEnabled = val);
                  await _saveSetting('shake_to_call_enabled', val);
                },
              ),
              if (_shakeToCallEnabled) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _callNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Emergency Call Number',
                      hintText: 'e.g. 911 or +1234567890',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    onChanged: (val) async {
                      setState(() => _emergencyCallNumber = val);
                      await _saveSetting('emergency_call_number', val);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        _buildSectionHeader('COVERT RECORDING', Icons.mic, Colors.orange),
        const SizedBox(height: 8),

        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.mic, color: Colors.orange),
                title: Text(
                  'Covert Recording',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                  ),
                ),
                subtitle: Text(
                  'Record audio in background during emergency',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                ),
                value: _covertRecordingEnabled,
                onChanged: (val) async {
                  await _vibrationService.light();
                  setState(() => _covertRecordingEnabled = val);
                  await _saveSetting('covert_recording_enabled', val);
                  if (val) {
                    _showSnackBar('Covert recording will activate when panic is triggered', Colors.orange);
                  }
                },
              ),
              if (_covertRecordingEnabled) ...[
                const Divider(height: 1),
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.orange.withOpacity(0.05),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Audio recording will begin automatically when a panic alert is triggered. Recordings are stored locally and can be shared with authorities.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  // ==================== MEDICAL TAB ====================

  Widget _buildMedicalTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        _buildSectionHeader('MEDICAL ID', Icons.medical_services, Colors.red),
        const SizedBox(height: 8),

        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.medical_services, color: Colors.red),
                title: Text(
                  'Medical ID',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                  ),
                ),
                subtitle: Text(
                  'Show medical info on lock screen',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                ),
                value: _medicalIdEnabled,
                onChanged: (val) async {
                  await _vibrationService.light();
                  setState(() => _medicalIdEnabled = val);
                  await _saveSetting('medical_id_enabled', val);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.preview, color: Colors.red),
                title: Text(
                  'Preview Medical ID Card',
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showMedicalID,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        _buildSectionHeader('MEDICAL INFORMATION', Icons.edit_note, Colors.purple),
        const SizedBox(height: 8),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMedicalTextField('Blood Type', _bloodType, 'e.g. A+, B-, O+', (val) => setState(() => _bloodType = val)),
                const SizedBox(height: 12),
                _buildMedicalTextField('Allergies', _allergies, 'e.g. Penicillin, Peanuts', (val) => setState(() => _allergies = val)),
                const SizedBox(height: 12),
                _buildMedicalTextField('Medical Conditions', _conditions, 'e.g. Diabetes, Asthma', (val) => setState(() => _conditions = val)),
                const SizedBox(height: 12),
                _buildMedicalTextField('Current Medications', _medications, 'e.g. Metformin 500mg', (val) => setState(() => _medications = val)),
                const SizedBox(height: 12),
                _buildMedicalTextField('Emergency Notes', _emergencyNotes, 'Any important notes for responders', (val) => setState(() => _emergencyNotes = val), maxLines: 3),
                const SizedBox(height: 12),
                _buildMedicalTextField('Doctor Name', _doctorName, 'e.g. Dr. Smith', (val) => setState(() => _doctorName = val)),
                const SizedBox(height: 12),
                _buildMedicalTextField('Doctor Phone', _doctorPhone, 'e.g. +1234567890', (val) => setState(() => _doctorPhone = val)),
                const SizedBox(height: 12),
                _buildMedicalTextField('Preferred Hospital', _hospital, 'e.g. City General Hospital', (val) => setState(() => _hospital = val)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Medical Info'),
                    onPressed: _saveMedicalInfo,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        _buildSectionHeader('AUTO SHARE', Icons.share, Colors.blue),
        const SizedBox(height: 8),

        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.share, color: Colors.blue),
                title: Text(
                  'Auto Share Medical Info',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                  ),
                ),
                subtitle: Text(
                  'Automatically include medical info in panic alerts',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                ),
                value: _autoShareMedicalEnabled,
                onChanged: (val) async {
                  await _vibrationService.light();
                  setState(() => _autoShareMedicalEnabled = val);
                  await _saveSetting('auto_share_medical_enabled', val);
                  await _saveMedicalInfo();
                },
              ),
              if (_autoShareMedicalEnabled) ...[
                const Divider(height: 1),
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue.withOpacity(0.05),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your blood type, allergies and critical conditions will be included in all panic alerts.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        _buildSectionHeader('ONE-TAP DOCTOR CALL', Icons.phone, Colors.green),
        const SizedBox(height: 8),

        Card(
          child: ListTile(
            leading: const Icon(Icons.phone, color: Colors.green),
            title: Text(
              _doctorName.isNotEmpty ? 'Call ' + _doctorName : 'Call Doctor',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
            ),
            subtitle: Text(
              _doctorPhone.isNotEmpty ? _doctorPhone : 'Add doctor phone number above',
              style: TextStyle(
                color: _doctorPhone.isNotEmpty ? Colors.green : Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
            trailing: _doctorPhone.isNotEmpty
                ? ElevatedButton.icon(
              icon: const Icon(Icons.phone, size: 16),
              label: const Text('Call', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () async {
                await _vibrationService.light();
                _showSnackBar('Calling ' + _doctorName, Colors.green);
              },
            )
                : null,
          ),
        ),

        const SizedBox(height: 24),

        _buildSectionHeader('MEDICATION REMINDERS', Icons.medication, Colors.teal),
        const SizedBox(height: 8),

        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.medication, color: Colors.teal),
                title: Text(
                  'Medication Reminders',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                  ),
                ),
                subtitle: Text(
                  'Get notified to take your medications',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
                ),
                value: _medicationRemindersEnabled,
                onChanged: (val) async {
                  await _vibrationService.light();
                  setState(() => _medicationRemindersEnabled = val);
                  await _saveSetting('medication_reminders_enabled', val);
                },
              ),
              if (_medicationRemindersEnabled) ...[
                const Divider(height: 1),
                if (_medicationReminders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No reminders set. Tap + to add one.',
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  )
                else
                  ..._medicationReminders.map((reminder) {
                    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    final days = reminder['days'] as List?;
                    final activeDays = days != null
                        ? dayNames.asMap().entries
                        .where((e) => days[e.key] == true)
                        .map((e) => e.value)
                        .join(', ')
                        : 'Every day';

                    return ListTile(
                      leading: const Icon(Icons.medication, color: Colors.teal),
                      title: Text(
                        reminder['name'] as String? ?? 'Unknown',
                        style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color),
                      ),
                      subtitle: Text(
                        (reminder['dosage'] as String? ?? '') + ' - ' +
                            _formatTime(reminder['hour'] as int? ?? 0, reminder['minute'] as int? ?? 0) +
                            '\n' + activeDays,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 11,
                        ),
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: reminder['active'] as bool? ?? true,
                            onChanged: (val) => _toggleMedicationReminder(reminder['id'] as String, val),
                            activeColor: Colors.teal,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _deleteMedicationReminder(
                              reminder['id'] as String,
                              reminder['name'] as String? ?? 'Unknown',
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.add_circle, color: Colors.teal),
                  title: Text(
                    'Add Medication Reminder',
                    style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                  ),
                  onTap: _addMedicationReminder,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        _buildSectionHeader('EMERGENCY CHECKLIST', Icons.checklist, Colors.red),
        const SizedBox(height: 8),

        Card(
          child: ListTile(
            leading: const Icon(Icons.checklist, color: Colors.red),
            title: Text(
              'Medical Emergency Checklist',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
            ),
            subtitle: Text(
              'Step-by-step guide for medical emergencies',
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showMedicalEmergencyChecklist,
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalTextField(
      String label,
      String value,
      String hint,
      ValueChanged<String> onChanged, {
        int maxLines = 1,
      }) {
    return TextFormField(
      initialValue: value,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onChanged: onChanged,
    );
  }
}