import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/call_service.dart';
import '../services/battery_service.dart';
import '../services/connectivity_service.dart';
import '../services/retry_service.dart'; // NEW
import '../providers/auth_provider.dart';

class AppDiagnosticsScreen extends StatefulWidget {
  const AppDiagnosticsScreen({Key? key}) : super(key: key);

  @override
  State<AppDiagnosticsScreen> createState() => _AppDiagnosticsScreenState();
}

class _AppDiagnosticsScreenState extends State<AppDiagnosticsScreen> {
  final CallService _callService = CallService();
  final BatteryService _batteryService = BatteryService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final RetryService _retryService = RetryService(); // NEW

  Map<String, dynamic> diagnosticResults = {};
  bool isRunning = false;
  String statusMessage = 'Ready to run diagnostics';

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    if (!mounted) return;

    setState(() {
      isRunning = true;
      diagnosticResults.clear();
      statusMessage = 'Running diagnostics...';
    });

    try {
      statusMessage = 'Checking permissions...';
      if (mounted) setState(() {});
      await _checkPermissions();

      statusMessage = 'Checking location services...';
      if (mounted) setState(() {});
      await _checkLocationServices();

      statusMessage = 'Getting device info...';
      if (mounted) setState(() {});
      await _checkDeviceInfo();

      statusMessage = 'Getting app info...';
      if (mounted) setState(() {});
      await _checkAppInfo();

      statusMessage = 'Checking network...';
      if (mounted) setState(() {});
      await _checkNetwork();

      statusMessage = 'Checking battery...';
      if (mounted) setState(() {});
      await _checkBattery();

      statusMessage = 'Getting call statistics...';
      if (mounted) setState(() {});
      await _checkCallStats();

      statusMessage = 'Getting retry statistics...'; // NEW
      if (mounted) setState(() {});
      await _checkRetryStats();

      statusMessage = 'Testing performance...';
      if (mounted) setState(() {});
      await _checkPerformance();

      statusMessage = 'Diagnostics complete!';
    } catch (e) {
      diagnosticResults['error'] = e.toString();
      statusMessage = 'Error: ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() {
          isRunning = false;
        });
      }
    }
  }

  Future<void> _checkPermissions() async {
    Map<String, dynamic> permissions = {};

    try {
      final locationStatus = await Permission.location.status;
      permissions['Location'] = {
        'granted': locationStatus.isGranted,
        'status': locationStatus.toString().split('.').last,
        'icon': locationStatus.isGranted ? ' ' : ' ',
      };

      final smsStatus = await Permission.sms.status;
      permissions['SMS'] = {
        'granted': smsStatus.isGranted,
        'status': smsStatus.toString().split('.').last,
        'icon': smsStatus.isGranted ? ' ' : ' ',
      };

      final phoneStatus = await Permission.phone.status;
      permissions['Phone'] = {
        'granted': phoneStatus.isGranted,
        'status': phoneStatus.toString().split('.').last,
        'icon': phoneStatus.isGranted ? ' ' : ' ',
      };

      final notificationStatus = await Permission.notification.status;
      permissions['Notifications'] = {
        'granted': notificationStatus.isGranted,
        'status': notificationStatus.toString().split('.').last,
        'icon': notificationStatus.isGranted ? ' ' : ' ',
      };

    } catch (e) {
      permissions['error'] = e.toString();
    }

    diagnosticResults['permissions'] = permissions;
  }

  Future<void> _checkLocationServices() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (serviceEnabled) {
        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          ).timeout(const Duration(seconds: 5));

          diagnosticResults['location'] = {
            'service_enabled': true,
            'icon': ' ',
            'latitude': position.latitude.toStringAsFixed(6),
            'longitude': position.longitude.toStringAsFixed(6),
            'accuracy': '${position.accuracy.toStringAsFixed(2)}m',
            'status': 'Working',
          };
        } catch (e) {
          diagnosticResults['location'] = {
            'service_enabled': true,
            'icon': ' ',
            'status': 'Enabled but cannot get position',
            'error': e.toString(),
          };
        }
      } else {
        diagnosticResults['location'] = {
          'service_enabled': false,
          'icon': ' ',
          'status': 'Disabled',
        };
      }
    } catch (e) {
      diagnosticResults['location'] = {
        'error': e.toString(),
        'icon': ' ',
      };
    }
  }

  Future<void> _checkDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        diagnosticResults['device'] = {
          'platform': 'Android',
          'model': androidInfo.model,
          'version': 'Android ${androidInfo.version.release}',
          'sdk': androidInfo.version.sdkInt.toString(),
          'manufacturer': androidInfo.manufacturer,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        diagnosticResults['device'] = {
          'platform': 'iOS',
          'model': iosInfo.model,
          'version': iosInfo.systemVersion,
          'name': iosInfo.name,
        };
      } else {
        diagnosticResults['device'] = {
          'platform': 'Web',
          'version': 'N/A',
        };
      }
    } catch (e) {
      diagnosticResults['device'] = {'error': e.toString()};
    }
  }

  Future<void> _checkAppInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      diagnosticResults['app'] = {
        'name': packageInfo.appName,
        'package': packageInfo.packageName,
        'version': packageInfo.version,
        'build': packageInfo.buildNumber,
      };
    } catch (e) {
      diagnosticResults['app'] = {'error': e.toString()};
    }
  }

  Future<void> _checkNetwork() async {
    try {
      final isOnline = await _connectivityService.isOnline();

      if (isOnline) {
        final result = await InternetAddress.lookup('google.com').timeout(
          const Duration(seconds: 5),
        );

        diagnosticResults['network'] = {
          'status': 'Connected',
          'icon': ' ',
          'connected': true,
          'address': result.isNotEmpty ? result[0].address : 'N/A',
          'latency': 'Good',
        };
      } else {
        diagnosticResults['network'] = {
          'status': 'Offline',
          'icon': ' ',
          'connected': false,
        };
      }
    } catch (e) {
      diagnosticResults['network'] = {
        'status': 'Error',
        'icon': ' ',
        'connected': false,
        'error': e.toString(),
      };
    }
  }

  Future<void> _checkBattery() async {
    try {
      final level = await _batteryService.getBatteryLevel();
      final isCharging = await _batteryService.isCharging();
      final isLow = await _batteryService.isLowBattery();

      String status;
      String icon;

      if (isCharging) {
        status = 'Charging';
        icon = ' ';
      } else if (isLow) {
        status = 'Low Battery';
        icon = ' ';
      } else {
        status = 'On Battery';
        icon = ' ';
      }

      diagnosticResults['battery'] = {
        'level': '$level%',
        'status': status,
        'charging': isCharging ? 'Yes' : 'No',
        'icon': icon,
        'health': level > 50 ? 'Good' : (level > 20 ? 'Fair' : 'Critical'),
      };
    } catch (e) {
      diagnosticResults['battery'] = {
        'error': e.toString(),
        'icon': ' ',
      };
    }
  }

  Future<void> _checkCallStats() async {
    try {
      final stats = _callService.getCallStats();
      final history = _callService.getCallHistory();

      diagnosticResults['call_stats'] = {
        'total_calls': stats['total'] ?? 0,
        'successful': stats['successful'] ?? 0,
        'failed': stats['failed'] ?? 0,
        'no_permission': stats['noPermission'] ?? 0,
        'success_rate': stats['total'] != null && stats['total']! > 0
            ? '${((stats['successful']! / stats['total']!) * 100).toStringAsFixed(1)}%'
            : 'N/A',
        'icon': stats['successful'] != null && stats['successful']! > 0 ? ' ' : ' ',
      };

      diagnosticResults['recent_calls'] = history.reversed.take(5).toList();
    } catch (e) {
      diagnosticResults['call_stats'] = {
        'error': e.toString(),
        'icon': ' ',
      };
    }
  }

  // NEW: Check retry statistics
  Future<void> _checkRetryStats() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid ?? 'demo_user';

      final stats = await _retryService.getRetryStats(userId);
      final pendingRetries = _retryService.getPendingRetries(userId);

      diagnosticResults['retry_stats'] = {
        ...stats,
        'icon': stats['successful'] > 0 ? ' ' : ' ',
      };

      diagnosticResults['pending_retries'] = pendingRetries.take(5).toList();
    } catch (e) {
      diagnosticResults['retry_stats'] = {
        'error': e.toString(),
        'icon': ' ',
      };
    }
  }

  Future<void> _checkPerformance() async {
    final stopwatch = Stopwatch()..start();

    int sum = 0;
    for (int i = 0; i < 1000000; i++) {
      sum += i;
    }

    stopwatch.stop();

    String status;
    String icon;

    if (stopwatch.elapsedMilliseconds < 50) {
      status = 'Excellent';
      icon = ' ';
    } else if (stopwatch.elapsedMilliseconds < 100) {
      status = 'Good';
      icon = ' ';
    } else if (stopwatch.elapsedMilliseconds < 200) {
      status = 'Fair';
      icon = ' ';
    } else {
      status = 'Slow';
      icon = ' ';
    }

    diagnosticResults['performance'] = {
      'computation_time': '${stopwatch.elapsedMilliseconds}ms',
      'status': status,
      'icon': icon,
    };
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E2740) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('App Diagnostics'),
        backgroundColor: const Color(0xFF00BFA5),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isRunning ? null : _runDiagnostics,
            tooltip: 'Refresh Diagnostics',
          ),
        ],
      ),
      body: isRunning
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
            ),
            const SizedBox(height: 24),
            Text(
              statusMessage,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusCard(cardColor, textColor),
          const SizedBox(height: 16),
          _buildInfoCard('App Information', diagnosticResults['app'], cardColor, textColor),
          const SizedBox(height: 16),
          _buildInfoCard('Device', diagnosticResults['device'], cardColor, textColor),
          const SizedBox(height: 16),
          _buildInfoCard('Network', diagnosticResults['network'], cardColor, textColor),
          const SizedBox(height: 16),
          _buildInfoCard('Battery', diagnosticResults['battery'], cardColor, textColor),
          const SizedBox(height: 16),
          _buildInfoCard('Performance', diagnosticResults['performance'], cardColor, textColor),
          const SizedBox(height: 16),
          _buildPermissionsCard(cardColor, textColor),
          const SizedBox(height: 16),
          _buildLocationCard(cardColor, textColor),
          const SizedBox(height: 16),
          _buildCallStatsCard(cardColor, textColor),
          const SizedBox(height: 16),
          _buildRetryStatsCard(cardColor, textColor), // NEW
        ],
      ),
    );
  }

  Widget _buildStatusCard(Color cardColor, Color textColor) {
    final hasErrors = diagnosticResults.values.any((v) => v is Map && v.containsKey('error'));

    return Card(
      color: cardColor,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              hasErrors ? Icons.warning : Icons.check_circle,
              size: 64,
              color: hasErrors ? Colors.orange : Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'System Health',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasErrors ? 'Some Issues Detected' : 'All Systems Operational',
              style: TextStyle(
                color: hasErrors ? Colors.orange : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsCard(Color cardColor, Color textColor) {
    final permissions = diagnosticResults['permissions'] as Map<String, dynamic>?;
    if (permissions == null) return const SizedBox.shrink();

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Color(0xFF00BFA5)),
                const SizedBox(width: 12),
                Text(
                  'Permissions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...permissions.entries.where((e) => e.value is Map).map((entry) {
              final data = entry.value as Map<String, dynamic>;
              final granted = data['granted'] ?? false;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          data['icon'] ?? '',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      data['status'] ?? 'Unknown',
                      style: TextStyle(
                        color: granted ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(Color cardColor, Color textColor) {
    final location = diagnosticResults['location'] as Map<String, dynamic>?;
    if (location == null) return const SizedBox.shrink();

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: location['service_enabled'] == true ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                Text(
                  'Location Services',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...location.entries.where((e) => e.key != 'icon').map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    e.key.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      e.value.toString(),
                      textAlign: TextAlign.right,
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCallStatsCard(Color cardColor, Color textColor) {
    final callStats = diagnosticResults['call_stats'] as Map<String, dynamic>?;
    final recentCalls = diagnosticResults['recent_calls'] as List<CallResult>?;

    if (callStats == null) return const SizedBox.shrink();

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.phone_forwarded, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Auto-Call Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            _buildStatRow('Total Calls', callStats['total_calls'].toString(), Icons.phone, textColor),
            _buildStatRow('Successful', callStats['successful'].toString(), Icons.check_circle, textColor, Colors.green),
            _buildStatRow('Failed', callStats['failed'].toString(), Icons.error, textColor, Colors.red),
            _buildStatRow('No Permission', callStats['no_permission'].toString(), Icons.block, textColor, Colors.orange),
            _buildStatRow('Success Rate', callStats['success_rate'].toString(), Icons.trending_up, textColor, const Color(0xFF00BFA5)),

            if (recentCalls != null && recentCalls.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Text(
                'Recent Calls',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              ...recentCalls.map((call) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      call.status == CallStatus.success
                          ? Icons.check_circle
                          : Icons.error,
                      size: 16,
                      color: call.status == CallStatus.success
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        call.phoneNumber,
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(call.timestamp),
                      style: TextStyle(
                        color: textColor.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              )),

              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  _callService.clearHistory();
                  _runDiagnostics();
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Clear Call History'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // NEW: Build retry statistics card
  Widget _buildRetryStatsCard(Color cardColor, Color textColor) {
    final retryStats = diagnosticResults['retry_stats'] as Map<String, dynamic>?;
    final pendingRetries = diagnosticResults['pending_retries'] as List<RetryAttempt>?;

    if (retryStats == null) return const SizedBox.shrink();

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.repeat, color: Colors.orange),
                const SizedBox(width: 12),
                Text(
                  'Auto-Retry Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            _buildStatRow('Total Retries', retryStats['totalRetries'].toString(), Icons.all_inclusive, textColor),
            _buildStatRow('Successful', retryStats['successful'].toString(), Icons.check_circle, textColor, Colors.green),
            _buildStatRow('Failed', retryStats['failed'].toString(), Icons.error, textColor, Colors.red),
            _buildStatRow('Success Rate', retryStats['successRate'].toString(), Icons.trending_up, textColor, const Color(0xFF00BFA5)),
            _buildStatRow('Avg Attempts', retryStats['averageAttempts'].toString(), Icons.format_list_numbered, textColor),
            _buildStatRow('Pending', retryStats['currentPending'].toString(), Icons.pending, textColor, Colors.orange),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Exponential backoff: 30s → 1m → 5m → 15m → 30m (max 5 attempts)',
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (pendingRetries != null && pendingRetries.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Text(
                'Pending Retries',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              ...pendingRetries.map((retry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      retry.status == RetryStatus.pending
                          ? Icons.schedule
                          : Icons.sync,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            retry.contactName,
                            style: TextStyle(
                              color: textColor.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Attempt ${retry.attemptNumber}/${retry.maxAttempts}',
                            style: TextStyle(
                              color: textColor.withOpacity(0.5),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatTime(retry.scheduledTime),
                      style: TextStyle(
                        color: textColor.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              )),

              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final userId = authProvider.user?.uid ?? 'demo_user';
                  await _retryService.clearRetries(userId);
                  _runDiagnostics();
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Clear Retry Queue'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color textColor, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: valueColor ?? textColor.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: textColor.withOpacity(0.7)),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, dynamic data, Color cardColor, Color textColor) {
    if (data == null) return const SizedBox.shrink();

    IconData icon;
    Color iconColor;

    switch (title) {
      case 'App Information':
        icon = Icons.apps;
        iconColor = Colors.purple;
        break;
      case 'Device':
        icon = Icons.phone_android;
        iconColor = Colors.blue;
        break;
      case 'Network':
        icon = Icons.wifi;
        iconColor = Colors.green;
        break;
      case 'Battery':
        icon = Icons.battery_full;
        iconColor = Colors.orange;
        break;
      case 'Performance':
        icon = Icons.speed;
        iconColor = Colors.red;
        break;
      default:
        icon = Icons.info;
        iconColor = const Color(0xFF00BFA5);
    }

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (data is Map)
              ...data.entries.where((e) => e.key != 'icon').map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        e.key.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        e.value.toString(),
                        textAlign: TextAlign.right,
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    _retryService.dispose();
    super.dispose();
  }
}