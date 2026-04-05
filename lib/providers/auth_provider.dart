import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user/user_profile.dart';
import '../services/auth/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _userProfile != null;

  AuthProvider() {
    _initializeAuth();
  }

// Initialize auth state
  Future<void> _initializeAuth() async {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        _userProfile = await _authService.getUserProfile(user.uid);
        notifyListeners();
      } else {
        _userProfile = null;
        notifyListeners();
      }
    });
  }

// Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      _userProfile = await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      _setLoading(false);
      return _userProfile != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

// Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      _userProfile = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );

      _setLoading(false);
      return _userProfile != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

// Update profile
  Future<bool> updateProfile(UserProfile profile) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.updateUserProfile(profile);
      _userProfile = profile;

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

// Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _userProfile = null;
    notifyListeners();
  }

// Send password reset
  Future<bool> sendPasswordReset(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.sendPasswordResetEmail(email);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}