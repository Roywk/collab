import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../core/app_widgets.dart';
import '../../../data/learning_repository.dart';
import '../../../models/learning_models.dart';
import 'package:url_launcher/url_launcher.dart';

class ScenarioGameplayScreen extends StatefulWidget {
  const ScenarioGameplayScreen({
    required this.scenario,
    required this.repository,
    super.key,
  });

  final Scenario scenario;
  final LearningRepository repository;

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
    if (selectedOption?.isCorrect != true) {
      setState(() {
        selectedOption = null;
        showFeedback = false;
      });
      return;
    }
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

  Future<void> _showCompletion() async {
    final earnedXp = await widget.repository.completeScenario(
      widget.scenario.id,
      fallbackXp: widget.scenario.xpReward,
    );
    if (!mounted) return;
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
              style: TextStyle(
                fontSize: 24,
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
                earnedXp > 0
                    ? '+$earnedXp XP EARNED!'
                    : 'PRACTICE COMPLETE · TODAY’S XP ALREADY EARNED',
                style: const TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SurfaceCard(
              color: AppColors.blueSoft.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXPLANATION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Correct answer: ${selectedOption?.text}\n\n${selectedOption?.feedback ?? widget.scenario.description}',
                    style: const TextStyle(fontSize: 13, color: AppColors.navy),
                  ),
                ],
              ),
            ),
            const Spacer(),
            PrimaryActionButton(
              label: 'Back to Scenarios',
              onPressed: () {
                Navigator.pop(context); // Close modal
                Navigator.pop(context); // Back to selection
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Review my final choice',
                style: TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
      title:
          'Scenario ${currentStepIndex + 1} of ${widget.scenario.steps.length}',
      onBack: () => Navigator.pop(context),
      currentNavigationIndex: 5,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'ACTIVE SIMULATION',
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            widget.scenario.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 20),
          if (widget.scenario.mediaUrl?.isNotEmpty == true) ...[
            _ScenarioMedia(scenario: widget.scenario),
            const SizedBox(height: 16),
          ],
          SurfaceCard(
            color: AppColors.blueSoft.withValues(alpha: 0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'THE SITUATION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  step.situation,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.navy,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
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
                onTap: showFeedback
                    ? null
                    : () => setState(() => selectedOption = option),
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
                          border: Border.all(
                            color: isSelected
                                ? AppColors.blue
                                : AppColors.slate,
                          ),
                        ),
                        child: isSelected
                            ? const Center(
                                child: CircleAvatar(
                                  radius: 5,
                                  backgroundColor: AppColors.blue,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option.text,
                          style: TextStyle(
                            color: isSelected ? AppColors.blue : AppColors.navy,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          if (showFeedback)
            Builder(
              builder: (context) {
                final correctOption = step.options.firstWhere(
                  (option) => option.isCorrect,
                );
                return SurfaceCard(
                  color: selectedOption!.isCorrect
                      ? AppColors.greenSoft
                      : AppColors.redSoft,
                  borderColor: selectedOption!.isCorrect
                      ? AppColors.green
                      : AppColors.red,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        selectedOption!.isCorrect
                            ? Icons.check_circle
                            : Icons.school_outlined,
                        color: selectedOption!.isCorrect
                            ? AppColors.green
                            : AppColors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedOption!.isCorrect
                                  ? 'Correct — that is the safest response.'
                                  : 'No harm done — this is a safe place to practise.',
                              style: TextStyle(
                                color: selectedOption!.isCorrect
                                    ? AppColors.green
                                    : AppColors.red,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (!selectedOption!.isCorrect) ...[
                              Text(
                                'Correct answer: ${correctOption.text}',
                                style: const TextStyle(
                                  color: AppColors.green,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 5),
                            ],
                            Text(
                              selectedOption!.isCorrect
                                  ? selectedOption!.feedback
                                  : '${selectedOption!.feedback}\n\nWhy the safer answer works: ${correctOption.feedback}',
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          PrimaryActionButton(
            label: showFeedback
                ? selectedOption!.isCorrect
                      ? 'Continue'
                      : 'Try the safest response'
                : 'Submit Answer',
            onPressed: showFeedback ? _nextStep : _submitAnswer,
          ),
        ],
      ),
    );
  }
}

class _ScenarioMedia extends StatelessWidget {
  const _ScenarioMedia({required this.scenario});
  final Scenario scenario;

  Future<void> _openVideo(BuildContext context) async {
    final uri = Uri.tryParse(scenario.mediaUrl ?? '');
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This scenario video could not be opened.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (scenario.mediaType == 'video') {
      return Semantics(
        label: scenario.mediaCaption ?? 'Scenario video',
        button: true,
        child: InkWell(
          onTap: () => _openVideo(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 170,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF111827), Color(0xFF334155)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.blue,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Watch scenario briefing',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (scenario.mediaCaption?.isNotEmpty == true) ...[
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      scenario.mediaCaption!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            scenario.mediaUrl!,
            width: double.infinity,
            height: 190,
            fit: BoxFit.cover,
            semanticLabel: scenario.mediaCaption ?? 'Scenario image',
            errorBuilder: (_, _, _) => Container(
              height: 130,
              color: AppColors.canvas,
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                color: AppColors.muted,
              ),
            ),
          ),
        ),
        if (scenario.mediaCaption?.isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Text(
            scenario.mediaCaption!,
            style: const TextStyle(color: AppColors.slate, fontSize: 9),
          ),
        ],
      ],
    );
  }
}
