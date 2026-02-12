import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/swipe_service.dart';
import '../services/user_profile_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/match_dialog.dart';

class FindBuddyScreen extends StatefulWidget {
  const FindBuddyScreen({super.key});

  @override
  State<FindBuddyScreen> createState() => _FindBuddyScreenState();
}

class _FindBuddyScreenState extends State<FindBuddyScreen> {
  final SwipeService _swipeService = SwipeService();
  final UserProfileService _profileService = UserProfileService();

  List<UserProfile> _candidates = [];
  Set<String> _swipedUserIds = {};
  Set<String> _blockedUserIds = {};
  bool _isLoading = true;
  String? _currentUid;
  int _currentIndex = 0;

  Offset _cardOffset = Offset.zero;
  double _cardRotation = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    if (_currentUid == null) return;

    setState(() => _isLoading = true);

    try {
      _swipedUserIds = await _swipeService.getSwipedUserIds(_currentUid!);
      _blockedUserIds = await _swipeService.getBlockedUserIds(_currentUid!);
      final excludeUids = {..._swipedUserIds, ..._blockedUserIds};
      final currentProfile = await _profileService.getProfile(_currentUid!);

      final candidates = await _profileService.getDiscoverableUsers(
        currentUid: _currentUid!,
        excludeUids: excludeUids,
        track: currentProfile?.matchPreferences['sameTrackOnly'] == true
            ? currentProfile?.track
            : null,
        gradeLevel: currentProfile?.matchPreferences['gradeLevel'] != null
            ? (currentProfile?.matchPreferences['gradeLevel'] as num?)?.toInt()
            : null,
        limit: 20,
      );

      setState(() {
        _candidates = candidates;
        _currentIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading candidates: $e')));
      }
    }
  }

