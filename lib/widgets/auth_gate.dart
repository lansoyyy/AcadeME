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

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const String _onboardingCompletedKey = 'onboarding_completed';

  /// Cached profile stream — only recreated when the logged-in user changes.
  /// Keeping it stable prevents the inner StreamBuilder from resetting to
  /// ConnectionState.waiting (and briefly showing ProfileCreationScreen) on
  /// every rebuild of the outer StreamBuilder.
  Stream<UserProfile?>? _profileStream;
  String? _profileStreamUid;

  /// Onboarding future loaded once in initState so FutureBuilder never
  /// receives a new Future instance on rebuild.
  late final Future<bool> _onboardingFuture;
  bool _isSigningOutDeletedUser = false;

  @override
  void initState() {
    super.initState();
    _onboardingFuture = _loadOnboardingCompleted();
  }

  Future<bool> _loadOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  /// Returns the stable profile stream for [uid], creating it only when the
  /// uid changes (i.e. a different user logs in).
  Stream<UserProfile?> _profileStreamFor(String uid) {
    if (_profileStreamUid != uid) {
      _profileStreamUid = uid;
      _profileStream = UserProfileService().streamProfile(uid);
    }
    return _profileStream!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // initialData lets us skip the waiting→null→user flash on cold start:
      // if the user was already signed in, Firebase Auth has a synchronous
      // currentUser available before the async stream emits.
      initialData: FirebaseAuth.instance.currentUser,
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Only show the spinner when we are truly waiting AND have no cached
        // user (i.e. we genuinely don't know the auth state yet).
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          // User is definitely signed out — show onboarding or login.
          return FutureBuilder<bool>(
            future: _onboardingFuture,
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

        // User is signed in — stream their profile using the stable stream.
        return StreamBuilder<UserProfile?>(
          stream: _profileStreamFor(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // On stream error (e.g. Firestore rules / network blip), keep
            // showing a spinner rather than incorrectly redirecting the user
            // to ProfileCreationScreen or appearing to log them out.
            if (profileSnapshot.hasError) {
              debugPrint('AuthGate profile stream error: ${profileSnapshot.error}');
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final profile = profileSnapshot.data;
            if (profile == null) {
              return const ProfileCreationScreen(canGoBack: false);
            }

            if (profile.isDeleted) {
              if (!_isSigningOutDeletedUser) {
                _isSigningOutDeletedUser = true;
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    setState(() {
                      _isSigningOutDeletedUser = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'This account has been deleted and can no longer be used.',
                        ),
                      ),
                    );
                  }
                });
              }

              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

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
