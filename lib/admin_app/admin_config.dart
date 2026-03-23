/// Admin configuration constants
/// Hardcoded admin credentials for the admin interface.
///
/// NOTE:
/// - These credentials are validated locally in the admin app.
/// - They do not automatically grant privileged Firebase / Firestore access.
class AdminConfig {
  // Hardcoded admin credentials
  static const String adminUsername = 'admin';
  static const String adminPassword = 'academe_admin_2026';

  // Session persistence key
  static const String sessionKey = 'admin_session';

  // App name
  static const String appName = 'AcadeME Admin';
}
