import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
    return flaggedWords.any((word) => name.contains(word) || bio.contains(word));
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
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
