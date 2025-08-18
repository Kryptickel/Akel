import 'package:flutter_test/flutter_test.dart';
import 'package:akel_panic_button/models/user_profile.dart';

void main() {
  group('UserProfile Tests', () {
    test('UserProfile creation and JSON serialization', () {
      // Test user profile creation
      final profile = UserProfile(
        name: 'John Doe',
        age: 30,
        sex: 'Male',
        address: '123 Main Street, City, State',
        profilePicturePath: '/path/to/image.jpg',
        emergencyMessage: 'Help! Emergency situation!',
        emergencyContacts: ['1234567890', '0987654321'],
      );

      // Test properties
      expect(profile.name, 'John Doe');
      expect(profile.age, 30);
      expect(profile.sex, 'Male');
      expect(profile.address, '123 Main Street, City, State');
      expect(profile.profilePicturePath, '/path/to/image.jpg');
      expect(profile.emergencyMessage, 'Help! Emergency situation!');
      expect(profile.emergencyContacts.length, 2);

      // Test JSON serialization
      final json = profile.toJson();
      expect(json['name'], 'John Doe');
      expect(json['age'], 30);
      expect(json['sex'], 'Male');

      // Test JSON deserialization
      final profileFromJson = UserProfile.fromJson(json);
      expect(profileFromJson.name, profile.name);
      expect(profileFromJson.age, profile.age);
      expect(profileFromJson.sex, profile.sex);
      expect(profileFromJson.address, profile.address);
    });

    test('UserProfile copyWith functionality', () {
      final originalProfile = UserProfile(
        name: 'Jane Doe',
        age: 25,
        sex: 'Female',
        address: '456 Oak Avenue',
      );

      final updatedProfile = originalProfile.copyWith(
        name: 'Jane Smith',
        age: 26,
      );

      expect(updatedProfile.name, 'Jane Smith');
      expect(updatedProfile.age, 26);
      expect(updatedProfile.sex, 'Female'); // Unchanged
      expect(updatedProfile.address, '456 Oak Avenue'); // Unchanged
    });

    test('UserProfile default values', () {
      final profile = UserProfile(
        name: 'Test User',
        age: 20,
        sex: 'Other',
        address: 'Test Address',
      );

      expect(profile.emergencyMessage, 
          'Emergency! I need immediate assistance. Please send help to my location.');
      expect(profile.emergencyContacts, isEmpty);
      expect(profile.profilePicturePath, isNull);
    });
  });
}