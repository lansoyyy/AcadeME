import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import 'profile_creation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Welcome to AcadeME!',
      'description':
          'Your smart study buddy for PHINMA-Araullo University. Let\'s get you connected.',
      'image': 'assets/images/student.png', // Placeholder path
    },
    {
      'title': 'Find Your Perfect Match',
      'description':
          'Get matched with study buddies based on your subjects, learning style, and availability.',
      'image': 'assets/images/communication.png', // Placeholder path
    },
    {
      'title': 'Schedule Sessions with Ease',
      'description':
          'Coordinate and plan your study sessions directly within the app.',
      'image': 'assets/images/book.png', // Placeholder path
    },
    {
      'title': 'Grow Together',
      'description':
          'Provide and receive valuable feedback to improve your collaborative learning experience.',
      'image': 'assets/images/graduation.png', // Placeholder path
    },
  ];

  void _onNext() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _onGetStarted();
    }
  }

  void _onSkip() {
    _onGetStarted();
  }

  void _onGetStarted() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ProfileCreationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentPage < _onboardingData.length - 1)
            TextButton(
              onPressed: _onSkip,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(
                    title: _onboardingData[index]['title']!,
                    description: _onboardingData[index]['description']!,
                    // For placeholder, we'll use a Container with a color or Icon
                    isLast: index == _onboardingData.length - 1,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Column(
                children: [
                  // Page Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => _buildDot(index),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingXL),
                  // Next / Get Started Button
                  CustomButton(
                    text: _currentPage == _onboardingData.length - 1
                        ? 'Get Started'
                        : 'Next',
                    onPressed: _onNext,
                    fullWidth: true,
                    type: ButtonType.primary,
                  ),
                  const SizedBox(height: AppConstants.paddingL),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage({
    required String title,
    required String description,
    required bool isLast,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image Placeholder
          Image.asset(_onboardingData[_currentPage]['image']!),
          const SizedBox(height: AppConstants.paddingXL),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24, // fontXXL
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingM),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16, // fontL
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppColors.primary
            : AppColors.backgroundLight, // Active vs Inactive
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
