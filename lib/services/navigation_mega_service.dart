import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class NavigationMegaService {
  static final NavigationMegaService _instance = NavigationMegaService._internal();
  factory NavigationMegaService() => _instance;
  NavigationMegaService._internal();

  Database? _db;

  Future<void> initialize() async {
    final path = join(await getDatabasesPath(), 'navigation.db');

    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
 CREATE TABLE map_regions (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 name TEXT NOT NULL,
 bounds TEXT NOT NULL,
 zoom_levels TEXT NOT NULL,
 download_date INTEGER NOT NULL,
 size_mb REAL,
 tile_count INTEGER
 )
 ''');

      await db.execute('''
 CREATE TABLE escape_routes (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 origin_lat REAL NOT NULL,
 origin_lng REAL NOT NULL,
 destination_lat REAL,
 destination_lng REAL,
 route_type TEXT NOT NULL,
 route_data TEXT NOT NULL,
 created_at INTEGER NOT NULL
 )
 ''');

      await db.execute('''
 CREATE TABLE hazard_reports (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 user_id TEXT NOT NULL,
 type TEXT NOT NULL,
 latitude REAL NOT NULL,
 longitude REAL NOT NULL,
 description TEXT,
 photo_paths TEXT,
 timestamp INTEGER NOT NULL,
 status TEXT DEFAULT 'pending',
 verified INTEGER DEFAULT 0,
 votes_up INTEGER DEFAULT 0,
 votes_down INTEGER DEFAULT 0
 )
 ''');
    });

    debugPrint(' Navigation Mega Service initialized');
  }

  Future<int> downloadMapRegion({
    required String name,
    required double northLat,
    required double southLat,
    required double eastLng,
    required double westLng,
    required List<int> zoomLevels,
  }) async {
    final tileCount = _calculateTileCount(
      northLat, southLat, eastLng, westLng, zoomLevels,
    );

    final id = await _db!.insert('map_regions', {
      'name': name,
      'bounds': jsonEncode({
        'north': northLat,
        'south': southLat,
        'east': eastLng,
        'west': westLng,
      }),
      'zoom_levels': jsonEncode(zoomLevels),
      'download_date': DateTime.now().millisecondsSinceEpoch,
      'tile_count': tileCount,
    });

    debugPrint(' Map region "$name" queued for download ($tileCount tiles)');
    return id;
  }

  int _calculateTileCount(
      double northLat,
      double southLat,
      double eastLng,
      double westLng,
      List<int> zoomLevels,
      ) {
    int total = 0;
    for (final zoom in zoomLevels) {
      final tilesX = ((eastLng - westLng) / 360 * (1 << zoom)).ceil();
      final tilesY = ((northLat - southLat) / 180 * (1 << zoom)).ceil();
      total += tilesX * tilesY;
    }
    return total;
  }

  Future<List<Map<String, dynamic>>> getDownloadedRegions() async {
    return await _db!.query('map_regions', orderBy: 'download_date DESC');
  }

  Future<List<Map<String, dynamic>>> calculateEscapeRoutes({
    required Position origin,
    Position? destination,
  }) async {
    final routes = <Map<String, dynamic>>[];

    routes.add({
      'type': 'fastest',
      'distance_km': 5.2,
      'duration_min': 12,
      'description': 'Via Main St - Fastest route',
      'waypoints': [],
    });

    routes.add({
      'type': 'safest',
      'distance_km': 6.1,
      'duration_min': 15,
      'description': 'Via Police Station - Safest route',
      'waypoints': [],
    });

    routes.add({
      'type': 'least_populated',
      'distance_km': 7.3,
      'duration_min': 18,
      'description': 'Via Residential Areas - Least crowded',
      'waypoints': [],
    });

    for (final route in routes) {
      await _db!.insert('escape_routes', {
        'origin_lat': origin.latitude,
        'origin_lng': origin.longitude,
        'destination_lat': destination?.latitude,
        'destination_lng': destination?.longitude,
        'route_type': route['type'],
        'route_data': jsonEncode(route),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    }

    return routes;
  }

  Future<int> reportHazard({
    required String userId,
    required String type,
    required Position location,
    String? description,
    List<String>? photoPaths,
  }) async {
    final id = await _db!.insert('hazard_reports', {
      'user_id': userId,
      'type': type,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'description': description,
      'photo_paths': photoPaths != null ? jsonEncode(photoPaths) : null,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'status': 'pending',
    });

    debugPrint(' Hazard reported: Type=$type, ID=$id');
    return id;
  }

  Future<List<Map<String, dynamic>>> getNearbyHazards({
    required Position center,
    double radiusKm = 5.0,
  }) async {
    final hazards = await _db!.query(
      'hazard_reports',
      where: 'status != ?',
      whereArgs: ['resolved'],
      orderBy: 'timestamp DESC',
    );

    return hazards.where((hazard) {
      final lat = hazard['latitude'] as double;
      final lng = hazard['longitude'] as double;
      final distance = Geolocator.distanceBetween(
        center.latitude,
        center.longitude,
        lat,
        lng,
      );
      return distance <= (radiusKm * 1000);
    }).toList();
  }

  Future<void> voteOnHazard(int hazardId, bool upvote) async {
    final field = upvote ? 'votes_up' : 'votes_down';
    await _db!.rawUpdate(
      'UPDATE hazard_reports SET $field = $field + 1 WHERE id = ?',
      [hazardId],
    );
  }

  void dispose() {
    _db?.close();
  }
}