  Future<void> _handleSwipe(SwipeDirection direction) async {
    if (_currentUid == null ||
        _candidates.isEmpty ||
        _currentIndex >= _candidates.length) {
      return;
    }

    final targetUser = _candidates[_currentIndex];

    try {
      final result = await _swipeService.swipe(
        fromUid: _currentUid!,
        toUid: targetUser.uid,
        direction: direction,
      );

      _swipedUserIds.add(targetUser.uid);

      setState(() {
        _currentIndex++;
        _cardOffset = Offset.zero;
        _cardRotation = 0;
      });

      if (result.hasNewMatch && mounted) {
        _showMatchDialog(targetUser, result.conversationId!);
      }

      if (_currentIndex >= _candidates.length - 3) {
        _loadMoreCandidates();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _loadMoreCandidates() async {
    if (_currentUid == null) return;

    try {
      final excludeUids = {..._swipedUserIds, ..._blockedUserIds};
      final currentProfile = await _profileService.getProfile(_currentUid!);

      final moreCandidates = await _profileService.getDiscoverableUsers(
        currentUid: _currentUid!,
        excludeUids: excludeUids,
        track: currentProfile?.matchPreferences['sameTrackOnly'] == true
            ? currentProfile?.track
            : null,
        gradeLevel: currentProfile?.matchPreferences['gradeLevel'] != null
            ? (currentProfile?.matchPreferences['gradeLevel'] as num?)?.toInt()
            : null,
        limit: 20,
      );

      setState(() {
        _candidates.addAll(moreCandidates);
      });
    } catch (e) {
      debugPrint('Error loading more candidates: $e');
    }
  }

  void _showMatchDialog(UserProfile matchedUser, String conversationId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          MatchDialog(otherUser: matchedUser, conversationId: conversationId),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _cardOffset += details.delta;
      _cardRotation = _cardOffset.dx * 0.001;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() => _isDragging = false);

    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.25;

    if (_cardOffset.dx > threshold) {
      _animateSwipeAndAction(SwipeDirection.like);
    } else if (_cardOffset.dx < -threshold) {
      _animateSwipeAndAction(SwipeDirection.nope);
    } else {
      _snapBack();
    }
  }

  void _animateSwipeAndAction(SwipeDirection direction) {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset = direction == SwipeDirection.like
        ? Offset(screenWidth * 1.5, 0)
        : Offset(-screenWidth * 1.5, 0);

    setState(() {
      _cardOffset = targetOffset;
      _cardRotation = direction == SwipeDirection.like ? 0.3 : -0.3;
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      _handleSwipe(direction);
    });
  }

  void _snapBack() {
    setState(() {
      _cardOffset = Offset.zero;
      _cardRotation = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        title: const Text(
          'Find Study Buddy',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_candidates.isEmpty || _currentIndex >= _candidates.length) {
      return _buildEmptyState();
    }

    final currentCandidate = _candidates[_currentIndex];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Transform.translate(
              offset: _cardOffset,
              child: Transform.rotate(
                angle: _cardRotation,
                child: _buildProfileCard(currentCandidate),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingXL),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                icon: Icons.close,
                color: AppColors.error,
                onPressed: () => _animateSwipeAndAction(SwipeDirection.nope),
              ),
              const SizedBox(width: AppConstants.paddingXL),
              _buildActionButton(
                icon: Icons.star,
                color: AppColors.primary,
                onPressed: () =>
                    _animateSwipeAndAction(SwipeDirection.superlike),
                size: 56,
              ),
              const SizedBox(width: AppConstants.paddingXL),
              _buildActionButton(
                icon: Icons.favorite,
                color: AppColors.success,
                onPressed: () => _animateSwipeAndAction(SwipeDirection.like),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingL),
          Text(
            'Swipe right to like, left to pass',
            style: TextStyle(color: AppColors.textLight, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(UserProfile profile) {
    return Container(
      height: 450,
      width: 340,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.radiusXL),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  profile.photoUrl.isNotEmpty
                      ? Image.network(
                          profile.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderAvatar(),
                        )
                      : _buildPlaceholderAvatar(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                  if (_isDragging) ...[
                    Positioned(
                      top: 40,
                      left: 20,
                      child: Opacity(
                        opacity: (_cardOffset.dx < 0)
                            ? (_cardOffset.dx.abs() / 100).clamp(0, 1)
                            : 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.error,
                              width: 4,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'NOPE',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 20,
                      child: Opacity(
                        opacity: (_cardOffset.dx > 0)
                            ? (_cardOffset.dx / 100).clamp(0, 1)
                            : 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.success,
                              width: 4,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'LIKE',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayNameWithAge,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (profile.track.isNotEmpty)
                          Text(
                            '${profile.track} • Grade ${profile.gradeLevel}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (profile.subjectsInterested.isNotEmpty)
                          Text(
                            'Studying: ${profile.subjectsSummary}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (profile.bio.isNotEmpty) ...[
                    Text(
                      'About',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.bio,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (profile.studyGoals.isNotEmpty) ...[
                    Text(
                      'Study Goals',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: profile.studyGoals
                          .take(3)
                          .map(
                            (goal) => Chip(
                              label: Text(
                                goal,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const Spacer(),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _showReportDialog(profile),
                      icon: const Icon(Icons.flag_outlined, size: 16),
                      label: const Text('Report or Block'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      color: AppColors.backgroundLight,
      child: const Center(
        child: Icon(Icons.person, size: 120, color: Colors.white),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double size = 64,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.4),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: AppColors.textLight),
          const SizedBox(height: AppConstants.paddingL),
          const Text(
            'No more study buddies nearby',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingM),
          Text(
            'Check back later or adjust your filters',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppConstants.paddingXL),
          ElevatedButton(
            onPressed: _loadCandidates,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filters'),
        content: const Text('Filter options coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(UserProfile profile) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block, color: AppColors.error),
              title: const Text('Block User'),
              subtitle: Text('You won\'t see ${profile.fullName} again'),
              onTap: () async {
                Navigator.pop(context);
                if (_currentUid != null) {
                  await _swipeService.blockUser(
                    uid: _currentUid!,
                    blockedUid: profile.uid,
                  );
                  _blockedUserIds.add(profile.uid);
                  setState(() {
                    _swipedUserIds.add(profile.uid);
                    _currentIndex++;
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${profile.fullName} blocked')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: AppColors.warning),
              title: const Text('Report User'),
              subtitle: const Text('Report inappropriate behavior'),
              onTap: () {
                Navigator.pop(context);
                _showReportReasonDialog(profile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportReasonDialog(UserProfile profile) {
    final reasons = [
      'Inappropriate content',
      'Harassment',
      'Fake profile',
      'Spam',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Why are you reporting?'),
        children: reasons.map((reason) {
          return SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);
              if (_currentUid != null) {
                await _swipeService.reportUser(
                  reporterUid: _currentUid!,
                  reportedUid: profile.uid,
                  reason: reason,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted')),
                  );
                }
              }
            },
            child: Text(reason),
          );
        }).toList(),
      ),
    );
  }
}
