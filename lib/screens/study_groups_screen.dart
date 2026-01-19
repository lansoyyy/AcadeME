import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class StudyGroupsScreen extends StatelessWidget {
  const StudyGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.groups, size: 80, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: AppConstants.paddingXL),
              const Text(
                'Study Groups',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),
              const Text(
                'Create a new study circle or join an existing one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppConstants.paddingXL),
              CustomButton(
                text: 'Create a Group',
                onPressed: () {},
                fullWidth: true,
                type: ButtonType.primary,
              ),
              const SizedBox(height: AppConstants.paddingM),
              CustomButton(
                text: 'Join a Group',
                onPressed: () {},
                fullWidth: true,
                type: ButtonType.primary,
                backgroundColor: AppColors.backgroundLight,
                textColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
