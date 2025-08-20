class UserProfile {
  final String name;
  final int age;
  final String sex;
  final String address;
  final String? profilePicturePath;
  final String emergencyMessage;
  final List<String> emergencyContacts;

  UserProfile({
    required this.name,
    required this.age,
    required this.sex,
    required this.address,
    this.profilePicturePath,
    this.emergencyMessage = "Emergency! I need immediate assistance. Please send help to my location.",
    this.emergencyContacts = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'sex': sex,
      'address': address,
      'profilePicturePath': profilePicturePath,
      'emergencyMessage': emergencyMessage,
      'emergencyContacts': emergencyContacts,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      sex: json['sex'] ?? '',
      address: json['address'] ?? '',
      profilePicturePath: json['profilePicturePath'],
      emergencyMessage: json['emergencyMessage'] ?? "Emergency! I need immediate assistance. Please send help to my location.",
      emergencyContacts: List<String>.from(json['emergencyContacts'] ?? []),
    );
  }

  UserProfile copyWith({
    String? name,
    int? age,
    String? sex,
    String? address,
    String? profilePicturePath,
    String? emergencyMessage,
    List<String>? emergencyContacts,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      address: address ?? this.address,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      emergencyMessage: emergencyMessage ?? this.emergencyMessage,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }
}