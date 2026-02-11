import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

/// Screen shown to users whose registration is pending admin approval
class PendingApprovalScreen extends StatelessWidget {
  final String status; // 'pending' or 'rejected'

  const PendingApprovalScreen({super.key, this.status = 'pending'});

  @override
  Widget build(BuildContext context) {
    final bool isRejected = status == 'rejected';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: isRejected
                      ? Colors.red.withAlpha(25)
                      : AppColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRejected ? Icons.cancel_outlined : Icons.hourglass_top,
                  size: 64,
                  color: isRejected ? Colors.red : AppColors.primary,
                ),
              ),
              const SizedBox(height: AppConstants.paddingXL),
              Text(
                isRejected ? 'Registration Rejected' : 'Pending Approval',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),
              Text(
                isRejected
                    ? 'Your registration has been rejected by the admin. Please contact your school administrator for more information.'
                    : 'Your registration is being reviewed by the admin. You will be able to access the app once your account is approved.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppConstants.paddingXL * 2),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusM),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
