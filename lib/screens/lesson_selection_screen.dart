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

  final List<Map<String, dynamic>> _lessons = [
    {
      'title': 'General Mathematics',
      'type': 'Core Subject',
      'icon': Icons.calculate_outlined, // Placeholder for image
      'color': Colors.white,
    },
    {
      'title': 'Oral Communication',
      'type': 'Core Subject',
      'icon': Icons.record_voice_over_outlined, // Placeholder for image
      'color': AppColors.backgroundLight, // Selected-ish
      'isSelected': true,
    },
    {
      'title': 'Earth and Life Science',
      'type': 'Core Subject',
      'icon': Icons.public, // Placeholder for image
      'color': Colors.white,
    },
    {
      'title': 'Physical Education',
      'type': 'Core Subject',
      'icon': Icons.sports_handball, // Placeholder for image
      'color': Colors.white,
    },
  ];

  @override
  Widget build(BuildContext context) {
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
                itemCount: _lessons.length,
                itemBuilder: (context, index) {
                  final lesson = _lessons[index];
                  final isSelected = lesson['isSelected'] == true;
                  return GestureDetector(
                    onTap: () {
                      // Select lesson logic
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
                              lesson['icon'],
                              size: 40,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingM),
                          Text(
                            lesson['title'],
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
                            lesson['type'],
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
