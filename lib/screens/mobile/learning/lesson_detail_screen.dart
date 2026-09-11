import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../core/app_widgets.dart';
import '../../../data/learning_repository.dart';
import '../../../models/learning_models.dart';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({
    required this.lesson,
    required this.repository,
    this.isReview = false,
    super.key,
  });

  final LearningLesson lesson;
  final LearningRepository repository;
  final bool isReview;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  bool isCompleting = false;

  Future<void> _complete() async {
    setState(() => isCompleting = true);
    try {
      final xpAwarded = await widget.repository.completeLesson(
        widget.lesson.id,
        fallbackXp: widget.lesson.xpReward,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              xpAwarded > 0
                  ? 'Lesson completed! +$xpAwarded XP earned.'
                  : 'Review completed. XP for this lesson was already earned today.',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save progress: $e')));
      }
    } finally {
      if (mounted) setState(() => isCompleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Safety Lesson',
      onBack: () => Navigator.pop(context),
      currentNavigationIndex: 5,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              widget.lesson.imageUrl ??
                  'https://images.unsplash.com/photo-1596701062351-8c2c14d1fdd0?auto=format&fit=crop&q=80&w=800',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.redSoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.lesson.category,
                          style: const TextStyle(
                            color: AppColors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.lesson.readTime,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.lesson.title,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'How It Works',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.lesson.content,
                    style: const TextStyle(
                      color: AppColors.slate,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.redSoft.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.redSoft),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Red Flags',
                          style: TextStyle(
                            color: AppColors.red,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...widget.lesson.redFlags.map(
                          (flag) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '• ',
                                  style: TextStyle(
                                    color: AppColors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    flag,
                                    style: const TextStyle(
                                      color: AppColors.navy,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'What To Do',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.lesson.whatToDo,
                    style: const TextStyle(
                      color: AppColors.slate,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (!widget.lesson.isCompleted || widget.isReview)
                    PrimaryActionButton(
                      label: isCompleting
                          ? 'Saving...'
                          : widget.isReview
                          ? 'Finish Review'
                          : 'Mark as Completed',
                      icon: isCompleting ? null : Icons.check_circle_outline,
                      onPressed: isCompleting ? null : _complete,
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.greenSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: AppColors.green),
                          SizedBox(width: 8),
                          Text(
                            'Lesson Completed',
                            style: TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
