import 'package:flutter/material.dart';
import '../services/smartwatch_service.dart';
import 'package:intl/intl.dart';

class SmartwatchScreen extends StatefulWidget {
  const SmartwatchScreen({super.key});

  @override
  State<SmartwatchScreen> createState() => _SmartwatchScreenState();
}

class _SmartwatchScreenState extends State<SmartwatchScreen> {
  final SmartwatchService _smartwatchService = SmartwatchService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _smartwatchService.initialize();
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

    final watches = _smartwatchService.getConnectedWatches();
    final primaryWatch = _smartwatchService.getPrimaryWatch();
    final stats = _smartwatchService.getStatistics();
    final fallEvents = _smartwatchService.getFallEvents();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Smartwatch Integration'),
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
          await _smartwatchService.syncWithWatch();
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Primary Watch Card
            if (primaryWatch != null)
              _buildPrimaryWatchCard(primaryWatch)
            else
              _buildNoWatchCard(),

            const SizedBox(height: 16),

            // Quick Actions
            _buildQuickActionsCard(),

            const SizedBox(height: 16),

            // Statistics Card
            _buildStatisticsCard(stats),

            const SizedBox(height: 16),

            // Connected Watches
            if (watches.isNotEmpty) ...[
              _buildSectionHeader('Connected Watches', Icons.watch),
              const SizedBox(height: 12),
              ...watches.map((watch) => _buildWatchCard(watch)),
              const SizedBox(height: 16),
            ],

