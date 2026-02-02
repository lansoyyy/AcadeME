import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Ratings Overview Screen
/// View match/session ratings and identify high/low performers
class RatingsOverviewScreen extends StatefulWidget {
  const RatingsOverviewScreen({super.key});

  @override
  State<RatingsOverviewScreen> createState() => _RatingsOverviewScreenState();
}

class _RatingsOverviewScreenState extends State<RatingsOverviewScreen> {
  String _viewMode = 'overview';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'overview', label: Text('Overview')),
              ButtonSegment(value: 'top', label: Text('Top Rated')),
              ButtonSegment(value: 'flagged', label: Text('Flagged')),
            ],
            selected: {_viewMode},
            onSelectionChanged: (set) => setState(() => _viewMode = set.first),
          ),
        ),
        Expanded(
          child: _viewMode == 'overview'
              ? _buildOverview()
              : _viewMode == 'top'
                  ? _buildTopRated()
                  : _buildFlaggedUsers(),
        ),
      ],
    );
  }

  Widget _buildOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ratings').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final ratings = snapshot.data!.docs;
        final avgRating = ratings.isEmpty
            ? 0.0
            : ratings.map((r) => (r['rating'] as num?)?.toDouble() ?? 0).reduce((a, b) => a + b) / ratings.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _StatCard(
                title: 'Total Ratings',
                value: '${ratings.length}',
                icon: Icons.star,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),
              _StatCard(
                title: 'Average Rating',
                value: avgRating.toStringAsFixed(1),
                icon: Icons.trending_up,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              _buildRecentRatingsList(ratings.take(5).toList()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentRatingsList(List<QueryDocumentSnapshot> ratings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Ratings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...ratings.map((r) {
              final data = r.data() as Map<String, dynamic>;
              return ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    Text('${data['rating']}'),
                  ],
                ),
                title: Text('From: ${data['fromUid']}'),
                subtitle: Text('To: ${data['toUid']}'),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRated() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Calculate average rating per user (placeholder for future implementation)
        // final userRatings = <String, List<double>>{};

        // In real implementation, query ratings collection
        // For now, show placeholder
        return ListView.builder(
          itemCount: 10,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(child: Text('#${index + 1}')),
                title: Text('Top User ${index + 1}'),
                subtitle: const Text('⭐ 4.8 avg • 12 ratings'),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFlaggedUsers() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('warningsCount', isGreaterThan: 0)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;

        if (users.isEmpty) {
          return const Center(child: Text('No flagged users'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final data = user.data() as Map<String, dynamic>;
            final warnings = data['warningsCount'] ?? 0;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.warning, color: Colors.orange),
                title: Text(data['fullName'] ?? 'Unknown'),
                subtitle: Text('$warnings warnings'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: warnings >= 3 ? Colors.red : Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        warnings >= 3 ? 'HIGH RISK' : 'WARNING',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600])),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
