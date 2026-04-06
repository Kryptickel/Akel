import 'package:flutter_test/flutter_test.dart';
import 'package:akel/models/user_profile.dart'; // ✅ FIX: Changed from akel_panic_button to akel

void main() {
  group('UserProfile Tests', () {
    test('UserProfile creation and serialization', () {
// Test user profile creation with current structure
      final profile = UserProfile(
        id: 'user123',
        name: 'John Doe',
        email: 'john.doe@example.com',
        phone: '1234567890',
        createdAt: DateTime(2024, 1, 1),
        lastLoginAt: DateTime(2024, 1, 15),
      );

// Test properties
      expect(profile.id, 'user123');
      expect(profile.name, 'John Doe');
      expect(profile.email, 'john.doe@example.com');
      expect(profile.phone, '1234567890');
      expect(profile.createdAt, DateTime(2024, 1, 1));
      expect(profile.lastLoginAt, DateTime(2024, 1, 15));

// Test JSON serialization (toJson)
      final json = profile.toJson();
      expect(json['id'], 'user123');
      expect(json['name'], 'John Doe');
      expect(json['email'], 'john.doe@example.com');
      expect(json['phone'], '1234567890');

// Test JSON deserialization (fromJson)
      final profileFromJson = UserProfile.fromJson(json);
      expect(profileFromJson.id, profile.id);
      expect(profileFromJson.name, profile.name);
      expect(profileFromJson.email, profile.email);
      expect(profileFromJson.phone, profile.phone);
    });

    test('UserProfile fromMap and toMap', () {
// Test using fromMap (original method)
      final map = {
        'id': 'user456',
        'name': 'Jane Smith',
        'email': 'jane.smith@example.com',
        'phone': '0987654321',
        'createdAt': '2024-02-01T10:00:00.000Z',
        'lastLoginAt': '2024-02-15T15:30:00.000Z',
      };

      final profile = UserProfile.fromMap(map);
      expect(profile.id, 'user456');
      expect(profile.name, 'Jane Smith');
      expect(profile.email, 'jane.smith@example.com');
      expect(profile.phone, '0987654321');

// Test toMap
      final mapFromProfile = profile.toMap();
      expect(mapFromProfile['id'], 'user456');
      expect(mapFromProfile['name'], 'Jane Smith');
      expect(mapFromProfile['email'], 'jane.smith@example.com');
    });

    test('UserProfile copyWith functionality', () {
      final originalProfile = UserProfile(
        id: 'user789',
        name: 'Jane Doe',
        email: 'jane.doe@example.com',
        phone: '5551234567',
        createdAt: DateTime(2024, 3, 1),
        lastLoginAt: DateTime(2024, 3, 10),
      );

      final updatedProfile = originalProfile.copyWith(
        name: 'Jane Smith',
        phone: '5559876543',
      );

      expect(updatedProfile.id, 'user789'); // Unchanged
      expect(updatedProfile.name, 'Jane Smith'); // Changed
      expect(updatedProfile.email, 'jane.doe@example.com'); // Unchanged
      expect(updatedProfile.phone, '5559876543'); // Changed
      expect(updatedProfile.createdAt, originalProfile.createdAt); // Unchanged
    });

    test('UserProfile with null phone', () {
      final profile = UserProfile(
        id: 'user999',
        name: 'Test User',
        email: 'test@example.com',
        phone: null, // Optional field
        createdAt: DateTime(2024, 4, 1),
        lastLoginAt: DateTime(2024, 4, 1),
      );

      expect(profile.phone, isNull);
      expect(profile.name, 'Test User');
      expect(profile.email, 'test@example.com');
    });

    test('UserProfile default createdAt and lastLoginAt', () {
      final now = DateTime.now();

// Test that fromMap handles missing dates
      final map = {
        'id': 'user111',
        'name': 'Default User',
        'email': 'default@example.com',
// createdAt and lastLoginAt not provided
      };

      final profile = UserProfile.fromMap(map);

      expect(profile.createdAt.year, now.year);
      expect(profile.createdAt.month, now.month);
      expect(profile.createdAt.day, now.day);
      expect(profile.lastLoginAt.year, now.year);
      expect(profile.lastLoginAt.month, now.month);
      expect(profile.lastLoginAt.day, now.day);
    });

    test('UserProfile toString', () {
      final profile = UserProfile(
        id: 'user222',
        name: 'String Test',
        email: 'string@test.com',
        createdAt: DateTime(2024, 5, 1),
        lastLoginAt: DateTime(2024, 5, 1),
      );

      final str = profile.toString();
      expect(str, contains('user222'));
      expect(str, contains('String Test'));
      expect(str, contains('string@test.com'));
    });

    test('UserProfile equality', () {
      final profile1 = UserProfile(
        id: 'user333',
        name: 'Equal Test',
        email: 'equal@test.com',
        createdAt: DateTime(2024, 6, 1),
        lastLoginAt: DateTime(2024, 6, 1),
      );

      final profile2 = UserProfile(
        id: 'user333', // Same ID
        name: 'Different Name',
        email: 'different@email.com',
        createdAt: DateTime(2024, 7, 1),
        lastLoginAt: DateTime(2024, 7, 1),
      );

      final profile3 = UserProfile(
        id: 'user444', // Different ID
        name: 'Equal Test',
        email: 'equal@test.com',
        createdAt: DateTime(2024, 6, 1),
        lastLoginAt: DateTime(2024, 6, 1),
      );

// Same ID = equal
      expect(profile1, equals(profile2));
      expect(profile1.hashCode, equals(profile2.hashCode));

// Different ID = not equal
      expect(profile1, isNot(equals(profile3)));
    });
  });
}