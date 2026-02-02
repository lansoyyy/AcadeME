import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Forum Overview Screen
/// Moderate forum posts and comments
class ForumOverviewScreen extends StatefulWidget {
  const ForumOverviewScreen({super.key});

  @override
  State<ForumOverviewScreen> createState() => _ForumOverviewScreenState();
}

class _ForumOverviewScreenState extends State<ForumOverviewScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('All')),
              ButtonSegment(value: 'hidden', label: Text('Hidden')),
              ButtonSegment(value: 'locked', label: Text('Locked')),
            ],
            selected: {_filter},
            onSelectionChanged: (set) => setState(() => _filter = set.first),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('forumPosts')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var posts = snapshot.data!.docs;

              if (_filter == 'hidden') {
                posts = posts.where((p) => (p['isHidden'] ?? false) == true).toList();
              } else if (_filter == 'locked') {
                posts = posts.where((p) => (p['isLocked'] ?? false) == true).toList();
              }

              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _ForumPostCard(post: post);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ForumPostCard extends StatelessWidget {
  final QueryDocumentSnapshot post;

  const _ForumPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final data = post.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Untitled';
    final body = data['body'] ?? '';
    final isHidden = data['isHidden'] ?? false;
    final isLocked = data['isLocked'] ?? false;
    final createdAt = data['createdAt'] as Timestamp?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isHidden)
                  const Chip(label: Text('Hidden'), visualDensity: VisualDensity.compact, backgroundColor: Colors.red),
                if (isLocked)
                  const Chip(label: Text('Locked'), visualDensity: VisualDensity.compact, backgroundColor: Colors.orange),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              body.length > 150 ? '${body.substring(0, 150)}...' : body,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  createdAt != null ? _formatDate(createdAt.toDate()) : 'Unknown date',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _toggleHide(context),
                      icon: Icon(isHidden ? Icons.visibility : Icons.visibility_off),
                      label: Text(isHidden ? 'Unhide' : 'Hide'),
                    ),
                    TextButton.icon(
                      onPressed: () => _toggleLock(context),
                      icon: Icon(isLocked ? Icons.lock_open : Icons.lock),
                      label: Text(isLocked ? 'Unlock' : 'Lock'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _toggleHide(BuildContext context) async {
    final data = post.data() as Map<String, dynamic>;
    final isHidden = data['isHidden'] ?? false;
    
    await FirebaseFirestore.instance.collection('forumPosts').doc(post.id).update({
      'isHidden': !isHidden,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isHidden ? 'Post unhidden' : 'Post hidden')),
    );
  }

  Future<void> _toggleLock(BuildContext context) async {
    final data = post.data() as Map<String, dynamic>;
    final isLocked = data['isLocked'] ?? false;
    
    await FirebaseFirestore.instance.collection('forumPosts').doc(post.id).update({
      'isLocked': !isLocked,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isLocked ? 'Post unlocked' : 'Post locked')),
    );
  }
}
