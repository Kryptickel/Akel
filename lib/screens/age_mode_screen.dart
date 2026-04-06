import 'package:flutter/material.dart';
import '../services/age_mode_service.dart';

class AgeModeScreen extends StatefulWidget {
  const AgeModeScreen({super.key});

  @override
  State<AgeModeScreen> createState() => _AgeModeScreenState();
}

class _AgeModeScreenState extends State<AgeModeScreen> {
  final AgeModeService _ageModeService = AgeModeService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _ageModeService.initialize();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E27),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
        ),
      );
    }

    final currentMode = _ageModeService.getCurrentMode();
    final userAge = _ageModeService.getUserAge();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Age-Specific Modes'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
// Current Mode Card
          _buildCurrentModeCard(currentMode, userAge),

          const SizedBox(height: 24),

// Mode Selection
          _buildSectionHeader('Select Mode'),
          const SizedBox(height: 12),
          _buildModeCard(
            AgeMode.kid,
            'Kid Mode',
            'Simplified interface for children',
            Icons.child_care,
            Colors.blue,
            currentMode == AgeMode.kid,
          ),
          const SizedBox(height: 12),
          _buildModeCard(
            AgeMode.standard,
            'Standard Mode',
            'Full features for adults',
            Icons.person,
            const Color(0xFF00BFA5),
            currentMode == AgeMode.standard,
          ),
          const SizedBox(height: 12),
          _buildModeCard(
            AgeMode.senior,
            'Senior Mode',
            'Large buttons and voice control',
            Icons.elderly,
            Colors.orange,
            currentMode == AgeMode.senior,
          ),

          const SizedBox(height: 24),

// Mode-Specific Settings
          if (currentMode == AgeMode.kid) _buildKidModeSettings(),
          if (currentMode == AgeMode.senior) _buildSeniorModeSettings(),

          const SizedBox(height: 24),

// School Zones (for Kid Mode)
          if (currentMode == AgeMode.kid) _buildSchoolZonesSection(),

          const SizedBox(height: 24),

