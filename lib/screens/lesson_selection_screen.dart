import 'package:flutter/material.dart';
import '../screens/study_groups_screen.dart';
import '../services/academic_data_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class LessonSelectionScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const LessonSelectionScreen({super.key, this.onBack});

  @override
  State<LessonSelectionScreen> createState() => _LessonSelectionScreenState();
}

class _LessonSelectionScreenState extends State<LessonSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AcademicDataService _academicService = AcademicDataService();

  String _selectedCode = '';
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    try {
      final subjects = await _academicService.getSubjects();
      setState(() {
        // Use Firestore data if available, otherwise fallback to defaults
        _subjects = subjects.isNotEmpty
            ? subjects
            : [
                {'code': 'OC', 'name': 'Oral Communication', 'type': 'Core'},
                {'code': 'GM', 'name': 'General Mathematics', 'type': 'Core'},
                {'code': 'EAP', 'name': 'English for Academic', 'type': 'Core'},
                {'code': 'FIL', 'name': 'Filipino', 'type': 'Core'},
                {
                  'code': '21LIT',
                  'name': '21st Century Literature',
                  'type': 'Core',
                },
                {'code': 'CA', 'name': 'Contemporary Arts', 'type': 'Core'},
                {
                  'code': 'MIL',
                  'name': 'Media and Information Literacy',
                  'type': 'Core',
                },
                {'code': 'PE', 'name': 'Physical Education', 'type': 'Core'},
                {'code': 'ES', 'name': 'Earth Science', 'type': 'Core'},
                {'code': 'CHEM', 'name': 'General Chemistry', 'type': 'Core'},
                {'code': 'CALC', 'name': 'Basic Calculus', 'type': 'Core'},
                {'code': 'PHY', 'name': 'Physics', 'type': 'Core'},
                {
                  'code': 'ABM1',
                  'name': 'Applied Economics',
                  'type': 'Applied',
                },
                {'code': 'ABM2', 'name': 'Business Math', 'type': 'Applied'},
                {
                  'code': 'STEM1',
                  'name': 'Pre-Calculus',
                  'type': 'Specialized',
                },
                {'code': 'HUMSS1', 'name': 'Philosophy', 'type': 'Specialized'},
              ];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading subjects: $e');
      // Use fallback data on error
      setState(() {
        _subjects = [
          {'code': 'OC', 'name': 'Oral Communication', 'type': 'Core'},
          {'code': 'GM', 'name': 'General Mathematics', 'type': 'Core'},
          {'code': 'EAP', 'name': 'English for Academic', 'type': 'Core'},
          {'code': 'FIL', 'name': 'Filipino', 'type': 'Core'},
          {'code': '21LIT', 'name': '21st Century Literature', 'type': 'Core'},
          {'code': 'CA', 'name': 'Contemporary Arts', 'type': 'Core'},
          {
            'code': 'MIL',
            'name': 'Media and Information Literacy',
            'type': 'Core',
          },
          {'code': 'PE', 'name': 'Physical Education', 'type': 'Core'},
          {'code': 'ES', 'name': 'Earth Science', 'type': 'Core'},
          {'code': 'CHEM', 'name': 'General Chemistry', 'type': 'Core'},
          {'code': 'CALC', 'name': 'Basic Calculus', 'type': 'Core'},
          {'code': 'PHY', 'name': 'Physics', 'type': 'Core'},
          {'code': 'ABM1', 'name': 'Applied Economics', 'type': 'Applied'},
          {'code': 'ABM2', 'name': 'Business Math', 'type': 'Applied'},
          {'code': 'STEM1', 'name': 'Pre-Calculus', 'type': 'Specialized'},
          {'code': 'HUMSS1', 'name': 'Philosophy', 'type': 'Specialized'},
        ];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Core':
        return Icons.menu_book_outlined;
      case 'Applied':
        return Icons.lightbulb_outline;
      case 'Program':
        return Icons.school_outlined;
      case 'Specialized':
      default:
        return Icons.auto_stories_outlined;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'Core':
        return 'Core Subject';
      case 'Applied':
        return 'Applied Subject';
      case 'Program':
        return 'Program';
      case 'Specialized':
      default:
        return 'Specialized';
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredSubjects = _subjects.where((item) {
      final code = (item['code'] ?? '').toLowerCase();
      final name = (item['name'] ?? '').toLowerCase();
      final type = (item['type'] ?? '').toLowerCase();

      if (query.isEmpty) return true;
      return code.contains(query) ||
          name.contains(query) ||
          type.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        title: const Text(
          'Lesson Selection',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search for a subject...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textLight,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),

            const Text(
              'Select lesson you need help with.',
              style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppConstants.paddingL),

            // Grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredSubjects.isEmpty
                  ? Center(
                      child: Text(
                        'No subjects found',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppConstants.paddingM,
                            mainAxisSpacing: AppConstants.paddingM,
                            childAspectRatio: 0.8,
                          ),
                      itemCount: filteredSubjects.length,
                      itemBuilder: (context, index) {
                        final lesson = filteredSubjects[index];
                        final code = (lesson['code'] ?? '').trim();
                        final name = (lesson['name'] ?? '').trim();
                        final type = (lesson['type'] ?? '').trim();
                        final isSelected =
                            _selectedCode == code && code.isNotEmpty;

                        return GestureDetector(
                          onTap: () {
                            // Navigate to StudyGroupsScreen with the selected subject
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    StudyGroupsScreen(initialSubject: name),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(
                              AppConstants.paddingM,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFDCE4FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusL,
                              ),
                              border: isSelected
                                  ? Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    )
                                  : Border.all(color: AppColors.borderLight),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: 80,
                                  width: 80,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.backgroundLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _iconForType(type),
                                    size: 40,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppConstants.paddingM),
                                Text(
                                  name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_labelForType(type)}${code.isNotEmpty ? ' • $code' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? AppColors.primary.withOpacity(0.7)
                                        : AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
