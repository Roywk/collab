import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../core/app_widgets.dart';
import '../../../data/learning_repository.dart';
import '../../../models/learning_models.dart';
import 'lesson_detail_screen.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({required this.repository, super.key});

  final LearningRepository repository;

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  late Future<List<LearningLesson>> lessons;
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _refreshLessons();
  }

  // 1. Helper method to centralize data fetching
  void _refreshLessons() {
    setState(() {
      lessons = widget.repository.getLessons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Safety Lessons',
      onBack: () => Navigator.pop(context),
      currentNavigationIndex: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safety Lessons',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Arm yourself with local knowledge to bypass common scams.',
                  style: TextStyle(color: AppColors.slate, fontSize: 13),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Location-Based'),
                      const SizedBox(width: 8),
                      _buildFilterChip('General'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<LearningLesson>>(
              future: lessons,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 2. Added Error Handling
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allItems = snapshot.data ?? [];

                // 3. Implemented Filtering logic
                final filteredItems = allItems.where((lesson) {
                  if (selectedFilter == 'Location-Based') {
                    return lesson.isLocationBased;
                  }
                  if (selectedFilter == 'General') {
                    return !lesson.isLocationBased;
                  }
                  return true; // 'All'
                }).toList();

                if (filteredItems.isEmpty) {
                  return const Center(child: Text('No lessons found.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final lesson = filteredItems[index];
                    return _buildLessonTile(context, lesson);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() => selectedFilter = label),
      selectedColor: AppColors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.slate,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppColors.blue : AppColors.line),
      ),
    );
  }

  Widget _buildLessonTile(BuildContext context, LearningLesson lesson) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonDetailScreen(
              lesson: lesson,
              repository: widget.repository,
            ),
          ),
        );

        // 4. Use the helper method here to refresh if data changed
        if (result == true) {
          _refreshLessons();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: SurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: lesson.isLocationBased
                    ? AppColors.redSoft
                    : AppColors.blueSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                lesson.isLocationBased ? Icons.place : Icons.directions_car,
                color: lesson.isLocationBased ? AppColors.red : AppColors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lesson.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      if (lesson.isCompleted)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.green,
                          size: 16,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lesson.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.slate,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        lesson.difficulty,
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${lesson.readTime}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
