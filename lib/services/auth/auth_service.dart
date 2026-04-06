import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

// Sign in with email and password
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting sign in...');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Sign in successful! UID: ${userCredential.user?.uid}');

      return userCredential;
    } catch (e) {
      print('Sign in error: $e');
      throw Exception('Login failed: $e');
    }
  }

// Sign up with email and password - AUTH ONLY
  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      print('========================================');
      print('STEP 1: Creating Firebase Auth account ONLY');
      print('Email: $email');
      print('========================================');

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('SUCCESS! Auth account created!');
      print('UID: ${userCredential.user?.uid}');
      print('Email: ${userCredential.user?.email}');
      print('========================================');

      return userCredential;
    } catch (e) {
      print('Registration error: $e');
      throw Exception('Registration failed: $e');
    }
  }

// Create user profile in Firestore - SEPARATE FROM AUTH
  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
    String? phone,
  }) async {
    try {
      print('========================================');
      print('STEP 2: Creating Firestore user profile');
      print('UID: $uid');
      print('Waiting 2 seconds for auth to settle...');
      print('========================================');

// Wait for auth to fully propagate
      await Future.delayed(Duration(seconds: 2));

      final userData = {
        'id': uid,
        'name': name,
        'email': email,
        'phone': phone ?? '',
        'createdAt': DateTime.now().toIso8601String(),
        'lastLoginAt': DateTime.now().toIso8601String(),
      };

      print('Data to save:');
      print(userData);
      print('Saving to path: users/$uid');

      await _firestore
          .collection('users')
          .doc(uid)
          .set(userData);

      print('========================================');
      print('SUCCESS! Firestore profile created!');
      print('========================================');
    } catch (e) {
      print('========================================');
      print('ERROR creating Firestore profile: $e');
      print('========================================');
      throw Exception('Failed to create profile: $e');
    }
  }

// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      print('Getting user profile for UID: $uid');

      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        print('User profile found!');
        return doc.data();
      } else {
        print('WARNING: User profile does not exist yet');
        return null;
      }
    } catch (e) {
      print('Error getting user profile: $e');
      throw Exception('Failed to get user profile: $e');
    }
  }

// Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
  }) async {
    try {
      print('Updating user profile for UID: $uid');

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);
        print('Profile updated successfully!');
      }
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

// Reset password
  Future<void> resetPassword(String email) async {
    try {
      print('Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent!');
    } catch (e) {
      print('Error sending reset email: $e');
      throw Exception('Failed to send reset email: $e');
    }
  }

// Sign out
  Future<void> signOut() async {
    try {
      print('Signing out...');
      await _auth.signOut();
      print('Signed out successfully!');
    } catch (e) {
      print('Error signing out: $e');
      throw Exception('Sign out failed: $e');
    }
  }
}