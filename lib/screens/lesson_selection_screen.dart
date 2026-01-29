import 'package:flutter/material.dart';
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

  String _selectedCode = '';

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
    final subjects = AppConstants.shsCurriculumSubjects.where((item) {
      final code = (item['code'] ?? '').toLowerCase();
      final title = (item['title'] ?? '').toLowerCase();
      final type = (item['type'] ?? '').toLowerCase();

      if (query.isEmpty) return true;
      return code.contains(query) ||
          title.contains(query) ||
          type.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
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
              'Select the lesson you need help with.',
              style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppConstants.paddingL),

            // Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppConstants.paddingM,
                  mainAxisSpacing: AppConstants.paddingM,
                  childAspectRatio: 0.8,
                ),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final lesson = subjects[index];
                  final code = (lesson['code'] ?? '').trim();
                  final title = (lesson['title'] ?? '').trim();
                  final type = (lesson['type'] ?? '').trim();
                  final isSelected = _selectedCode == code && code.isNotEmpty;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCode = code;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppConstants.paddingM),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFDCE4FF)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusL,
                        ),
                        border: isSelected
                            ? Border.all(color: AppColors.primary, width: 2)
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
                            title,
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
