import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/app_widgets.dart';
import '../../../models/learning_models.dart';

class QuizReviewScreen extends StatelessWidget {
  const QuizReviewScreen({
    required this.questions,
    required this.answers,
    super.key,
  });
  final List<QuizQuestion> questions;
  final List<int> answers;

  @override
  Widget build(BuildContext context) => MobileShell(
    title: 'Review Answers',
    onBack: () => Navigator.pop(context),
    currentNavigationIndex: 5,
    child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: questions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final question = questions[index];
        final selected = index < answers.length ? answers[index] : -1;
        final correct = selected == question.correctOptionIndex;
        return SurfaceCard(
          borderColor: correct ? AppColors.green : AppColors.red,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: correct
                        ? AppColors.greenSoft
                        : AppColors.redSoft,
                    child: Icon(
                      correct ? Icons.check : Icons.close,
                      color: correct ? AppColors.green : AppColors.red,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'QUESTION ${index + 1} · ${question.category.toUpperCase()}',
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                question.question,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              _AnswerLine(
                label: 'Your answer',
                value: selected >= 0 && selected < question.options.length
                    ? question.options[selected]
                    : 'No answer — time expired',
                color: correct ? AppColors.green : AppColors.red,
              ),
              if (!correct) ...[
                const SizedBox(height: 7),
                _AnswerLine(
                  label: 'Correct answer',
                  value: question.options[question.correctOptionIndex],
                  color: AppColors.green,
                ),
              ],
              const Divider(height: 24),
              Text(
                question.explanation,
                style: const TextStyle(
                  color: AppColors.slate,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _AnswerLine extends StatelessWidget {
  const _AnswerLine({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
