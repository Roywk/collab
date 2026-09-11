import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../core/app_widgets.dart';
import '../../../models/learning_models.dart';
import 'quiz_review_screen.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({
    required this.score,
    required this.total,
    required this.timeTaken,
    required this.progressSaved,
    required this.xpEarned,
    required this.questions,
    required this.answers,
    this.saveError,
    super.key,
  });

  final int score;
  final int total;
  final Duration timeTaken;
  final bool progressSaved;
  final int xpEarned;
  final String? saveError;
  final List<QuizQuestion> questions;
  final List<int> answers;

  @override
  Widget build(BuildContext context) {
    final scorePercent = total == 0 ? 0 : ((score / total) * 100).round();
    final bool isPassed = scorePercent >= 70;
    String timeString = "${timeTaken.inMinutes}m ${timeTaken.inSeconds % 60}s";

    return MobileShell(
      title: 'Quiz Result',
      currentNavigationIndex: 5,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: scorePercent / 100,
                  strokeWidth: 10,
                  backgroundColor: AppColors.line,
                  valueColor: AlwaysStoppedAnimation(
                    isPassed ? AppColors.green : AppColors.amber,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$scorePercent%',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  Text(
                    '$score of $total correct',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPassed ? 'Passed!' : 'Try Again',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isPassed ? AppColors.green : AppColors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Quiz Completed',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.greenSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              xpEarned > 0
                  ? '+$xpEarned XP EARNED!'
                  : !isPassed
                  ? 'NO XP · 70% REQUIRED TO GRADUATE'
                  : 'PASSED · TODAY’S XP ALREADY EARNED',
              style: const TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PERFORMANCE BREAKDOWN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                _buildResultRow(
                  'Score Percentage',
                  '$scorePercent%',
                  isPassed ? AppColors.green : AppColors.amber,
                ),
                _buildResultRow('Correct Answers', '$score', AppColors.green),
                _buildResultRow(
                  'Wrong Answers',
                  '${total - score}',
                  AppColors.red,
                ),
                _buildResultRow('Time Taken', timeString, AppColors.navy),
                const Divider(height: 32),
                Text(
                  isPassed
                      ? "Great job! You have strong scam awareness and a good eye for identifying fraudulent money changers."
                      : "No XP was awarded this time, and that is okay—this is a safe place to practise. Review the correct answers, then try again when you are ready.",
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.slate,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryActionButton(
            label: 'Return to Homepage',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    QuizReviewScreen(questions: questions, answers: answers),
              ),
            ),
            child: const Text(
              'Review Answers',
              style: TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: progressSaved ? AppColors.greenSoft : AppColors.amberSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  progressSaved
                      ? Icons.cloud_done_outlined
                      : Icons.warning_amber_rounded,
                  color: progressSaved ? AppColors.green : AppColors.amber,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    progressSaved
                        ? 'Progress and XP saved to your profile.'
                        : 'Progress could not be saved. ${saveError ?? ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: progressSaved ? AppColors.green : AppColors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.slate, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
