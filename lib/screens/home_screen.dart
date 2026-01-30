import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import 'find_buddy_screen.dart';
import 'lesson_selection_screen.dart';
import 'study_groups_screen.dart';
import 'settings_screen.dart';
import 'matches_list_screen.dart';
import 'schedule_session_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _goHome() {
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeDashboard(),
      LessonSelectionScreen(onBack: _goHome),
      FindBuddyScreen(), // Placeholder
      // const Center(child: Text('Leaderboard Screen')), // Placeholder
      SettingsScreen(onBack: _goHome),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Subjects'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'New Session',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.bar_chart),
          //   label: 'Leaderboard',
          // ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text('You are not logged in.'));
    }

    return StreamBuilder<UserProfile?>(
      stream: UserProfileService().streamProfile(uid),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final fullName = (profile?.fullName ?? '').trim();
        final displayName = fullName.isNotEmpty ? fullName : 'Student';
        final initial = displayName.isNotEmpty
            ? displayName[0].toUpperCase()
            : 'S';
        final photoUrl = (profile?.photoUrl ?? '').trim();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.secondary,
                        backgroundImage: photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl.isEmpty
                            ? Text(
                                initial,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.black,
                      size: 28,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingS),
              Text(
                'Hello, $displayName!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),

              // Grid Menu
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppConstants.paddingM,
                mainAxisSpacing: AppConstants.paddingM,
                childAspectRatio: 1.1,
                children: [
                  _buildMenuCard(
                    context,
                    icon: Icons.search,
                    title: 'Find Study\nBuddy',
                    subtitle: 'Connect with peers',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FindBuddyScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.calendar_today,
                    title: 'My Sessions',
                    subtitle: 'View your schedule',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScheduleSessionScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.people,
                    title: 'Study Groups',
                    subtitle: 'Collaborate with others',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StudyGroupsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.chat_bubble_outline,
                    title: 'Messages',
                    subtitle: 'Your conversations',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MatchesListScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingXL),

              // Your Progress
              const Text(
                'Your Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),
              _buildProgressItem('Weekly Goal', '5/8 sessions', 0.6),
              const SizedBox(height: AppConstants.paddingM),
              _buildProgressItem('Subjects Studied', '3/5 subjects', 0.6),
              const SizedBox(height: AppConstants.paddingXL),

              // Pick Up Where You Left Off
              const Text(
                'Pick Up Where You Left Off',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),
              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCourseCard(
                      'COR 005\nGeneral Mathematics',
                      Icons.calculate,
                    ),
                    const SizedBox(width: AppConstants.paddingM),
                    _buildCourseCard(
                      'STM 003\nGeneral Physics 1',
                      Icons.science,
                    ),
                    // Add more cards as needed
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: AppColors.backgroundLight.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AppColors.secondary, size: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String title, String value, double progress) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.backgroundLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.backgroundLight,
              color: AppColors.primary,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(String title, IconData icon) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.backgroundLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusM,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(color: Colors.white),
                    ),
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
