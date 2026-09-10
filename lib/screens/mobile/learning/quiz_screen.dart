import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../core/app_widgets.dart';
import '../../../data/learning_repository.dart';
import '../../../models/learning_models.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    required this.repository,
    required this.questions,
    super.key,
  });

  final LearningRepository repository;
  final List<QuizQuestion> questions;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<QuizQuestion> questions = [];
  late List<int> answers;
  int currentQuestionIndex = 0;
  int? selectedOptionIndex;
  int correctAnswers = 0;
  bool isAnswered = false;
  bool _loading = true;
  bool _finishing = false;
  Object? _loadError;

  Timer? _timer;
  int _secondsRemaining = 15;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    questions = widget.questions;
    answers = List<int>.filled(questions.length, -1);
    _loading = false;
    if (questions.isNotEmpty) _startQuestion();
  }

  void _startQuestion() {
    _secondsRemaining = questions[currentQuestionIndex].timeLimitSeconds;
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _submitAnswer();
        }
      });
    });
  }

  void _submitAnswer() {
    if (isAnswered) return;

    _timer?.cancel();
    _stopwatch.stop();

    setState(() {
      isAnswered = true;
      answers[currentQuestionIndex] = selectedOptionIndex ?? -1;
      if (selectedOptionIndex ==
          questions[currentQuestionIndex].correctOptionIndex) {
        correctAnswers++;
      }
    });
  }

  Future<void> _nextQuestion() async {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedOptionIndex = null;
        isAnswered = false;
      });
      _startQuestion();
    } else {
      if (_finishing) return;
      setState(() => _finishing = true);
      var saved = true;
      String? saveError;
      var xpAwarded = 0;
      try {
        xpAwarded = await widget.repository.submitQuizAttempt(
          score: correctAnswers,
          total: questions.length,
          timeTaken: _stopwatch.elapsed,
        );
      } catch (error) {
        saved = false;
        saveError = error.toString();
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            score: correctAnswers,
            total: questions.length,
            timeTaken: _stopwatch.elapsed,
            progressSaved: saved,
            saveError: saveError,
            xpEarned: xpAwarded,
            questions: questions,
            answers: answers,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null || questions.isEmpty) {
      return MobileShell(
        title: 'Spot the Scam',
        onBack: () => Navigator.pop(context),
        currentNavigationIndex: 5,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.quiz_outlined,
                  color: AppColors.muted,
                  size: 46,
                ),
                const SizedBox(height: 12),
                Text(
                  _loadError == null
                      ? 'No quiz is published yet.'
                      : 'Quiz questions could not be loaded.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_loadError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '$_loadError',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final question = questions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / questions.length;

    return MobileShell(
      title: 'Fraud Awareness Quiz',
      onBack: () => Navigator.pop(context),
      currentNavigationIndex: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${currentQuestionIndex + 1} of ${questions.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}% Done',
                  style: const TextStyle(fontSize: 10, color: AppColors.slate),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.line,
              valueColor: const AlwaysStoppedAnimation(AppColors.blue),
            ),
            const SizedBox(height: 24),
            SurfaceCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Visual Recognition',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.blue,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: _secondsRemaining < 5
                                ? AppColors.red
                                : AppColors.slate,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '0:${_secondsRemaining.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _secondsRemaining < 5
                                  ? AppColors.red
                                  : AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (question.imageUrl != null &&
                      question.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        question.imageUrl!,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 110,
                          color: AppColors.canvas,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Text(
                    question.question,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(question.options.length, (index) {
              final isSelected = selectedOptionIndex == index;
              Color borderColor = isSelected ? AppColors.blue : AppColors.line;
              Color bgColor = isSelected ? AppColors.blueSoft : Colors.white;

              if (isAnswered) {
                if (index == question.correctOptionIndex) {
                  borderColor = AppColors.green;
                  bgColor = AppColors.greenSoft;
                } else if (isSelected) {
                  borderColor = AppColors.red;
                  bgColor = AppColors.redSoft;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: isAnswered
                      ? null
                      : () => setState(() => selectedOptionIndex = index),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(
                        color: borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            question.options[index],
                            softWrap: true,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.navy
                                  : AppColors.slate,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (isAnswered && index == question.correctOptionIndex)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.green,
                            size: 20,
                          ),
                        if (isAnswered &&
                            isSelected &&
                            index != question.correctOptionIndex)
                          const Icon(
                            Icons.cancel,
                            color: AppColors.red,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            if (isAnswered)
              SurfaceCard(
                color: AppColors.blueSoft.withValues(alpha: 0.3),
                child: Text(
                  'Explanation: ${question.explanation}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.navy,
                    height: 1.4,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            PrimaryActionButton(
              label: isAnswered ? 'Next Question' : 'Submit Answer',
              onPressed:
                  _finishing || (selectedOptionIndex == null && !isAnswered)
                  ? null
                  : (isAnswered ? _nextQuestion : _submitAnswer),
            ),
          ],
        ),
      ),
    );
  }
}
