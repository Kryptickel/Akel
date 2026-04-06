import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'route_navigation_screen.dart';

class RouteNavigationWrapperScreen extends StatelessWidget {
  const RouteNavigationWrapperScreen({super.key});

  @override
  Widget build(BuildContext context) {
// Default destination coordinates (example: a hospital)
    const destination = LatLng(37.7749, -122.4194); // San Francisco coordinates
    const destinationName = 'Nearest Emergency Hospital';

    return const RouteNavigationScreen(
      destination: destination,
      destinationName: destinationName,
    );
  }
}