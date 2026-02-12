import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import 'edit_profile_screen.dart';
import 'notification_preferences_screen.dart';
import 'privacy_settings_screen.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const SettingsScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          if (uid != null)
            StreamBuilder<UserProfile?>(
              stream: UserProfileService().streamProfile(uid),
              builder: (context, snapshot) {
                final profile = snapshot.data;
                final name = (profile?.fullName ?? 'Student').trim();
                final studentId = (profile?.studentId ?? '').trim();
                final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
                final photoUrl = (profile?.photoUrl ?? '').trim();

                return Container(
                  margin: const EdgeInsets.fromLTRB(
                    AppConstants.paddingL,
                    AppConstants.paddingM,
                    AppConstants.paddingL,
                    AppConstants.paddingM,
                  ),
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                    border: Border.all(color: AppColors.backgroundLight),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.backgroundLight,
                        backgroundImage: photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl.isEmpty
                            ? Text(
                                initial,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            if (studentId.isNotEmpty)
                              Text(
                                studentId,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          _buildSettingsItem(
            icon: Icons.person,
            title: 'Edit Profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.notifications,
            title: 'Notification Preferences',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPreferencesScreen(),
                ),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.lock,
            title: 'Privacy Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacySettingsScreen(),
                ),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.info,
            title: 'About AcadeME',
            onTap: () {},
          ),
          const SizedBox(height: AppConstants.paddingL),
          _buildSettingsItem(
            icon: Icons.logout,
            title: 'Logout',
            textColor: AppColors.primary,
            iconColor: AppColors.primary,
            showChevron: false, // Icon for logout usually distinct
            leadingIcon: Icons.exit_to_app, // Or use custom icon
            onTap: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
    bool showChevron = true,
    IconData? leadingIcon,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(leadingIcon ?? icon, color: iconColor ?? AppColors.primary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.black,
        ),
      ),
      trailing: showChevron
          ? const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textLight,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
        vertical: AppConstants.paddingS,
      ),
    );
  }
}
