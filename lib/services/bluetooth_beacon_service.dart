import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';

/// ==================== BLUETOOTH BEACON SERVICE ====================
///
/// Broadcast emergency beacon and detect nearby contacts
///
/// FEATURES:
/// - Bluetooth broadcasting (MOCK - ready for real implementation)
/// - Detect nearby contacts
/// - Auto-send queued alerts
/// - Range detection
/// - Background operation
///
/// NOTE: This is a MOCK implementation. Replace with actual Bluetooth
/// package when ready (flutter_blue_plus recommended).
///
/// ==================================================================

class BluetoothBeaconService {
  bool _isInitialized = false;
  bool _isBroadcasting = false;

  final List<String> _nearbyBeacons = [];
  final StreamController<List<String>> _beaconsStreamController =
  StreamController<List<String>>.broadcast();

  Timer? _scanTimer;

  // Beacon configuration
  static const String _beaconPrefix = 'AKEL_EMERGENCY_';
  String? _myBeaconId;

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      // Generate unique beacon ID
      _myBeaconId = _beaconPrefix + DateTime.now().millisecondsSinceEpoch.toString();

      _isInitialized = true;
      debugPrint(' Bluetooth Beacon Service initialized (MOCK MODE)');
      debugPrint(' Beacon ID: $_myBeaconId');
      debugPrint(' Note: Using mock Bluetooth - replace with real implementation');
    } catch (e) {
      debugPrint(' Bluetooth Beacon init error: $e');
    }
  }

  // ==================== BROADCASTING ====================

  Future<void> startBroadcasting() async {
    try {
      if (!_isInitialized) await initialize();
      if (_isBroadcasting) return;

      debugPrint(' Broadcasting beacon: $_myBeaconId (MOCK MODE)');

      _isBroadcasting = true;

      // Start mock scanning
      _startMockScanning();

      debugPrint(' Bluetooth beacon broadcasting started (MOCK)');
    } catch (e) {
      debugPrint(' Start broadcasting error: $e');
    }
  }

  Future<void> stopBroadcasting() async {
    try {
      _isBroadcasting = false;
      _stopScanning();

      debugPrint(' Bluetooth beacon broadcasting stopped');
    } catch (e) {
      debugPrint(' Stop broadcasting error: $e');
    }
  }

  // ==================== MOCK SCANNING ====================

  void _startMockScanning() {
    _stopScanning(); // Stop any existing scan

    // Periodic scanning (every 30 seconds)
    _scanTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _performMockScan();
    });

    // Initial scan
    _performMockScan();
  }

  void _stopScanning() {
    _scanTimer?.cancel();
    _scanTimer = null;
  }

  Future<void> _performMockScan() async {
    try {
      debugPrint(' Scanning for nearby beacons... (MOCK)');

      final previousBeacons = List<String>.from(_nearbyBeacons);
      _nearbyBeacons.clear();

      // MOCK: Simulate finding nearby beacons (for testing)
      // In production, this would scan actual Bluetooth devices

      // Uncomment to simulate nearby beacons for testing:
      // _nearbyBeacons.add('AKEL_EMERGENCY_MOCK_BEACON_1');
      // _nearbyBeacons.add('AKEL_EMERGENCY_MOCK_BEACON_2');

      debugPrint(' Scan complete. Found ${_nearbyBeacons.length} beacons (MOCK)');

      // Notify listeners if beacons changed
      if (!_listsEqual(previousBeacons, _nearbyBeacons)) {
        _beaconsStreamController.add(List.from(_nearbyBeacons));
      }
    } catch (e) {
      debugPrint(' Scan error: $e');
    }
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ==================== ALERT SENDING ====================

  Future<void> sendAlertToBeacon(String beaconId, Map<String, dynamic> alertData) async {
    try {
      debugPrint(' Sending alert to beacon: $beaconId (MOCK)');

      // MOCK: Simulate sending alert
      // In production, this would:
      // 1. Connect to the Bluetooth device
      // 2. Send the alert data
      // 3. Close the connection

      final alertJson = jsonEncode(alertData);

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint(' Alert sent to beacon: $beaconId (MOCK)');
      debugPrint(' Alert data: ${alertJson.substring(0, 100)}...');
    } catch (e) {
      debugPrint(' Send alert error: $e');
    }
  }

  // ==================== NEARBY BEACONS ====================

  List<String> get nearbyBeacons => List.unmodifiable(_nearbyBeacons);

  Stream<List<String>> get nearbyBeaconsStream => _beaconsStreamController.stream;

  bool isBeaconNearby(String beaconId) {
    return _nearbyBeacons.contains(beaconId);
  }

  // ==================== PAIRED DEVICES ====================

  Future<List<MockBluetoothDevice>> getPairedDevices() async {
    try {
      // MOCK: Return empty list
      // In production, this would return actual paired Bluetooth devices
      debugPrint(' Getting paired devices... (MOCK)');
      return [];
    } catch (e) {
      debugPrint(' Get paired devices error: $e');
      return [];
    }
  }

  // ==================== MOCK BEACON SIMULATION (FOR TESTING) ====================

  /// Add a mock nearby beacon for testing purposes
  void addMockNearbyBeacon(String beaconId) {
    if (!_nearbyBeacons.contains(beaconId)) {
      _nearbyBeacons.add(beaconId);
      _beaconsStreamController.add(List.from(_nearbyBeacons));
      debugPrint(' Mock beacon added: $beaconId');
    }
  }

  /// Remove a mock nearby beacon
  void removeMockNearbyBeacon(String beaconId) {
    if (_nearbyBeacons.remove(beaconId)) {
      _beaconsStreamController.add(List.from(_nearbyBeacons));
      debugPrint(' Mock beacon removed: $beaconId');
    }
  }

  /// Clear all mock nearby beacons
  void clearMockNearbyBeacons() {
    _nearbyBeacons.clear();
    _beaconsStreamController.add([]);
    debugPrint(' All mock beacons cleared');
  }

  // ==================== STATUS ====================

  bool get isInitialized => _isInitialized;
  bool get isBroadcasting => _isBroadcasting;
  String? get myBeaconId => _myBeaconId;
  int get nearbyBeaconCount => _nearbyBeacons.length;

  // ==================== DISPOSE ====================

  void dispose() {
    stopBroadcasting();
    _beaconsStreamController.close();
    _isInitialized = false;
    debugPrint(' Bluetooth Beacon Service disposed');
  }
}

// ==================== MOCK BLUETOOTH DEVICE MODEL ====================

/// Mock Bluetooth device model (for type compatibility)
/// Replace with actual BluetoothDevice from flutter_blue_plus when ready
class MockBluetoothDevice {
  final String name;
  final String address;
  final bool isConnected;

  MockBluetoothDevice({
    required this.name,
    required this.address,
    this.isConnected = false,
  });

  @override
  String toString() => 'MockBluetoothDevice(name: $name, address: $address)';
}