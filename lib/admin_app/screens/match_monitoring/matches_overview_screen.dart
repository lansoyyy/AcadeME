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
                  ? _buildSwipeList(direction: 'like', label: 'Like')
                  : _buildSwipeList(direction: 'nope', label: 'Pass'),
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
        if (matches.isEmpty) {
          return const Center(
            child: Text('No active matches', style: TextStyle(color: Colors.grey)),
          );
        }
        return ListView.builder(
          itemCount: matches.length,
          itemBuilder: (context, index) =>
              _MatchCard(match: matches[index], showCancel: true),
        );
      },
    );
  }

  Widget _buildSwipeList({
    required String direction,
    required String label,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('swipes')
          .where('direction', isEqualTo: direction)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final swipes = snapshot.data!.docs;
        if (swipes.isEmpty) {
          return Center(
            child: Text(
              'No ${direction == 'like' ? 'pending' : 'declined'} swipes',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          itemCount: swipes.length,
          itemBuilder: (context, index) {
            final data = swipes[index].data() as Map<String, dynamic>;
            return _SwipeCard(
              fromUid: data['fromUid'] as String? ?? '',
              toUid: data['toUid'] as String? ?? '',
              label: label,
              date: (data['createdAt'] as Timestamp?)?.toDate(),
              isLike: direction == 'like',
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _SwipeCard — shows who liked / passed whom, resolving UIDs to display names
// ---------------------------------------------------------------------------
class _SwipeCard extends StatefulWidget {
  final String fromUid;
  final String toUid;
  final String label;
  final DateTime? date;
  final bool isLike;

  const _SwipeCard({
    required this.fromUid,
    required this.toUid,
    required this.label,
    this.date,
    required this.isLike,
  });

  @override
  State<_SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<_SwipeCard> {
  late Future<Map<String, String>> _namesFuture;

  @override
  void initState() {
    super.initState();
    _namesFuture = _fetchNames();
  }

  Future<Map<String, String>> _fetchNames() async {
    final result = <String, String>{};
    for (final uid in [widget.fromUid, widget.toUid]) {
      if (uid.isEmpty) continue;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      result[uid] =
          doc.data()?['fullName'] as String? ??
          uid.substring(0, uid.length.clamp(0, 8));
    }
    return result;
  }

  String _fmt(DateTime? d) =>
      d == null ? '' : '${d.month}/${d.day}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _namesFuture,
      builder: (context, snap) {
        final names = snap.data ?? {};
        final from = names[widget.fromUid] ??
            (widget.fromUid.isEmpty
                ? 'Unknown'
                : widget.fromUid.substring(0, widget.fromUid.length.clamp(0, 8)));
        final to = names[widget.toUid] ??
            (widget.toUid.isEmpty
                ? 'Unknown'
                : widget.toUid.substring(0, widget.toUid.length.clamp(0, 8)));

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(
              widget.isLike ? Icons.hourglass_empty : Icons.thumb_down,
              color: widget.isLike ? Colors.orange : Colors.red,
            ),
            title: Text('${widget.label} from $from'),
            subtitle: Text('To: $to'),
            trailing: Text(
              _fmt(widget.date),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _MatchCard — shows two matched users by name, with optional cancel action
// ---------------------------------------------------------------------------
class _MatchCard extends StatefulWidget {
  final QueryDocumentSnapshot match;
  final bool showCancel;

  const _MatchCard({required this.match, this.showCancel = false});

  @override
  State<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<_MatchCard> {
  late Future<List<String>> _namesFuture;

  @override
  void initState() {
    super.initState();
    final data = widget.match.data() as Map<String, dynamic>;
    final uids = List<String>.from(data['users'] ?? []);
    _namesFuture = _resolveNames(uids);
  }

  Future<List<String>> _resolveNames(List<String> uids) async {
    final names = <String>[];
    for (final uid in uids) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      names.add(
        doc.data()?['fullName'] as String? ??
            uid.substring(0, uid.length.clamp(0, 8)),
      );
    }
    return names;
  }

  String _fmt(DateTime? d) =>
      d == null ? 'Unknown' : '${d.month}/${d.day}/${d.year}';

  Future<void> _cancelMatch(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Match?'),
        content: const Text(
          'This will deactivate the match and prevent further messaging.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.match.id)
          .update({
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

  @override
  Widget build(BuildContext context) {
    final data = widget.match.data() as Map<String, dynamic>;
    final uids = List<String>.from(data['users'] ?? []);
    final createdAt = data['createdAt'] as Timestamp?;

    return FutureBuilder<List<String>>(
      future: _namesFuture,
      builder: (context, snap) {
        final names = snap.data ??
            uids.map((u) => u.substring(0, u.length.clamp(0, 8))).toList();

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
                        names.join(' ↔ '),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Matched on ${_fmt(createdAt?.toDate())}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                if (widget.showCancel) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _cancelMatch(context),
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      label: const Text(
                        'Cancel Match',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
