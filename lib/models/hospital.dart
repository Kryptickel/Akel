enum FacilityType {
  hospital,
  urgentCare,
  pharmacy,
  clinic,
  emergencyRoom,
}

enum Specialty {
  emergency,
  cardiology,
  pediatrics,
  orthopedics,
  neurology,
  generalPractice,
  pharmacy,
  urgentCare,
}

class Hospital {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String phoneNumber;
  final FacilityType type;
  final List<Specialty> specialties;
  final double rating;
  final int reviewCount;
  final int estimatedWaitTime; // in minutes
  final bool isOpen24Hours;
  final String? operatingHours;
  final double distance; // in miles
  final bool hasEmergencyRoom;
  final bool acceptsWalkIns;
  final String? website;

  Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    required this.type,
    this.specialties = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.estimatedWaitTime = 0,
    this.isOpen24Hours = false,
    this.operatingHours,
    this.distance = 0.0,
    this.hasEmergencyRoom = false,
    this.acceptsWalkIns = true,
    this.website,
  });

  String get typeLabel {
    switch (type) {
      case FacilityType.hospital:
        return 'Hospital';
      case FacilityType.urgentCare:
        return 'Urgent Care';
      case FacilityType.pharmacy:
        return 'Pharmacy';
      case FacilityType.clinic:
        return 'Clinic';
      case FacilityType.emergencyRoom:
        return 'Emergency Room';
    }
  }

  String get typeEmoji {
    switch (type) {
      case FacilityType.hospital:
        return ' ';
      case FacilityType.urgentCare:
        return ' ';
      case FacilityType.pharmacy:
        return ' ';
      case FacilityType.clinic:
        return ' ';
      case FacilityType.emergencyRoom:
        return ' ';
    }
  }

  String get waitTimeLabel {
    if (estimatedWaitTime == 0) return 'No wait time data';
    if (estimatedWaitTime < 15) return ' Short wait (~$estimatedWaitTime min)';
    if (estimatedWaitTime < 45) return ' Moderate wait (~$estimatedWaitTime min)';
    return ' Long wait (~$estimatedWaitTime min)';
  }

  String get distanceLabel {
    if (distance < 1) {
      return '${(distance * 5280).toStringAsFixed(0)} ft away';
    }
    return '${distance.toStringAsFixed(1)} miles away';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'type': type.toString(),
      'specialties': specialties.map((s) => s.toString()).toList(),
      'rating': rating,
      'reviewCount': reviewCount,
      'estimatedWaitTime': estimatedWaitTime,
      'isOpen24Hours': isOpen24Hours,
      'operatingHours': operatingHours,
      'distance': distance,
      'hasEmergencyRoom': hasEmergencyRoom,
      'acceptsWalkIns': acceptsWalkIns,
      'website': website,
    };
  }
}