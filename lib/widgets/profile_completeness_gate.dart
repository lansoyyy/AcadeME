import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../utils/colors.dart';
import '../widgets/custom_button.dart';
import '../screens/edit_profile_screen.dart';

/// Widget that checks if user profile is complete for matching
/// Shows a prompt to complete profile if required fields are missing
class ProfileCompletenessGate extends StatelessWidget {
  final Widget child;
  
  const ProfileCompletenessGate({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    if (uid == null) {
      return const Center(child: Text('Please log in'));
    }

    return StreamBuilder<UserProfile?>(
      stream: UserProfileService().streamProfile(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = snapshot.data;
        
        if (profile == null) {
          return _buildIncompleteProfileScreen(context);
        }

        // Check required fields for matching
        final isComplete = _isProfileCompleteForMatching(profile);
        
        if (!isComplete) {
          return _buildIncompleteProfileScreen(context, profile: profile);
        }

        return child;
      },
    );
  }

  bool _isProfileCompleteForMatching(UserProfile profile) {
    // Required fields for study buddy matching
    return profile.fullName.isNotEmpty &&
           profile.photoUrl.isNotEmpty &&
           profile.track.isNotEmpty &&
           profile.bio.isNotEmpty &&
           profile.subjectsInterested.isNotEmpty;
  }

  Widget _buildIncompleteProfileScreen(BuildContext context, {UserProfile? profile}) {
    final missingFields = _getMissingFields(profile);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 80,
                color: AppColors.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              const Text(
                'Complete Your Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'To find study buddies, you need to complete your profile with the following:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ...missingFields.map((field) => _buildMissingFieldItem(field)),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Complete Profile',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
                fullWidth: true,
                type: ButtonType.primary,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getMissingFields(UserProfile? profile) {
    final missing = <String>[];
    
    if (profile == null) {
      return [
        'Profile photo',
        'Full name',
        'Track (STEM/ABM/HUMSS/TVL)',
        'Bio',
        'Subjects interested in',
      ];
    }
    
    if (profile.photoUrl.isEmpty) missing.add('Profile photo');
    if (profile.fullName.isEmpty) missing.add('Full name');
    if (profile.track.isEmpty) missing.add('Track (STEM/ABM/HUMSS/TVL)');
    if (profile.bio.isEmpty) missing.add('Bio');
    if (profile.subjectsInterested.isEmpty) missing.add('Subjects interested in');
    
    return missing;
  }

  Widget _buildMissingFieldItem(String field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              field,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension to use ProfileCompletenessGate easily
extension ProfileCompletenessGateExtension on BuildContext {
  Future<void> navigateWithProfileCheck(
    Widget destination, {
    required bool requireCompleteProfile,
  }) async {
    if (!requireCompleteProfile) {
      Navigator.push(this, MaterialPageRoute(builder: (_) => destination));
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final profile = await UserProfileService().getProfile(uid);
    
    if (profile == null || !_isCompleteForMatching(profile)) {
      Navigator.push(
        this,
        MaterialPageRoute(
          builder: (_) => ProfileCompletenessGate(
            child: destination,
          ),
        ),
      );
    } else {
      Navigator.push(this, MaterialPageRoute(builder: (_) => destination));
    }
  }

  bool _isCompleteForMatching(UserProfile profile) {
    return profile.fullName.isNotEmpty &&
           profile.photoUrl.isNotEmpty &&
           profile.track.isNotEmpty &&
           profile.bio.isNotEmpty &&
           profile.subjectsInterested.isNotEmpty;
  }
}
