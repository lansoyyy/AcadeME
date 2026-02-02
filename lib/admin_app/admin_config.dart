/// Admin configuration constants
/// Hardcoded admin credentials for the admin interface
///
/// SECURITY NOTE:
/// - These credentials are for the UI login screen only
/// - For secure Firestore access, create Firebase Auth admin accounts and add their UIDs below
/// - Update firestore.rules with the same admin UIDs
class AdminConfig {
  // Hardcoded admin credentials (UI login only)
  static const String adminUsername = 'admin';
  static const String adminPassword = 'academe_admin_2026';

  // Admin email for Firebase Auth (for secure Firestore access)
  // Create this admin account in Firebase Console > Authentication
  static const String adminEmail = 'admin@academe.app';
  static const String adminFirebasePassword = 'AcadeME_Admin_2026!';

  // Allowed admin UIDs in Firestore rules
  // IMPORTANT: Add your admin Firebase Auth UIDs here after creating admin accounts
  // Get UIDs from: Firebase Console > Authentication > Users > Click on admin user > Copy UID
  static const List<String> adminUids = [
    // 'YOUR_ADMIN_UID_1_HERE',
    // 'YOUR_ADMIN_UID_2_HERE',
  ];

  // Session persistence key
  static const String sessionKey = 'admin_session';

  // App name
  static const String appName = 'AcadeME Admin';
}
