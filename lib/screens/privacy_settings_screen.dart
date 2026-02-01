import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../services/swipe_service.dart';
import '../services/user_profile_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SwipeService _swipeService = SwipeService();
  final UserProfileService _profileService = UserProfileService();
  String? _currentUid;
  bool _isLoading = true;

  // Privacy settings
  bool _isDiscoverable = true;
  bool _sameTrackOnly = false;
  List<String> _blockedUserIds = [];
  List<UserProfile> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_currentUid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Load profile for discoverable setting
      final profile = await _profileService.getProfile(_currentUid!);
      if (profile != null) {
        setState(() {
          _isDiscoverable = profile.isDiscoverable;
          _sameTrackOnly = profile.matchPreferences['sameTrackOnly'] ?? false;
        });
      }

      // Load blocked users
      final blockedIds = await _swipeService.getBlockedUserIds(_currentUid!);
      setState(() => _blockedUserIds = blockedIds.toList());

      // Load blocked user profiles
      final blockedProfiles = <UserProfile>[];
      for (final uid in blockedIds) {
        final userProfile = await _profileService.getProfile(uid);
        if (userProfile != null) {
          blockedProfiles.add(userProfile);
        }
      }
      setState(() => _blockedUsers = blockedProfiles);
    } catch (e) {
      debugPrint('Error loading privacy settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDiscoverable(bool value) async {
    if (_currentUid == null) return;

    try {
      await _firestore.collection('users').doc(_currentUid).update({
        'isDiscoverable': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving setting: $e')),
        );
      }
    }
  }

  Future<void> _saveMatchPreferences() async {
    if (_currentUid == null) return;

    try {
      await _firestore.collection('users').doc(_currentUid).update({
        'matchPreferences.sameTrackOnly': _sameTrackOnly,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving match preferences: $e');
    }
  }

  Future<void> _unblockUser(String uid) async {
    if (_currentUid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('blocks')
          .doc(uid)
          .delete();

      setState(() {
        _blockedUserIds.remove(uid);
        _blockedUsers.removeWhere((user) => user.uid == uid);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User unblocked')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error unblocking user: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Discovery',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    _buildSwitchTile(
                      icon: Icons.visibility,
                      title: 'Discoverable',
                      subtitle: 'Allow others to find you in study buddy matching',
                      value: _isDiscoverable,
                      onChanged: (value) {
                        setState(() => _isDiscoverable = value);
                        _saveDiscoverable(value);
                      },
                    ),
                    _buildSwitchTile(
                      icon: Icons.school,
                      title: 'Same Track Only',
                      subtitle: 'Only match with students in the same track',
                      value: _sameTrackOnly,
                      onChanged: (value) {
                        setState(() => _sameTrackOnly = value);
                        _saveMatchPreferences();
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingXL),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Blocked Users',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_blockedUsers.length} blocked',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    if (_blockedUsers.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppConstants.paddingL),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppConstants.radiusL),
                          border: Border.all(color: AppColors.backgroundLight),
                        ),
                        child: const Center(
                          child: Text(
                            'No blocked users',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._blockedUsers.map((user) => _buildBlockedUserTile(user)),
                    const SizedBox(height: AppConstants.paddingXL),
                    const Text(
                      'Data & Privacy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    _buildActionTile(
                      icon: Icons.download,
                      title: 'Download My Data',
                      onTap: () {
                        // TODO: Implement data export
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Data export coming soon'),
                          ),
                        );
                      },
                    ),
                    _buildActionTile(
                      icon: Icons.delete_forever,
                      title: 'Delete Account',
                      textColor: AppColors.error,
                      onTap: _showDeleteAccountDialog,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.backgroundLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUserTile(UserProfile user) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.backgroundLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.backgroundLight,
            backgroundImage:
                user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
            child: user.photoUrl.isEmpty
                ? Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : '?',
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
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (user.track.isNotEmpty)
                  Text(
                    '${user.track} • Grade ${user.gradeLevel}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _unblockUser(user.uid),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (textColor ?? AppColors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: textColor ?? AppColors.primary, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor ?? Colors.black,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textLight,
        ),
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          side: BorderSide(color: AppColors.backgroundLight),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action cannot be undone. All your data including matches, messages, and profile will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion coming soon'),
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
