import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/app_widgets.dart';
import '../../../core/haversine.dart';
import '../../../data/learning_repository.dart';
import '../../../models/learning_models.dart';
import '../../../services/location_service.dart';
import 'lesson_detail_screen.dart';
import 'lessons_screen.dart';
import 'quiz_screen.dart';
import 'rewards_screen.dart';
import 'scenarios_screen.dart';

class LearningHomeScreen extends StatefulWidget {
  const LearningHomeScreen({required this.repository, super.key});
  final LearningRepository repository;
  @override
  State<LearningHomeScreen> createState() => _LearningHomeScreenState();
}

class _LearningHomeScreenState extends State<LearningHomeScreen> {
  late Future<_LearningDashboardData> _dashboard;
  final LocationService _locationService = LocationService();
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _dashboard = _LearningDashboardData.load(
      widget.repository,
      _locationService,
    );
  }

  Future<void> _refresh() async {
    setState(_load);
    await _dashboard;
  }

  @override
  Widget build(BuildContext context) => MobileShell(
    currentNavigationIndex: 5,
    statusLabel: 'Safety content live',
    child: FutureBuilder<_LearningDashboardData>(
      future: _dashboard,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return _LearningError(error: snapshot.error, onRetry: _refresh);
        }
        final data = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 28),
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SCAM AWARENESS',
                    style: TextStyle(
                      color: AppColors.blue,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Learn. Practise. Stay ready.',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Short, local training made for travellers in Malaysia.',
                    style: TextStyle(color: AppColors.slate, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _ProgressHero(profile: data.profile),
              const SizedBox(height: 14),
              if (data.hotspotLesson != null) ...[
                _HotspotCard(
                  lesson: data.hotspotLesson!,
                  distanceMeters: data.hotspotDistanceMeters,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LessonDetailScreen(
                        lesson: data.hotspotLesson!,
                        repository: widget.repository,
                      ),
                    ),
                  ).then((_) => _refresh()),
                ),
                const SizedBox(height: 18),
              ],
              const Text(
                'Build your street smarts',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Every activity comes directly from the Visit 1MY safety team.',
                style: TextStyle(color: AppColors.slate, fontSize: 10),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 11,
                crossAxisSpacing: 11,
                childAspectRatio: .91,
                children: [
                  _ModuleCard(
                    icon: Icons.travel_explore_outlined,
                    color: AppColors.blue,
                    eyebrow: '${data.overview.lessons} LOCAL GUIDES',
                    title: 'Insider safety tips',
                    subtitle: 'Know what to watch for before you arrive.',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LessonsScreen(repository: widget.repository),
                      ),
                    ).then((_) => _refresh()),
                  ),
                  _ModuleCard(
                    icon: Icons.alt_route,
                    color: const Color(0xFFDB2777),
                    eyebrow: '${data.overview.scenarios} SIMULATIONS',
                    title: 'Street Smart Challenge',
                    subtitle: 'Choose your response and see the consequence.',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ScenariosScreen(repository: widget.repository),
                      ),
                    ).then((_) => _refresh()),
                  ),
                  _ModuleCard(
                    icon: Icons.center_focus_strong_outlined,
                    color: const Color(0xFF7C3AED),
                    eyebrow: '${data.overview.questions} TIMED QUESTIONS',
                    title: 'Spot the Scam',
                    subtitle: 'Train your eye to catch payment red flags.',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            QuizScreen(repository: widget.repository),
                      ),
                    ).then((_) => _refresh()),
                  ),
                  _ModuleCard(
                    icon: Icons.redeem_outlined,
                    color: AppColors.green,
                    eyebrow: '${data.overview.rewards} PARTNER REWARDS',
                    title: 'Badges & rewards',
                    subtitle: 'Turn safety progress into real travel perks.',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RewardsScreen(repository: widget.repository),
                      ),
                    ).then((_) => _refresh()),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  border: Border.all(color: AppColors.amberSoft),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.amberSoft,
                      child: Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.amber,
                        size: 19,
                      ),
                    ),
                    SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '60-second safety habit',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Before every payment: check the amount, recipient name, and destination one final time.',
                            style: TextStyle(
                              color: AppColors.slate,
                              fontSize: 9,
                              height: 1.35,
                            ),
                          ),
                        ],
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
  );
}

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({required this.profile});
  final UserLearningProfile profile;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF111E3D), Color(0xFF1E40AF)],
      ),
      borderRadius: BorderRadius.circular(17),
      boxShadow: const [
        BoxShadow(
          color: Color(0x331E40AF),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR SAFETY RANK',
                    style: TextStyle(
                      color: Color(0xFFBFDBFE),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .7,
                    ),
                  ),
                  Text(
                    profile.rankTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Level ${profile.currentLevel}',
                    style: const TextStyle(
                      color: Color(0xFFDBEAFE),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${profile.totalXp} XP',
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${profile.xpIntoCurrentLevel} / 200 XP to next level',
              style: const TextStyle(color: Colors.white70, fontSize: 9),
            ),
            Text(
              '${(profile.progressToNextLevel * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: profile.progressToNextLevel,
            minHeight: 7,
            backgroundColor: Colors.white.withValues(alpha: .17),
            color: const Color(0xFF60A5FA),
          ),
        ),
      ],
    ),
  );
}

