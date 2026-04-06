import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamController<bool>? _connectivityController;

// Stream of connectivity status (true = online, false = offline)
  Stream<bool> get connectivityStream {
    _connectivityController ??= StreamController<bool>.broadcast();

    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isOnline = results.isNotEmpty &&
          results.any((result) => result != ConnectivityResult.none);
      _connectivityController?.add(isOnline);
    });

    return _connectivityController!.stream;
  }

// Check current connectivity status
  Future<bool> isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.isNotEmpty &&
          results.any((result) => result != ConnectivityResult.none);
    } catch (e) {
// If we can't check, assume online to not block functionality
      return true;
    }
  }

// Get connectivity type name
  Future<String> getConnectionType() async {
    try {
      final results = await _connectivity.checkConnectivity();

      if (results.isEmpty || results.first == ConnectivityResult.none) {
        return 'Offline';
      }

      if (results.contains(ConnectivityResult.wifi)) {
        return 'WiFi';
      } else if (results.contains(ConnectivityResult.mobile)) {
        return 'Mobile Data';
      } else if (results.contains(ConnectivityResult.ethernet)) {
        return 'Ethernet';
      } else {
        return 'Connected';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

// Dispose
  void dispose() {
    _connectivityController?.close();
  }
}