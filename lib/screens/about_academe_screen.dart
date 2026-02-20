import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class AboutAcademeScreen extends StatelessWidget {
  const AboutAcademeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'About AcadeME',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo Section
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.school,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  const Text(
                    'AcadeME',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingXL),

            // Our Mission Section
            _buildSection(
              title: 'Our Mission',
              icon: Icons.flag,
              content:
                  '''AcadeME is a dedicated academic platform designed to streamline the learning experience for students. By providing tools for goal setting, subject tracking, and collaborative discussion, AcadeME aims to foster a disciplined and supportive environment for academic excellence.''',
            ),

            const SizedBox(height: AppConstants.paddingL),

            // Terms and Conditions Section
            _buildSection(
              title: 'Terms and Conditions',
              icon: Icons.gavel,
              content:
                  '''By using AcadeME, you agree to abide by the following terms:

• User Conduct: Users are expected to maintain academic integrity and professional decorum. The use of profanity, harassment, or "bad words" in chat rooms is strictly prohibited and may result in account restriction.

• Account Responsibility: You are responsible for maintaining the confidentiality of your login credentials.

• Content Usage: All materials provided within the app are for educational purposes only. Unauthorized distribution of platform content is prohibited.

• Service Modifications: AcadeME reserves the right to update features, tracks, and subject lists to better serve the student body.''',
            ),

            const SizedBox(height: AppConstants.paddingL),

            // Data Privacy Act Statement Section
            _buildSection(
              title: 'Data Privacy Act Statement',
              icon: Icons.security,
              content:
                  '''In compliance with Republic Act No. 10173 (Data Privacy Act of 2012)

AcadeME values your privacy and is committed to protecting the personal information you share with us. By registering an account, you acknowledge and agree to the following terms regarding your data:

• Academic Research Purpose: You are hereby informed that AcadeME is a Capstone Project developed for academic purposes. The data collected—including user study habits, frequency of feature use, and academic tracks—will be utilized as primary data for the researchers' capstone thesis completion.

• Information Collection: We collect specific personal and academic information, including your full name, email address, grade level, strand, and list of enrolled subjects.

• Data Processing & Anonymity: For the purpose of the final research report, all data will be anonymous. Individual identities will be protected, and results will be presented as aggregate statistics.

• Confidentiality & Storage: Your data is stored in a secure database accessible only to the authorized Capstone Research Team and their Faculty Adviser. No data will be shared with third-party entities or used for commercial marketing.

• Data Retention: Upon the successful completion and defense of this Capstone Project, all personal identifiable information will be permanently deleted from our servers, unless otherwise required for institutional archiving.

• Consent: By clicking continuing to use the application, you provide your explicit consent for the researchers to process your information for the aforementioned academic study.

User Rights
Under the Data Privacy Act, you retain the right to:

1. Access: Request a copy of the data we have collected about your app usage.

2. Correction: Request the rectification of any errors in your profile (e.g., wrong Track/Strand).

3. Withdrawal: Withdraw your consent and request the deletion of your account if you no longer wish to participate in the research study.''',
            ),

            const SizedBox(height: AppConstants.paddingXL),

            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    '© 2024 AcadeME',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All rights reserved.',
                    style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.backgroundLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingM),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
