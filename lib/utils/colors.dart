import 'package:flutter/material.dart';

/// App color palette based on AcadeME design
class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF142B6F); // Dark Blue
  static const Color secondary = Color(0xFFFFD601); // Yellow
  static const Color backgroundLight = Color(0xFFE1DEE6); // Light Purple/Grey

  // Compatibility / Derived Colors
  static const Color primaryLight = Color(
    0xFF3F5AA6,
  ); // Lighter shade of Dark Blue
  static const Color secondaryLight = Color(
    0xFFFFE066,
  ); // Lighter shade of Yellow
  static const Color accent = secondary;
  static const Color surfaceLight = backgroundLight;

  // Background Colors
  static const Color background = Colors.white;
  static const Color cardBackground = Colors.white;
  static const Color scaffoldBackground = Color(0xFFF8F9FA);

  // Text Colors
  static const Color textPrimary = Color(0xFF142B6F); // Dark Blue for headings
  static const Color textSecondary = Color(
    0xFF1D1D1F,
  ); // Dark Gray/Black for body
  static const Color textLight = Color(0xFF8E8E93); // Light Gray
  static const Color textWhite = Colors.white;

  // Status Colors
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);

  // Learning Status Colors (Mapped to new palette or standard status colors)
  static const Color completed = success;
  static const Color inProgress = info;
  static const Color notStarted = textLight;
  static const Color overdue = error;

  // Role-specific Colors (Mapped to primary for now)
  static const Color studentPrimary = primary;

  // UI Elements
  static const Color divider = Color(0xFFE5E5EA);
  static const Color border = Color(0xFFD1D1D6);
  static const Color borderLight = Color(0xFFF2F2F7);
  static const Color inputBackground = Colors.white;

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF142B6F), Color(0xFF2A4596)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
