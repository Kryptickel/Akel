import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class OfflineEmergencyService {
  static final OfflineEmergencyService _instance = OfflineEmergencyService._internal();
  factory OfflineEmergencyService() => _instance;
  OfflineEmergencyService._internal();

  Database? _database;
  bool _isInitialized = false;

  // Initialize the offline database
  Future<void> initialize() async {
    if (_isInitialized) return;

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'offline_emergency.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Emergency queue table
        await db.execute('''
 CREATE TABLE emergency_queue (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 user_id TEXT NOT NULL,
 timestamp INTEGER NOT NULL,
 latitude REAL,
 longitude REAL,
 message TEXT NOT NULL,
 contacts TEXT NOT NULL,
 voice_note_path TEXT,
 photos TEXT,
 status TEXT DEFAULT 'pending',
 retry_count INTEGER DEFAULT 0,
 last_retry INTEGER,
 created_at INTEGER NOT NULL
 )
 ''');

        // Location breadcrumbs table
        await db.execute('''
 CREATE TABLE location_breadcrumbs (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 emergency_id INTEGER,
 latitude REAL NOT NULL,
 longitude REAL NOT NULL,
 accuracy REAL,
 timestamp INTEGER NOT NULL,
 FOREIGN KEY (emergency_id) REFERENCES emergency_queue (id)
 )
 ''');

        // Offline recordings table
        await db.execute('''
 CREATE TABLE offline_recordings (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 emergency_id INTEGER,
 audio_path TEXT NOT NULL,
 duration INTEGER,
 timestamp INTEGER NOT NULL,
 FOREIGN KEY (emergency_id) REFERENCES emergency_queue (id)
 )
 ''');
      },
    );

    _isInitialized = true;
    debugPrint(' Offline Emergency Service initialized');
  }

  // Queue an emergency when offline
  Future<int> queueEmergency({
    required String userId,
    required String message,
    required List<Map<String, dynamic>> contacts,
    Position? location,
    String? voiceNotePath,
    List<String>? photoPaths,
  }) async {
    await initialize();

    final emergencyId = await _database!.insert('emergency_queue', {
      'user_id': userId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'latitude': location?.latitude,
      'longitude': location?.longitude,
      'message': message,
      'contacts': jsonEncode(contacts),
      'voice_note_path': voiceNotePath,
      'photos': photoPaths != null ? jsonEncode(photoPaths) : null,
      'status': 'pending',
      'retry_count': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    debugPrint(' Emergency queued offline: ID $emergencyId');

    // Start breadcrumb tracking for this emergency
    _startBreadcrumbTracking(emergencyId);

    return emergencyId;
  }

  // Track location breadcrumbs while offline
  Future<void> _startBreadcrumbTracking(int emergencyId) async {
    // This will be called periodically to save location
    // Integration with your existing LocationHistoryService
  }

  // Add location breadcrumb
  Future<void> addBreadcrumb({
    required int emergencyId,
    required Position position,
  }) async {
    await initialize();

    await _database!.insert('location_breadcrumbs', {
      'emergency_id': emergencyId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    debugPrint(' Breadcrumb added for emergency $emergencyId');
  }

  // Get all pending emergencies
  Future<List<Map<String, dynamic>>> getPendingEmergencies() async {
    await initialize();

    final results = await _database!.query(
      'emergency_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'timestamp ASC',
    );

    return results;
  }

  // Get breadcrumbs for an emergency
  Future<List<Map<String, dynamic>>> getBreadcrumbs(int emergencyId) async {
    await initialize();

    final results = await _database!.query(
      'location_breadcrumbs',
      where: 'emergency_id = ?',
      whereArgs: [emergencyId],
      orderBy: 'timestamp ASC',
    );

    return results;
  }

  // Mark emergency as sent
  Future<void> markAsSent(int emergencyId) async {
    await initialize();

    await _database!.update(
      'emergency_queue',
      {'status': 'sent'},
      where: 'id = ?',
      whereArgs: [emergencyId],
    );

    debugPrint(' Emergency $emergencyId marked as sent');
  }

  // Mark emergency as failed
  Future<void> markAsFailed(int emergencyId, {String? error}) async {
    await initialize();

    await _database!.update(
      'emergency_queue',
      {
        'status': 'failed',
        'retry_count': null, // Will be incremented on retry
      },
      where: 'id = ?',
      whereArgs: [emergencyId],
    );

    debugPrint(' Emergency $emergencyId marked as failed: $error');
  }

  // Increment retry count
  Future<void> incrementRetry(int emergencyId) async {
    await initialize();

    await _database!.rawUpdate('''
 UPDATE emergency_queue 
 SET retry_count = retry_count + 1,
 last_retry = ?
 WHERE id = ?
 ''', [DateTime.now().millisecondsSinceEpoch, emergencyId]);
  }

  // Get count of pending emergencies
  Future<int> getPendingCount() async {
    await initialize();

    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM emergency_queue WHERE status = ?',
      ['pending'],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Clear old sent/failed emergencies (cleanup)
  Future<void> cleanup({int daysToKeep = 7}) async {
    await initialize();

    final cutoffTime = DateTime.now()
        .subtract(Duration(days: daysToKeep))
        .millisecondsSinceEpoch;

    await _database!.delete(
      'emergency_queue',
      where: 'created_at < ? AND status IN (?, ?)',
      whereArgs: [cutoffTime, 'sent', 'failed'],
    );

    debugPrint(' Cleaned up old emergency records');
  }

  // Export emergency data (for debugging/reporting)
  Future<Map<String, dynamic>> exportEmergencyData(int emergencyId) async {
    await initialize();

    final emergency = await _database!.query(
      'emergency_queue',
      where: 'id = ?',
      whereArgs: [emergencyId],
    );

    if (emergency.isEmpty) return {};

    final breadcrumbs = await getBreadcrumbs(emergencyId);

    return {
      'emergency': emergency.first,
      'breadcrumbs': breadcrumbs,
    };
  }

  void dispose() {
    _database?.close();
    _isInitialized = false;
  }
}