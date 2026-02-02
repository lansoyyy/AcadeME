import 'package:academe/firebase_options.dart';
import 'package:academe/admin_app/admin_app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Admin App Entry Point
/// 
/// Run with: flutter run -t lib/main_admin.dart
/// 
/// This is a separate admin interface for managing the AcadeME app.
/// Features:
/// - User Management (activate/deactivate, password reset)
/// - Profile Monitoring (incomplete profiles, inappropriate content)
/// - Forum Moderation (hide/delete posts, lock threads)
/// - Match Monitoring (view/cancel matches)
/// - Reports & Blacklist (warnings, suspensions)
/// - System Analytics (registered users, DAU, matches, subjects)
/// - Feedback & Ratings (overview, high/low performers)
/// - Academic Structure (manage subjects, strands, grade levels)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const AdminApp());
}
