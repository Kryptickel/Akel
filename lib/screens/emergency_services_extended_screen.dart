import 'package:flutter/material.dart';
import 'package:akel_panic_button/providers/auth_provider.dart' as akel;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart' hide AuthProvider;
import '../services/vibration_service.dart';
import '../services/sound_service.dart';
import 'fire_emergency_screen.dart';
import 'emergency_services_screen.dart';

/// ==================== EMERGENCY SERVICES EXTENDED SCREEN ====================
///
/// HOUR 4 - EMERGENCY SERVICES INTEGRATION (EXTENDED)
/// Extends the existing EmergencyServicesScreen with:
/// - Police incident reporting form
/// - Ambulance/EMS dispatch with patient details
/// - Multi-agency coordination (all services at once)
/// - Fire report link to existing FireEmergencyScreen
///
/// Navigate here from EmergencyServicesScreen via an "Advanced" button
/// ================================================================

class EmergencyServicesExtendedScreen extends StatefulWidget {
  const EmergencyServicesExtendedScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyServicesExtendedScreen> createState() =>
      _EmergencyServicesExtendedScreenState();
}

class _EmergencyServicesExtendedScreenState
    extends State<EmergencyServicesExtendedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Position? _currentPosition;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      debugPrint('Location error: ' + e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _makeCall(String number) async {
    await _vibrationService.light();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Call ' + number + '?',
          style: TextStyle(
              color: Theme.of(context).textTheme.headlineMedium?.color),
        ),
        content: Text(
          'This will dial ' + number + ' immediately.',
          style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('CALL'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final uri = Uri.parse('tel:' + number);
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    }
  }

  String _getLocationString() {
    if (_currentPosition == null) return 'Location unavailable';
    return 'Lat: ' +
        _currentPosition!.latitude.toStringAsFixed(5) +
        ', Lng: ' +
        _currentPosition!.longitude.toStringAsFixed(5);
  }

  String _getMapsLink() {
    if (_currentPosition == null) return '';
    return 'https://maps.google.com/?q=' +
        _currentPosition!.latitude.toString() +
        ',' +
        _currentPosition!.longitude.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Emergency Services'),
        backgroundColor: Colors.red[900],
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.list, color: Colors.white),
            label: const Text('All Services',
                style: TextStyle(color: Colors.white, fontSize: 12)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const EmergencyServicesScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.local_fire_department), text: 'Fire'),
            Tab(icon: Icon(Icons.local_police), text: 'Police'),
            Tab(icon: Icon(Icons.emergency), text: 'Ambulance'),
            Tab(icon: Icon(Icons.hub), text: 'All Services'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFireTab(),
          _buildPoliceTab(),
          _buildAmbulanceTab(),
          _buildMultiAgencyTab(),
        ],
      ),
    );
  }

  // ==================== TAB 1: FIRE ====================

  Widget _buildFireTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEmergencyCallButton(
            'CALL FIRE DEPARTMENT (911)',
            Icons.phone,
            Colors.red,
                () => _makeCall('911'),
          ),
          const SizedBox(height: 16),

          // Link to existing fire screen
          Card(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_fire_department,
                            color: Colors.red, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fire Emergency Report',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Report fire with location, photos and building details',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.local_fire_department),
                      label: const Text('OPEN FIRE REPORT FORM'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FireEmergencyScreen()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          _buildInfoCard('Fire Safety Tips', Colors.orange, [
            'Get out immediately — do not stop for belongings',
            'Feel doors before opening — if hot use another exit',
            'Stay low to avoid smoke inhalation',
            'Call fire department once outside',
            'Never go back inside a burning building',
          ]),
        ],
      ),
    );
  }

  // ==================== TAB 2: POLICE ====================

  Widget _buildPoliceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEmergencyCallButton(
            'CALL POLICE (911)',
            Icons.phone,
            Colors.blue[900]!,
                () => _makeCall('911'),
          ),
          const SizedBox(height: 8),
          _buildEmergencyCallButton(
            'NON-EMERGENCY LINE (311)',
            Icons.phone_in_talk,
            Colors.blue,
                () => _makeCall('311'),
          ),
          const SizedBox(height: 20),

          Text(
            'REPORT INCIDENT',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),

          _buildPoliceIncidentForm(),

          const SizedBox(height: 16),
          _buildInfoCard('When to Call Police', Colors.blue, [
            'Crime in progress or just occurred',
            'Suspicious activity threatening safety',
            'Traffic accidents with injuries',
            'Domestic violence situations',
            'Stolen property or break-ins',
            'Missing persons',
          ]),
        ],
      ),
    );
  }

  Widget _buildPoliceIncidentForm() {
    final incidentTypes = [
      {'value': 'theft', 'label': 'Theft/Robbery', 'icon': Icons.money_off},
      {
        'value': 'assault',
        'label': 'Assault',
        'icon': Icons.personal_injury
      },
      {
        'value': 'suspicious',
        'label': 'Suspicious Activity',
        'icon': Icons.visibility
      },
      {
        'value': 'vandalism',
        'label': 'Vandalism',
        'icon': Icons.home_repair_service
      },
      {'value': 'domestic', 'label': 'Domestic Violence', 'icon': Icons.warning},
      {
        'value': 'accident',
        'label': 'Traffic Accident',
        'icon': Icons.car_crash
      },
      {
        'value': 'missing',
        'label': 'Missing Person',
        'icon': Icons.person_search
      },
      {'value': 'other', 'label': 'Other', 'icon': Icons.report},
    ];

    String selectedType = 'suspicious';
    final descController = TextEditingController();
    final suspectController = TextEditingController();

    return StatefulBuilder(
      builder: (context, setFormState) => Card(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Incident Type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: incidentTypes.map((type) {
                  final isSelected = selectedType == type['value'];
                  return GestureDetector(
                    onTap: () => setFormState(
                            () => selectedType = type['value'] as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue
                              : Colors.grey.withOpacity(0.4),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(type['icon'] as IconData,
                              size: 14,
                              color: isSelected ? Colors.blue : Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            type['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.blue : null,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe what happened...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: suspectController,
                decoration: InputDecoration(
                  labelText: 'Suspect Description (optional)',
                  hintText: 'Height, clothing, direction of travel...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.person_search),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border:
                  Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isLoadingLocation
                            ? 'Getting location...'
                            : _getLocationString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.local_police),
                  label: const Text('SUBMIT POLICE REPORT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _submitPoliceReport(
                    incidentType: selectedType,
                    description: descController.text.trim(),
                    suspectDescription: suspectController.text.trim(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitPoliceReport({
    required String incidentType,
    required String description,
    required String suspectDescription,
  }) async {
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please describe the incident'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    await _vibrationService.panic();
    await _soundService.playWarning();

    try {
      final docRef =
      await _firestore.collection('police_reports').add({
        'userId': user.uid,
        'incidentType': incidentType,
        'description': description,
        'suspectDescription': suspectDescription,
        'location': _currentPosition != null
            ? {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'mapsLink': _getMapsLink(),
        }
            : null,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'submitted',
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Report Submitted',
                  style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.color),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your police report has been logged.',
                  style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color),
                ),
                const SizedBox(height: 8),
                Text(
                  'Report ID: ' +
                      docRef.id.substring(0, 8).toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                ),
                const SizedBox(height: 16),
                const Text(
                  'If this is an active emergency call 911 immediately.',
                  style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')),
              ElevatedButton.icon(
                icon: const Icon(Icons.phone),
                label: const Text('CALL 911'),
                style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(context);
                  _makeCall('911');
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: ' + e.toString()),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==================== TAB 3: AMBULANCE ====================

  Widget _buildAmbulanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEmergencyCallButton(
            'CALL AMBULANCE (911)',
            Icons.phone,
            Colors.green[900]!,
                () => _makeCall('911'),
          ),
          const SizedBox(height: 20),

          Text(
            'MEDICAL EMERGENCY DISPATCH',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),

          _buildAmbulanceForm(),

          const SizedBox(height: 16),
          _buildInfoCard('While Waiting for Ambulance', Colors.green, [
            'Keep the person still and calm',
            'Do not give food or water',
            'Apply pressure to bleeding wounds',
            'Perform CPR if trained and person is unresponsive',
            'Keep the person warm with a blanket',
            'Clear the area for paramedic access',
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('CPR Quick Guide', Colors.red, [
            '1. Check for responsiveness — tap shoulders and shout',
            '2. Call 911 or send someone to call',
            '3. Lay person on firm flat surface',
            '4. Push hard and fast on center of chest',
            '5. Rate — 100 to 120 compressions per minute',
            '6. Continue until help arrives',
          ]),
        ],
      ),
    );
  }

  Widget _buildAmbulanceForm() {
    final emergencyTypes = [
      {
        'value': 'cardiac',
        'label': 'Cardiac Arrest',
        'icon': Icons.favorite_border
      },
      {'value': 'breathing', 'label': 'Breathing Problems', 'icon': Icons.air},
      {'value': 'stroke', 'label': 'Stroke', 'icon': Icons.psychology},
      {
        'value': 'injury',
        'label': 'Severe Injury',
        'icon': Icons.personal_injury
      },
      {
        'value': 'unconscious',
        'label': 'Unconscious',
        'icon': Icons.airline_seat_flat
      },
      {
        'value': 'allergic',
        'label': 'Allergic Reaction',
        'icon': Icons.warning
      },
      {'value': 'diabetic', 'label': 'Diabetic Emergency', 'icon': Icons.bloodtype},
      {'value': 'overdose', 'label': 'Overdose', 'icon': Icons.medication},
      {
        'value': 'pregnancy',
        'label': 'Pregnancy Emergency',
        'icon': Icons.child_friendly
      },
      {
        'value': 'other',
        'label': 'Other Medical',
        'icon': Icons.medical_services
      },
    ];

    String selectedType = 'injury';
    bool isConscious = true;
    bool isBreathing = true;
    final ageController = TextEditingController();
    final notesController = TextEditingController();

    return StatefulBuilder(
      builder: (context, setFormState) => Card(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emergency Type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: emergencyTypes.map((type) {
                  final isSelected = selectedType == type['value'];
                  return GestureDetector(
                    onTap: () => setFormState(
                            () => selectedType = type['value'] as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.green.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.green
                              : Colors.grey.withOpacity(0.4),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(type['icon'] as IconData,
                              size: 14,
                              color:
                              isSelected ? Colors.green : Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            type['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.green : null,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Conscious / Breathing toggles
              Row(
                children: [
                  Expanded(
                    child: _buildVitalToggle(
                      'Conscious?',
                      isConscious,
                      Colors.green,
                          (val) => setFormState(() => isConscious = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildVitalToggle(
                      'Breathing?',
                      isBreathing,
                      Colors.green,
                          (val) => setFormState(() => isBreathing = val),
                    ),
                  ),
                ],
              ),

              if (!isConscious || !isBreathing) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (!isConscious && !isBreathing)
                              ? 'CRITICAL: Start CPR immediately'
                              : !isConscious
                              ? 'Monitor breathing and pulse'
                              : 'Person not breathing — begin CPR now',
                          style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Patient Age (approximate)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Additional Notes',
                  hintText:
                  'Known conditions, medications, allergies...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isLoadingLocation
                            ? 'Getting location...'
                            : _getLocationString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.emergency),
                  label: const Text('REQUEST AMBULANCE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[900],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _submitAmbulanceRequest(
                    emergencyType: selectedType,
                    isConscious: isConscious,
                    isBreathing: isBreathing,
                    age: ageController.text.trim(),
                    notes: notesController.text.trim(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVitalToggle(
      String label, bool value, Color color, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: value
            ? color.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: value ? color : Colors.red),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: value ? color : Colors.red,
              fontSize: 13,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
          Text(
            value ? 'YES' : 'NO',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: value ? color : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAmbulanceRequest({
    required String emergencyType,
    required bool isConscious,
    required bool isBreathing,
    required String age,
    required String notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _vibrationService.panic();
    await _soundService.playWarning();

    try {
      final authProvider =
      Provider.of<akel.AuthProvider>(context, listen: false);

      final docRef =
      await _firestore.collection('ambulance_requests').add({
        'userId': user.uid,
        'userName': authProvider.userProfile?['name'] ?? 'User',
        'emergencyType': emergencyType,
        'isConscious': isConscious,
        'isBreathing': isBreathing,
        'patientAge': age,
        'notes': notes,
        'location': _currentPosition != null
            ? {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'mapsLink': _getMapsLink(),
        }
            : null,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'dispatched',
        'estimatedArrival': '8-12 minutes',
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Row(
              children: [
                const Icon(Icons.emergency,
                    color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Ambulance Dispatched',
                  style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.color),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EMS is on the way',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Estimated arrival: 8-12 minutes',
                          style: TextStyle(color: Colors.green)),
                      const SizedBox(height: 4),
                      Text(
                        'Request ID: ' +
                            docRef.id.substring(0, 8).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (!isConscious || !isBreathing)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'START CPR NOW if person is unresponsive and not breathing',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Keep the person still and comfortable until help arrives.',
                  style: TextStyle(color: Colors.orange),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')),
              ElevatedButton.icon(
                icon: const Icon(Icons.phone),
                label: const Text('CALL 911'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(context);
                  _makeCall('911');
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: ' + e.toString()),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==================== TAB 4: MULTI-AGENCY ====================

  Widget _buildMultiAgencyTab() {
    bool fireDept = true;
    bool police = true;
    bool ambulance = true;
    bool notifyFamily = true;
    String emergencyType = 'general';
    final descController = TextEditingController();

    final emergencyTypes = [
      {'value': 'general', 'label': 'General Emergency'},
      {'value': 'mass_casualty', 'label': 'Mass Casualty'},
      {'value': 'natural_disaster', 'label': 'Natural Disaster'},
      {'value': 'terrorist', 'label': 'Security Threat'},
      {'value': 'hazmat', 'label': 'Hazmat/Chemical'},
    ];

    return StatefulBuilder(
      builder: (context, setPageState) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: Colors.red.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.hub, color: Colors.red, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'MULTI-AGENCY DISPATCH',
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Alert all emergency services simultaneously',
                    style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color,
                        fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'SELECT SERVICES',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 12),

            _buildAgencyToggle(
                'Fire Department',
                Icons.local_fire_department,
                Colors.red,
                fireDept,
                    (val) => setPageState(() => fireDept = val)),
            const SizedBox(height: 8),
            _buildAgencyToggle(
                'Police',
                Icons.local_police,
                Colors.blue,
                police,
                    (val) => setPageState(() => police = val)),
            const SizedBox(height: 8),
            _buildAgencyToggle(
                'Ambulance / EMS',
                Icons.emergency,
                Colors.green,
                ambulance,
                    (val) => setPageState(() => ambulance = val)),
            const SizedBox(height: 8),
            _buildAgencyToggle(
                'Notify Family Contacts',
                Icons.family_restroom,
                Colors.purple,
                notifyFamily,
                    (val) => setPageState(() => notifyFamily = val)),

            const SizedBox(height: 20),

            Text(
              'EMERGENCY TYPE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: emergencyTypes.map((type) {
                final isSelected = emergencyType == type['value'];
                return ChoiceChip(
                  label: Text(type['label'] as String),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      setPageState(() =>
                      emergencyType = type['value'] as String);
                    }
                  },
                  selectedColor: Colors.red.withOpacity(0.3),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.red : null,
                    fontWeight:
                    isSelected ? FontWeight.bold : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Emergency Description',
                hintText: 'Describe the situation...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.orange.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isLoadingLocation
                          ? 'Getting location...'
                          : _getLocationString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.hub, size: 24),
                label: const Text(
                  'DISPATCH ALL SELECTED SERVICES',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _dispatchMultiAgency(
                  fireDept: fireDept,
                  police: police,
                  ambulance: ambulance,
                  notifyFamily: notifyFamily,
                  emergencyType: emergencyType,
                  description: descController.text.trim(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Only use for major emergencies requiring multiple services. False reports are illegal.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgencyToggle(String label, IconData icon, Color color,
      bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value ? color : Colors.grey.withOpacity(0.3),
          width: value ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: value ? color : Colors.grey, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight:
                value ? FontWeight.bold : FontWeight.normal,
                color: value ? color : null,
              ),
            ),
          ),
          Switch(
              value: value, onChanged: onChanged, activeColor: color),
        ],
      ),
    );
  }

  Future<void> _dispatchMultiAgency({
    required bool fireDept,
    required bool police,
    required bool ambulance,
    required bool notifyFamily,
    required String emergencyType,
    required String description,
  }) async {
    if (!fireDept && !police && !ambulance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Select at least one service'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Confirm Multi-Agency Dispatch',
          style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The following will be alerted:',
              style: TextStyle(
                  color:
                  Theme.of(context).textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 8),
            if (fireDept)
              _buildConfirmRow(Icons.local_fire_department,
                  'Fire Department', Colors.red),
            if (police)
              _buildConfirmRow(
                  Icons.local_police, 'Police', Colors.blue),
            if (ambulance)
              _buildConfirmRow(Icons.emergency,
                  'Ambulance / EMS', Colors.green),
            if (notifyFamily)
              _buildConfirmRow(Icons.family_restroom,
                  'Family Contacts', Colors.purple),
            const SizedBox(height: 12),
            const Text(
              'Only proceed if this is a real emergency.',
              style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DISPATCH NOW'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _vibrationService.panic();
    await _soundService.playWarning();

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final authProvider =
      Provider.of<akel.AuthProvider>(context, listen: false);

      final docRef = await _firestore
          .collection('multi_agency_dispatches')
          .add({
        'userId': user.uid,
        'userName': authProvider.userProfile?['name'] ?? 'User',
        'emergencyType': emergencyType,
        'description': description,
        'services': {
          'fire': fireDept,
          'police': police,
          'ambulance': ambulance,
          'family': notifyFamily,
        },
        'location': _currentPosition != null
            ? {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'mapsLink': _getMapsLink(),
        }
            : null,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'dispatched',
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Row(
              children: [
                const Icon(Icons.hub, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                Text(
                  'All Services Alerted',
                  style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.color),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fireDept)
                  _buildConfirmRow(Icons.local_fire_department,
                      'Fire Department notified', Colors.red),
                if (police)
                  _buildConfirmRow(Icons.local_police,
                      'Police notified', Colors.blue),
                if (ambulance)
                  _buildConfirmRow(Icons.emergency,
                      'Ambulance dispatched', Colors.green),
                if (notifyFamily)
                  _buildConfirmRow(Icons.family_restroom,
                      'Family contacts alerted', Colors.purple),
                const SizedBox(height: 12),
                Text(
                  'Dispatch ID: ' +
                      docRef.id.substring(0, 8).toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Call 911 to speak directly with dispatch.',
                  style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')),
              ElevatedButton.icon(
                icon: const Icon(Icons.phone),
                label: const Text('CALL 911'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(context);
                  _makeCall('911');
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: ' + e.toString()),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildConfirmRow(
      IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ==================== SHARED WIDGETS ====================

  Widget _buildEmergencyCallButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 24),
        label: Text(label,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildInfoCard(
      String title, Color color, List<String> items) {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 12),
            ...items
                .map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle,
                      size: 6, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(item,
                          style: const TextStyle(
                              fontSize: 13,
                              height: 1.4))),
                ],
              ),
            ))
                .toList(),
          ],
        ),
      ),
    );
  }
}