class _HotspotCard extends StatelessWidget {
  const _HotspotCard({
    required this.lesson,
    required this.distanceMeters,
    required this.onTap,
  });
  final LearningLesson lesson;
  final double? distanceMeters;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFFF7ED),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: Color(0xFFFED7AA)),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 21,
              backgroundColor: Color(0xFFFFEDD5),
              child: Icon(
                Icons.location_on_outlined,
                color: Color(0xFFEA580C),
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEARBY INSIDER TIP · ${lesson.hotspotLabel?.toUpperCase() ?? 'MALAYSIA'}',
                    style: const TextStyle(
                      color: Color(0xFFEA580C),
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lesson.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${distanceMeters == null ? '' : '${distanceMeters!.round()}m away · '}${lesson.readTime} · +${lesson.xpReward} XP',
                    style: const TextStyle(color: AppColors.slate, fontSize: 9),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFFEA580C),
              size: 14,
            ),
          ],
        ),
      ),
    ),
  );
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.color,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String eyebrow;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: const BorderSide(color: AppColors.line),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const Spacer(),
                Icon(Icons.arrow_outward_rounded, color: color, size: 17),
              ],
            ),
            const Spacer(),
            Text(
              eyebrow,
              style: TextStyle(
                color: color,
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
                letterSpacing: .25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 2,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1.14,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.slate,
                fontSize: 8.5,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LearningError extends StatelessWidget {
  const _LearningError({required this.error, required this.onRetry});
  final Object? error;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.redSoft,
            child: Icon(Icons.cloud_off_outlined, color: AppColors.red),
          ),
          const SizedBox(height: 12),
          const Text(
            'Safety content is unavailable',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Check the connection or ask an administrator to publish Module 5 content.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate, fontSize: 11),
          ),
          const SizedBox(height: 7),
          Text(
            '$error',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.red, fontSize: 9),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 17),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

class _LearningDashboardData {
  const _LearningDashboardData({
    required this.profile,
    required this.overview,
    required this.hotspotLesson,
    required this.hotspotDistanceMeters,
  });
  final UserLearningProfile profile;
  final LearningOverview overview;
  final LearningLesson? hotspotLesson;
  final double? hotspotDistanceMeters;
  static Future<_LearningDashboardData> load(
    LearningRepository repository,
    LocationService locationService,
  ) async {
    final values = await Future.wait([
      repository.getUserProfile(),
      repository.getOverview(),
      repository.getLessons(),
    ]);
    final lessons = values[2] as List<LearningLesson>;
    LearningLesson? nearbyLesson;
    double? nearbyDistance;
    try {
      final status = await locationService.accessStatus();
      if (status == LocationAccessStatus.granted) {
        final position = await locationService.currentPosition().timeout(
          const Duration(seconds: 5),
        );
        for (final lesson in lessons.where(
          (item) =>
              item.isLocationBased &&
              item.latitude != null &&
              item.longitude != null,
        )) {
          final distance = haversineDistanceMeters(
            startLatitude: position.latitude,
            startLongitude: position.longitude,
            endLatitude: lesson.latitude!,
            endLongitude: lesson.longitude!,
          );
          if (distance <= 1500 &&
              (nearbyDistance == null || distance < nearbyDistance)) {
            nearbyLesson = lesson;
            nearbyDistance = distance;
          }
        }
      }
    } catch (_) {
      // Lessons and quizzes remain available when GPS is unavailable.
    }
    return _LearningDashboardData(
      profile: values[0] as UserLearningProfile,
      overview: values[1] as LearningOverview,
      hotspotLesson: nearbyLesson,
      hotspotDistanceMeters: nearbyDistance,
    );
  }
}
