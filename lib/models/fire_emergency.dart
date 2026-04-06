class FireEmergency {
  final String id;
  final String userId;
  final String userName;
  final double? latitude;
  final double? longitude;
  final String address;
  final String fireType;
  final String severity;
  final String buildingInfo;
  final String floorNumber;
  final String unitNumber;
  final List<String> photos;
  final String description;
  final DateTime timestamp;
  final String status; // pending, dispatched, responded, resolved

  FireEmergency({
    required this.id,
    required this.userId,
    required this.userName,
    this.latitude,
    this.longitude,
    this.address = '',
    this.fireType = 'unknown',
    this.severity = 'unknown',
    this.buildingInfo = '',
    this.floorNumber = '',
    this.unitNumber = '',
    this.photos = const [],
    this.description = '',
    required this.timestamp,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'fireType': fireType,
      'severity': severity,
      'buildingInfo': buildingInfo,
      'floorNumber': floorNumber,
      'unitNumber': unitNumber,
      'photos': photos,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }

  factory FireEmergency.fromMap(Map<String, dynamic> map) {
    return FireEmergency(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      latitude: map['latitude'],
      longitude: map['longitude'],
      address: map['address'] ?? '',
      fireType: map['fireType'] ?? 'unknown',
      severity: map['severity'] ?? 'unknown',
      buildingInfo: map['buildingInfo'] ?? '',
      floorNumber: map['floorNumber'] ?? '',
      unitNumber: map['unitNumber'] ?? '',
      photos: List<String>.from(map['photos'] ?? []),
      description: map['description'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      status: map['status'] ?? 'pending',
    );
  }
}