            // Fall Detection History
            if (fallEvents.isNotEmpty) ...[
              _buildSectionHeader('Fall Detection History', Icons.personal_injury),
              const SizedBox(height: 12),
              ...fallEvents.reversed.take(5).map((event) => _buildFallEventCard(event)),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _connectNewWatch(),
        backgroundColor: const Color(0xFF00BFA5),
        icon: const Icon(Icons.add),
        label: const Text('Connect Watch'),
      ),
    );
  }

  Widget _buildPrimaryWatchCard(ConnectedWatch watch) {
    final batteryColor = _getBatteryColor(watch.batteryLevel);
    final syncAge = DateTime.now().difference(watch.lastSync);
    final syncText = syncAge.inMinutes < 1
        ? 'Just synced'
        : syncAge.inMinutes < 60
        ? '${syncAge.inMinutes}m ago'
        : '${syncAge.inHours}h ago';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _smartwatchService.getWatchColor(watch.type).withValues(alpha: 0.3),
            _smartwatchService.getWatchColor(watch.type).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _smartwatchService.getWatchColor(watch.type),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _smartwatchService
                      .getWatchColor(watch.type)
                      .withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _smartwatchService.getWatchIcon(watch.type),
                  color: _smartwatchService.getWatchColor(watch.type),
                  size: 40,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Primary Watch',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      watch.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      watch.model,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: watch.isConnected
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: watch.isConnected ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  watch.isConnected ? 'CONNECTED' : 'OFFLINE',
                  style: TextStyle(
                    color: watch.isConnected ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildWatchStat(
                  'Battery',
                  '${watch.batteryLevel}%',
                  Icons.battery_charging_full,
                  batteryColor,
                ),
              ),
              Expanded(
                child: _buildWatchStat(
                  'Last Sync',
                  syncText,
                  Icons.sync,
                  const Color(0xFF00BFA5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoWatchCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00BFA5).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.watch_off,
            size: 80,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Watch Connected',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect your smartwatch to enable wrist panic button and fall detection',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _connectNewWatch(),
            icon: const Icon(Icons.add),
            label: const Text('Connect Watch'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Test Panic',
                  Icons.emergency,
                  Colors.red,
                      () => _testWristPanic(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Sync Now',
                  Icons.sync,
                  const Color(0xFF00BFA5),
                      () => _syncNow(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Test Fall',
                  Icons.personal_injury,
                  Colors.orange,
                      () => _testFallDetection(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Send Alert',
                  Icons.notifications,
                  Colors.blue,
                      () => _sendTestNotification(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Material(
      color: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.assessment, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Wearable Statistics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Watches',
                  '${stats['connectedWatches']}',
                  Icons.watch,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Falls',
                  '${stats['totalFalls']}',
                  Icons.personal_injury,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Battery',
                  '${stats['averageBattery'].round()}%',
                  Icons.battery_full,
                ),
              ),
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
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWatchCard(ConnectedWatch watch) {
    final batteryColor = _getBatteryColor(watch.batteryLevel);

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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _smartwatchService
                  .getWatchColor(watch.type)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _smartwatchService.getWatchIcon(watch.type),
              color: _smartwatchService.getWatchColor(watch.type),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  watch.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  watch.model,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.battery_full, color: batteryColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${watch.batteryLevel}%',
                      style: TextStyle(
                        color: batteryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _disconnectWatch(watch.id),
            icon: const Icon(Icons.close, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildFallEventCard(FallEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.personal_injury, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Fall Detected',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${event.impactForce.toStringAsFixed(1)}G',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('MMM d, y h:mm a').format(event.timestamp),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                if (event.location != null)
                  Text(
                    event.location!,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          if (event.emergencyContacted)
            const Icon(Icons.phone, color: Color(0xFF00BFA5), size: 20),
        ],
      ),
    );
  }

  Widget _buildWatchStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00BFA5), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getBatteryColor(int level) {
    if (level > 50) return Colors.green;
    if (level > 20) return Colors.orange;
    return Colors.red;
  }

  void _connectNewWatch() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(
          'Connect Smartwatch',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildWatchTypeButton(WatchType.appleWatch, 'Apple Watch'),
            const SizedBox(height: 12),
            _buildWatchTypeButton(WatchType.wearOS, 'Wear OS'),
            const SizedBox(height: 12),
            _buildWatchTypeButton(WatchType.samsungGalaxy, 'Galaxy Watch'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchTypeButton(WatchType type, String name) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          await _smartwatchService.connectWatch(type);
          if (mounted) {
            Navigator.pop(context);
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(' $name connected'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        icon: Icon(_smartwatchService.getWatchIcon(type)),
        label: Text(name),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00BFA5),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _disconnectWatch(String watchId) async {
    await _smartwatchService.disconnectWatch(watchId);
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Watch disconnected'),
        ),
      );
    }
  }

  void _testWristPanic() async {
    await _smartwatchService.triggerWristPanic();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Wrist panic test - Emergency contacts would be notified'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _syncNow() async {
    await _smartwatchService.syncWithWatch();
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Watch synced'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _testFallDetection() async {
    await _smartwatchService.detectFall(8.5);
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Fall detected - Emergency protocol activated'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _sendTestNotification() async {
    await _smartwatchService.sendNotificationToWatch(
      'Test Alert',
      'This is a test notification from Akel',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Notification sent to watch'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text(
          'Smartwatch Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text(
                  'Wrist Panic Button',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Enable panic from watch',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                value: _smartwatchService.isPanicButtonEnabled(),
                onChanged: (value) {
                  _smartwatchService.updateSettings(panicButton: value);
                  setState(() {});
                },
                activeColor: const Color(0xFF00BFA5),
              ),
              SwitchListTile(
                title: const Text(
                  'Fall Detection',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Auto-detect falls',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                value: _smartwatchService.isFallDetectionEnabled(),
                onChanged: (value) {
                  _smartwatchService.updateSettings(fallDetection: value);
                  setState(() {});
                },
                activeColor: const Color(0xFF00BFA5),
              ),
              SwitchListTile(
                title: const Text(
                  'Haptic Feedback',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Vibration alerts',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                value: _smartwatchService.isHapticFeedbackEnabled(),
                onChanged: (value) {
                  _smartwatchService.updateSettings(hapticFeedback: value);
                  setState(() {});
                },
                activeColor: const Color(0xFF00BFA5),
              ),
              const Divider(color: Colors.white12),
              ListTile(
                title: const Text(
                  'Fall Sensitivity',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Slider(
                  value: _smartwatchService.getFallSensitivity(),
                  min: 0.3,
                  max: 1.0,
                  divisions: 7,
                  label: '${(_smartwatchService.getFallSensitivity() * 100).round()}%',
                  activeColor: const Color(0xFF00BFA5),
                  onChanged: (value) {
                    _smartwatchService.updateSettings(fallSensitivity: value);
                    setState(() {});
                  },
                ),
              ),
            ],
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
}