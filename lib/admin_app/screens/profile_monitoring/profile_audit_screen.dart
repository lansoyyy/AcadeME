import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../user_management/user_detail_screen.dart';
import '../../services/admin_user_service.dart';

/// Profile Audit Screen
/// Monitor student profiles for completeness and inappropriate content
class ProfileAuditScreen extends StatefulWidget {
  const ProfileAuditScreen({super.key});

  @override
  State<ProfileAuditScreen> createState() => _ProfileAuditScreenState();
}

class _ProfileAuditScreenState extends State<ProfileAuditScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('All')),
              ButtonSegment(value: 'incomplete', label: Text('Incomplete')),
              ButtonSegment(value: 'flagged', label: Text('Flagged')),
            ],
            selected: {_selectedFilter},
            onSelectionChanged: (set) => setState(() => _selectedFilter = set.first),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var users = snapshot.data!.docs;

              if (_selectedFilter == 'incomplete') {
                users = users.where((u) => _isIncomplete(u.data() as Map<String, dynamic>)).toList();
              } else if (_selectedFilter == 'flagged') {
                users = users.where((u) => _hasInappropriateContent(u.data() as Map<String, dynamic>)).toList();
              }

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final data = user.data() as Map<String, dynamic>;
                  return _ProfileAuditTile(
                    uid: user.id,
                    data: data,
                    isIncomplete: _isIncomplete(data),
                    isFlagged: _hasInappropriateContent(data),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isIncomplete(Map<String, dynamic> data) {
    return (data['photoUrl'] ?? '').isEmpty ||
           (data['track'] ?? '').isEmpty ||
           (data['bio'] ?? '').isEmpty ||
           ((data['subjectsInterested'] as List?)?.isEmpty ?? true);
  }

  bool _hasInappropriateContent(Map<String, dynamic> data) {
    final name = (data['fullName'] ?? '').toString().toLowerCase();
    final bio = (data['bio'] ?? '').toString().toLowerCase();
    final flaggedWords = ['inappropriate', 'spam', 'fake', 'test', 'admin'];
    final hasWordFlag = flaggedWords.any((word) => name.contains(word) || bio.contains(word));
    final isExplicitlyFlagged = data['isFlagged'] == true;
    return hasWordFlag || isExplicitlyFlagged;
  }
}

class _ProfileAuditTile extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;
  final bool isIncomplete;
  final bool isFlagged;

  const _ProfileAuditTile({
    required this.uid,
    required this.data,
    required this.isIncomplete,
    required this.isFlagged,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['fullName'] ?? 'Unknown';
    final photoUrl = data['photoUrl'] ?? '';
    final isExplicitlyFlagged = data['isFlagged'] == true;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
        child: photoUrl.isEmpty ? Text(name[0].toUpperCase()) : null,
      ),
      title: Text(name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${data['track'] ?? 'No track'} • Grade ${data['gradeLevel'] ?? '?'}'),
          if (isIncomplete)
            const Text('⚠️ Incomplete profile', style: TextStyle(color: Colors.orange)),
          if (isFlagged)
            const Text('🚩 Flagged content', style: TextStyle(color: Colors.red)),
        ],
      ),
      isThreeLine: isIncomplete || isFlagged,
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) async {
          if (value == 'view') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UserDetailScreen(uid: uid)),
            );
          } else if (value == 'flag') {
            await _showFlagDialog(context);
          } else if (value == 'unflag') {
            await AdminUserService().unflagProfile(uid);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile unflagged')),
              );
            }
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'view', child: ListTile(leading: Icon(Icons.person), title: Text('View Full Profile'))),
          const PopupMenuItem(value: 'flag', child: ListTile(leading: Icon(Icons.flag, color: Colors.red), title: Text('Flag Profile'))),
          if (isExplicitlyFlagged)
            const PopupMenuItem(value: 'unflag', child: ListTile(leading: Icon(Icons.flag_outlined), title: Text('Remove Flag'))),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UserDetailScreen(uid: uid)),
        );
      },
    );
  }

  Future<void> _showFlagDialog(BuildContext context) async {
    String selectedField = 'bio';
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setst) => AlertDialog(
          title: const Text('Flag Profile Field'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedField,
                decoration: const InputDecoration(labelText: 'Field to flag'),
                items: const [
                  DropdownMenuItem(value: 'bio', child: Text('Bio')),
                  DropdownMenuItem(value: 'fullName', child: Text('Full Name')),
                  DropdownMenuItem(value: 'photoUrl', child: Text('Profile Photo')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setst(() => selectedField = v ?? 'bio'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Reason for flagging'),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Flag')),
          ],
        ),
      ),
    );
    if (confirmed == true && reasonCtrl.text.trim().isNotEmpty) {
      await AdminUserService().flagProfile(uid, selectedField, reasonCtrl.text.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile field "$selectedField" flagged')),
        );
      }
    }
  }
}
