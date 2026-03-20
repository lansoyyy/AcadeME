import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/admin_moderation_service.dart';

class StudyGroupsModerationScreen extends StatefulWidget {
  const StudyGroupsModerationScreen({super.key});

  @override
  State<StudyGroupsModerationScreen> createState() =>
      _StudyGroupsModerationScreenState();
}

class _StudyGroupsModerationScreenState
    extends State<StudyGroupsModerationScreen> {
  final AdminModerationService _moderationService = AdminModerationService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _statusFilter = 'active';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _moderationService.streamStudyGroups(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final groups = snapshot.data!.docs.toList()
                ..sort((a, b) {
                  final aDate =
                      (a.data()['updatedAt'] ?? a.data()['createdAt'])
                          as Timestamp?;
                  final bDate =
                      (b.data()['updatedAt'] ?? b.data()['createdAt'])
                          as Timestamp?;
                  if (aDate == null && bDate == null) return 0;
                  if (aDate == null) return 1;
                  if (bDate == null) return -1;
                  return bDate.compareTo(aDate);
                });

              final filtered = groups.where(_matchesFilters).toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: Text('No study groups match the current filters.'),
                );
              }

              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final groupDoc = filtered[index];
                  return _StudyGroupTile(
                    groupDoc: groupDoc,
                    onTakeDown: () => _handleTakeDown(groupDoc),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by group name, subject, or owner UID',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase();
              });
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(value: 'active', label: Text('Active')),
                ButtonSegment<String>(
                  value: 'taken_down',
                  label: Text('Taken Down'),
                ),
                ButtonSegment<String>(value: 'all', label: Text('All')),
              ],
              selected: {_statusFilter},
              onSelectionChanged: (selection) {
                setState(() {
                  _statusFilter = selection.first;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesFilters(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final isActive = data['isActive'] != false;

    if (_statusFilter == 'active' && !isActive) {
      return false;
    }
    if (_statusFilter == 'taken_down' && isActive) {
      return false;
    }

    if (_searchQuery.isEmpty) {
      return true;
    }

    final haystack = [
      data['name'],
      data['subject'],
      data['description'],
      data['ownerUid'],
    ].join(' ').toLowerCase();

    return haystack.contains(_searchQuery);
  }

  Future<void> _handleTakeDown(
    QueryDocumentSnapshot<Map<String, dynamic>> groupDoc,
  ) async {
    final data = groupDoc.data();
    if (data['isActive'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This study group is already inactive.')),
      );
      return;
    }

    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Take Down Study Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Remove "${data['name'] ?? 'Untitled Group'}" from the app for all members.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Required moderator note',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Take Down'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      reasonController.dispose();
      return;
    }

    try {
      final result = await _moderationService.takeDownStudyGroup(
        groupId: groupDoc.id,
        reason: reasonController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take down group: $error')),
      );
    } finally {
      reasonController.dispose();
    }
  }
}

class _StudyGroupTile extends StatelessWidget {
  const _StudyGroupTile({required this.groupDoc, required this.onTakeDown});

  final QueryDocumentSnapshot<Map<String, dynamic>> groupDoc;
  final VoidCallback onTakeDown;

  @override
  Widget build(BuildContext context) {
    final data = groupDoc.data();
    final isActive = data['isActive'] != false;
    final groupName = data['name'] as String? ?? 'Untitled Group';
    final subject = data['subject'] as String? ?? 'No subject';
    final ownerUid = data['ownerUid'] as String? ?? 'Unknown';
    final memberCount = data['memberCount'] as int? ?? 0;
    final maxMembers = data['maxMembers'] as int? ?? 0;
    final takedownReason = data['takedownReason'] as String?;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: isActive ? Colors.blue[50] : Colors.red[50],
        child: Icon(
          Icons.groups,
          color: isActive ? Colors.blue[700] : Colors.red[700],
        ),
      ),
      title: Row(
        children: [
          Expanded(child: Text(groupName)),
          _StatusChip(isActive: isActive),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('$subject • $memberCount/$maxMembers members'),
          const SizedBox(height: 4),
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(ownerUid)
                .get(),
            builder: (context, snapshot) {
              final ownerName = snapshot.data?.data()?['fullName'] as String?;
              if (ownerName == null || ownerName.isEmpty) {
                return Text('Owner UID: $ownerUid');
              }
              return Text('Owner: $ownerName ($ownerUid)');
            },
          ),
          if (!isActive && takedownReason != null && takedownReason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Reason: $takedownReason',
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
        ],
      ),
      trailing: isActive
          ? FilledButton.tonalIcon(
              onPressed: onTakeDown,
              icon: const Icon(Icons.gpp_bad),
              label: const Text('Take Down'),
              style: FilledButton.styleFrom(foregroundColor: Colors.red),
            )
          : const Icon(Icons.check_circle, color: Colors.grey),
      isThreeLine: true,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(isActive ? 'Active' : 'Taken Down'),
      visualDensity: VisualDensity.compact,
      backgroundColor: isActive ? Colors.green[50] : Colors.red[50],
      labelStyle: TextStyle(
        color: isActive ? Colors.green[800] : Colors.red[800],
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
