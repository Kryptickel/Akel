import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

class DoctorAnnieMapScreen extends StatefulWidget {
  const DoctorAnnieMapScreen({Key? key}) : super(key: key);

  @override
  State<DoctorAnnieMapScreen> createState() => _DoctorAnnieMapScreenState();
}

class Facility {
  final String id;
  final String name;
  final String type;
  final double lat;
  final double lng;
  final String? address;
  final String? phone;

  Facility({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    this.address,
    this.phone,
  });

  factory Facility.fromJson(Map<String, dynamic> j) {
    return Facility(
      id: j['id']?.toString() ?? (j['name'] ?? ''),
      name: j['name'] ?? '',
      type: j['type'] ?? (j['types'] != null ? (j['types'][0] as String) : 'Hospital'),
      lat: (j['lat'] ?? (j['geometry']?['location']?['lat']))?.toDouble() ?? 0.0,
      lng: (j['lng'] ?? (j['geometry']?['location']?['lng']))?.toDouble() ?? 0.0,
      address: j['vicinity'] ?? j['address'],
      phone: j['phone'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'lat': lat,
    'lng': lng,
    'address': address,
    'phone': phone,
  };
}

class _DoctorAnnieMapScreenState extends State<DoctorAnnieMapScreen> {
  final Completer<GoogleMapController> _mapController = Completer();

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  late StreamSubscription<List<ConnectivityResult>> _connectivitySub;
  bool _isOnline = true;

  Position? _currentLocation;

  Set<Marker> _markers = {};
  List<Facility> _facilities = [];

  bool _isListening = false;
  String _voiceCommand = '';
  Facility? _selectedFacility;
  bool _loading = false;

  static const _placesApiKey = "YOUR_GOOGLE_PLACES_API_KEY";
  static const _directionsApiKey = "YOUR_GOOGLE_PLACES_API_KEY";

  @override
  void initState() {
    super.initState();
    _initTts();
    _initConnectivity();
    _initLocationAndLoad();
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
  }

  void _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _isOnline = _isConnectedFromResult(result);

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = _isConnectedFromResult(results);
      if (wasOnline != _isOnline) {
        if (_isOnline) {
          _speak("Connection restored. Switching to online mode.");
          _fetchNearbyFacilities();
        } else {
          _speak("You are offline. Switching to emergency offline mode.");
          _loadOfflineFacilities();
        }
      }
    });
  }

  bool _isConnectedFromResult(List<ConnectivityResult> results) {
    return results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi);
  }

  Future<void> _initLocationAndLoad() async {
    await _ensureLocationPermissions();
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = position;
      });
      if (_isOnline) {
        await _fetchNearbyFacilities();
      } else {
        await _loadOfflineFacilities();
      }
    } catch (e) {
      debugPrint('Location error: $e');
      _speak("Unable to get your location. Please enable location services.");
    }
  }

  Future<void> _ensureLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _speak("Location services are disabled. Please enable them for Doctor Annie.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _speak("Location permission denied. Doctor Annie cannot provide location-based help.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _speak("Location permissions are permanently denied. Please enable them in settings.");
      return;
    }
  }

  Future<void> _fetchNearbyFacilities() async {
    if (_currentLocation == null) return;
    setState(() {
      _loading = true;
    });

    final lat = _currentLocation!.latitude;
    final lng = _currentLocation!.longitude;
    try {
      final url = Uri.parse(
          "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=5000&type=hospital&keyword=clinic|hospital|pharmacy&key=$_placesApiKey");

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final body = json.decode(response.body);

      if (body['status'] == 'OK' && body['results'] != null) {
        final results = body['results'] as List<dynamic>;
        final List<Facility> fetched = results.map((p) {
          final geom = p['geometry']?['location'];
          return Facility(
            id: p['place_id'] ?? p['name'],
            name: p['name'] ?? 'Unknown',
            type: (p['types'] != null && p['types'].isNotEmpty)
                ? p['types'][0]
                : 'Hospital',
            lat: (geom != null ? (geom['lat'] as num).toDouble() : 0.0),
            lng: (geom != null ? (geom['lng'] as num).toDouble() : 0.0),
            address: p['vicinity'],
            phone: null,
          );
        }).toList();

        _facilities = fetched;
        await _cacheFacilities(_facilities);
        _updateMarkers();
        _speak("Doctor Annie found ${_facilities.length} nearby medical centers.");
      } else {
        _speak("No results from the Places API. Switching to cached facilities.");
        await _loadOfflineFacilities();
      }
    } catch (e) {
      debugPrint('Fetch error: $e');
      await _loadOfflineFacilities();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _cacheFacilities(List<Facility> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(list.map((f) => f.toJson()).toList());
    await prefs.setString('cached_facilities', jsonStr);
    await prefs.setString('cached_at', DateTime.now().toIso8601String());
  }

  Future<void> _loadOfflineFacilities() async {
    setState(() {
      _loading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_facilities');
    if (cached != null) {
      try {
        final data = json.decode(cached) as List<dynamic>;
        _facilities = data
            .map((j) => Facility.fromJson(j as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Cache parse error: $e');
        _facilities = [];
      }
    }

    if (_facilities.isEmpty) {
      try {
        final raw = await rootBundle.loadString('assets/data/local_facilities.json');
        final arr = json.decode(raw) as List<dynamic>;
        _facilities = arr.map((j) {
          final m = j as Map<String, dynamic>;
          return Facility(
            id: m['name'],
            name: m['name'],
            type: m['type'] ?? 'Hospital',
            lat: (m['lat'] as num).toDouble(),
            lng: (m['lng'] as num).toDouble(),
            address: m['address'],
            phone: m['phone'],
          );
        }).toList();
      } catch (e) {
        debugPrint('Asset load error: $e');
        _facilities = [];
      }
    }

    _updateMarkers();
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
    _speak("Offline emergency centers loaded. I can still estimate travel times.");
  }

  void _updateMarkers() {
    final Set<Marker> m = {};
    for (var f in _facilities) {
      final marker = Marker(
        markerId: MarkerId(f.id),
        position: LatLng(f.lat, f.lng),
        infoWindow: InfoWindow(title: f.name, snippet: f.address ?? ''),
        onTap: () {
          setState(() {
            _selectedFacility = f;
          });
        },
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
      m.add(marker);
    }
    setState(() {
      _markers = m;
    });
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (!available) {
      _speak("Speech recognition not available on this device.");
      return;
    }
    setState(() {
      _isListening = true;
    });
    _speech.listen(
      onResult: (r) {
        setState(() {
          _voiceCommand = r.recognizedWords;
        });
        if (r.finalResult) {
          _processVoiceCommand(_voiceCommand);
        }
      },
      listenFor: const Duration(seconds: 6),
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _processVoiceCommand(String cmd) async {
    final lower = cmd.toLowerCase();
    if (lower.contains('nearest') &&
        (lower.contains('hospital') ||
            lower.contains('clinic') ||
            lower.contains('pharmacy'))) {
      await _speak("Okay, finding the nearest medical center.");
      if (_isOnline) {
        await _fetchNearbyFacilities();
      } else {
        await _loadOfflineFacilities();
      }
      _focusOnNearest();
    } else if (lower.contains('call') && lower.contains('emergency')) {
      await _speak("Calling emergency services.");
      _launchPhone('911');
    } else {
      await _speak(
          "Sorry, I did not understand. Say 'find nearest hospital' or 'call emergency'.");
    }
    _stopListening();
  }

  void _focusOnNearest() {
    if (_currentLocation == null || _facilities.isEmpty) {
      _speak("I don't have enough location data to find the nearest center.");
      return;
    }
    final lat = _currentLocation!.latitude;
    final lng = _currentLocation!.longitude;
    Facility? best;
    double bestDist = double.infinity;
    for (var f in _facilities) {
      final d = _haversine(lat, lng, f.lat, f.lng);
      if (d < bestDist) {
        bestDist = d;
        best = f;
      }
    }
    if (best != null) {
      setState(() {
        _selectedFacility = best;
      });
      _moveCameraTo(best.lat, best.lng, zoom: 15);
      _speak(
          "Nearest is ${best.name}, approximately ${_formatDistance(bestDist)} away. Tap to see directions or call.");
    }
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return "${(meters / 1000).toStringAsFixed(1)} km";
    } else {
      return "${meters.toStringAsFixed(0)} m";
    }
  }

  String _approximateEta(double meters) {
    final avgSpeedMs = 11.11;
    final secs = meters / avgSpeedMs;
    final mins = (secs / 60).round();
    if (mins < 60) return "$mins min";
    final hrs = (mins / 60).floor();
    final rem = mins % 60;
    return "${hrs}h ${rem}m";
  }

  Future<void> _moveCameraTo(double lat, double lng, {double zoom = 14.0}) async {
    final controller = await _mapController.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: zoom)));
  }

  Future<void> _getDirectionsAndOpen(Facility f) async {
    if (_currentLocation == null) return;

    if (!_isOnline) {
      final meters = _haversine(
          _currentLocation!.latitude, _currentLocation!.longitude, f.lat, f.lng);
      final eta = _approximateEta(meters);
      await _speak(
          "Offline. Estimated travel time is $eta. Would you like me to call this facility?");
      _showFacilityActionDialog(f, eta, offline: true);
      return;
    }

    final origin = "${_currentLocation!.latitude},${_currentLocation!.longitude}";
    final destination = "${f.lat},${f.lng}";
    final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=driving&key=$_directionsApiKey");

    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      final body = json.decode(res.body);
      if (body['status'] == 'OK') {
        final route = body['routes'][0];
        final leg = route['legs'][0];
        final durationText = leg['duration']['text'];
        final distanceText = leg['distance']['text'];
        await _speak(
            "Route found. It is $distanceText and will take about $durationText.");
        _showFacilityActionDialog(f, durationText,
            offline: false, directionsBody: body);
      } else {
        await _speak(
            "Could not get driving directions. Showing approximate ETA instead.");
        final meters = _haversine(
            _currentLocation!.latitude, _currentLocation!.longitude, f.lat, f.lng);
        final eta = _approximateEta(meters);
        _showFacilityActionDialog(f, eta, offline: true);
      }
    } catch (e) {
      final meters = _haversine(
          _currentLocation!.latitude, _currentLocation!.longitude, f.lat, f.lng);
      final eta = _approximateEta(meters);
      _showFacilityActionDialog(f, eta, offline: true);
    }
  }

  void _showFacilityActionDialog(Facility f, String eta,
      {bool offline = false, Map<String, dynamic>? directionsBody}) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                if (f.address != null) ...[
                  const SizedBox(height: 6),
                  Text(f.address!)
                ],
                const SizedBox(height: 8),
                Text("ETA: $eta"),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.call),
                      label: const Text("Call"),
                      onPressed: () {
                        Navigator.pop(context);
                        _launchPhone(f.phone ?? '911');
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.directions),
                      label: const Text("Navigate"),
                      onPressed: () {
                        Navigator.pop(context);
                        _openExternalMaps(f);
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text("Share"),
                      onPressed: () {
                        Navigator.pop(context);
                        _shareLocation(f);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _speak(
                          "Ok. I will notify your emergency contact with location and ETA.");
                    },
                    child: const Text("Send to emergency contacts"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _speak("Cannot place a phone call on this device.");
    }
  }

  Future<void> _openExternalMaps(Facility f) async {
    final url = Uri.parse("google.navigation:q=${f.lat},${f.lng}&mode=d");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      final web = Uri.parse(
          "https://www.google.com/maps/dir/?api=1&destination=${f.lat},${f.lng}");
      if (await canLaunchUrl(web)) await launchUrl(web);
    }
  }

  Future<void> _shareLocation(Facility f) async {
    _speak("Location sharing feature not yet implemented.");
  }

  @override
  Widget build(BuildContext context) {
    final initialCamera = CameraPosition(
      target: _currentLocation != null
          ? LatLng(_currentLocation!.latitude, _currentLocation!.longitude)
          : const LatLng(6.5244, 3.3792),
      zoom: 13,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Annie — Emergency Map"),
        backgroundColor: Colors.redAccent,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialCamera,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
            },
            markers: _markers,
            onTap: (_) {
              setState(() {
                _selectedFacility = null;
              });
            },
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_isOnline
                          ? "Online mode — live results"
                          : "Offline mode — cached emergency centers"),
                    ),
                    if (_loading) const SizedBox(width: 12),
                    if (_loading)
                      const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
              ),
            ),
          ),
          if (_selectedFacility != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 120,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedFacility!.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      if (_selectedFacility!.address != null)
                        Text(_selectedFacility!.address!),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.directions),
                            label: const Text("Directions"),
                            onPressed: () =>
                                _getDirectionsAndOpen(_selectedFacility!),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.call),
                            label: const Text("Call"),
                            onPressed: () => _launchPhone(
                                _selectedFacility!.phone ?? '911'),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.share),
                            label: const Text("Share"),
                            onPressed: () =>
                                _shareLocation(_selectedFacility!),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    label: Text(_isListening
                        ? "Listening..."
                        : "Talk to Doctor Annie"),
                    onPressed: _isListening ? _stopListening : _startListening,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _isListening
                            ? Colors.redAccent
                            : Colors.blueAccent),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  heroTag: "refresh",
                  onPressed: () {
                    if (_isOnline) {
                      _fetchNearbyFacilities();
                    } else {
                      _loadOfflineFacilities();
                    }
                  },
                  child: const Icon(Icons.refresh),
                )
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _focusOnNearest();
        },
        child: const Icon(Icons.location_searching),
      ),
    );
  }
}