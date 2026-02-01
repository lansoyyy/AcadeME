import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../services/study_session_service.dart';
import '../services/user_profile_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import 'feedback_rating_screen.dart';

class ScheduleSessionScreen extends StatefulWidget {
  const ScheduleSessionScreen({super.key});

  @override
  State<ScheduleSessionScreen> createState() => _ScheduleSessionScreenState();
}

class _ScheduleSessionScreenState extends State<ScheduleSessionScreen> {
  final StudySessionService _sessionService = StudySessionService();
  final UserProfileService _profileService = UserProfileService();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '3:00 PM';
  String? _currentUid;
  bool _isLoading = false;

  final List<String> _timeSlots = ['9:00 AM', '10:30 AM', '3:00 PM', '4:30 PM'];

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    _selectedDate = DateTime.now();
  }

  Future<void> _scheduleSession() async {
    if (_currentUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to schedule a session')),
      );
      return;
    }

    // Parse time
    final timeParts = _selectedTime.split(' ');
    final hourMinute = timeParts[0].split(':');
    var hour = int.parse(hourMinute[0]);
    final minute = int.parse(hourMinute[1]);
    final isPM = timeParts[1] == 'PM';
    
    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;

    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    );

    setState(() => _isLoading = true);

    try {
      // For demo purposes, we'll need to select a study buddy
      // In a real app, this would come from a match/conversation
      await _showSelectBuddyDialog(scheduledAt);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
          const SnackBar(content: Text('No study buddies found. Match with someone first!')),
        );
      }
      return;
    }

    // Get buddy profiles
    final buddies = <UserProfile>[];
    for (final match in matchesSnapshot.docs) {
      final users = List<String>.from(match.data()['users'] ?? []);
      final buddyUid = users.firstWhere((uid) => uid != _currentUid, orElse: () => '');
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
      builder: (context) => AlertDialog(
        title: const Text('Select Study Buddy'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
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
                      ? Text(buddy.fullName[0].toUpperCase())
                      : null,
                ),
                title: Text(buddy.fullName),
                subtitle: Text('${buddy.track} • Grade ${buddy.gradeLevel}'),
                onTap: () async {
                  Navigator.pop(context);
                  await _createSession(buddy.uid, scheduledAt);
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
      await _sessionService.createSession(
        guestUid: buddyUid,
        subject: 'Study Session', // Could be selectable
        scheduledAt: scheduledAt,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session scheduled successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule: $e')),
        );
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

            // Select a Time
            const Text(
              'Select a Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _timeSlots.map((time) {
                  final isSelected = time == _selectedTime;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTime = time;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
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

            // Upcoming Sessions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Sessions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: () => _showAllSessions(),
                  child: const Text('See All'),
                ),
              ],
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
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(now.year, now.month, 1).weekday % 7;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              onPressed: () {},
            ),
            Text(
              '${_getMonthName(now.month)} ${now.year}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {},
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
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
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

        final date = DateTime(DateTime.now().year, DateTime.now().month, day);
        final isSelected = _selectedDate.day == day && 
                          _selectedDate.month == DateTime.now().month;

        return GestureDetector(
          onTap: () => _onDateSelected(date),
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _sessionService.streamUserSessions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = snapshot.data?.docs ?? [];
        
        if (sessions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.radiusL),
            ),
            child: const Center(
              child: Text(
                'No upcoming sessions\nSchedule one now!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return Column(
          children: sessions.take(3).map((doc) {
            final session = StudySession.fromDoc(doc);
            return _buildSessionCard(session);
          }).toList(),
        );
      },
    );
  }

  Widget _buildSessionCard(StudySession session) {
    return FutureBuilder<UserProfile?>(
      future: _profileService.getProfile(session.guestUid),
      builder: (context, snapshot) {
        final buddy = snapshot.data;
        
        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
          padding: const EdgeInsets.all(AppConstants.paddingM),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
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
                backgroundImage: buddy?.photoUrl.isNotEmpty == true
                    ? NetworkImage(buddy!.photoUrl)
                    : null,
                child: buddy?.photoUrl.isEmpty != false
                    ? const Icon(Icons.person, color: AppColors.textSecondary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buddy?.fullName ?? 'Loading...',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      session.subject,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: session.statusColor.withOpacity(0.1),
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
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at $hour:$minute $ampm';
  }

  void _showAllSessions() {
    // Could navigate to a full sessions list screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All sessions view coming soon')),
    );
  }
}
