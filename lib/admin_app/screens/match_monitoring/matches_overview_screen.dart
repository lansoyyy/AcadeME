import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Matches Overview Screen
/// Monitor active, pending, and declined matches
class MatchesOverviewScreen extends StatefulWidget {
  const MatchesOverviewScreen({super.key});

  @override
  State<MatchesOverviewScreen> createState() => _MatchesOverviewScreenState();
}

class _MatchesOverviewScreenState extends State<MatchesOverviewScreen> {
  String _filter = 'active';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'active', label: Text('Active')),
              ButtonSegment(value: 'pending', label: Text('Pending')),
              ButtonSegment(value: 'declined', label: Text('Declined')),
            ],
            selected: {_filter},
            onSelectionChanged: (set) => setState(() => _filter = set.first),
          ),
        ),
        Expanded(
          child: _filter == 'active'
              ? _buildActiveMatches()
              : _filter == 'pending'
                  ? _buildPendingMatches()
                  : _buildDeclinedMatches(),
        ),
      ],
    );
  }

  Widget _buildActiveMatches() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final matches = snapshot.data!.docs;

        return ListView.builder(
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            return _MatchCard(match: match, showCancel: true);
          },
        );
      },
    );
  }

  Widget _buildPendingMatches() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('swipes')
          .where('direction', isEqualTo: 'like')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final swipes = snapshot.data!.docs;
        
        return ListView.builder(
          itemCount: swipes.length,
          itemBuilder: (context, index) {
            final swipe = swipes[index];
            final data = swipe.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.hourglass_empty, color: Colors.orange),
                title: Text('Like from ${data['fromUid'] ?? 'Unknown'}'),
                subtitle: Text('To: ${data['toUid'] ?? 'Unknown'}'),
                trailing: Text(_formatDate((data['createdAt'] as Timestamp?)?.toDate())),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDeclinedMatches() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('swipes')
          .where('direction', isEqualTo: 'nope')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final swipes = snapshot.data!.docs;
        
        return ListView.builder(
          itemCount: swipes.length,
          itemBuilder: (context, index) {
            final swipe = swipes[index];
            final data = swipe.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.thumb_down, color: Colors.red),
                title: Text('Pass from ${data['fromUid'] ?? 'Unknown'}'),
                subtitle: Text('To: ${data['toUid'] ?? 'Unknown'}'),
                trailing: Text(_formatDate((data['createdAt'] as Timestamp?)?.toDate())),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _MatchCard extends StatelessWidget {
  final QueryDocumentSnapshot match;
  final bool showCancel;

  const _MatchCard({required this.match, this.showCancel = false});

  @override
  Widget build(BuildContext context) {
    final data = match.data() as Map<String, dynamic>;
    final users = List<String>.from(data['users'] ?? []);
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
                const Icon(Icons.favorite, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Match: ${users.join(' ↔ ')}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Created: ${_formatDate(createdAt?.toDate())}'),
            if (showCancel) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _cancelMatch(context),
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text('Cancel Match', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _cancelMatch(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Match?'),
        content: const Text('This will deactivate the match and prevent further messaging.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('matches').doc(match.id).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match cancelled')),
        );
      }
    }
  }
}
