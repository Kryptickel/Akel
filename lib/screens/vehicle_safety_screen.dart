import 'package:flutter/material.dart';
import '../services/vehicle_safety_service.dart';

class VehicleSafetyScreen extends StatefulWidget {
  const VehicleSafetyScreen({super.key});

  @override
  State<VehicleSafetyScreen> createState() => _VehicleSafetyScreenState();
}

class _VehicleSafetyScreenState extends State<VehicleSafetyScreen> {
  final VehicleSafetyService _vehicleService = VehicleSafetyService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _vehicleService.initialize();
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

    final vehicleInfo = _vehicleService.getVehicleInfo();
    final isMonitoring = _vehicleService.isMonitoring();
    final isBluetoothConnected = _vehicleService.isBluetoothConnected();
    final crashHistory = _vehicleService.getCrashHistory();
    final vehicleHealth = _vehicleService.getVehicleHealth();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Vehicle Safety'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => _showSettings(),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Vehicle Info Card
            if (vehicleInfo != null)
              _buildVehicleInfoCard(vehicleInfo)
            else
              _buildAddVehicleCard(),

            const SizedBox(height: 16),

            // Crash Detection Card
            _buildCrashDetectionCard(isMonitoring),

            const SizedBox(height: 16),

            // Bluetooth Connection Card
            _buildBluetoothCard(isBluetoothConnected),

            const SizedBox(height: 16),

            // Vehicle Health
            _buildSectionHeader('Vehicle Health'),
            const SizedBox(height: 12),
            ...vehicleHealth.map((status) => _buildHealthStatusCard(status)),

            const SizedBox(height: 16),

            // Roadside Assistance
            _buildRoadsideAssistanceCard(),

            const SizedBox(height: 16),

            // Crash History
            if (crashHistory.isNotEmpty) ...[
              _buildSectionHeader('Crash History'),
              const SizedBox(height: 12),
              ...crashHistory.reversed
                  .take(5)
                  .map((crash) => _buildCrashHistoryCard(crash)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoCard(VehicleInfo info) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2740), Color(0xFF2A3654)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: Color(0xFF00BFA5),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${info.year ?? ''} ${info.make ?? ''} ${info.model ?? ''}'
                          .trim(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (info.licensePlate != null)
                      Text(
                        info.licensePlate!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _editVehicleInfo(info),
                icon: const Icon(Icons.edit, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddVehicleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00BFA5).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.directions_car,
            color: Color(0xFF00BFA5),
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Add Your Vehicle',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add vehicle information for better safety monitoring',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _editVehicleInfo(null),
            icon: const Icon(Icons.add),
            label: const Text('Add Vehicle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrashDetectionCard(bool isMonitoring) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMonitoring
              ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
              : [const Color(0xFF1E2740), const Color(0xFF2A3654)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMonitoring ? Icons.shield : Icons.shield_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Crash Detection',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isMonitoring
                          ? 'Active - Monitoring for crashes'
                          : 'Inactive - Tap to enable',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isMonitoring,
                onChanged: (value) async {
                  if (value) {
                    await _vehicleService.startCrashDetection();
                  } else {
                    await _vehicleService.stopCrashDetection();
                  }
                  setState(() {});
                },
                activeColor: Colors.white,
                activeTrackColor: Colors.white38,
              ),
            ],
          ),
          if (isMonitoring) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Emergency contacts will be notified if crash detected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBluetoothCard(bool isConnected) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected
              ? const Color(0xFF00BFA5)
              : Colors.white24,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
            color: isConnected ? const Color(0xFF00BFA5) : Colors.white54,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Connected to Vehicle' : 'Not Connected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isConnected
                      ? 'Vehicle data syncing'
                      : 'Tap to connect to vehicle',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _vehicleService.toggleBluetoothConnection();
              setState(() {});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _vehicleService.isBluetoothConnected()
                          ? ' Connected to vehicle'
                          : ' Disconnected from vehicle',
                    ),
                    backgroundColor: _vehicleService.isBluetoothConnected()
                        ? Colors.green
                        : Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isConnected
                  ? Colors.red
                  : const Color(0xFF00BFA5),
            ),
            child: Text(isConnected ? 'Disconnect' : 'Connect'),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStatusCard(VehicleHealthStatus status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status.getStatusColor().withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            status.getStatusIcon(),
            color: status.getStatusColor(),
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  status.message,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            status.status.toUpperCase(),
            style: TextStyle(
              color: status.getStatusColor(),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadsideAssistanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6F00), Color(0xFFFF8F00)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.build_circle, color: Colors.white, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Roadside Assistance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Need help? Request assistance',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAssistanceButton('Tow Truck', Icons.local_shipping),
              _buildAssistanceButton('Jump Start', Icons.battery_charging_full),
              _buildAssistanceButton('Flat Tire', Icons.tire_repair),
              _buildAssistanceButton('Lockout', Icons.lock_open),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssistanceButton(String label, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () => _requestAssistance(label),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFF6F00),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildCrashHistoryCard(CrashEvent crash) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.car_crash, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Severity: ${crash.severity.toStringAsFixed(1)}/10',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDateTime(crash.timestamp),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (crash.emergencyContacted)
            const Icon(Icons.phone, color: Color(0xFF00BFA5), size: 20),
        ],
      ),
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

  void _editVehicleInfo(VehicleInfo? currentInfo) {
    final makeController = TextEditingController(text: currentInfo?.make);
    final modelController = TextEditingController(text: currentInfo?.model);
    final yearController = TextEditingController(text: currentInfo?.year);
    final plateController =
    TextEditingController(text: currentInfo?.licensePlate);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(
          'Vehicle Information',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: makeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Make',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'e.g., Toyota',
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Model',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'e.g., Camry',
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: yearController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Year',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'e.g., 2023',
                  hintStyle: TextStyle(color: Colors.white38),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: plateController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'License Plate',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'e.g., ABC123',
                  hintStyle: TextStyle(color: Colors.white38),
                ),
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
              final info = VehicleInfo(
                make: makeController.text.trim(),
                model: modelController.text.trim(),
                year: yearController.text.trim(),
                licensePlate: plateController.text.trim(),
              );
              await _vehicleService.saveVehicleInfo(info);
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(' Vehicle info saved'),
                    backgroundColor: Colors.green,
                  ),
                );
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

  void _requestAssistance(String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(
          'Request Roadside Assistance',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Request assistance for: $type?\n\nYour location will be shared with the service provider.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _vehicleService.requestRoadsideAssistance(type);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(' $type assistance requested'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
            ),
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    final threshold = _vehicleService.getCrashThreshold();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(
          'Crash Detection Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Crash Sensitivity Threshold',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Slider(
              value: threshold,
              min: 2.0,
              max: 5.0,
              divisions: 30,
              label: '${threshold.toStringAsFixed(1)} G',
              activeColor: const Color(0xFF00BFA5),
              onChanged: (value) async {
                await _vehicleService.setCrashThreshold(value);
                setState(() {});
              },
            ),
            Text(
              'Current: ${threshold.toStringAsFixed(1)} G-force',
              style: const TextStyle(
                color: Color(0xFF00BFA5),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lower = More sensitive\nHigher = Less sensitive',
              style: TextStyle(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.center,
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}