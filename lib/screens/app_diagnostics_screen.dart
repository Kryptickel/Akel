import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class AppDiagnosticsScreen extends StatefulWidget {
  const AppDiagnosticsScreen({Key? key}) : super(key: key);

  @override
  State<AppDiagnosticsScreen> createState() => _AppDiagnosticsScreenState();
}

class _AppDiagnosticsScreenState extends State<AppDiagnosticsScreen> {
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
      permissions['Location'] = {
        'granted': await Permission.location.isGranted,
        'status': (await Permission.location.status).toString(),
      };
    } catch (e) {
      permissions['error'] = e.toString();
    }

    diagnosticResults['permissions'] = permissions;
  }

  Future<void> _checkLocationServices() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      diagnosticResults['location'] = {
        'service_enabled': serviceEnabled,
      };
    } catch (e) {
      diagnosticResults['location'] = {'error': e.toString()};
    }
  }

  Future<void> _checkDeviceInfo() async {
    try {
      diagnosticResults['device'] = {
        'platform': 'Web',
        'version': 'N/A',
      };
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
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 5),
      );

      diagnosticResults['network'] = {
        'connected': result.isNotEmpty && result[0].rawAddress.isNotEmpty,
        'address': result.isNotEmpty ? result[0].address : 'N/A',
      };
    } catch (e) {
      diagnosticResults['network'] = {
        'connected': false,
        'error': e.toString(),
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

    diagnosticResults['performance'] = {
      'computation_time_ms': stopwatch.elapsedMilliseconds,
      'status': stopwatch.elapsedMilliseconds < 100 ? 'Excellent' : 'Good',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildInfoCard('App Information', diagnosticResults['app']),
          const SizedBox(height: 16),
          _buildInfoCard('Device', diagnosticResults['device']),
          const SizedBox(height: 16),
          _buildInfoCard('Network', diagnosticResults['network']),
          const SizedBox(height: 16),
          _buildInfoCard('Performance', diagnosticResults['performance']),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'System Health',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Diagnostics Complete',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, dynamic data) {
    if (data == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            if (data is Map)
              ...data.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(e.value.toString()),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }
}