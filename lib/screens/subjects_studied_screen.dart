import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_profile_service.dart';
import '../services/study_session_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class SubjectsStudiedScreen extends StatefulWidget {
  const SubjectsStudiedScreen({super.key});

  @override
  State<SubjectsStudiedScreen> createState() => _SubjectsStudiedScreenState();
}

class _SubjectsStudiedScreenState extends State<SubjectsStudiedScreen> {
  final UserProfileService _profileService = UserProfileService();
  final StudySessionService _sessionService = StudySessionService();

  List<StudySession> _sessions = [];
  List<String> _subjectsInterested = [];
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
      // Load user profile to get subjects interested
      final profile = await _profileService.getProfile(uid);
      _subjectsInterested = profile?.subjectsInterested ?? [];

      // Load all completed sessions
      final sessions = await _sessionService.getAllUserSessions();
      _sessions = sessions.where((s) => s.isCompleted).toList();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading subjects data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, List<StudySession>> _groupSessionsBySubject() {
    final Map<String, List<StudySession>> grouped = {};
    for (final session in _sessions) {
      final subject = session.subject;
      if (!grouped.containsKey(subject)) {
        grouped[subject] = [];
      }
      grouped[subject]!.add(session);
    }
    return grouped;
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
            'Subjects Studied',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final groupedSessions = _groupSessionsBySubject();
    final totalSubjects = _subjectsInterested.length;
    final subjectsWithProgress = groupedSessions.keys.length;
    final progress = totalSubjects > 0
        ? subjectsWithProgress / totalSubjects
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
          'Subjects Studied',
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
                          'Overall Progress',
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
                            '$subjectsWithProgress/$totalSubjects Subjects',
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
                      '${(progress * 100).toStringAsFixed(0)}% Complete',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),

              if (groupedSessions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingXL),
                    child: Column(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 48,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        Text(
                          'No completed sessions yet',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start your first study session to track your progress',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Subjects List
                Text(
                  'Completed Subjects',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),

                ...groupedSessions.entries
                    .where(
                      (e) => e.value.length >= 8,
                    ) // Assume 8 sessions = completed
                    .map(
                      (entry) => _buildSubjectItem(
                        code: '',
                        name: entry.key,
                        progress: 1.0,
                        sessions: '${entry.value.length} sessions',
                        icon: Icons.school,
                        isCompleted: true,
                      ),
                    ),

                const SizedBox(height: AppConstants.paddingL),

                // In Progress Subjects
                Text(
                  'In Progress',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),

                ...groupedSessions.entries
                    .where((e) => e.value.length > 0 && e.value.length < 8)
                    .map(
                      (entry) => _buildSubjectItem(
                        code: '',
                        name: entry.key,
                        progress: entry.value.length / 8,
                        sessions: '${entry.value.length}/8',
                        icon: Icons.school,
                        isInProgress: true,
                      ),
                    ),

                const SizedBox(height: AppConstants.paddingL),

                // Not Started Subjects
                Text(
                  'Not Started',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),

                ..._subjectsInterested
                    .where((subject) => !groupedSessions.containsKey(subject))
                    .map(
                      (subject) => _buildSubjectItem(
                        code: '',
                        name: subject,
                        progress: 0.0,
                        sessions: '0/8',
                        icon: Icons.school,
                        isLocked: true,
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectItem({
    required String code,
    required String name,
    required double progress,
    required String sessions,
    required IconData icon,
    bool isLocked = false,
    bool isCompleted = false,
    bool isInProgress = false,
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
              : isInProgress
              ? AppColors.secondary.withOpacity(0.3)
              : AppColors.backgroundLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.primary.withOpacity(0.1)
                  : isInProgress
                  ? AppColors.secondary.withOpacity(0.1)
                  : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLocked
                ? Icon(Icons.lock, color: AppColors.textLight)
                : Icon(
                    icon,
                    color: isCompleted
                        ? AppColors.primary
                        : isInProgress
                        ? AppColors.secondary
                        : AppColors.textLight,
                  ),
          ),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      code,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? AppColors.primary
                            : isInProgress
                            ? AppColors.secondary
                            : AppColors.textLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.backgroundLight,
                          color: isCompleted
                              ? AppColors.primary
                              : isInProgress
                              ? AppColors.secondary
                              : AppColors.textLight,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      sessions,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isCompleted)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }
}
