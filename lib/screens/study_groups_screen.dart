import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../services/study_group_service.dart';
import '../services/user_profile_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class StudyGroupsScreen extends StatefulWidget {
  const StudyGroupsScreen({super.key});

  @override
  State<StudyGroupsScreen> createState() => _StudyGroupsScreenState();
}

class _StudyGroupsScreenState extends State<StudyGroupsScreen>
    with SingleTickerProviderStateMixin {
  final StudyGroupService _groupService = StudyGroupService();
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateGroupDialog() {
    final nameCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Study Group'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Group Name *',
                  hintText: 'e.g. STEM Calculus Squad',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subjectCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subject *',
                  hintText: 'e.g. Basic Calculus',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'What is this group about?',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty ||
                  subjectCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Name and subject are required'),
                  ),
                );
                return;
              }
              try {
                await _groupService.createGroup(
                  name: nameCtrl.text.trim(),
                  subject: subjectCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group created!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
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
          'Study Groups',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'My Groups'),
            Tab(text: 'Browse'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMyGroupsTab(), _buildBrowseTab()],
      ),
    );
  }

  Widget _buildMyGroupsTab() {
    return StreamBuilder<List<StudyGroup>>(
      stream: _groupService.streamMyGroups(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = snapshot.data ?? [];
        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'No groups yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create a group or browse to join one!',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            return _buildGroupCard(groups[index], isMember: true);
          },
        );
      },
    );
  }

  Widget _buildBrowseTab() {
    return StreamBuilder<List<StudyGroup>>(
      stream: _groupService.streamAllGroups(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = snapshot.data ?? [];
        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'No groups available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Be the first to create one!',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final isMember = group.members.contains(_currentUid);
            return _buildGroupCard(group, isMember: isMember);
          },
        );
      },
    );
  }

  Widget _buildGroupCard(StudyGroup group, {required bool isMember}) {
    final isOwner = group.ownerUid == _currentUid;

    return GestureDetector(
      onTap: isMember
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupDetailScreen(group: group),
                ),
              );
            }
          : null,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withAlpha(30),
                  child: const Icon(Icons.groups, color: AppColors.primary),
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
                              group.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (isOwner)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Owner',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        group.subject,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (group.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                group.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${group.memberCount}/${group.maxMembers} members',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (!isMember && !group.isFull)
                  TextButton(
                    onPressed: () async {
                      try {
                        await _groupService.joinGroup(group.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Joined ${group.name}!')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('$e')));
                        }
                      }
                    },
                    child: const Text('Join'),
                  ),
                if (!isMember && group.isFull)
                  const Text(
                    'Full',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (isMember && !isOwner)
                  TextButton(
                    onPressed: () async {
                      try {
                        await _groupService.leaveGroup(group.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Left ${group.name}')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('$e')));
                        }
                      }
                    },
                    child: const Text(
                      'Leave',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                if (isOwner)
                  TextButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Group?'),
                          content: const Text(
                            'This will remove the group for all members.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await _groupService.deleteGroup(group.id);
                      }
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Group detail screen with chat and member list
class GroupDetailScreen extends StatefulWidget {
  final StudyGroup group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final StudyGroupService _groupService = StudyGroupService();
  final UserProfileService _profileService = UserProfileService();
  final TextEditingController _messageCtrl = TextEditingController();
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    _messageCtrl.clear();
    try {
      await _groupService.sendGroupMessage(
        groupId: widget.group.id,
        text: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    }
  }

  void _showMembers() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Members (${widget.group.memberCount})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...widget.group.members.map((uid) {
              return FutureBuilder<UserProfile?>(
                future: _profileService.getProfile(uid),
                builder: (context, snap) {
                  final profile = snap.data;
                  final isOwner = uid == widget.group.ownerUid;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profile?.photoUrl.isNotEmpty == true
                          ? NetworkImage(profile!.photoUrl)
                          : null,
                      child: profile?.photoUrl.isEmpty != false
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(profile?.fullName ?? 'Loading...'),
                    subtitle: Text(isOwner ? 'Owner' : 'Member'),
                    trailing: isOwner
                        ? const Icon(Icons.star, color: Colors.amber, size: 20)
                        : null,
                  );
                },
              );
            }),
            const SizedBox(height: 16),
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
        title: Column(
          children: [
            Text(
              widget.group.name,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '${widget.group.memberCount} members • ${widget.group.subject}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.people, color: Colors.black),
            onPressed: _showMembers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _groupService.streamGroupMessages(widget.group.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet\nSay hello!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data();
                    final senderUid = msg['senderUid'] as String? ?? '';
                    final text = msg['text'] as String? ?? '';
                    final isMe = senderUid == _currentUid;

                    return _buildMessageBubble(senderUid, text, isMe);
                  },
                );
              },
            ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingM,
              vertical: AppConstants.paddingS,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(25),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageCtrl,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.backgroundLight,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String senderUid, String text, bool isMe) {
    return FutureBuilder<UserProfile?>(
      future: _profileService.getProfile(senderUid),
      builder: (context, snap) {
        final senderName = snap.data?.fullName ?? '...';

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
