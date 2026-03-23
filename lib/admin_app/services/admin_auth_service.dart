import 'dart:async';

import 'package:flutter/material.dart';

import '../admin_config.dart';

/// Admin authentication service
/// Handles hardcoded local admin login.
class AdminAuthService extends ChangeNotifier {
  static final AdminAuthService _instance = AdminAuthService._internal();
  factory AdminAuthService() => _instance;
  AdminAuthService._internal();

  bool _isAuthenticated = false;
  String _adminUsername = '';
  String? _lastErrorMessage;

  bool get isAuthenticated => _isAuthenticated;
  String get adminUsername => _adminUsername;
  String? get lastErrorMessage => _lastErrorMessage;

  /// Initialize local auth state.
  Future<void> initialize() async {
    _lastErrorMessage = null;
  }

  /// Login using hardcoded admin credentials.
  Future<bool> login(String username, String password) async {
    _lastErrorMessage = null;
    debugPrint('AdminAuthService.hashCode: ${hashCode}');
    debugPrint(
      'Admin login attempt: username="$username", password="${password.isNotEmpty ? "***" : "empty"}"',
    );

    if (username != AdminConfig.adminUsername ||
        password != AdminConfig.adminPassword) {
      _isAuthenticated = false;
      _adminUsername = '';
      _lastErrorMessage = 'Invalid username or password';
      debugPrint('Admin login FAILED: invalid UI credentials');
      notifyListeners();
      return false;
    }

    _isAuthenticated = true;
    _adminUsername = username;

    debugPrint('Admin login SUCCESS - hardcoded credentials accepted');
    notifyListeners();
    return true;
  }

  /// Logout
  Future<void> logout() async {
    _isAuthenticated = false;
    _adminUsername = '';
    _lastErrorMessage = null;

    notifyListeners();
  }

  /// Require authentication - use as guard
  bool requireAuth() {
    return _isAuthenticated;
  }
}
