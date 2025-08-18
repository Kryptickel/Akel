class UserProfile {
  final String id;
  final String name;
  final int age;
  final String sex;
  final String address;
  final String? profilePictureUrl;
  final List<String> emergencyContacts;
  final List<String> linkedDevices;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  
  // Medical information
  final String? bloodType;
  final List<String> allergies;
  final List<String> medications;
  final String? medicalConditions;
  final String? emergencyMedicalInfo;

  const UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.sex,
    required this.address,
    this.profilePictureUrl,
    this.emergencyContacts = const [],
    this.linkedDevices = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.bloodType,
    this.allergies = const [],
    this.medications = const [],
    this.medicalConditions,
    this.emergencyMedicalInfo,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    int? age,
    String? sex,
    String? address,
    String? profilePictureUrl,
    List<String>? emergencyContacts,
    List<String>? linkedDevices,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? bloodType,
    List<String>? allergies,
    List<String>? medications,
    String? medicalConditions,
    String? emergencyMedicalInfo,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      address: address ?? this.address,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      linkedDevices: linkedDevices ?? this.linkedDevices,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      emergencyMedicalInfo: emergencyMedicalInfo ?? this.emergencyMedicalInfo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'sex': sex,
      'address': address,
      'profilePictureUrl': profilePictureUrl,
      'emergencyContacts': emergencyContacts,
      'linkedDevices': linkedDevices,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'bloodType': bloodType,
      'allergies': allergies,
      'medications': medications,
      'medicalConditions': medicalConditions,
      'emergencyMedicalInfo': emergencyMedicalInfo,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      sex: json['sex'] as String,
      address: json['address'] as String,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      emergencyContacts: List<String>.from(json['emergencyContacts'] ?? []),
      linkedDevices: List<String>.from(json['linkedDevices'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      bloodType: json['bloodType'] as String?,
      allergies: List<String>.from(json['allergies'] ?? []),
      medications: List<String>.from(json['medications'] ?? []),
      medicalConditions: json['medicalConditions'] as String?,
      emergencyMedicalInfo: json['emergencyMedicalInfo'] as String?,
    );
  }
}