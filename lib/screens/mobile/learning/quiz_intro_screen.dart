import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/app_widgets.dart';
import '../../../data/learning_repository.dart';
import '../../../models/learning_models.dart';
import 'quiz_screen.dart';

class QuizIntroScreen extends StatefulWidget {
  const QuizIntroScreen({required this.repository, super.key});
  final LearningRepository repository;

  @override
  State<QuizIntroScreen> createState() => _QuizIntroScreenState();
}

class _QuizIntroScreenState extends State<QuizIntroScreen> {
  late final Future<List<QuizQuestion>> _questions;

  @override
  void initState() {
    super.initState();
    _questions = widget.repository.getQuizQuestions();
  }

  @override
  Widget build(BuildContext context) => MobileShell(
    title: 'Spot the Scam',
    onBack: () => Navigator.pop(context),
    currentNavigationIndex: 5,
    child: FutureBuilder<List<QuizQuestion>>(
      future: _questions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError || (snapshot.data?.isEmpty ?? true)) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.quiz_outlined,
                    color: AppColors.muted,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    snapshot.hasError
                        ? 'The challenge could not be loaded.'
                        : 'No quiz questions are published yet.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final questions = snapshot.data!;
        final categories = questions.map((q) => q.category).toSet().toList();
        final totalSeconds = questions.fold<int>(
          0,
          (sum, q) => sum + q.timeLimitSeconds,
        );
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.center_focus_strong,
                    color: Colors.white,
                    size: 34,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Can you spot the warning signs?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Inspect payment screens, QR codes, and suspicious links before the timer runs out.',
                    style: TextStyle(
                      color: Color(0xFFEDE9FE),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CHALLENGE BRIEFING',
                    style: TextStyle(
                      color: Color(0xFF7C3AED),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .7,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _BriefRow(
                    icon: Icons.quiz_outlined,
                    title: '${questions.length} questions',
                    subtitle: 'One answer per question',
                  ),
                  _BriefRow(
                    icon: Icons.timer_outlined,
                    title: 'About ${(totalSeconds / 60).ceil()} minutes',
                    subtitle: 'Each question has its own countdown',
                  ),
                  const _BriefRow(
                    icon: Icons.verified_outlined,
                    title: '70% passing score',
                    subtitle: 'Review every answer after finishing',
                  ),
                  const _BriefRow(
                    icon: Icons.stars_outlined,
                    title: 'Up to 80 XP',
                    subtitle: 'Only score improvements earn additional XP',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOPICS IN THIS RUN',
                    style: TextStyle(
                      color: AppColors.slate,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: categories
                        .map(
                          (category) => Chip(
                            label: Text(
                              category,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryActionButton(
              label: 'Start Challenge',
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizScreen(
                    repository: widget.repository,
                    questions: questions,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The timer starts only after you press Start Challenge.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.slate, fontSize: 9),
            ),
          ],
        );
      },
    ),
  );
}

class _BriefRow extends StatelessWidget {
  const _BriefRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.blueSoft,
          child: Icon(icon, color: AppColors.blue, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.slate, fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
