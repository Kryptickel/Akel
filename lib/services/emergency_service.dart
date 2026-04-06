import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'user_service.dart';

class EmergencyService {
  final UserService _userService = UserService();

  Future<bool> triggerEmergency() async {
    try {
      // Get current location
      final position = await _getCurrentLocation();
      
      // Get user profile and emergency message
      final profile = await _userService.getUserProfile();
      final emergencyMessage = await _userService.getEmergencyMessage();
      final emergencyContacts = await _userService.getEmergencyContacts();

      // Create emergency message with location
      final locationMessage = _createLocationMessage(position, emergencyMessage);

      // Send alerts to emergency contacts
      for (final contact in emergencyContacts) {
        await _sendSMSAlert(contact, locationMessage);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  String _createLocationMessage(Position? position, String baseMessage) {
    if (position == null) {
      return '$baseMessage\n\nLocation: Unable to determine current location.';
    }

    final googleMapsUrl = 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
    
    return '''$baseMessage

📍 LOCATION:
Latitude: ${position.latitude.toStringAsFixed(6)}
Longitude: ${position.longitude.toStringAsFixed(6)}
Accuracy: ${position.accuracy.toStringAsFixed(1)}m

🗺️ View on Map: $googleMapsUrl

⏰ Time: ${DateTime.now().toLocal().toString()}''';
  }

  Future<bool> _sendSMSAlert(String phoneNumber, String message) async {
    try {
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateLocation() async {
    try {
      final position = await _getCurrentLocation();
      if (position != null) {
        // In a real app, this would update the backend with current location
        // For now, we'll just return success
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Position?> getCurrentPosition() async {
    return await _getCurrentLocation();
  }

  Future<bool> requestLocationPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      return permission == LocationPermission.whileInUse ||
             permission == LocationPermission.always;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  String formatLocationForSharing(Position position) {
    return 'Latitude: ${position.latitude.toStringAsFixed(6)}, '
           'Longitude: ${position.longitude.toStringAsFixed(6)}';
  }

  String getGoogleMapsUrl(Position position) {
    return 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
  }
}