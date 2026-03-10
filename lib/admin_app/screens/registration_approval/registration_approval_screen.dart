import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/notification_service.dart';

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

  Future<void> _updateStatus(
    String uid,
    String newStatus, {
    String? rejectionReason,
  }) async {
    final Map<String, dynamic> updates = {
      'accountStatus': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (rejectionReason != null) {
      updates['rejectionReason'] = rejectionReason;
    }
    if (newStatus != 'rejected') {
      // Clear old rejection reason when approving or moving back to pending;
      // use FieldValue.delete() to remove the field entirely.
      updates['rejectionReason'] = FieldValue.delete();
    }
    await _firestore.collection('users').doc(uid).update(updates);
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
    final rejectionReason = data['rejectionReason'] as String? ?? '';
    final isResubmission = data['resubmittedAt'] != null;
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
            ],            // Resubmission badge
            if (isResubmission && status == 'pending') ...[              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.withAlpha(100)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 14, color: Colors.blue),
                    SizedBox(width: 4),
                    Text(
                      'Resubmission',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Rejection reason (shown on rejected cards)
            if (status == 'rejected' && rejectionReason.isNotEmpty) ...[              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rejection reason:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rejectionReason,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],            const Divider(height: 24),
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
    // For rejections, first ask the admin to choose a reason
    if (action == 'reject') {
      final reason = await _showRejectionReasonDialog(name);
      if (reason == null) return; // admin cancelled
      try {
        await _updateStatus(uid, 'rejected', rejectionReason: reason);
        await NotificationService().notifyApproval(
          uid: uid,
          status: 'rejected',
          rejectionReason: reason,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name has been rejected.'),
              backgroundColor: Colors.red,
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
      return;
    }

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
        // Notify the user about the approve / revoke outcome
        if (action == 'approve') {
          await NotificationService().notifyApproval(
            uid: uid,
            status: 'approved',
          );
        }
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

  /// Shows a dialog for the admin to select the reason for rejecting a user.
  /// Returns the chosen reason string, or null if the admin cancelled.
  Future<String?> _showRejectionReasonDialog(String name) async {
    const predefinedReasons = [
      'Incomplete information',
      'Invalid school ID',
      'Age requirement not met',
      'Photo does not meet requirements',
      'Duplicate account detected',
      'Suspicious or false information',
      'Other',
    ];
    String? selectedReason;
    final customController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: Text('Reject $name'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select a reason for rejection:'),
                  const SizedBox(height: 8),
                  ...predefinedReasons.map(
                    (r) => RadioListTile<String>(
                      value: r,
                      groupValue: selectedReason,
                      dense: true,
                      title: Text(r),
                      onChanged: (v) => setInner(() => selectedReason = v),
                    ),
                  ),
                  if (selectedReason == 'Other') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: customController,
                      decoration: const InputDecoration(
                        labelText: 'Specify reason',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedReason == null
                  ? null
                  : () {
                      final reason =
                          selectedReason == 'Other' &&
                                  customController.text.trim().isNotEmpty
                              ? customController.text.trim()
                              : selectedReason!;
                      Navigator.pop(ctx, reason);
                    },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        ),
      ),
    );
    customController.dispose();
    return result;
  }
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
