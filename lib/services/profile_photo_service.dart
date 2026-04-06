import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePhotoService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }

  /// Upload image to Firebase Storage and return download URL
  Future<String?> uploadProfilePhoto(XFile imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Create unique filename
      final fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('profile_photos').child(fileName);

      // Upload file logic
      if (kIsWeb) {
        // Web upload using bytes
        final bytes = await imageFile.readAsBytes();
        await ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        // Mobile upload using File path
        await ref.putFile(File(imageFile.path));
      }

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();

      // Update user profile in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': downloadUrl,
        'photoUpdatedAt': FieldValue.serverTimestamp(),
      });

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      return null;
    }
  }

  /// Delete profile photo from storage and firestore
  Future<bool> deleteProfilePhoto() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Get current photo URL
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final photoUrl = doc.data()?['photoUrl'] as String?;

      if (photoUrl != null && photoUrl.isNotEmpty) {
        // Delete from Storage
        try {
          final ref = _storage.refFromURL(photoUrl);
          await ref.delete();
        } catch (e) {
          debugPrint('Error deleting file from storage (might already be gone): $e');
        }

        // Remove field from Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'photoUrl': FieldValue.delete(),
          'photoDeletedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      return false;
    }
  }

  /// Get current profile photo URL from Firestore
  Future<String?> getCurrentPhotoUrl() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['photoUrl'] as String?;
    } catch (e) {
      debugPrint('Error getting photo URL: $e');
      return null;
    }
  }
}

// Helper for debugging (optional replacement for print)
void debugPrint(String message) {
  if (kDebugMode) {
    print(message);
  }
}