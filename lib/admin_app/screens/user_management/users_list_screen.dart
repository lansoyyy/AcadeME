import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/admin_user_service.dart';
import 'user_detail_screen.dart';

/// Users List Screen - User Management
/// View all registered students with search and filters
class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final AdminUserService _userService = AdminUserService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterGradeLevel;
  String? _filterTrack;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter Bar
        _buildFilterBar(),
        const Divider(height: 1),
        // Users List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _userService.streamUsers(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var users = snapshot.data!.docs;

              // Apply filters
              users = _applyFilters(users);

              if (users.isEmpty) {
                return const Center(
                  child: Text('No users found matching your criteria'),
                );
              }

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _UserListTile(
                    userDoc: user,
                    onTap: () => _navigateToUserDetail(user.id),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterGradeLevel ?? 'All',
                  decoration: InputDecoration(
                    labelText: 'Grade',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: const ['All', '11', '12'].map((item) {
                    return DropdownMenuItem(value: item, child: Text(item));
                  }).toList(),
                  onChanged: (value) => setState(() => _filterGradeLevel = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterTrack ?? 'All',
                  decoration: InputDecoration(
                    labelText: 'Track',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: const ['All', 'STEM', 'ABM', 'HUMSS', 'TVL'].map((item) {
                    return DropdownMenuItem(value: item, child: Text(item));
                  }).toList(),
                  onChanged: (value) => setState(() => _filterTrack = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot> _applyFilters(List<QueryDocumentSnapshot> users) {
    return users.where((user) {
      final data = user.data() as Map<String, dynamic>;

      if (_searchQuery.isNotEmpty) {
        final name = (data['fullName'] ?? '').toString().toLowerCase();
        if (!name.contains(_searchQuery)) return false;
      }

      if (_filterGradeLevel != null && _filterGradeLevel != 'All') {
        final grade = data['gradeLevel']?.toString();
        if (grade != _filterGradeLevel) return false;
      }

      if (_filterTrack != null && _filterTrack != 'All') {
        final track = data['track']?.toString();
        if (track != _filterTrack) return false;
      }

      return true;
    }).toList();
  }

  void _navigateToUserDetail(String uid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(uid: uid),
      ),
    );
  }
}

class _UserListTile extends StatelessWidget {
  final QueryDocumentSnapshot userDoc;
  final VoidCallback onTap;

  const _UserListTile({
    required this.userDoc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = userDoc.data() as Map<String, dynamic>;
    final name = data['fullName'] ?? 'Unknown';
    final photoUrl = data['photoUrl'] ?? '';
    final track = data['track'] ?? 'N/A';
    final gradeLevel = data['gradeLevel']?.toString() ?? 'N/A';
    final isActive = data['isActive'] ?? true;
    final subjects = (data['subjectsInterested'] as List?)?.length ?? 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
        child: photoUrl.isEmpty ? Text(name[0].toUpperCase()) : null,
      ),
      title: Text(name),
      subtitle: Text('$track • Grade $gradeLevel • $subjects subjects'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}
