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

  /// Login with hardcoded credentials only (no Firebase Auth required)
  /// Returns true if successful
  Future<bool> login(String username, String password) async {
    debugPrint('AdminAuthService.hashCode: ${hashCode}');
    debugPrint(
      'Admin login attempt: username="$username", password="${password.isNotEmpty ? "***" : "empty"}"',
    );

    // Hardcoded admin check - no Firebase Auth needed
    if (username == 'admin' && password == 'academe_admin_2026') {
      _isAuthenticated = true;
      _adminUsername = username;
      debugPrint('Admin login SUCCESS - isAuthenticated: $_isAuthenticated');
      debugPrint('Admin login SUCCESS - Calling notifyListeners()');
      notifyListeners();
      debugPrint(
        'Admin login SUCCESS - notifyListeners() called, listener count: ${hasListeners ? "has listeners" : "NO LISTENERS!"}',
      );
      return true;
    }
    debugPrint('Admin login FAILED: invalid credentials');
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
