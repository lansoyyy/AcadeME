import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/admin_user_service.dart';

/// User Detail Screen
/// Shows full user profile and admin actions
class UserDetailScreen extends StatefulWidget {
  final String uid;

  const UserDetailScreen({super.key, required this.uid});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final AdminUserService _userService = AdminUserService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
      ),
      body: FutureBuilder<DocumentSnapshot?>(
        future: _userService.getUser(widget.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('User not found'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                _buildProfileHeader(userData),
                const SizedBox(height: 24),
                // Account Status
                _buildStatusCard(userData),
                const SizedBox(height: 24),
                // Profile Info
                _buildInfoSection(userData),
                const SizedBox(height: 24),
                // Admin Actions
                _buildActionsSection(userData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> data) {
    final name = data['fullName'] ?? 'Unknown';
    final photoUrl = data['photoUrl'] ?? '';
    final track = data['track'] ?? 'N/A';

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty ? Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 32)) : null,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            track,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Map<String, dynamic> data) {
    final isActive = data['isActive'] ?? true;
    final suspendedUntil = data['suspendedUntil'] as Timestamp?;
    final warningsCount = data['warningsCount'] ?? 0;

    final isSuspended = suspendedUntil != null && suspendedUntil.toDate().isAfter(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account Status', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isActive && !isSuspended ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isSuspended ? 'Suspended' : (isActive ? 'Active' : 'Deactivated'),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (isSuspended) ...[
              const SizedBox(height: 8),
              Text(
                'Until: ${suspendedUntil.toDate()}',
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
            const SizedBox(height: 12),
            Text('Warnings: $warningsCount', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile Information', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow('Student ID', data['studentId'] ?? 'N/A'),
            _buildInfoRow('Grade Level', 'Grade ${data['gradeLevel'] ?? 'N/A'}'),
            _buildInfoRow('Age', '${data['age'] ?? 'N/A'}'),
            _buildInfoRow('Birthday', data['birthday'] ?? 'N/A'),
            const Divider(),
            _buildInfoRow('Bio', data['bio'] ?? 'No bio'),
            const SizedBox(height: 12),
            Text('Subjects Interested:', style: const TextStyle(fontWeight: FontWeight.w500)),
            Wrap(
              spacing: 8,
              children: ((data['subjectsInterested'] as List?) ?? []).map((s) {
                return Chip(label: Text(s.toString()), visualDensity: VisualDensity.compact);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(color: Colors.grey[600]))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildActionsSection(Map<String, dynamic> data) {
    final isActive = data['isActive'] ?? true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _toggleActivation(!isActive),
                  icon: Icon(isActive ? Icons.block : Icons.check_circle),
                  label: Text(isActive ? 'Deactivate' : 'Activate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showSuspendDialog(),
                  icon: const Icon(Icons.timer_off),
                  label: const Text('Suspend'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showWarningDialog(),
                  icon: const Icon(Icons.warning),
                  label: const Text('Issue Warning'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _resetPassword(data['email'] ?? ''),
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Reset Password'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActivation(bool activate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activate ? 'Activate Account?' : 'Deactivate Account?'),
        content: Text(activate
            ? 'This user will be able to access the app again.'
            : 'This user will be blocked from accessing the app.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed == true) {
      await _userService.updateUserStatus(widget.uid, activate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(activate ? 'Account activated' : 'Account deactivated')),
        );
        setState(() {});
      }
    }
  }

  Future<void> _showSuspendDialog() async {
    final days = await showDialog<int>(
      context: context,
      builder: (context) {
        int selectedDays = 7;
        return AlertDialog(
          title: const Text('Suspend Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select suspension duration:'),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedDays,
                items: [1, 3, 7, 14, 30].map((d) {
                  return DropdownMenuItem(value: d, child: Text('$d days'));
                }).toList(),
                onChanged: (v) => selectedDays = v ?? 7,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, selectedDays), child: const Text('Suspend')),
          ],
        );
      },
    );

    if (days != null) {
      final until = DateTime.now().add(Duration(days: days));
      await _userService.suspendUser(widget.uid, until);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account suspended for $days days')),
        );
        setState(() {});
      }
    }
  }

  Future<void> _showWarningDialog() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Issue Warning'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Warning reason'),
            maxLines: 3,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Issue'),
            ),
          ],
        );
      },
    );

    if (reason != null && reason.isNotEmpty) {
      await _userService.addWarning(widget.uid, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Warning issued')),
        );
        setState(() {});
      }
    }
  }

  Future<void> _resetPassword(String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email available for this user')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password?'),
        content: Text('Send password reset email to $email?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send')),
        ],
      ),
    );

    if (confirmed == true) {
      await _userService.sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')),
        );
      }
    }
  }
}
