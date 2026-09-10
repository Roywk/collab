import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../core/app_widgets.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({
    required this.score,
    required this.total,
    required this.timeTaken,
    required this.progressSaved,
    required this.xpEarned,
    this.saveError,
    super.key,
  });

  final int score;
  final int total;
  final Duration timeTaken;
  final bool progressSaved;
  final int xpEarned;
  final String? saveError;

  @override
  Widget build(BuildContext context) {
    final bool isPassed = score / total >= 0.7;
    String timeString = "${timeTaken.inMinutes}m ${timeTaken.inSeconds % 60}s";

    return MobileShell(
      title: 'Quiz Result',
      currentNavigationIndex: 5,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: score / total,
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
                      '$score/$total',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
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
                    : 'BEST RESULT ALREADY REWARDED',
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
                        : "Keep practicing! Scammers use subtle tricks to deceive people. Review the lessons to improve your score.",
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.slate,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            PrimaryActionButton(
              label: 'Back to Module 5',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context), // Would typically navigate to review
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
                color: progressSaved
                    ? AppColors.greenSoft
                    : AppColors.amberSoft,
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
                        color: progressSaved
                            ? AppColors.green
                            : AppColors.amber,
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
