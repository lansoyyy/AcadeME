/// Admin configuration constants
/// Hardcoded admin credentials for the admin interface
class AdminConfig {
  // Hardcoded admin credentials
  static const String adminUsername = 'admin';
  static const String adminPassword = 'academe_admin_2026';

  // Admin email for Firebase Auth (optional, for secure Firestore access)
  static const String adminEmail = 'admin@academe.app';
  static const String adminFirebasePassword = 'AcadeME_Admin_2026!';

  // Allowed admin UIDs in Firestore rules
  static const List<String> adminUids = [
    // Add admin Firebase Auth UIDs here after creating the admin account
    // e.g., 'abc123xyz789',
  ];

  // Session persistence key
  static const String sessionKey = 'admin_session';

  // App name
  static const String appName = 'AcadeME Admin';
}
