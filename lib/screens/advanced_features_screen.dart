import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/emergency_core_service.dart';
import '../services/navigation_mega_service.dart';
import '../services/accessibility_cloud_service.dart';
import '../services/mesh_cad_service.dart';
import '../widgets/glossy_3d_widgets.dart';

class AdvancedFeaturesScreen extends StatefulWidget {
  const AdvancedFeaturesScreen({super.key});

  @override
  State<AdvancedFeaturesScreen> createState() => _AdvancedFeaturesScreenState();
}

class _AdvancedFeaturesScreenState extends State<AdvancedFeaturesScreen> {
  final _coreService = EmergencyCoreService();
  final _navService = NavigationMegaService();
  final _accessService = AccessibilityCloudService();
  final _meshService = MeshCADService();

  int _pendingEmergencies = 0;
  int _downloadedRegions = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final pending = await _coreService.getPendingCount();
    final regions = await _navService.getDownloadedRegions();

    if (mounted) {
      setState(() {
        _pendingEmergencies = pending;
        _downloadedRegions = regions.length;
        _isLoadingStats = false;
      });
    }
  }

  void _showCheckinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text('Configure Check-ins', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Set check-in interval for worker safety:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            _buildIntervalOption('Every 30 minutes', 30),
            _buildIntervalOption('Every 1 hour', 60),
            _buildIntervalOption('Every 2 hours', 120),
            _buildIntervalOption('Every 4 hours', 240),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalOption(String label, int minutes) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
      onTap: () async {
        Navigator.pop(context);
        await _coreService.enableCheckins(minutes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Check-ins enabled: $label'),
              backgroundColor: Colors.cyan,
            ),
          );
        }
      },
    );
  }

  void _showDyslexiaModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text('Dyslexia Mode', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a color scheme:',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              ..._accessService.colorSchemes.entries.map((entry) {
                return GestureDetector(
                  onTap: () async {
                    await _accessService.enableDyslexiaMode(
                      backgroundColor: entry.value['background'],
                      textColor: entry.value['text'],
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Dyslexia mode enabled: ${entry.key}'),
                          backgroundColor: Colors.purple,
                        ),
                      );
                      // Restart app to apply theme
                      _showRestartDialog();
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: entry.value['background'],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: entry.value['text']!,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: entry.value['text'],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  color: entry.value['text'],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Optimized for dyslexia',
                                style: TextStyle(
                                  color: entry.value['text']!.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: entry.value['text'],
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await _accessService.disableDyslexiaMode();
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dyslexia mode disabled'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                child: const Text('Disable Dyslexia Mode'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text('Restart Required', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Please restart the app to apply the new theme.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to settings
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMapDownloadDialog() {
    final regionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text('Download Offline Maps', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter region name (e.g., "Downtown", "My City"):',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: regionController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Region name',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.green),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will download map tiles for offline use. The download size depends on the area and zoom levels selected.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = regionController.text.trim();
              if (name.isEmpty) return;

              Navigator.pop(context);

              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Preparing map download...'),
                  duration: Duration(seconds: 2),
                ),
              );

              // Get current location as center
              try {
                final position = await Geolocator.getCurrentPosition();

                // Download 10km radius around current location
                final regionId = await _navService.downloadMapRegion(
                  name: name,
                  northLat: position.latitude + 0.05,
                  southLat: position.latitude - 0.05,
                  eastLng: position.longitude + 0.05,
                  westLng: position.longitude - 0.05,
                  zoomLevels: [10, 11, 12, 13, 14, 15],
                );

                await _loadStats();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Map region "$name" queued for download (ID: $regionId)'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _showEscapeRoutesDialog() async {
    try {
      final position = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E2740),
          title: const Text('Calculate Escape Routes', style: TextStyle(color: Colors.white)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This will calculate 3 emergency escape routes from your current location:',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.speed, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text('Fastest route', style: TextStyle(color: Colors.white)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.security, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text('Safest route', style: TextStyle(color: Colors.white)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text('Least crowded route', style: TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Calculating escape routes...'),
                    duration: Duration(seconds: 2),
                  ),
                );

                final routes = await _navService.calculateEscapeRoutes(
                  origin: position,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${routes.length} escape routes calculated'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  _showRoutesResultDialog(routes);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Calculate'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRoutesResultDialog(List<Map<String, dynamic>> routes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text('Escape Routes', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: routes.map((route) {
              Color routeColor;
              IconData routeIcon;

              switch (route['type']) {
                case 'fastest':
                  routeColor = Colors.green;
                  routeIcon = Icons.speed;
                  break;
                case 'safest':
                  routeColor = Colors.blue;
                  routeIcon = Icons.security;
                  break;
                default:
                  routeColor = Colors.orange;
                  routeIcon = Icons.people_outline;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: routeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: routeColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(routeIcon, color: routeColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            route['description'] as String,
                            style: TextStyle(
                              color: routeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${route['distance_km']} km',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '~${route['duration_min']} min',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
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

  void _showHazardReportDialog() {
    String? selectedType;
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E2740),
          title: const Text('Report Hazard', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hazard Type:', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Power Line',
                    'Gas Leak',
                    'Flooding',
                    'Fire',
                    'Road Hazard',
                    'Structural Damage',
                  ].map((type) {
                    final isSelected = selectedType == type;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedType = type;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.red : Colors.white24,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: isSelected ? Colors.red : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Description (optional):', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Additional details...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
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
              onPressed: selectedType == null ? null : () async {
                Navigator.pop(context);

                try {
                  final position = await Geolocator.getCurrentPosition();

                  final reportId = await _navService.reportHazard(
                    userId: 'current_user',
                    type: selectedType!.toLowerCase().replaceAll(' ', '_'),
                    location: position,
                    description: descriptionController.text.trim(),
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hazard reported successfully (ID: $reportId)'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                disabledBackgroundColor: Colors.grey,
              ),
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCloudProviderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text('Choose Cloud Provider', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCloudOption(
              provider: CloudProvider.aws,
              name: 'Amazon Web Services',
              icon: Icons.cloud_queue,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildCloudOption(
              provider: CloudProvider.google,
              name: 'Google Cloud Platform',
              icon: Icons.cloud_circle,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto-Failover', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Automatically switch if current provider fails',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              value: _accessService.autoFailover,
              onChanged: (value) async {
                await _accessService.setAutoFailover(value);
                setState(() {});
              },
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudOption({
    required CloudProvider provider,
    required String name,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _accessService.currentProvider == provider;

    return GestureDetector(
      onTap: () async {
        await _accessService.setCloudProvider(provider);
        setState(() {});
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Switched to $name'),
              backgroundColor: color,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  if (isSelected)
                    Text(
                      'Currently Active',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text(' Advanced Features'),
        backgroundColor: const Color(0xFF1E2740),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoadingStats = true;
              });
              _loadStats();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoadingStats
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // STATISTICS BANNER
          RealisticGlassCard(
            enable3D: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.pending,
                  label: 'Queued',
                  value: _pendingEmergencies.toString(),
                  color: _pendingEmergencies > 0 ? Colors.orange : Colors.green,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white24,
                ),
                _buildStatItem(
                  icon: Icons.map,
                  label: 'Maps',
                  value: _downloadedRegions.toString(),
                  color: Colors.blue,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white24,
                ),
                _buildStatItem(
                  icon: Icons.cloud,
                  label: _accessService.currentProvider.name.toUpperCase(),
                  value: '✓',
                  color: Colors.purple,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // OFFLINE EMERGENCY
          _buildSectionHeader(' OFFLINE EMERGENCY'),
          const SizedBox(height: 8),
          RealisticGlassCard(
            enable3D: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cloud_off, color: Colors.orange, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Offline Emergency Mode',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Records emergencies when offline and auto-sends when connection is restored.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _pendingEmergencies > 0
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _pendingEmergencies > 0 ? Icons.pending : Icons.check_circle,
                        color: _pendingEmergencies > 0 ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _pendingEmergencies > 0
                            ? '$_pendingEmergencies queued emergencies'
                            : 'No pending emergencies',
                        style: TextStyle(
                          color: _pendingEmergencies > 0 ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // WORKER SAFETY
          _buildSectionHeader(' WORKER SAFETY SYSTEM'),
          const SizedBox(height: 8),
          LiquidGlassCard(
            gradientColors: const [Colors.blue, Colors.cyan, Colors.lightBlue],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.accessibility_new, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Worker Safety System',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Automatic man-down detection + timed check-ins for lone workers.',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Glossy3DButton(
                        text: 'Man-Down',
                        icon: Icons.person_off,
                        onPressed: () async {
                          await _coreService.enableManDown();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Man-down detection enabled'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          }
                        },
                        color: Colors.blue,
                        height: 50,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Glossy3DButton(
                        text: 'Check-ins',
                        icon: Icons.timer,
                        onPressed: _showCheckinDialog,
                        color: Colors.cyan,
                        height: 50,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // DYSLEXIA MODE
          _buildSectionHeader(' ACCESSIBILITY'),
          const SizedBox(height: 8),
          MetallicCard(
            baseColor: Colors.purple,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.accessibility, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Dyslexia-Friendly Mode',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _accessService.isDyslexiaMode
                      ? 'Currently using ${_accessService.currentFont} font'
                      : 'Special fonts, colors, and spacing optimized for dyslexia.',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Glossy3DButton(
                  text: _accessService.isDyslexiaMode
                      ? 'Change Settings'
                      : 'Configure Accessibility',
                  icon: Icons.settings_accessibility,
                  onPressed: _showDyslexiaModeDialog,
                  color: Colors.purple,
                  width: double.infinity,
                  height: 50,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // NAVIGATION & MAPS
          _buildSectionHeader(' NAVIGATION & MAPS'),
          const SizedBox(height: 8),
          FrostedGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.map, color: Colors.green, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Offline Maps & Escape Routes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Downloaded regions: $_downloadedRegions',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Glossy3DButton(
                        text: 'Download',
                        icon: Icons.download,
                        onPressed: _showMapDownloadDialog,
                        color: Colors.green,
                        height: 50,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Glossy3DButton(
                        text: 'Routes',
                        icon: Icons.alt_route,
                        onPressed: _showEscapeRoutesDialog,
                        color: Colors.teal,
                        height: 50,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // CITIZEN REPORTER
          _buildSectionHeader(' CITIZEN REPORTER'),
          const SizedBox(height: 8),
          NeumorphicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.report, color: Colors.red, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Citizen Hazard Reporter',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Report hazards (power lines, gas leaks) to authorities and community.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Glossy3DButton(
                  text: 'Report Hazard',
                  icon: Icons.warning,
                  onPressed: _showHazardReportDialog,
                  color: Colors.red,
                  width: double.infinity,
                  height: 50,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // CLOUD PROVIDER
          _buildSectionHeader(' CLOUD INFRASTRUCTURE'),
          const SizedBox(height: 8),
          RealisticGlassCard(
            enable3D: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cloud, color: Colors.blue, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Cloud Provider',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Currently using: ${_accessService.currentProvider == CloudProvider.aws ? "AWS" : "Google Cloud"}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Glossy3DButton(
                  text: 'Switch Provider',
                  icon: Icons.swap_horiz,
                  onPressed: _showCloudProviderDialog,
                  color: Colors.blue,
                  width: double.infinity,
                  height: 50,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // MESH NETWORKING (OPTIONAL)
          _buildSectionHeader(' MESH NETWORKING (OPTIONAL)'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.wifi_tethering, color: Colors.amber, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Mesh Networking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  ' Battery intensive. Relays emergencies through nearby phones.',
                  style: TextStyle(color: Colors.amber, fontSize: 12),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Enable Mesh',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: _meshService.isMeshEnabled,
                  onChanged: (value) async {
                    if (value) {
                      await _meshService.enableMeshNetworking();
                    } else {
                      await _meshService.disableMeshNetworking();
                    }
                    setState(() {});
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'Mesh networking enabled'
                                : 'Mesh networking disabled',
                          ),
                          backgroundColor: Colors.amber,
                        ),
                      );
                    }
                  },
                  activeColor: Colors.amber,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF00BFA5),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
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
}