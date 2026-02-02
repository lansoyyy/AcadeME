import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Reports List Screen
/// View and manage user reports
class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  String _filter = 'open';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'open', label: Text('Open')),
              ButtonSegment(value: 'reviewing', label: Text('Reviewing')),
              ButtonSegment(value: 'resolved', label: Text('Resolved')),
            ],
            selected: {_filter},
            onSelectionChanged: (set) => setState(() => _filter = set.first),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reports')
                .where('status', isEqualTo: _filter)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final reports = snapshot.data!.docs;

              if (reports.isEmpty) {
                return Center(
                  child: Text(
                    'No $_filter reports',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              return ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return _ReportCard(report: report);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final QueryDocumentSnapshot report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final data = report.data() as Map<String, dynamic>;
    final reporterUid = data['reporterUid'] ?? 'Unknown';
    final reportedUid = data['reportedUid'] ?? 'Unknown';
    final reason = data['reason'] ?? 'No reason provided';
    final status = data['status'] ?? 'open';
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(createdAt?.toDate()),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Reporter: $reporterUid',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              'Reported: $reportedUid',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(reason),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'open')
                  TextButton(
                    onPressed: () => _updateStatus(context, 'reviewing'),
                    child: const Text('Start Review'),
                  ),
                if (status != 'resolved')
                  TextButton(
                    onPressed: () => _showActionDialog(context),
                    child: const Text('Take Action'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.red;
      case 'reviewing':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    await FirebaseFirestore.instance.collection('reports').doc(report.id).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report marked as $newStatus')),
      );
    }
  }

  Future<void> _showActionDialog(BuildContext context) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Take Action'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: const Text('Issue Warning'),
              onTap: () => Navigator.pop(context, 'warning'),
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Suspend User'),
              onTap: () => Navigator.pop(context, 'suspend'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Deactivate Account'),
              onTap: () => Navigator.pop(context, 'deactivate'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Dismiss Report'),
              onTap: () => Navigator.pop(context, 'dismiss'),
            ),
          ],
        ),
      ),
    );

    if (action != null) {
      await FirebaseFirestore.instance.collection('reports').doc(report.id).update({
        'status': 'resolved',
        'actionTaken': action,
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report resolved: $action')),
        );
      }
    }
  }
}
