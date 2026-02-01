import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUid;
  bool _isLoading = true;

  // Notification settings
  bool _newMatches = true;
  bool _newMessages = true;
  bool _sessionReminders = true;
  bool _studyTips = true;
  bool _marketingNotifications = false;

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    if (_currentUid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _newMatches = data['newMatches'] ?? true;
          _newMessages = data['newMessages'] ?? true;
          _sessionReminders = data['sessionReminders'] ?? true;
          _studyTips = data['studyTips'] ?? true;
          _marketingNotifications = data['marketingNotifications'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    if (_currentUid == null) return;

    setState(() => _isLoading = true);

    try {
      await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('settings')
          .doc('notifications')
          .set({
        'newMatches': _newMatches,
        'newMessages': _newMessages,
        'sessionReminders': _sessionReminders,
        'studyTips': _studyTips,
        'marketingNotifications': _marketingNotifications,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          'Notification Preferences',
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
                      'Push Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    _buildSwitchTile(
                      icon: Icons.favorite,
                      title: 'New Matches',
                      subtitle: 'When you match with a study buddy',
                      value: _newMatches,
                      onChanged: (value) => setState(() => _newMatches = value),
                    ),
                    _buildSwitchTile(
                      icon: Icons.chat,
                      title: 'New Messages',
                      subtitle: 'When someone sends you a message',
                      value: _newMessages,
                      onChanged: (value) => setState(() => _newMessages = value),
                    ),
                    _buildSwitchTile(
                      icon: Icons.calendar_today,
                      title: 'Session Reminders',
                      subtitle: 'Reminders before scheduled study sessions',
                      value: _sessionReminders,
                      onChanged: (value) => setState(() => _sessionReminders = value),
                    ),
                    const SizedBox(height: AppConstants.paddingXL),
                    const Text(
                      'General Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingM),
                    _buildSwitchTile(
                      icon: Icons.lightbulb,
                      title: 'Study Tips',
                      subtitle: 'Weekly study tips and recommendations',
                      value: _studyTips,
                      onChanged: (value) => setState(() => _studyTips = value),
                    ),
                    _buildSwitchTile(
                      icon: Icons.campaign,
                      title: 'Marketing & Promotions',
                      subtitle: 'New features and special offers',
                      value: _marketingNotifications,
                      onChanged: (value) => setState(() => _marketingNotifications = value),
                    ),
                    const SizedBox(height: AppConstants.paddingXL),
                    CustomButton(
                      text: 'Save Preferences',
                      onPressed: _savePreferences,
                      fullWidth: true,
                      type: ButtonType.primary,
                      isLoading: _isLoading,
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
}
