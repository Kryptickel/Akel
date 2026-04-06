import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math; // ADDED: Import for tan, cos, log functions

/// ==================== OFFLINE MAPS SERVICE ====================
///
/// GPS tracking and navigation without internet
///
/// FEATURES:
/// - Cached map tiles
/// - Offline navigation
/// - Last known position
/// - Route caching
/// - Area download
///
/// ==============================================================

class OfflineMapsService {
  bool _isInitialized = false;
  Position? _lastKnownPosition;
  final List<CachedMapTile> _cachedTiles = [];
  String? _cacheDirectory;

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      // Setup cache directory
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = '${appDir.path}/offline_maps';

      final cacheDir = Directory(_cacheDirectory!);
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      // Load last known position
      await _loadLastKnownPosition();

      // Load cached tiles info
      await _loadCachedTilesInfo();

      _isInitialized = true;
      debugPrint(' Offline Maps Service initialized');
      debugPrint(' Cache directory: $_cacheDirectory');
      debugPrint(' Cached tiles: ${_cachedTiles.length}');
    } catch (e) {
      debugPrint(' Offline Maps init error: $e');
    }
  }

  // ==================== POSITION TRACKING ====================

  Future<Position?> getLastKnownPosition() async {
    try {
      // Try to get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          if (_lastKnownPosition != null) {
            return _lastKnownPosition!;
          }
          throw TimeoutException('Position timeout');
        },
      );

      // Save as last known
      _lastKnownPosition = position;
      await _saveLastKnownPosition(position);

      return position;
    } catch (e) {
      debugPrint(' Get position error: $e');
      return _lastKnownPosition;
    }
  }

  Future<void> _loadLastKnownPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final positionJson = prefs.getString('last_known_position');

      if (positionJson != null) {
        final data = jsonDecode(positionJson);
        _lastKnownPosition = Position(
          latitude: data['latitude'],
          longitude: data['longitude'],
          timestamp: DateTime.parse(data['timestamp']),
          accuracy: data['accuracy'],
          altitude: data['altitude'],
          altitudeAccuracy: data['altitudeAccuracy'] ?? 0.0,
          heading: data['heading'],
          headingAccuracy: data['headingAccuracy'] ?? 0.0,
          speed: data['speed'],
          speedAccuracy: data['speedAccuracy'],
        );
        debugPrint(' Loaded last known position: ${_lastKnownPosition!.latitude}, ${_lastKnownPosition!.longitude}');
      }
    } catch (e) {
      debugPrint(' Load position error: $e');
    }
  }

  Future<void> _saveLastKnownPosition(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final positionJson = jsonEncode({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': position.timestamp.toIso8601String(),
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'altitudeAccuracy': position.altitudeAccuracy,
        'heading': position.heading,
        'headingAccuracy': position.headingAccuracy,
        'speed': position.speed,
        'speedAccuracy': position.speedAccuracy,
      });

      await prefs.setString('last_known_position', positionJson);
    } catch (e) {
      debugPrint(' Save position error: $e');
    }
  }

  // ==================== OFFLINE MAPS AVAILABILITY ====================

  Future<bool> checkOfflineMapsAvailable() async {
    try {
      if (_cacheDirectory == null) return false;

      final cacheDir = Directory(_cacheDirectory!);
      if (!await cacheDir.exists()) return false;

      final files = await cacheDir.list().toList();
      final hasMapTiles = files.any((file) =>
      file.path.endsWith('.png') || file.path.endsWith('.jpg')
      );

      debugPrint(' Offline maps available: $hasMapTiles (${files.length} files)');
      return hasMapTiles;
    } catch (e) {
      debugPrint(' Check offline maps error: $e');
      return false;
    }
  }

  // ==================== MAP TILE CACHING ====================

  Future<void> _loadCachedTilesInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tilesJson = prefs.getString('cached_map_tiles');

      if (tilesJson != null) {
        final List<dynamic> tilesList = jsonDecode(tilesJson);
        _cachedTiles.clear();

        for (final tileData in tilesList) {
          _cachedTiles.add(CachedMapTile.fromJson(tileData));
        }

        debugPrint(' Loaded ${_cachedTiles.length} cached tiles info');
      }
    } catch (e) {
      debugPrint(' Load cached tiles error: $e');
    }
  }

  Future<void> _saveCachedTilesInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tilesJson = jsonEncode(
          _cachedTiles.map((tile) => tile.toJson()).toList()
      );

      await prefs.setString('cached_map_tiles', tilesJson);
    } catch (e) {
      debugPrint(' Save cached tiles error: $e');
    }
  }

  Future<void> downloadAreaForOffline({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
    required int zoomLevel,
  }) async {
    try {
      debugPrint(' Downloading area for offline use...');
      debugPrint(' Center: $centerLat, $centerLng');
      debugPrint(' Radius: ${radiusKm}km, Zoom: $zoomLevel');

      // Calculate tile range
      final tiles = _calculateTilesInRadius(
        centerLat,
        centerLng,
        radiusKm,
        zoomLevel,
      );

      debugPrint(' Total tiles to download: ${tiles.length}');

      // Download tiles (simulation - real implementation would download from tile server)
      for (final tile in tiles) {
        final cached = CachedMapTile(
          x: tile.x,
          y: tile.y,
          zoom: tile.zoom,
          filePath: '${_cacheDirectory}/tile_${tile.zoom}_${tile.x}_${tile.y}.png',
          downloadedAt: DateTime.now(),
        );

        _cachedTiles.add(cached);
      }

      await _saveCachedTilesInfo();
      debugPrint(' Downloaded ${tiles.length} tiles for offline use');
    } catch (e) {
      debugPrint(' Download area error: $e');
    }
  }

  List<MapTile> _calculateTilesInRadius(
      double lat,
      double lng,
      double radiusKm,
      int zoom,
      ) {
    final tiles = <MapTile>[];

    // Convert radius to tile coordinates
    final centerTile = _latLngToTile(lat, lng, zoom);
    final radiusTiles = (radiusKm / 40).ceil(); // Approximate

    for (int x = centerTile.x - radiusTiles; x <= centerTile.x + radiusTiles; x++) {
      for (int y = centerTile.y - radiusTiles; y <= centerTile.y + radiusTiles; y++) {
        tiles.add(MapTile(x: x, y: y, zoom: zoom));
      }
    }

    return tiles;
  }

  MapTile _latLngToTile(double lat, double lng, int zoom) {
    final n = 1 << zoom;
    final x = ((lng + 180.0) / 360.0 * n).floor();

    // FIXED: Use math.tan and math.cos instead of calling on double
    final latRad = lat * math.pi / 180.0;
    final y = ((1.0 - (math.log(math.tan(latRad) + (1 / math.cos(latRad))) / math.pi)) / 2.0 * n).floor();

    return MapTile(x: x, y: y, zoom: zoom);
  }

  // ==================== NAVIGATION ====================

  Future<void> navigateToLocation(
      double lat,
      double lng,
      String locationName,
      ) async {
    try {
      debugPrint(' Navigating to: $locationName ($lat, $lng)');

      // Open in Google Maps (online)
      final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
      debugPrint(' Navigation URL: $url');

      // In real implementation, would open URL
      // await launchUrl(Uri.parse(url));
    } catch (e) {
      debugPrint(' Navigate error: $e');
    }
  }

  Future<void> navigateToLocationOffline(
      double lat,
      double lng,
      String locationName,
      ) async {
    try {
      debugPrint(' Offline navigation to: $locationName ($lat, $lng)');

      final currentPosition = await getLastKnownPosition();
      if (currentPosition == null) {
        debugPrint(' No current position available');
        return;
      }

      // Calculate route (simplified - real implementation would use routing algorithm)
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        lat,
        lng,
      );

      final bearing = Geolocator.bearingBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        lat,
        lng,
      );

      debugPrint(' Distance: ${(distance / 1000).toStringAsFixed(2)}km');
      debugPrint(' Bearing: ${bearing.toStringAsFixed(1)}°');

      // In real implementation, would show route on offline map
    } catch (e) {
      debugPrint(' Offline navigate error: $e');
    }
  }

  // ==================== CACHE MANAGEMENT ====================

  Future<int> getCacheSizeBytes() async {
    try {
      if (_cacheDirectory == null) return 0;

      final cacheDir = Directory(_cacheDirectory!);
      if (!await cacheDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint(' Get cache size error: $e');
      return 0;
    }
  }

  Future<void> clearCache() async {
    try {
      if (_cacheDirectory == null) return;

      final cacheDir = Directory(_cacheDirectory!);
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }

      _cachedTiles.clear();
      await _saveCachedTilesInfo();

      debugPrint(' Offline maps cache cleared');
    } catch (e) {
      debugPrint(' Clear cache error: $e');
    }
  }

  // ==================== STATUS ====================

  bool get isInitialized => _isInitialized;
  Position? get lastKnownPosition => _lastKnownPosition;
  int get cachedTilesCount => _cachedTiles.length;

  // ==================== DISPOSE ====================

  void dispose() {
    _isInitialized = false;
    debugPrint(' Offline Maps Service disposed');
  }
}

// ==================== MODELS ====================

class MapTile {
  final int x;
  final int y;
  final int zoom;

  MapTile({required this.x, required this.y, required this.zoom});
}

class CachedMapTile {
  final int x;
  final int y;
  final int zoom;
  final String filePath;
  final DateTime downloadedAt;

  CachedMapTile({
    required this.x,
    required this.y,
    required this.zoom,
    required this.filePath,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'zoom': zoom,
    'filePath': filePath,
    'downloadedAt': downloadedAt.toIso8601String(),
  };

  factory CachedMapTile.fromJson(Map<String, dynamic> json) => CachedMapTile(
    x: json['x'],
    y: json['y'],
    zoom: json['zoom'],
    filePath: json['filePath'],
    downloadedAt: DateTime.parse(json['downloadedAt']),
  );
}