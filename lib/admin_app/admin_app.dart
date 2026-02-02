import 'package:flutter/material.dart';
import 'services/admin_auth_service.dart';
import 'screens/admin_login_screen.dart';
import 'widgets/admin_shell.dart';

/// Root widget for the Admin App
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdminAuthService(),
      builder: (context, child) {
        final authService = AdminAuthService();
        
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
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
            ),
          ),
          home: authService.isAuthenticated 
              ? const AdminShell() 
              : const AdminLoginScreen(),
        );
      },
    );
  }
}
