import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../services/study_session_service.dart';
import '../services/user_profile_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

class ScheduleSessionScreen extends StatefulWidget {
  const ScheduleSessionScreen({super.key});

  @override
  State<ScheduleSessionScreen> createState() => _ScheduleSessionScreenState();
}

class _ScheduleSessionScreenState extends State<ScheduleSessionScreen> {
  final StudySessionService _sessionService = StudySessionService();
  final UserProfileService _profileService = UserProfileService();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedSubject = '';
  String? _currentUid;
  bool _isLoading = false;

  // Fallback subjects if Firestore academic data is empty
  final List<String> _defaultSubjects = [
    'Oral Communication',
    'General Mathematics',
    'English for Academic',
    'Filipino',
    '21st Century Literature',
    'Contemporary Arts',
    'Media and Information Literacy',
    'Physical Education',
    'Earth Science',
    'General Chemistry',
    'Basic Calculus',
    'Physics',
  ];

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    _selectedDate = DateTime.now();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _scheduleSession() async {
    if (_currentUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to schedule a session')),
      );
      return;
    }

    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (scheduledAt.isBefore(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a future date and time')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _showSelectBuddyDialog(scheduledAt);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showSelectBuddyDialog(DateTime scheduledAt) async {
    // Get user's matches to select a study buddy
    final matchesSnapshot = await FirebaseFirestore.instance
        .collection('matches')
        .where('users', arrayContains: _currentUid)
        .where('isActive', isEqualTo: true)
        .get();

    if (matchesSnapshot.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No study buddies found. Match with someone first!'),
          ),
        );
      }
      return;
    }

    // Get buddy profiles
    final buddies = <UserProfile>[];
    for (final match in matchesSnapshot.docs) {
      final users = List<String>.from(match.data()['users'] ?? []);
      final buddyUid = users.firstWhere(
        (uid) => uid != _currentUid,
        orElse: () => '',
      );
      if (buddyUid.isNotEmpty) {
        final profile = await _profileService.getProfile(buddyUid);
        if (profile != null) {
          buddies.add(profile);
        }
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Study Buddy'),
        content: SizedBox(
          width: double.maxFinite,
          child: buddies.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No buddies available'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: buddies.length,
                  itemBuilder: (context, index) {
                    final buddy = buddies[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: buddy.photoUrl.isNotEmpty
                            ? NetworkImage(buddy.photoUrl)
                            : null,
                        child: buddy.photoUrl.isEmpty
                            ? Text(
                                buddy.fullName.isNotEmpty
                                    ? buddy.fullName[0].toUpperCase()
                                    : '?',
                              )
                            : null,
                      ),
                      title: Text(buddy.fullName),
                      subtitle: Text(
                        '${buddy.track} • Grade ${buddy.gradeLevel}',
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _createSession(buddy.uid, scheduledAt);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _createSession(String buddyUid, DateTime scheduledAt) async {
    setState(() => _isLoading = true);

    try {
      final subject = _selectedSubject.isNotEmpty
          ? _selectedSubject
          : 'Study Session';

      await _sessionService.createSession(
        guestUid: buddyUid,
        subject: subject,
        scheduledAt: scheduledAt,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session scheduled! Your buddy will be notified.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to schedule: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  /// Show session actions depending on role and status
  void _showSessionActions(StudySession session) {
    final isHost = session.hostUid == _currentUid;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Guest can accept a pending session
            if (!isHost && session.isPending)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Accept Session'),
                onTap: () {
                  Navigator.pop(ctx);
                  _sessionService.confirmSession(session.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session accepted!')),
                  );
                },
              ),
            // Guest can decline a pending session
            if (!isHost && session.isPending)
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Decline Session'),
                onTap: () {
                  Navigator.pop(ctx);
                  _sessionService.cancelSession(session.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session declined')),
                  );
                },
              ),
            // Either user can cancel a pending/confirmed session
            if ((session.isPending || session.isConfirmed))
              ListTile(
                leading: const Icon(Icons.event_busy, color: Colors.orange),
                title: Text(isHost ? 'Cancel Session' : 'Cancel Session'),
                onTap: () {
                  Navigator.pop(ctx);
                  _sessionService.cancelSession(session.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session cancelled')),
                  );
                },
              ),
            // Either user can mark a confirmed session as completed
            if (session.isConfirmed)
              ListTile(
                leading: const Icon(Icons.task_alt, color: Colors.blue),
                title: const Text('Mark as Completed'),
                onTap: () {
                  Navigator.pop(ctx);
                  _sessionService.completeSession(session.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Session marked as completed!'),
                    ),
                  );
                },
              ),
            // Host can delete cancelled/completed sessions
            if (isHost && (session.isCancelled || session.isCompleted))
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Session'),
                onTap: () {
                  Navigator.pop(ctx);
                  _sessionService.deleteSession(session.id);
                },
              ),
          ],
        ),
      ),
    );
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
          'Schedule a Session',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Section
            _buildCalendar(),
            const SizedBox(height: AppConstants.paddingL),

            // Select a Time - free picker
            const Text(
              'Select a Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _formatTimeOfDay(_selectedTime),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Tap to change',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),

            // Subject selection
            const Text(
              'Subject',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingM,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSubject.isEmpty ? null : _selectedSubject,
                  isExpanded: true,
                  hint: const Text(
                    'Select a subject (optional)',
                    style: TextStyle(color: AppColors.textLight),
                  ),
                  items: _defaultSubjects.map((subject) {
                    return DropdownMenuItem<String>(
                      value: subject,
                      child: Text(subject),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSubject = value ?? '');
                  },
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),

            // Schedule Button
            CustomButton(
              text: 'Schedule Session',
              onPressed: _isLoading ? null : _scheduleSession,
              fullWidth: true,
              type: ButtonType.primary,
              isLoading: _isLoading,
            ),
            const SizedBox(height: AppConstants.paddingXL),

            // Upcoming Sessions — streams BOTH host and guest sessions
            const Text(
              'Your Sessions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            _buildSessionsList(),
            const SizedBox(height: AppConstants.paddingL),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final daysInMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month + 1,
      0,
    ).day;
    final firstWeekday =
        DateTime(_selectedDate.year, _selectedDate.month, 1).weekday % 7;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime(
                    _selectedDate.year,
                    _selectedDate.month - 1,
                    1,
                  );
                });
              },
            ),
            Text(
              '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime(
                    _selectedDate.year,
                    _selectedDate.month + 1,
                    1,
                  );
                });
              },
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingM),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map(
                (day) => Text(
                  day,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppConstants.paddingS),
        _buildCalendarGrid(daysInMonth, firstWeekday),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Widget _buildCalendarGrid(int daysInMonth, int firstWeekday) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.2,
      ),
      itemCount: 42,
      itemBuilder: (context, index) {
        final day = index - firstWeekday + 1;

        if (day < 1 || day > daysInMonth) {
          return const SizedBox();
        }

        final date = DateTime(_selectedDate.year, _selectedDate.month, day);
        final isSelected =
            _selectedDate.day == day &&
            _selectedDate.month == date.month &&
            _selectedDate.year == date.year;
        final isToday =
            date.day == DateTime.now().day &&
            date.month == DateTime.now().month &&
            date.year == DateTime.now().year;

        return GestureDetector(
          onTap: () => _onDateSelected(date),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : isToday
                  ? AppColors.primary.withAlpha(40)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected || isToday
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionsList() {
    if (_currentUid == null) {
      return const Center(child: Text('Please log in'));
    }

    return StreamBuilder<List<StudySession>>(
      stream: _sessionService.streamAllUserSessions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = snapshot.data ?? [];

        if (sessions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
            ),
            child: const Center(
              child: Text(
                'No sessions yet\nSchedule one now!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return Column(
          children: sessions.map((session) {
            return _buildSessionCard(session);
          }).toList(),
        );
      },
    );
  }

  Widget _buildSessionCard(StudySession session) {
    // Show the OTHER user's profile (host sees guest, guest sees host)
    final buddyUid = session.hostUid == _currentUid
        ? session.guestUid
        : session.hostUid;
    final isHost = session.hostUid == _currentUid;

    return FutureBuilder<UserProfile?>(
      future: _profileService.getProfile(buddyUid),
      builder: (context, snapshot) {
        final buddy = snapshot.data;

        return GestureDetector(
          onTap: () => _showSessionActions(session),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
            padding: const EdgeInsets.all(AppConstants.paddingM),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(25),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.backgroundLight,
                      backgroundImage: buddy?.photoUrl.isNotEmpty == true
                          ? NetworkImage(buddy!.photoUrl)
                          : null,
                      child: buddy?.photoUrl.isEmpty != false
                          ? const Icon(
                              Icons.person,
                              color: AppColors.textSecondary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  buddy?.fullName ?? 'Loading...',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isHost
                                      ? AppColors.primary.withAlpha(30)
                                      : Colors.purple.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isHost ? 'Host' : 'Invited',
                                  style: TextStyle(
                                    color: isHost
                                        ? AppColors.primary
                                        : Colors.purple,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            session.subject,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDateTime(session.scheduledAt),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: session.statusColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        session.statusDisplay,
                        style: TextStyle(
                          color: session.statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    // Quick action hints
                    if (!isHost && session.isPending)
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              _sessionService.confirmSession(session.id);
                            },
                            icon: const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.green,
                            ),
                            label: const Text(
                              'Accept',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              _sessionService.cancelSession(session.id);
                            },
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Decline',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    if (session.isConfirmed)
                      TextButton.icon(
                        onPressed: () {
                          _sessionService.completeSession(session.id);
                        },
                        icon: const Icon(
                          Icons.task_alt,
                          size: 16,
                          color: Colors.blue,
                        ),
                        label: const Text(
                          'Complete',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
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
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at $hour:$minute $ampm';
  }
}
