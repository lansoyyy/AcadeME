import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

/// Screen shown to users whose registration is pending or has been rejected.
class PendingApprovalScreen extends StatefulWidget {
  final String status; // 'pending' or 'rejected'

  const PendingApprovalScreen({super.key, this.status = 'pending'});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _isResubmitting = false;

  Future<void> _resubmit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _isResubmitting = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'accountStatus': 'pending',
        'resubmittedAt': FieldValue.serverTimestamp(),
        'rejectionReason': FieldValue.delete(),
      });
      // auth_gate will automatically redirect once accountStatus changes
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error resubmitting: $e')));
      }
    } finally {
      if (mounted) setState(() => _isResubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = widget.status == 'rejected';
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (isRejected && uid != null) {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          final d = snapshot.data?.data();
          final reason = d?['rejectionReason'] as String?;
          return _buildBody(context, isRejected: true, rejectionReason: reason);
        },
      );
    }

    return _buildBody(context, isRejected: isRejected, rejectionReason: null);
  }

  Widget _buildBody(
    BuildContext context, {
    required bool isRejected,
    String? rejectionReason,
  }) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: isRejected
                      ? Colors.red.withAlpha(25)
                      : AppColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRejected ? Icons.cancel_outlined : Icons.hourglass_top,
                  size: 64,
                  color: isRejected ? Colors.red : AppColors.primary,
                ),
              ),
              const SizedBox(height: AppConstants.paddingXL),
              Text(
                isRejected ? 'Registration Rejected' : 'Pending Approval',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),
              Text(
                isRejected
                    ? 'Your registration was rejected. Review the reason below, make the necessary corrections, then resubmit.'
                    : 'Your registration is being reviewed by the admin. You will be able to access the app once approved.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              // Show rejection reason if available
              if (isRejected && rejectionReason != null &&
                  rejectionReason.isNotEmpty) ...[
                const SizedBox(height: AppConstants.paddingL),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(15),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusM),
                    border: Border.all(color: Colors.red.withAlpha(80)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reason for rejection:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rejectionReason,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppConstants.paddingXL),
              // Resubmit button (only for rejected users)
              if (isRejected) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isResubmitting ? null : _resubmit,
                    icon: _isResubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(
                      _isResubmitting
                          ? 'Resubmitting...'
                          : 'Resubmit for Approval',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusM),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusM),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

