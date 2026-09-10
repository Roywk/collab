import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../core/app_widgets.dart';
import '../../../data/learning_repository.dart';
import '../../../models/learning_models.dart';
import 'scenario_gameplay_screen.dart';

class ScenariosScreen extends StatefulWidget {
  const ScenariosScreen({required this.repository, super.key});

  final LearningRepository repository;

  @override
  State<ScenariosScreen> createState() => _ScenariosScreenState();
}

class _ScenariosScreenState extends State<ScenariosScreen> {
  late Future<List<Scenario>> scenarios;

  @override
  void initState() {
    super.initState();
    scenarios = widget.repository.getScenarios();
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Scenario Simulations',
      onBack: () => Navigator.pop(context),
      currentNavigationIndex: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scenario Simulations',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Practice handling real scam situations',
                  style: TextStyle(color: AppColors.slate, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Scenario>>(
              future: scenarios,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data ?? [];

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final scenario = items[index];
                    return _buildScenarioTile(context, scenario);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioTile(BuildContext context, Scenario scenario) {
    final isCompleted = scenario.status == 'Completed';

    return InkWell(
      onTap: () async {
        if (scenario.steps.isNotEmpty) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScenarioGameplayScreen(
                scenario: scenario,
                repository: widget.repository,
              ),
            ),
          );
          if (!mounted) return;
          setState(() {
            scenarios = widget.repository.getScenarios();
          });
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
                color: isCompleted ? AppColors.greenSoft : AppColors.blueSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.psychology,
                color: isCompleted ? AppColors.green : AppColors.blue,
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
                          scenario.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      if (scenario.status == 'Not Started') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.redSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: AppColors.red,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+${scenario.xpReward} XP • ${scenario.status}',
                    style: TextStyle(
                      color: isCompleted ? AppColors.green : AppColors.slate,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                scenario.difficulty,
                style: const TextStyle(
                  color: AppColors.slate,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
