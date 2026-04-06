import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/emergency_services_service.dart';
import '../services/vibration_service.dart';
import 'emergency_services_extended_screen.dart'; // Add this import

class EmergencyServicesScreen extends StatefulWidget {
  const EmergencyServicesScreen({super.key});

  @override
  State<EmergencyServicesScreen> createState() => _EmergencyServicesScreenState();
}

class _EmergencyServicesScreenState extends State<EmergencyServicesScreen> {
  final EmergencyServicesService _servicesService = EmergencyServicesService();
  final VibrationService _vibrationService = VibrationService();

  List<EmergencyService> _services = [];
  List<EmergencyCall> _callHistory = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  bool _shareLocation = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadCallHistory();
    _loadStatistics();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);

    try {
      final services = await _servicesService.getEmergencyServices(null);

      if (mounted) {
        setState(() {
          _services = services;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Load services error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCallHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        final history = await _servicesService.getEmergencyCallHistory(userId);

        if (mounted) {
          setState(() {
            _callHistory = history;
          });
        }
      } catch (e) {
        debugPrint('❌ Load call history error: $e');
      }
    }
  }

  Future<void> _loadStatistics() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        final stats = await _servicesService.getCallStatistics(userId);

        if (mounted) {
          setState(() {
            _statistics = stats;
          });
        }
      } catch (e) {
        debugPrint('❌ Load statistics error: $e');
      }
    }
  }

  Future<void> _callEmergencyService(EmergencyService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${EmergencyServicesService.getServiceTypeIcon(service.type)} Call ${service.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to call:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              service.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (service.description != null) ...[
              Text(service.description!),
              const SizedBox(height: 16),
            ],
            SwitchListTile(
              title: const Text('Share my location'),
              subtitle: const Text('Send GPS coordinates'),
              value: _shareLocation,
              onChanged: (value) {
                setState(() => _shareLocation = value);
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only call emergency services in genuine emergencies.',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Call Now'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;

      if (userId != null) {
        await _vibrationService.panic();

        final success = await _servicesService.callEmergencyService(
          userId: userId,
          service: service,
          shareLocation: _shareLocation,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📞 Calling ${service.name}...'),
              backgroundColor: Colors.red,
            ),
          );

          _loadCallHistory();
          _loadStatistics();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _vibrationService.light();
              _loadServices();
              _loadCallHistory();
              _loadStatistics();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
// Statistics Card
          if (_statistics != null) _buildStatisticsCard(),

          const SizedBox(height: 24),

// Warning Card
          _buildWarningCard(),

          const SizedBox(height: 24),

// Emergency Services
          _buildSectionHeader('Emergency Services'),
          ..._services.map((service) => _buildServiceCard(service)),

          const SizedBox(height: 24),

// International Numbers
          _buildSectionHeader('International Emergency Numbers'),
          _buildInternationalNumbers(),

          const SizedBox(height: 24),

// Call History
          if (_callHistory.isNotEmpty) ...[
            _buildSectionHeader('Recent Emergency Calls'),
            ..._callHistory.take(5).map((call) => _buildCallHistoryCard(call)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final total = _statistics!['totalCalls'] as int;
    final police = _statistics!['policeCalls'] as int;
    final ambulance = _statistics!['ambulanceCalls'] as int;
    final fire = _statistics!['fireCalls'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red,
            Colors.red.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', '$total', Icons.phone),
              _buildStatItem('Police', '$police', Icons.local_police),
              _buildStatItem('Medical', '$ambulance', Icons.medical_services),
              _buildStatItem('Fire', '$fire', Icons.local_fire_department),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.red, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency Use Only',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Only call emergency services in genuine emergencies. Misuse may result in legal consequences.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
// Advanced Dispatch Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.hub),
              label: const Text('Advanced Dispatch'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[900],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                _vibrationService.light();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EmergencyServicesExtendedScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildServiceCard(EmergencyService service) {
    final typeColor = _hexToColor(
      EmergencyServicesService.getServiceTypeColor(service.type),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      child: InkWell(
        onTap: () {
          _vibrationService.light();
          _callEmergencyService(service);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    EmergencyServicesService.getServiceTypeIcon(service.type),
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.number,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),
                    if (service.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        service.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.phone,
                color: typeColor,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInternationalNumbers() {
    final numbers = EmergencyServicesService.getInternationalEmergencyNumbers();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: numbers.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    entry.value,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCallHistoryCard(EmergencyCall call) {
    final typeColor = _hexToColor(
      EmergencyServicesService.getServiceTypeColor(call.serviceType),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              EmergencyServicesService.getServiceTypeIcon(call.serviceType),
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          EmergencyServicesService.getServiceTypeLabel(call.serviceType),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${DateFormat('MMM dd, yyyy hh:mm a').format(call.timestamp)}\n'
              '${call.locationShared ? '📍 Location shared' : '📍 Location not shared'}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          call.serviceNumber,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: typeColor,
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
  }
}