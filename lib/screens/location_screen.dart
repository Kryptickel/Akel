import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  // Choose any starting point (this example is Lagos)
  static const LatLng _startPoint = LatLng(6.5244, 3.3792);

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: _startPoint,
    zoom: 14,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Location Map'),
        centerTitle: true,
      ),
      body: const GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        mapType: MapType.normal,
        myLocationEnabled: false, // we’ll enable this later
        myLocationButtonEnabled: false, // we’ll enable this later
      ),
    );
  }
}