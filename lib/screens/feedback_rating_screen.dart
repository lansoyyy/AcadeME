import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class FeedbackRatingScreen extends StatefulWidget {
  const FeedbackRatingScreen({super.key});

  @override
  State<FeedbackRatingScreen> createState() => _FeedbackRatingScreenState();
}

class _FeedbackRatingScreenState extends State<FeedbackRatingScreen> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Feedback & Rating',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.backgroundLight,
                    child: const Icon(
                      Icons.person,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your study buddy',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                        ),
                      ),
                      const Text(
                        'Sarah Chen',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingXL),

            // Rating Question
            const Center(
              child: Text(
                'How was your session with\nSarah?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: AppColors.secondary,
                    size: 40,
                  ),
                );
              }),
            ),
            const SizedBox(height: AppConstants.paddingXL),

            // Feedback Input
            const Text(
              'Feedback',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: AppConstants.paddingS),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: TextField(
                controller: _feedbackController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Share some helpful feedback...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(AppConstants.paddingM),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Remember to be respectful and constructive.',
              style: TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
            const SizedBox(height: AppConstants.paddingL),

            // Submit Button
            CustomButton(
              text: 'Submit Feedback',
              onPressed: () {
                // Submit logic
                Navigator.pop(context);
              },
              fullWidth: true,
              type: ButtonType.secondary, // Yellow button as per design
              textColor: Colors.black,
            ),
            const SizedBox(height: AppConstants.paddingXL),

            // Rating History
            const Text(
              'Your Rating History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),

            _buildHistoryItem(
              name: 'John Doe',
              date: 'Oct 12, 2023',
              rating: 5,
              comment:
                  '"Very helpful with calculus, explained the concepts clearly and was very..."',
            ),
            const SizedBox(height: AppConstants.paddingM),
            _buildHistoryItem(
              name: 'Emily Rose',
              date: 'Sep 28, 2023',
              rating: 4,
              comment: '"Good session, but was a bit late."',
              avatarColor: Colors.pink.shade100,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem({
    required String name,
    required String date,
    required int rating,
    required String comment,
    Color? avatarColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: avatarColor ?? AppColors.primary.withOpacity(0.1),
            child: const Icon(Icons.person, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      Icons.star,
                      size: 16,
                      color: index < rating
                          ? AppColors.secondary
                          : AppColors.border,
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  comment,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
