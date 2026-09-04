import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../core/app_widgets.dart';
import '../../../data/learning_repository.dart';
import '../../../models/learning_models.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({required this.repository, super.key});

  final LearningRepository repository;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late Future<List<QuizQuestion>> questionsFuture;
  List<QuizQuestion> questions = [];
  int currentQuestionIndex = 0;
  int? selectedOptionIndex;
  int correctAnswers = 0;
  bool isAnswered = false;
  
  Timer? _timer;
  int _secondsRemaining = 15;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    questionsFuture = widget.repository.getQuizQuestions();
    questionsFuture.then((value) {
      setState(() => questions = value);
      _startQuestion();
    });
  }

  void _startQuestion() {
    _secondsRemaining = 15;
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
      if (selectedOptionIndex == questions[currentQuestionIndex].correctOptionIndex) {
        correctAnswers++;
      }
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedOptionIndex = null;
        isAnswered = false;
      });
      _startQuestion();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            score: correctAnswers,
            total: questions.length,
            timeTaken: _stopwatch.elapsed,
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
    if (questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final question = questions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / questions.length;

    return MobileShell(
      title: 'Fraud Awareness Quiz',
      onBack: () => Navigator.pop(context),
      currentNavigationIndex: 4,
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
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
                Text('${(progress * 100).toInt()}% Done', style: const TextStyle(fontSize: 10, color: AppColors.slate)),
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
                      const Text('Visual Recognition', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.blue)),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: _secondsRemaining < 5 ? AppColors.red : AppColors.slate),
                          const SizedBox(width: 4),
                          Text(
                            '0:${_secondsRemaining.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.w700,
                              color: _secondsRemaining < 5 ? AppColors.red : AppColors.navy
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    question.question,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy, height: 1.4),
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
                  onTap: isAnswered ? null : () => setState(() => selectedOptionIndex = index),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          question.options[index],
                          style: TextStyle(
                            color: isSelected ? AppColors.navy : AppColors.slate,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (isAnswered && index == question.correctOptionIndex)
                          const Icon(Icons.check_circle, color: AppColors.green, size: 20),
                        if (isAnswered && isSelected && index != question.correctOptionIndex)
                          const Icon(Icons.cancel, color: AppColors.red, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            if (isAnswered)
              SurfaceCard(
                color: AppColors.blueSoft.withOpacity(0.3),
                child: Text(
                  'Explanation: ${question.explanation}',
                  style: const TextStyle(fontSize: 12, color: AppColors.navy, height: 1.4),
                ),
              ),
            const SizedBox(height: 16),
            PrimaryActionButton(
              label: isAnswered ? 'Next Question' : 'Submit Answer',
              onPressed: selectedOptionIndex == null && !isAnswered ? null : (isAnswered ? _nextQuestion : _submitAnswer),
            ),
          ],
        ),
      ),
    );
  }
}
