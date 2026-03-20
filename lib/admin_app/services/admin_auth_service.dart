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
  String? _lastErrorMessage;

  bool get isAuthenticated => _isAuthenticated;
  User? get firebaseUser => _firebaseUser;
  String get adminUsername => _adminUsername;
  String? get lastErrorMessage => _lastErrorMessage;

  /// Initialize and check for existing session
  Future<void> initialize() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    final email = currentUser.email?.trim().toLowerCase();
    if (email == AdminConfig.adminEmail.toLowerCase()) {
      _firebaseUser = currentUser;
      _isAuthenticated = true;
      _adminUsername = AdminConfig.adminUsername;
      notifyListeners();
      return;
    }

    await FirebaseAuth.instance.signOut();
  }

  /// Login with UI credentials and the Firebase admin account.
  Future<bool> login(String username, String password) async {
    _lastErrorMessage = null;
    debugPrint('AdminAuthService.hashCode: ${hashCode}');
    debugPrint(
      'Admin login attempt: username="$username", password="${password.isNotEmpty ? "***" : "empty"}"',
    );

    if (username != AdminConfig.adminUsername ||
        password != AdminConfig.adminPassword) {
      _lastErrorMessage = 'Invalid username or password';
      debugPrint('Admin login FAILED: invalid UI credentials');
      return false;
    }

    try {
      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.signOut();
      }

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: AdminConfig.adminEmail,
        password: AdminConfig.adminFirebasePassword,
      );

      _firebaseUser = credential.user;
      _isAuthenticated = true;
      _adminUsername = username;

      debugPrint('Admin login SUCCESS - Firebase admin session established');
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (error) {
      _isAuthenticated = false;
      _firebaseUser = null;
      _adminUsername = '';
      _lastErrorMessage = switch (error.code) {
        'user-not-found' => 'Admin Firebase account is not set up.',
        'wrong-password' ||
        'invalid-credential' => 'Admin Firebase credentials are invalid.',
        _ => 'Admin backend sign-in failed: ${error.message ?? error.code}',
      };
      debugPrint('Firebase admin sign-in failed: $error');
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _isAuthenticated = false;
    _adminUsername = '';
    _lastErrorMessage = null;

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
