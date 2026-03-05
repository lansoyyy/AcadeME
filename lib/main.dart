import 'package:academe/firebase_options.dart';
import 'package:academe/services/fcm_service.dart';
import 'package:academe/services/presence_service.dart';
import 'package:academe/utils/theme.dart';
import 'package:academe/widgets/auth_gate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Top-level background message handler — MUST be a top-level function.
/// Firebase invokes this in a separate Dart isolate when the app is
/// terminated or in the background.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase must be initialised before any Firestore / Auth calls.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('FCM [background]: ${message.notification?.title}');
  // The OS will display the notification automatically when the message
  // contains a notification payload sent from the server.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background handler BEFORE runApp.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize FCM for push notifications
  await FCMService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AcadeME',
      theme: AppTheme.lightTheme,
      home: const PresenceWrapper(
        child: AuthGate(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
