import 'package:flutter/material.dart';
import 'services/admin_auth_service.dart';
import 'screens/admin_login_screen.dart';
import 'widgets/admin_shell.dart';

/// Root widget for the Admin App
class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  final AdminAuthService _authService = AdminAuthService();

  @override
  void initState() {
    super.initState();
    debugPrint(
      'AdminApp.initState() - AdminAuthService hashCode: ${_authService.hashCode}',
    );
    debugPrint('AdminApp.initState() - Adding listener to AdminAuthService');
    _authService.addListener(_onAuthChanged);
    debugPrint(
      'AdminApp.initState() - Listener added, hasListeners: ${_authService.hasListeners}',
    );
  }

  @override
  void dispose() {
    debugPrint('AdminApp.dispose() - Removing listener');
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    debugPrint(
      'AdminApp._onAuthChanged() called - isAuthenticated: ${_authService.isAuthenticated}',
    );
    if (mounted) {
      debugPrint('AdminApp._onAuthChanged() - calling setState()');
      setState(() {});
    } else {
      debugPrint('AdminApp._onAuthChanged() - widget not mounted!');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'AdminApp.build() called - isAuthenticated: ${_authService.isAuthenticated}',
    );
    return MaterialApp(
      title: 'AcadeME Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      home: () {
        if (_authService.isAuthenticated) {
          debugPrint('Showing AdminShell');
          return const AdminShell();
        } else {
          debugPrint('Showing AdminLoginScreen');
          return const AdminLoginScreen();
        }
      }(),
    );
  }
}
