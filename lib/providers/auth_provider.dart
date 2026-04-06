import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// ==================== AUTH PROVIDER ====================
///
/// AKEL PANIC BUTTON - BUILD 58 - FLUTTER 3.43+ COMPATIBLE
///
/// =====================================================

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // FIXED: Constructor updated to standard initialization for modern SDKs
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email'],
  );

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userProfile;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isAuthenticated => _user != null;

  // FIXED: Constructor placement maintained
  AuthProvider() {
    _auth.authStateChanges().listen((User? user) async {
      debugPrint(' ========== AUTH STATE CHANGED ==========');
      debugPrint(' User: ${user?.email ?? "SIGNED OUT"}');

      _user = user;

      if (user != null) {
        debugPrint(' Loading user profile...');
        await loadUserProfile(user.uid);
      } else {
        _userProfile = null;
        debugPrint(' User profile cleared');
      }

      notifyListeners();
      debugPrint(' ==========================================');
    });
  }

  // ==================== AUTH STATE ====================

  Future<void> checkAuthState() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint(' Checking auth state...');
      _user = _auth.currentUser;

      if (_user != null) {
        debugPrint(' Current user: ${_user!.email}');
        await loadUserProfile(_user!.uid);
      } else {
        debugPrint(' No current user');
      }
    } catch (e) {
      _errorMessage = 'Error checking auth state: ${e.toString()}';
      debugPrint(' Auth check error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserProfile(String userId) async {
    try {
      debugPrint(' ========== LOADING USER PROFILE ==========');
      debugPrint(' User ID: $userId');

      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        _userProfile = doc.data();
        debugPrint(' Profile loaded successfully');
        debugPrint(' Profile data: $_userProfile');
        debugPrint(' Onboarding complete: ${_userProfile?['onboarding_complete']}');
      } else {
        debugPrint(' Profile does not exist, creating...');
        await _createBasicProfile(userId);
      }

      notifyListeners();
      debugPrint(' ===========================================');
    } catch (e) {
      debugPrint(' Error loading profile: $e');
    }
  }

  Future<void> _createBasicProfile(String userId) async {
    try {
      debugPrint(' Creating basic profile for: $userId');

      final userData = {
        'uid': userId,
        'email': _user?.email ?? '',
        'displayName': _user?.displayName ?? '',
        'photoUrl': _user?.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'onboarding_complete': false,
        'accountStatus': 'active',
        'role': 'user',
        'emergencyContactsCount': 0,
        'panicAlertsCount': 0,
        'safeWordEnabled': false,
        'fallDetectionEnabled': false,
        'shakeDetectionEnabled': true,
        'volumeTriggerEnabled': false,
        'powerTriggerEnabled': false,
      };

      await _firestore.collection('users').doc(userId).set(userData);
      _userProfile = userData;

      debugPrint(' Basic profile created');
      debugPrint(' Onboarding complete: false');

      notifyListeners();
    } catch (e) {
      debugPrint(' Error creating profile: $e');
    }
  }

  // ==================== SIGN UP ====================

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint(' ========== SIGNING UP ==========');
      debugPrint(' Email: $email');
      debugPrint(' Name: $name');

      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(name);

        final userData = {
          'uid': user.uid,
          'email': email,
          'displayName': name,
          'phone': phone ?? '',
          'photoUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'onboarding_complete': false,
          'accountStatus': 'active',
          'role': 'user',
          'emergencyContactsCount': 0,
          'panicAlertsCount': 0,
          'safeWordEnabled': false,
          'fallDetectionEnabled': false,
          'shakeDetectionEnabled': true,
          'volumeTriggerEnabled': false,
          'powerTriggerEnabled': false,
        };

        await _firestore.collection('users').doc(user.uid).set(userData);

        _user = user;
        await loadUserProfile(user.uid);

        _isLoading = false;
        notifyListeners();

        debugPrint(' User created: ${user.email}');
        debugPrint(' Onboarding complete: false');
        debugPrint(' ==================================');

        return {'success': true, 'message': 'Account created successfully'};
      }

      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Failed to create account'};
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      final String message = _handleAuthError(e);
      _errorMessage = message;
      notifyListeners();

      debugPrint(' Signup error: ${e.code}');
      return {'success': false, 'message': message};
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();

      debugPrint(' Signup error: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  // ==================== SIGN IN ====================

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint(' ========== SIGNING IN ==========');
      debugPrint(' Email: $email');

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });

        _user = user;
        await loadUserProfile(user.uid);

        _isLoading = false;
        notifyListeners();

        debugPrint(' User signed in: ${user.email}');
        debugPrint(' Onboarding complete: ${_userProfile?['onboarding_complete']}');
        debugPrint(' ==================================');

        return {'success': true, 'message': 'Signed in successfully'};
      }

      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Failed to sign in'};
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      final String message = _handleAuthError(e);
      _errorMessage = message;
      notifyListeners();

      debugPrint(' Signin error: ${e.code}');
      return {'success': false, 'message': message};
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();

      debugPrint(' Signin error: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  // ==================== GOOGLE SIGN-IN ====================

  Future<Map<String, dynamic>> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint(' ========== GOOGLE SIGN-IN ==========');

      // Trigger flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        debugPrint(' Google sign-in cancelled by user');
        return {'success': false, 'message': 'Sign in cancelled'};
      }

      debugPrint(' Google user: ${googleUser.email}');

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential (AccessToken and IdToken)
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint(' Credential created successfully');

      // Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user != null) {
        debugPrint(' Firebase user: ${user.email}');

        final doc = await _firestore.collection('users').doc(user.uid).get();

        if (!doc.exists) {
          debugPrint(' Creating new Google user profile...');

          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email ?? '',
            'displayName': user.displayName ?? '',
            'photoUrl': user.photoURL ?? '',
            'phone': user.phoneNumber ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'onboarding_complete': false,
            'accountStatus': 'active',
            'role': 'user',
            'emergencyContactsCount': 0,
            'panicAlertsCount': 0,
            'safeWordEnabled': false,
            'fallDetectionEnabled': false,
            'shakeDetectionEnabled': true,
            'volumeTriggerEnabled': false,
            'powerTriggerEnabled': false,
          });

          debugPrint(' Google user profile created');
        } else {
          debugPrint(' Updating existing Google user...');

          await _firestore.collection('users').doc(user.uid).update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }

        _user = user;
        await loadUserProfile(user.uid);

        _isLoading = false;
        notifyListeners();

        debugPrint(' Google sign-in successful: ${user.email}');
        debugPrint(' Onboarding complete: ${_userProfile?['onboarding_complete']}');
        debugPrint(' =====================================');

        return {'success': true, 'message': 'Signed in with Google successfully'};
      }

      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Failed to sign in with Google'};
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Google sign-in error: ${e.toString()}';
      notifyListeners();

      debugPrint(' Google signin error: $e');
      return {'success': false, 'message': 'Google sign-in failed: ${e.toString()}'};
    }
  }

  // ==================== SIGN OUT ====================

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint(' ========== SIGNING OUT ==========');

      // FIXED: Correct check for modern google_sign_in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
        debugPrint(' Google sign-out successful');
      }

      await _auth.signOut();

      _user = null;
      _userProfile = null;
      _errorMessage = null;

      _isLoading = false;
      notifyListeners();

      debugPrint(' User signed out');
      debugPrint(' ==================================');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint(' Signout error: $e');
    }
  }

  // ==================== PASSWORD RESET ====================

  Future<Map<String, dynamic>> resetPassword({required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint(' Sending password reset email to: $email');

      await _auth.sendPasswordResetEmail(email: email);

      _isLoading = false;
      notifyListeners();

      debugPrint(' Password reset email sent to: $email');
      return {'success': true, 'message': 'Password reset email sent'};
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      final String message = _handleAuthError(e);
      _errorMessage = message;
      notifyListeners();

      debugPrint(' Reset password error: ${e.code}');
      return {'success': false, 'message': message};
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();

      debugPrint(' Reset password error: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  // ==================== PROFILE MANAGEMENT ====================

  Future<void> updateUserProfile({
    String? userId,
    String? name,
    String? phone,
    String? address,
    Map<String, dynamic>? medicalInfo,
    String? emergencyMessage,
  }) async {
    try {
      final uid = userId ?? _user?.uid;
      if (uid == null) return;

      debugPrint(' Updating user profile...');

      final updates = <String, dynamic>{};
      if (name != null) updates['displayName'] = name;
      if (phone != null) updates['phone'] = phone;
      if (address != null) updates['address'] = address;
      if (medicalInfo != null) updates['medicalInfo'] = medicalInfo;
      if (emergencyMessage != null) updates['emergencyMessage'] = emergencyMessage;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);

        if (name != null && _user != null) {
          await _user!.updateDisplayName(name);
        }

        await loadUserProfile(uid);
        debugPrint(' Profile updated');
      }
    } catch (e) {
      debugPrint(' Error updating profile: $e');
    }
  }

  Future<void> updateOnboardingComplete(String userId, bool completed) async {
    try {
      debugPrint(' ========== UPDATING ONBOARDING STATUS ==========');
      debugPrint(' User ID: $userId');
      debugPrint(' Completed: $completed');

      await _firestore.collection('users').doc(userId).update({
        'onboarding_complete': completed,
        'onboarding_completed_at': completed ? FieldValue.serverTimestamp() : null,
      });

      await loadUserProfile(userId);

      debugPrint(' Onboarding status updated successfully');
      debugPrint(' New status: ${_userProfile?['onboarding_complete']}');
      debugPrint(' ================================================');
    } catch (e) {
      debugPrint(' Error updating onboarding: $e');
      rethrow;
    }
  }

  bool isOnboardingComplete() {
    final status = _userProfile?['onboarding_complete'] ?? false;
    debugPrint(' Checking onboarding status: $status');
    return status;
  }

  Future<void> incrementPanicAlertsCount() async {
    try {
      if (_user == null) return;

      await _firestore.collection('users').doc(_user!.uid).update({
        'panicAlertsCount': FieldValue.increment(1),
      });

      await loadUserProfile(_user!.uid);
      debugPrint(' Panic alerts count incremented');
    } catch (e) {
      debugPrint(' Error incrementing panic alerts: $e');
    }
  }

  Future<void> updateEmergencyContactsCount(int count) async {
    try {
      if (_user == null) return;

      await _firestore.collection('users').doc(_user!.uid).update({
        'emergencyContactsCount': count,
      });

      await loadUserProfile(_user!.uid);
      debugPrint(' Emergency contacts count updated: $count');
    } catch (e) {
      debugPrint(' Error updating contacts count: $e');
    }
  }

  // ==================== UTILITIES ====================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'invalid-email':
        return 'The email address is invalid';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      case 'requires-recent-login':
        return 'Please sign in again to perform this action';
      default:
        return 'Authentication error: ${e.message ?? e.code}';
    }
  }
}