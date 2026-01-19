import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const SettingsScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            if (onBack != null) {
              onBack!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSettingsItem(
            icon: Icons.person,
            title: 'Edit Profile',
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.notifications,
            title: 'Notification Preferences',
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.lock,
            title: 'Privacy Settings',
            onTap: () {},
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
            onTap: () {},
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
