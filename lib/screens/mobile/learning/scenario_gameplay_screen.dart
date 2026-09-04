import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../core/app_widgets.dart';
import '../../../models/learning_models.dart';

class ScenarioGameplayScreen extends StatefulWidget {
  const ScenarioGameplayScreen({required this.scenario, super.key});

  final Scenario scenario;

  @override
  State<ScenarioGameplayScreen> createState() => _ScenarioGameplayScreenState();
}

class _ScenarioGameplayScreenState extends State<ScenarioGameplayScreen> {
  int currentStepIndex = 0;
  ScenarioOption? selectedOption;
  bool showFeedback = false;

  void _submitAnswer() {
    if (selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an option to proceed.')),
      );
      return;
    }
    setState(() {
      showFeedback = true;
    });
  }

  void _nextStep() {
    if (currentStepIndex < widget.scenario.steps.length - 1) {
      setState(() {
        currentStepIndex++;
        selectedOption = null;
        showFeedback = false;
      });
    } else {
      _showCompletion();
    }
  }

  void _showCompletion() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: AppColors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Scenario Complete!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.greenSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+${widget.scenario.xpReward} XP EARNED!',
                style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
            SurfaceCard(
              color: AppColors.blueSoft.withOpacity(0.3),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EXPLANATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.blue)),
                  SizedBox(height: 8),
                  Text(
                    'You chose correctly! Always verify with official sources. Batu Caves is free to enter without a guide. Non-official guides can occasionally overcharge or mislead you about entry policies.',
                    style: TextStyle(fontSize: 13, color: AppColors.navy),
                  ),
                ],
              ),
            ),
            const Spacer(),
            PrimaryActionButton(
              label: 'Next Scenario',
              onPressed: () {
                Navigator.pop(context); // Close modal
                Navigator.pop(context); // Back to selection
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Scenarios', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.scenario.steps[currentStepIndex];

    return MobileShell(
      title: 'Scenario ${currentStepIndex + 1} of ${widget.scenario.steps.length}',
      onBack: () => Navigator.pop(context),
      currentNavigationIndex: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ACTIVE SIMULATION',
              style: TextStyle(color: AppColors.blue, fontSize: 10, fontWeight: FontWeight.w800),
            ),
            Text(
              widget.scenario.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy),
            ),
            const SizedBox(height: 20),
            SurfaceCard(
              color: AppColors.blueSoft.withOpacity(0.2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('THE SITUATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.blue)),
                  const SizedBox(height: 8),
                  Text(
                    step.situation,
                    style: const TextStyle(fontSize: 14, color: AppColors.navy, fontWeight: FontWeight.w600, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...step.options.map((option) {
              final isSelected = selectedOption == option;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: showFeedback ? null : () => setState(() => selectedOption = option),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.blueSoft : Colors.white,
                      border: Border.all(
                        color: isSelected ? AppColors.blue : AppColors.line,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? AppColors.blue : AppColors.slate),
                          ),
                          child: isSelected ? const Center(child: CircleAvatar(radius: 5, backgroundColor: AppColors.blue)) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option.text,
                            style: TextStyle(
                              color: isSelected ? AppColors.blue : AppColors.navy,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            if (showFeedback)
              SurfaceCard(
                color: selectedOption!.isCorrect ? AppColors.greenSoft : AppColors.redSoft,
                borderColor: selectedOption!.isCorrect ? AppColors.green : AppColors.red,
                child: Row(
                  children: [
                    Icon(selectedOption!.isCorrect ? Icons.check_circle : Icons.error, color: selectedOption!.isCorrect ? AppColors.green : AppColors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedOption!.feedback,
                        style: TextStyle(
                          color: selectedOption!.isCorrect ? AppColors.green : AppColors.red,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            PrimaryActionButton(
              label: showFeedback ? 'Continue' : 'Submit Answer',
              onPressed: showFeedback ? _nextStep : _submitAnswer,
            ),
          ],
        ),
      ),
    );
  }
}
