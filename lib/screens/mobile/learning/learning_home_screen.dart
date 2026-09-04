import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../core/app_widgets.dart';
import '../../../data/learning_repository.dart';
import '../../../data/scam_map_repository.dart';
import '../../../models/learning_models.dart';
import '../scam_map_screen.dart';
import 'lessons_screen.dart';
import 'scenarios_screen.dart';
import 'rewards_screen.dart';
import 'quiz_screen.dart';

class LearningHomeScreen extends StatefulWidget {
  const LearningHomeScreen({required this.repository, super.key});

  final LearningRepository repository;

  @override
  State<LearningHomeScreen> createState() => _LearningHomeScreenState();
}

class _LearningHomeScreenState extends State<LearningHomeScreen> {
  late Future<UserLearningProfile> userProfile;

  @override
  void initState() {
    super.initState();
    userProfile = widget.repository.getUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      currentNavigationIndex: 4,
      onVerify: () => Navigator.of(context).popUntil((route) => route.isFirst),
      onMap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ScamMapScreen(
              repository: ScamMapRepository(client: widget.repository.client),
            ),
          ),
        );
      },
      child: FutureBuilder<UserLearningProfile>(
        future: userProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}'));
          }

          final profile = snapshot.data!;
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'MODULE 5',
                style: TextStyle(
                  color: AppColors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'Scam Shield & Rewards',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              
              // Profile Header
              SurfaceCard(
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=alex'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Alex Mercer',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const Text(
                            'Tourist Member',
                            style: TextStyle(
                              color: AppColors.slate,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.blueSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, color: AppColors.blue, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            profile.rankTitle,
                            style: const TextStyle(
                              color: AppColors.blue,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Level 3 Progress',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${profile.totalXp} / ${profile.xpForNextLevel} XP',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: profile.progressToNextLevel,
                  minHeight: 8,
                  backgroundColor: AppColors.line,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
                ),
              ),
              const SizedBox(height: 24),
              
              // Grid Menu
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
                children: [
                  _buildMenuCard(
                    context,
                    icon: Icons.security,
                    iconColor: AppColors.blue,
                    title: 'Safety Lessons',
                    subtitle: 'Learn location-based scam prevention tips',
                    badge: '5 lessons available',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LessonsScreen(repository: widget.repository),
                      ),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.psychology,
                    iconColor: AppColors.blue,
                    title: 'Scenario Simulation',
                    subtitle: 'Practice handling real scam situations',
                    badge: '4 scenarios',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScenariosScreen(repository: widget.repository),
                      ),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.help_outline,
                    iconColor: AppColors.amber,
                    title: 'Fraud Quiz',
                    subtitle: 'Test your scam awareness knowledge',
                    badge: '10 questions',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(repository: widget.repository),
                      ),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.card_giftcard,
                    iconColor: AppColors.green,
                    title: 'Rewards Profile',
                    subtitle: 'View XP, level & redeem vouchers',
                    badge: '2 rewards available',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RewardsScreen(repository: widget.repository),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Bottom Tip
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.amberSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.amber, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bukit Bintang Area Tip',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Color(0xFF856404),
                            ),
                          ),
                          Text(
                            'Watch for fake ticket sellers near monorail stations.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF856404),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SurfaceCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.slate,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  badge,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward, color: iconColor, size: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
