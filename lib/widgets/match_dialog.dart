import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../screens/chat_screen.dart'; // Will implement next

class MatchDialog extends StatelessWidget {
  const MatchDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppConstants.paddingM),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatars
            SizedBox(
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // User Avatar (Left)
                  Positioned(
                    left: 40,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  // Match Avatar (Right)
                  Positioned(
                    right: 40,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.backgroundLight,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  // Heart/Match Icon in middle? Design doesn't show one explicitly overlapping,
                  // but the avatars overlap slightly.
                  // In the provided image "It's a Match!", there are two avatars in circles.
                  // I'll stick to the visual of two avatars side by side or overlapping.
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),

            const Text(
              "It's a Match!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingS),

            const Text(
              "You and Maria are now study buddies.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppConstants.paddingXL),

            CustomButton(
              text: 'Start Chat',
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatScreen()),
                );
              },
              fullWidth: true,
              type: ButtonType.primary,
            ),
            const SizedBox(height: AppConstants.paddingM),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Keep Swiping',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
