import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../services/conversation_service.dart';
import '../services/user_profile_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import 'chat_screen.dart';

class MatchesListScreen extends StatefulWidget {
  const MatchesListScreen({super.key});

  @override
  State<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends State<MatchesListScreen> {
  final ConversationService _conversationService = ConversationService();
  final UserProfileService _profileService = UserProfileService();
  String? _currentUid;

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUid == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

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
          'Messages',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          StreamBuilder<int>(
            stream: _conversationService.streamTotalUnreadCount(_currentUid!),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return unreadCount > 0
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _conversationService.streamConversations(_currentUid!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversations = snapshot.data?.docs ?? [];

          if (conversations.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _buildConversationTile(conversation);
            },
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(DocumentSnapshot<Map<String, dynamic>> conversation) {
    final data = conversation.data()!;
    final otherUid = _conversationService.getOtherParticipantId(conversation, _currentUid!);
    final unreadCount = _conversationService.getUnreadCount(conversation, _currentUid!);
    final lastMessage = data['lastMessage'] as Map<String, dynamic>?;

    return FutureBuilder<UserProfile?>(
      future: _profileService.getProfile(otherUid ?? ''),
      builder: (context, snapshot) {
        final otherUser = snapshot.data;

        return ListTile(
          onTap: () => _openChat(conversation.id, otherUser),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 16,
          ),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.backgroundLight,
            backgroundImage: otherUser?.photoUrl.isNotEmpty == true
                ? NetworkImage(otherUser!.photoUrl)
                : null,
            child: otherUser?.photoUrl.isEmpty != false
                ? const Icon(Icons.person, color: AppColors.primary)
                : null,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  otherUser?.fullName ?? 'Loading...',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (lastMessage != null)
                Text(
                  _formatTimestamp(lastMessage['createdAt'] as Timestamp?),
                  style: TextStyle(
                    fontSize: 12,
                    color: unreadCount > 0 ? AppColors.primary : AppColors.textLight,
                  ),
                ),
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  lastMessage?['text'] ?? 'Start a conversation',
                  style: TextStyle(
                    fontSize: 14,
                    color: unreadCount > 0 ? Colors.black : AppColors.textSecondary,
                    fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: AppColors.textLight,
          ),
          const SizedBox(height: AppConstants.paddingL),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingM),
          Text(
            'Find a study buddy to start chatting!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingXL),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
            ),
            child: const Text('Find Study Buddy'),
          ),
        ],
      ),
    );
  }

  void _openChat(String conversationId, UserProfile? otherUser) {
    if (otherUser == null) return;

    // Mark as read when opening
    _conversationService.markAsRead(
      conversationId: conversationId,
      uid: _currentUid!,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversationId: conversationId,
          otherUser: otherUser,
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      // Today - show time
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
