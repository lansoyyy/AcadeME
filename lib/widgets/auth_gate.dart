import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/pending_approval_screen.dart';
import '../screens/profile_creation_screen.dart';
import '../screens/auth/login_screen.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  static const String _onboardingCompletedKey = 'onboarding_completed';

  Future<bool> _isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return FutureBuilder<bool>(
            future: _isOnboardingCompleted(),
            builder: (context, onboardingSnapshot) {
              if (onboardingSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final isCompleted = onboardingSnapshot.data ?? false;
              return isCompleted
                  ? const LoginScreen()
                  : const OnboardingScreen();
            },
          );
        }

        return StreamBuilder<UserProfile?>(
          stream: UserProfileService().streamProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final profile = profileSnapshot.data;
            if (profile == null) {
              return const ProfileCreationScreen(canGoBack: false);
            }

            print(profile.accountStatus);

            // Check account approval status
            if (profile.isPending) {
              return const PendingApprovalScreen(status: 'pending');
            }
            if (profile.isRejected) {
              return const PendingApprovalScreen(status: 'rejected');
            }

            return const HomeScreen();
          },
        );
      },
    );
  }
}
