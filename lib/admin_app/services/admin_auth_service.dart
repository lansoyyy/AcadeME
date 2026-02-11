import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin_config.dart';

/// Admin authentication service
/// Handles hardcoded UI login + optional Firebase Auth
class AdminAuthService extends ChangeNotifier {
  static final AdminAuthService _instance = AdminAuthService._internal();
  factory AdminAuthService() => _instance;
  AdminAuthService._internal();

  bool _isAuthenticated = false;
  User? _firebaseUser;
  String _adminUsername = '';

  bool get isAuthenticated => _isAuthenticated;
  User? get firebaseUser => _firebaseUser;
  String get adminUsername => _adminUsername;

  /// Initialize and check for existing session
  Future<void> initialize() async {
    // In-memory session only (no persistence without shared_preferences)
    // Can be enhanced later if needed
  }

  /// Login with hardcoded credentials and sign into Firebase Auth
  /// Returns true if successful
  Future<bool> login(String username, String password) async {
    // Validate against hardcoded credentials
    if (username == AdminConfig.adminUsername &&
        password == AdminConfig.adminPassword) {
      _isAuthenticated = true;
      _adminUsername = username;

      // Also sign into Firebase Auth for Firestore permissions
      try {
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: AdminConfig.adminEmail,
              password: AdminConfig.adminFirebasePassword,
            );
        _firebaseUser = credential.user;
      } catch (e) {
        debugPrint('Admin Firebase sign-in failed: $e');
        // Still allow UI login even if Firebase fails - will show error in UI
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  /// Optional: Sign into Firebase Auth as admin
  /// This enables privileged Firestore access
  Future<bool> signInToFirebase() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: AdminConfig.adminEmail,
        password: AdminConfig.adminFirebasePassword,
      );
      _firebaseUser = credential.user;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Firebase admin sign-in failed: $e');
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _isAuthenticated = false;
    _adminUsername = '';

    // Sign out from Firebase
    if (_firebaseUser != null) {
      await FirebaseAuth.instance.signOut();
      _firebaseUser = null;
    }

    notifyListeners();
  }

  /// Require authentication - use as guard
  bool requireAuth() {
    return _isAuthenticated;
  }
}