// Parental Controls (for Kid Mode)
          if (currentMode == AgeMode.kid) _buildParentalControlsSection(),
        ],
      ),
    );
  }

  Widget _buildCurrentModeCard(AgeMode mode, int age) {
    String modeName;
    IconData icon;
    Color color;

    switch (mode) {
      case AgeMode.kid:
        modeName = 'Kid Mode';
        icon = Icons.child_care;
        color = Colors.blue;
        break;
      case AgeMode.senior:
        modeName = 'Senior Mode';
        icon = Icons.elderly;
        color = Colors.orange;
        break;
      case AgeMode.standard:
      default:
        modeName = 'Standard Mode';
        icon = Icons.person;
        color = const Color(0xFF00BFA5);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Mode',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  modeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Age: $age years',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _changeAge(),
            icon: const Icon(Icons.edit, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(
      AgeMode mode,
      String title,
      String description,
      IconData icon,
      Color color,
      bool isSelected,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectMode(mode),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? color : Colors.white38,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKidModeSettings() {
    final settings = _ageModeService.getKidSettings();
    final badges = _ageModeService.getAvailableBadges();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Kid Mode Features'),
        const SizedBox(height: 12),

// Gamification Stats
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.purple, Colors.deepPurple],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                  SizedBox(width: 12),
                  Text(
                    'Safety Points',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${settings.safetyPoints}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${settings.earnedBadges.length} badges earned',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

// Badges
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2740),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.stars, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Badges',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: badges.map((badge) {
                  final earned = badge['earned'] as bool;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: earned
                          ? Colors.amber.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: earned ? Colors.amber : Colors.white24,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          badge['icon'] as IconData,
                          color: earned ? Colors.amber : Colors.white38,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          badge['name'] as String,
                          style: TextStyle(
                            color: earned ? Colors.amber : Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeniorModeSettings() {
    final settings = _ageModeService.getSeniorSettings();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Senior Mode Settings'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2740),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text(
                  'Voice Control',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Control app with voice commands',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                value: settings.voiceControlEnabled,
                onChanged: (value) {
                  final updated = SeniorModeSettings(
                    textSize: settings.textSize,
                    voiceControlEnabled: value,
                    medicationReminders: settings.medicationReminders,
                    medicationSchedule: settings.medicationSchedule,
                    fallDetectionSensitive: settings.fallDetectionSensitive,
                    largeButtonsEnabled: settings.largeButtonsEnabled,
                  );
                  _ageModeService.updateSeniorSettings(updated);
                  setState(() {});
                },
                activeColor: Colors.orange,
              ),
              SwitchListTile(
                title: const Text(
                  'Medication Reminders',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Get reminders to take medications',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                value: settings.medicationReminders,
                onChanged: (value) {
                  final updated = SeniorModeSettings(
                    textSize: settings.textSize,
                    voiceControlEnabled: settings.voiceControlEnabled,
                    medicationReminders: value,
                    medicationSchedule: settings.medicationSchedule,
                    fallDetectionSensitive: settings.fallDetectionSensitive,
                    largeButtonsEnabled: settings.largeButtonsEnabled,
                  );
                  _ageModeService.updateSeniorSettings(updated);
                  setState(() {});
                },
                activeColor: Colors.orange,
              ),
              SwitchListTile(
                title: const Text(
                  'Sensitive Fall Detection',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'More sensitive to falls',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                value: settings.fallDetectionSensitive,
                onChanged: (value) {
                  final updated = SeniorModeSettings(
                    textSize: settings.textSize,
                    voiceControlEnabled: settings.voiceControlEnabled,
                    medicationReminders: settings.medicationReminders,
                    medicationSchedule: settings.medicationSchedule,
                    fallDetectionSensitive: value,
                    largeButtonsEnabled: settings.largeButtonsEnabled,
                  );
                  _ageModeService.updateSeniorSettings(updated);
                  setState(() {});
                },
                activeColor: Colors.orange,
              ),
              const Divider(color: Colors.white12),
              ListTile(
                title: const Text(
                  'Text Size',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Slider(
                  value: settings.textSize,
                  min: 1.0,
                  max: 2.5,
                  divisions: 15,
                  label: '${(settings.textSize * 100).round()}%',
                  activeColor: Colors.orange,
                  onChanged: (value) {
                    final updated = SeniorModeSettings(
                      textSize: value,
                      voiceControlEnabled: settings.voiceControlEnabled,
                      medicationReminders: settings.medicationReminders,
                      medicationSchedule: settings.medicationSchedule,
                      fallDetectionSensitive: settings.fallDetectionSensitive,
                      largeButtonsEnabled: settings.largeButtonsEnabled,
                    );
                    _ageModeService.updateSeniorSettings(updated);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolZonesSection() {
    final zones = _ageModeService.getSchoolZones();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('School Zones'),
            TextButton.icon(
              onPressed: () => _addSchoolZone(),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (zones.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No school zones configured',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          )
        else
          ...zones.map((zone) => _buildSchoolZoneCard(zone)),
      ],
    );
  }

  Widget _buildSchoolZoneCard(SchoolZone zone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.school, color: Colors.blue, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zone.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${zone.arrivalTime} - ${zone.departureTime}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeSchoolZone(zone.id),
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildParentalControlsSection() {
    final controls = _ageModeService.getParentalControl();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Parental Controls'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2740),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text(
                  'Require Contact Approval',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Parent must approve new contacts',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                value: controls.requireApprovalForContacts,
                onChanged: (value) {
                  final updated = ParentalControl(
                    requireApprovalForContacts: value,
                    restrictedMode: controls.restrictedMode,
                    allowedContacts: controls.allowedContacts,
                    disableEmergencyDataWipe: controls.disableEmergencyDataWipe,
                    locationAlwaysOn: controls.locationAlwaysOn,
                    maxPanicButtonUsesPerDay: controls.maxPanicButtonUsesPerDay,
                  );
                  _ageModeService.updateParentalControl(updated);
                  setState(() {});
                },
                activeColor: Colors.blue,
              ),
              SwitchListTile(
                title: const Text(
                  'Location Always On',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Cannot disable location sharing',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                value: controls.locationAlwaysOn,
                onChanged: (value) {
                  final updated = ParentalControl(
                    requireApprovalForContacts: controls.requireApprovalForContacts,
                    restrictedMode: controls.restrictedMode,
                    allowedContacts: controls.allowedContacts,
                    disableEmergencyDataWipe: controls.disableEmergencyDataWipe,
                    locationAlwaysOn: value,
                    maxPanicButtonUsesPerDay: controls.maxPanicButtonUsesPerDay,
                  );
                  _ageModeService.updateParentalControl(updated);
                  setState(() {});
                },
                activeColor: Colors.blue,
              ),
              SwitchListTile(
                title: const Text(
                  'Restricted Mode',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Limit access to certain features',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                value: controls.restrictedMode,
                onChanged: (value) {
                  final updated = ParentalControl(
                    requireApprovalForContacts: controls.requireApprovalForContacts,
                    restrictedMode: value,
                    allowedContacts: controls.allowedContacts,
                    disableEmergencyDataWipe: controls.disableEmergencyDataWipe,
                    locationAlwaysOn: controls.locationAlwaysOn,
                    maxPanicButtonUsesPerDay: controls.maxPanicButtonUsesPerDay,
                  );
                  _ageModeService.updateParentalControl(updated);
                  setState(() {});
                },
                activeColor: Colors.blue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _selectMode(AgeMode mode) async {
    await _ageModeService.setAgeMode(mode);
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Switched to ${mode.name} mode'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _changeAge() {
    final ageController = TextEditingController(
      text: _ageModeService.getUserAge().toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(
          'Enter Your Age',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: ageController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Age',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final age = int.tryParse(ageController.text);
              if (age != null && age > 0 && age < 150) {
                await _ageModeService.setUserAge(age);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Age updated'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addSchoolZone() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(
          'Add School Zone',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'School Name',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final zone = SchoolZone(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  latitude: 37.7749,
                  longitude: -122.4194,
                  radiusMeters: 500,
                  arrivalTime: '08:00',
                  departureTime: '15:00',
                  weekdays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
                );
                await _ageModeService.addSchoolZone(zone);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ School zone added'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeSchoolZone(String zoneId) async {
    await _ageModeService.removeSchoolZone(zoneId);
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ School zone removed'),
        ),
      );
    }
  }
}