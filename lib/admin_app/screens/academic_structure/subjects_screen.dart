import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Subjects Screen - Academic Structure Management
/// Manage subjects, strands, and grade levels
class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  String _selectedTab = 'subjects';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'subjects', label: Text('Subjects')),
              ButtonSegment(value: 'strands', label: Text('Strands')),
              ButtonSegment(value: 'grades', label: Text('Grades')),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (set) => setState(() => _selectedTab = set.first),
          ),
        ),
        Expanded(
          child: _selectedTab == 'subjects'
              ? _buildSubjectsTab()
              : _selectedTab == 'strands'
                  ? _buildStrandsTab()
                  : _buildGradesTab(),
        ),
      ],
    );
  }

  Widget _buildSubjectsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('academic/subjects')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        return _buildAcademicList(
          snapshot: snapshot,
          title: 'Subjects',
          onAdd: () => _showAddDialog('subject'),
          onToggle: (id, isActive) => _toggleAcademicItem('subjects', id, isActive),
        );
      },
    );
  }

  Widget _buildStrandsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('academic/strands')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        return _buildAcademicList(
          snapshot: snapshot,
          title: 'Strands',
          onAdd: () => _showAddDialog('strand'),
          onToggle: (id, isActive) => _toggleAcademicItem('strands', id, isActive),
        );
      },
    );
  }

  Widget _buildGradesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('academic/gradeLevels')
          .orderBy('value')
          .snapshots(),
      builder: (context, snapshot) {
        return _buildAcademicList(
          snapshot: snapshot,
          title: 'Grade Levels',
          onAdd: () => _showAddDialog('grade'),
          onToggle: (id, isActive) => _toggleAcademicItem('gradeLevels', id, isActive),
        );
      },
    );
  }

  Widget _buildAcademicList({
    required AsyncSnapshot<QuerySnapshot> snapshot,
    required String title,
    required VoidCallback onAdd,
    required Function(String, bool) onToggle,
  }) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = snapshot.data!.docs;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$title (${items.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final data = item.data() as Map<String, dynamic>;
              final name = data['name'] ?? data['value']?.toString() ?? 'Unnamed';
              final isActive = data['isActive'] ?? true;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(name),
                  trailing: Switch(
                    value: isActive,
                    onChanged: (value) => onToggle(item.id, value),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showAddDialog(String type) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${type.capitalize()}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: type == 'grade' ? 'Grade Level (11 or 12)' : 'Name',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final collection = type == 'subject'
          ? 'academic/subjects'
          : type == 'strand'
              ? 'academic/strands'
              : 'academic/gradeLevels';

      await FirebaseFirestore.instance.collection(collection).add({
        type == 'grade' ? 'value' : 'name': result,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${type.capitalize()} added successfully')),
        );
      }
    }
  }

  Future<void> _toggleAcademicItem(String collection, String id, bool isActive) async {
    await FirebaseFirestore.instance
        .collection('academic/$collection')
        .doc(id)
        .update({'isActive': isActive});
  }
}

extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }
}
