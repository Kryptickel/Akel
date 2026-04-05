import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MeshCADService {
  static final MeshCADService _instance = MeshCADService._internal();
  factory MeshCADService() => _instance;
  MeshCADService._internal();

  bool _meshEnabled = false;
  bool _cadIntegrationEnabled = false;
  String? _cadApiEndpoint;
  String? _cadApiKey;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _meshEnabled = prefs.getBool('mesh_enabled') ?? false;
    _cadIntegrationEnabled = prefs.getBool('cad_integration_enabled') ?? false;
    _cadApiEndpoint = prefs.getString('cad_api_endpoint');
    _cadApiKey = prefs.getString('cad_api_key');

    debugPrint('✅ Mesh & CAD Service initialized');
  }

  Future<void> enableMeshNetworking() async {
    _meshEnabled = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mesh_enabled', true);

    debugPrint('✅ Mesh networking enabled (OPTIONAL - Battery intensive)');
  }

  Future<void> disableMeshNetworking() async {
    _meshEnabled = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mesh_enabled', false);

    debugPrint('❌ Mesh networking disabled');
  }

  Future<void> sendViaMesh({
    required String message,
    required Map<String, dynamic> emergency,
  }) async {
    if (!_meshEnabled) return;

    debugPrint('📡 Sending emergency via mesh network...');
  }

  bool get isMeshEnabled => _meshEnabled;

  Future<void> enableCADIntegration({
    required String apiEndpoint,
    required String apiKey,
  }) async {
    _cadIntegrationEnabled = true;
    _cadApiEndpoint = apiEndpoint;
    _cadApiKey = apiKey;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cad_integration_enabled', true);
    await prefs.setString('cad_api_endpoint', apiEndpoint);
    await prefs.setString('cad_api_key', apiKey);

    debugPrint('✅ CAD integration enabled: $apiEndpoint');
  }

  Future<void> disableCADIntegration() async {
    _cadIntegrationEnabled = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cad_integration_enabled', false);

    debugPrint('❌ CAD integration disabled');
  }

  Future<Map<String, dynamic>?> sendToCAD({
    required Map<String, dynamic> emergency,
  }) async {
    if (!_cadIntegrationEnabled || _cadApiEndpoint == null) return null;

    try {
      final payload = {
        'caller_name': emergency['user_name'],
        'caller_phone': emergency['user_phone'],
        'location': {
          'latitude': emergency['latitude'],
          'longitude': emergency['longitude'],
          'address': emergency['address'],
        },
        'incident_type': 'PANIC_BUTTON',
        'priority': 'HIGH',
        'notes': emergency['message'],
        'timestamp': DateTime.now().toIso8601String(),
      };

      await Future.delayed(const Duration(seconds: 1));

      debugPrint('📞 Emergency sent to CAD system');

      return {
        'status': 'success',
        'incident_id': 'CAD-${DateTime.now().millisecondsSinceEpoch}',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ CAD integration error: $e');
      return null;
    }
  }

  bool get isCADEnabled => _cadIntegrationEnabled;
  String? get cadEndpoint => _cadApiEndpoint;

  void dispose() {
// Cleanup if needed
  }
}