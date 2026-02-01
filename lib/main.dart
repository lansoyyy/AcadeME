import 'package:academe/firebase_options.dart';
import 'package:academe/services/fcm_service.dart';
import 'package:academe/services/presence_service.dart';
import 'package:academe/utils/theme.dart';
import 'package:academe/widgets/auth_gate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
