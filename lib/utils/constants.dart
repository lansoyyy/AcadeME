import 'package:flutter/material.dart';

/// App-wide constants
class AppConstants {
  // App Information
  static const String appName = 'AcadeME';
  static const String appFullName = 'AcadeME - Study Buddy & Learning Platform';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Connect, Learn, Succeed Together';

  // Spacing
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusRound = 100.0;

  // Icon Sizes
  static const double iconXS = 16.0;
  static const double iconS = 20.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;
  static const double iconXXL = 64.0;

  // Font Sizes
  static const double fontXS = 10.0;
  static const double fontS = 12.0;
  static const double fontM = 14.0;
  static const double fontL = 16.0;
  static const double fontXL = 20.0;
  static const double fontXXL = 24.0;
  static const double fontTitle = 28.0;
  static const double fontDisplay = 32.0;

  // Elevation
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 16.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Image Paths
  static const String imagePath = 'assets/images/';
  static const String iconPath = 'assets/icons/';
  static const String animationPath = 'assets/animations/';

  // Local Storage Keys
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserType = 'user_type';
  static const String keyLanguage = 'language';
  static const String keyThemeMode = 'theme_mode';
  static const String keyNotifications = 'notifications_enabled';
  static const String keyOfflineMode = 'offline_mode';

  // User Types
  static const String userTypeStudent = 'student';
  static const String userTypeTeacher = 'teacher';
  static const String userTypeAdmin = 'admin';

  // Grade Levels (Reference only - actual data from Firestore `academic/gradeLevels`)
  static const List<String> gradeLevels = ['Grade 11', 'Grade 12'];

  // Strands/Tracks (Reference only - actual data from Firestore `academic/strands`)
  static const List<String> tracks = [
    'STEM',
    'ABM',
    'HUMSS',
    'TVL',
    'SPORTS',
    'ARTS & DESIGN',
  ];

  // Study Goals
  static const List<String> studyGoals = [
    'Exam Preparation',
    'Homework Help',
    'Project Collaboration',
    'Concept Review',
    'Practice Exercises',
    'Study Group',
  ];

  // Availability Days
  static const List<String> availabilityDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Default Time Slots
  static const List<String> defaultTimeSlots = [
    '7:00 AM',
    '8:00 AM',
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
    '6:00 PM',
    '7:00 PM',
    '8:00 PM',
  ];

  // Pagination
  static const int defaultPageSize = 20;
  static const int messagePageSize = 50;

  // Swipe thresholds
  static const double swipeThreshold = 0.25; // 25% of screen width
  static const double swipeRotation = 0.3; // Max rotation in radians
}

/// Text Styles
class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: AppConstants.fontDisplay,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: AppConstants.fontTitle,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: AppConstants.fontXXL,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: AppConstants.fontXL,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: AppConstants.fontL,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: AppConstants.fontM,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: AppConstants.fontL,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: AppConstants.fontM,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: AppConstants.fontS,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: AppConstants.fontM,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: AppConstants.fontS,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: AppConstants.fontXS,
    fontWeight: FontWeight.w500,
  );
}
