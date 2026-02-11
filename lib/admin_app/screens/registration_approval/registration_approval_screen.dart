import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin screen to review and approve/reject student registrations
class RegistrationApprovalScreen extends StatefulWidget {
  const RegistrationApprovalScreen({super.key});

  @override
  State<RegistrationApprovalScreen> createState() =>
      _RegistrationApprovalScreenState();
}

class _RegistrationApprovalScreenState extends State<RegistrationApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _streamByStatus(String status) {
    return _firestore
        .collection('users')
        .where('accountStatus', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _updateStatus(String uid, String newStatus) async {
    await _firestore.collection('users').doc(uid).update({
      'accountStatus': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildList('pending'),
              _buildList('approved'),
              _buildList('rejected'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(String status) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _streamByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'pending'
                      ? Icons.hourglass_empty
                      : status == 'approved'
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No $status registrations',
                  style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            return _buildUserCard(doc.id, data, status);
          },
        );
      },
    );
  }

  Widget _buildUserCard(String uid, Map<String, dynamic> data, String status) {
    final fullName = data['fullName'] as String? ?? 'Unknown';
    final studentId = data['studentId'] as String? ?? '';
    final photoUrl = data['photoUrl'] as String? ?? '';
    final track = data['track'] as String? ?? '';
    final gradeLevel = data['gradeLevel'] ?? '';
    final birthday = data['birthday'] as String? ?? '';
    final age = data['age'] ?? '';
    final bio = data['bio'] as String? ?? '';
    final createdAt = data['createdAt'];
    String dateStr = '';
    if (createdAt is Timestamp) {
      final d = createdAt.toDate();
      dateStr = '${d.month}/${d.day}/${d.year}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile photo
                GestureDetector(
                  onTap: photoUrl.isNotEmpty
                      ? () => _showFullImage(context, photoUrl)
                      : null,
                  child: CircleAvatar(
                    radius: 32,
                    backgroundImage: photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl.isEmpty
                        ? const Icon(Icons.person, size: 32)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (studentId.isNotEmpty)
                        Text(
                          'ID: $studentId',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      if (track.isNotEmpty)
                        Text(
                          '$track • Grade $gradeLevel',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
              ],
            ),
            if (birthday.isNotEmpty || age.toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Birthday: $birthday  •  Age: $age',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                bio,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (photoUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.face, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Face-verified photo',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'pending') ...[
                  OutlinedButton.icon(
                    onPressed: () => _confirmAction(
                      uid: uid,
                      name: fullName,
                      action: 'reject',
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _confirmAction(
                      uid: uid,
                      name: fullName,
                      action: 'approve',
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
                if (status == 'approved')
                  OutlinedButton.icon(
                    onPressed: () => _confirmAction(
                      uid: uid,
                      name: fullName,
                      action: 'revoke',
                    ),
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('Revoke Approval'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                if (status == 'rejected') ...[
                  FilledButton.icon(
                    onPressed: () => _confirmAction(
                      uid: uid,
                      name: fullName,
                      action: 'approve',
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAction({
    required String uid,
    required String name,
    required String action,
  }) async {
    final String title;
    final String content;
    final String newStatus;
    final Color buttonColor;

    switch (action) {
      case 'approve':
        title = 'Approve Registration';
        content =
            'Are you sure you want to approve $name\'s registration? They will be able to log in and use the app.';
        newStatus = 'approved';
        buttonColor = Colors.green;
        break;
      case 'reject':
        title = 'Reject Registration';
        content =
            'Are you sure you want to reject $name\'s registration? They will not be able to access the app.';
        newStatus = 'rejected';
        buttonColor = Colors.red;
        break;
      case 'revoke':
        title = 'Revoke Approval';
        content =
            'Are you sure you want to revoke $name\'s approval? They will be moved back to pending status.';
        newStatus = 'pending';
        buttonColor = Colors.orange;
        break;
      default:
        return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: buttonColor),
            child: Text(action == 'revoke' ? 'Revoke' : action.capitalize()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _updateStatus(uid, newStatus);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$name has been ${action == 'revoke' ? 'moved to pending' : '${action}d'}.',
              ),
              backgroundColor: buttonColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
