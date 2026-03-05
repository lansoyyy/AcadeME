import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import 'chat_screen.dart';

/// Screen that shows study buddies who are interested in or studying a specific subject.
class BuddiesBySubjectScreen extends StatefulWidget {
  final String subject;

  const BuddiesBySubjectScreen({super.key, required this.subject});

  @override
  State<BuddiesBySubjectScreen> createState() => _BuddiesBySubjectScreenState();
}

class _BuddiesBySubjectScreenState extends State<BuddiesBySubjectScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUid;
  List<UserProfile> _buddies = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    _loadBuddies();
  }

  Future<void> _loadBuddies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final Set<String> matchedUids = await _getMatchedUids();
      final List<UserProfile> results = [];

      // Query users who have the subject in their subjectsInterested
      final byInterest = await _firestore
          .collection('users')
          .where('subjectsInterested', arrayContains: widget.subject)
          .where('isDiscoverable', isEqualTo: true)
          .limit(50)
          .get();

      final Set<String> seenUids = {};

      for (final doc in byInterest.docs) {
        final uid = doc.id;
        if (uid == _currentUid || seenUids.contains(uid)) continue;
        seenUids.add(uid);
        final data = doc.data();
        final profile = UserProfile.fromMap(uid, data);
        results.add(profile);
      }

      // Also search case-insensitively (subjects may be stored with different casing)
      // by checking all discoverable users and filtering client-side if results are sparse.
      if (results.length < 5) {
        final allUsers = await _firestore
            .collection('users')
            .where('isDiscoverable', isEqualTo: true)
            .limit(100)
            .get();

        final subjectLower = widget.subject.toLowerCase();
        for (final doc in allUsers.docs) {
          final uid = doc.id;
          if (uid == _currentUid || seenUids.contains(uid)) continue;
          final data = doc.data();
          final interests = (data['subjectsInterested'] as List<dynamic>? ?? [])
              .map((e) => e.toString().toLowerCase())
              .toList();
          if (interests.any(
            (s) => s.contains(subjectLower) || subjectLower.contains(s),
          )) {
            seenUids.add(uid);
            results.add(UserProfile.fromMap(uid, data));
          }
        }
      }

      // Sort: matched buddies first, then others
      results.sort((a, b) {
        final aMatched = matchedUids.contains(a.uid) ? 0 : 1;
        final bMatched = matchedUids.contains(b.uid) ? 0 : 1;
        return aMatched.compareTo(bMatched);
      });

      if (mounted) {
        setState(() {
          _buddies = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<Set<String>> _getMatchedUids() async {
    if (_currentUid == null) return {};
    try {
      final snap = await _firestore
          .collection('matches')
          .where('users', arrayContains: _currentUid)
          .where('isActive', isEqualTo: true)
          .get();
      final uids = <String>{};
      for (final doc in snap.docs) {
        final users = List<String>.from(doc.data()['users'] ?? []);
        uids.addAll(users.where((u) => u != _currentUid));
      }
      return uids;
    } catch (_) {
      return {};
    }
  }

  Future<String?> _getConversationId(String otherUid) async {
    if (_currentUid == null) return null;
    try {
      final snap = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: _currentUid)
          .get();
      for (final doc in snap.docs) {
        final participants = List<String>.from(
          doc.data()['participants'] ?? [],
        );
        if (participants.contains(otherUid)) return doc.id;
      }
    } catch (_) {}
    return null;
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
        title: Column(
          children: [
            const Text(
              'Study Buddies',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              widget.subject,
              style: const TextStyle(color: AppColors.primary, fontSize: 13),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $_error', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadBuddies,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _buddies.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'No buddies found for this subject yet.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Try browsing all buddies from the main screen.',
                    style: TextStyle(color: AppColors.textLight),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              itemCount: _buddies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final buddy = _buddies[index];
                return _BuddyCard(
                  buddy: buddy,
                  isMatched: false, // will be computed below
                  onMessage: () async {
                    final convId = await _getConversationId(buddy.uid);
                    if (convId != null && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            conversationId: convId,
                            otherUser: buddy,
                          ),
                        ),
                      );
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'You need to match with this buddy first to message them.',
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}

class _BuddyCard extends StatelessWidget {
  final UserProfile buddy;
  final bool isMatched;
  final VoidCallback onMessage;

  const _BuddyCard({
    required this.buddy,
    required this.isMatched,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.backgroundLight,
            backgroundImage: buddy.photoUrl.isNotEmpty
                ? NetworkImage(buddy.photoUrl)
                : null,
            child: buddy.photoUrl.isEmpty
                ? Text(
                    buddy.fullName.isNotEmpty
                        ? buddy.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  buddy.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${buddy.track} • Grade ${buddy.gradeLevel}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (buddy.bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    buddy.bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (buddy.subjectsInterested.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: buddy.subjectsInterested.take(3).map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          s,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onMessage,
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.primary,
            ),
            tooltip: 'Message',
          ),
        ],
      ),
    );
  }
}
