import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_profile_service.dart';
import '../services/study_session_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class WeeklyGoalScreen extends StatefulWidget {
  const WeeklyGoalScreen({super.key});

  @override
  State<WeeklyGoalScreen> createState() => _WeeklyGoalScreenState();
}

class _WeeklyGoalScreenState extends State<WeeklyGoalScreen> {
  final UserProfileService _profileService = UserProfileService();
  final StudySessionService _sessionService = StudySessionService();

  int _weeklyGoal = 8;
  List<StudySession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Load user profile to get weekly goal
      final profile = await _profileService.getProfile(uid);
      final studyGoals = profile?.studyGoals ?? [];
      if (studyGoals.isNotEmpty) {
        // Try to parse the first goal as number
        final goal = int.tryParse(studyGoals.first);
        if (goal != null && goal > 0) {
          _weeklyGoal = goal;
        }
      }

      // Load all user sessions
      final sessions = await _sessionService.getAllUserSessions();
      final now = DateTime.now();

      // Filter sessions for current week (Monday to Sunday)
      final weekStart = _getWeekStart(now);
      final weekEnd = weekStart.add(const Duration(days: 7));

      _sessions = sessions
          .where(
            (s) =>
                s.scheduledAt.isAfter(weekStart) &&
                s.scheduledAt.isBefore(weekEnd),
          )
          .toList();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading weekly goal data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  DateTime _getWeekStart(DateTime date) {
    // Get Monday of the current week
    final dayOfWeek = date.weekday;
    final monday = date.subtract(Duration(days: dayOfWeek - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  List<StudySession> _getCompletedSessions() {
    return _sessions.where((s) => s.isCompleted).toList();
  }

  List<StudySession> _getUpcomingSessions() {
    return _sessions.where((s) => !s.isCompleted && !s.isCancelled).toList();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
            'Weekly Goal',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final completedSessions = _getCompletedSessions();
    final upcomingSessions = _getUpcomingSessions();
    final progress = _weeklyGoal > 0
        ? completedSessions.length / _weeklyGoal
        : 0.0;

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
          'Weekly Goal',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Card
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingL),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'This Week\'s Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${completedSessions.length}/$_weeklyGoal Sessions',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingL),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: AppColors.backgroundLight,
                        color: AppColors.primary,
                        minHeight: 12,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingS),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}% Complete',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),

              // Sessions List
              Text(
                'Sessions Completed',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),

              if (completedSessions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingXL),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        Text(
                          'No completed sessions this week',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...completedSessions.map(
                  (session) => _buildSessionItem(
                    title: session.subject,
                    date: _formatDate(session.scheduledAt),
                    time:
                        '${_formatTime(session.scheduledAt)} - ${_formatTime(session.scheduledAt.add(const Duration(minutes: 90)))}',
                    status: session.statusDisplay,
                    isCompleted: session.isCompleted,
                  ),
                ),

              const SizedBox(height: AppConstants.paddingL),

              // Upcoming Sessions
              Text(
                'Upcoming Sessions',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),

              if (upcomingSessions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingXL),
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 48,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        Text(
                          'No upcoming sessions this week',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...upcomingSessions.map(
                  (session) => _buildSessionItem(
                    title: session.subject,
                    date: _formatDate(session.scheduledAt),
                    time:
                        '${_formatTime(session.scheduledAt)} - ${_formatTime(session.scheduledAt.add(const Duration(minutes: 90)))}',
                    status: session.statusDisplay,
                    isCompleted: session.isCompleted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionItem({
    required String title,
    required String date,
    required String time,
    required String status,
    required bool isCompleted,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: isCompleted
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.backgroundLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle : Icons.schedule,
              color: isCompleted ? AppColors.primary : AppColors.textLight,
            ),
          ),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(fontSize: 13, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCompleted ? AppColors.primary : AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
