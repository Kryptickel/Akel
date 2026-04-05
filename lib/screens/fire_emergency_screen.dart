import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/fire_service.dart';
import '../services/panic_service.dart';
import '../providers/auth_provider.dart';
import '../models/emergency_info.dart';

class FireEmergencyScreen extends StatefulWidget {
  const FireEmergencyScreen({super.key});

  @override
  State<FireEmergencyScreen> createState() => _FireEmergencyScreenState();
}

class _FireEmergencyScreenState extends State<FireEmergencyScreen> {
  final FireService _fireService = FireService();
  final PanicService _panicService = PanicService();
  final _formKey = GlobalKey<FormState>();

  String _selectedFireType = 'building';
  String _selectedSeverity = 'moderate';
  final _buildingInfoController = TextEditingController();
  final _floorController = TextEditingController();
  final _unitController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isReporting = false;

  @override
  void dispose() {
    _buildingInfoController.dispose();
    _floorController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _reportFire() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isReporting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      final userName = authProvider.userProfile?['name'] ?? 'User';

      if (user == null) {
        throw Exception('Not logged in');
      }

// Get medical info
      final medicalInfo = await _panicService.getEmergencyInfo(user.uid);

// Report fire
      final result = await _fireService.reportFire(
        userId: user.uid,
        userName: userName,
        fireType: _selectedFireType,
        severity: _selectedSeverity,
        buildingInfo: _buildingInfoController.text.trim(),
        floorNumber: _floorController.text.trim(),
        unitNumber: _unitController.text.trim(),
        description: _descriptionController.text.trim(),
        medicalInfo: medicalInfo,
      );

      if (mounted) {
        setState(() => _isReporting = false);

        if (result['success'] == true) {
          _showSuccessDialog(result);
        } else {
          _showErrorDialog(result['error'] ?? 'Failed to report fire');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isReporting = false);
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            Text(
              'Fire Reported',
              style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result['message'] ?? 'Fire department has been notified',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Fire Department Dispatched',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '⏱️ ETA: ${result['estimatedArrival'] ?? '5-10 minutes'}',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📋 Emergency ID: ${result['emergencyId']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Safety Instructions:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Evacuate the building immediately\n'
                  '• Close doors behind you\n'
                  '• Do not use elevators\n'
                  '• Stay low to avoid smoke\n'
                  '• Meet at designated safe point\n'
                  '• Do not re-enter until cleared',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          '❌ Error',
          style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color),
        ),
        content: Text(
          error,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 Report Fire Emergency'),
        backgroundColor: Colors.red,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
// Warning Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'EMERGENCY ONLY',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Only use this for actual fire emergencies.\nFalse reports are illegal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.red[200] : Colors.red[900],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

// Fire Type
            _buildSectionTitle('🔥 Fire Type'),
            _buildFireTypeSelector(),

            const SizedBox(height: 24),

// Severity
            _buildSectionTitle('⚠️ Severity Level'),
            _buildSeveritySelector(),

            const SizedBox(height: 24),

// Building Info
            _buildSectionTitle('🏢 Building Information'),
            TextField(
              controller: _buildingInfoController,
              decoration: InputDecoration(
                hintText: 'Building name or address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.business),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _floorController,
                    decoration: InputDecoration(
                      hintText: 'Floor #',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.stairs),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _unitController,
                    decoration: InputDecoration(
                      hintText: 'Unit #',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.door_front_door),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

// Description
            _buildSectionTitle('📝 Description'),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'What do you see? Location of fire, people trapped, etc.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 4,
            ),

            const SizedBox(height: 32),

// Report Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isReporting ? null : _reportFire,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isReporting
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_fire_department, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'REPORT FIRE EMERGENCY',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Fire department will be notified immediately with your location and medical information.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFireTypeSelector() {
    final types = [
      {'value': 'building', 'label': 'Building Fire', 'icon': Icons.business},
      {'value': 'vehicle', 'label': 'Vehicle Fire', 'icon': Icons.directions_car},
      {'value': 'wildfire', 'label': 'Wildfire', 'icon': Icons.forest},
      {'value': 'electrical', 'label': 'Electrical', 'icon': Icons.electrical_services},
      {'value': 'gas', 'label': 'Gas Leak/Fire', 'icon': Icons.gas_meter},
      {'value': 'chemical', 'label': 'Chemical Fire', 'icon': Icons.science},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = _selectedFireType == type['value'];
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type['icon'] as IconData,
                size: 18,
                color: isSelected ? Colors.white : null,
              ),
              const SizedBox(width: 6),
              Text(type['label'] as String),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedFireType = type['value'] as String);
            }
          },
          selectedColor: Colors.red,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeveritySelector() {
    final severities = [
      {'value': 'minor', 'label': '🟡 Minor', 'desc': 'Small flames, contained'},
      {'value': 'moderate', 'label': '🟠 Moderate', 'desc': 'Spreading, visible smoke'},
      {'value': 'severe', 'label': '🔴 Severe', 'desc': 'Large flames, danger'},
      {'value': 'critical', 'label': '🚨 CRITICAL', 'desc': 'Life-threatening'},
    ];

    return Column(
      children: severities.map((severity) {
        final isSelected = _selectedSeverity == severity['value'];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            selected: isSelected,
            selectedTileColor: Colors.red.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? Colors.red
                    : Colors.grey.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            title: Text(
              severity['label'] as String,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
            subtitle: Text(severity['desc'] as String),
            onTap: () {
              setState(() => _selectedSeverity = severity['value'] as String);
            },
          ),
        );
      }).toList(),
    );
  }
}