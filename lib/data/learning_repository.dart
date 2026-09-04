import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/learning_models.dart';

class LearningRepository {
  LearningRepository({SupabaseClient? client})
      : client = client ?? Supabase.instance.client;

  final SupabaseClient client;

  Future<UserLearningProfile> getUserProfile() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated");

    final profileData = await client
        .from('profiles')
        .select('total_xp, current_level')
        .eq('id', userId)
        .single();

    final vouchersResponse = await client
        .from('user_claimed_vouchers')
        .select('id')
        .eq('user_id', userId)
        .count(CountOption.exact);

    return UserLearningProfile(
      userId: userId,
      totalXp: profileData['total_xp'] ?? 0,
      currentLevel: profileData['current_level'] ?? 1,
      vouchersCount: vouchersResponse.count ?? 0,
      rankTitle: _getRankTitle(profileData['current_level'] ?? 1),
    );
  }

  String _getRankTitle(int level) {
    if (level >= 10) return 'Scam Mastermind';
    if (level >= 7) return 'Fraud Fighter';
    if (level >= 4) return 'Safety Sentinel';
    return 'Vigilant Voyager';
  }

  Future<List<LearningLesson>> getLessons() async {
    final userId = client.auth.currentUser?.id;
    
    final response = await client
        .from('learning_lessons')
        .select('*, user_completed_lessons(user_id)')
        .eq('is_active', true);

    final List<dynamic> data = response as List<dynamic>;

    return data.map((item) {
      final List<dynamic> completedData = item['user_completed_lessons'] ?? [];
      final bool isCompleted = userId != null && 
          completedData.any((c) => c['user_id'] == userId);

      return LearningLesson(
        id: item['id'].toString(),
        title: item['title'],
        category: item['category'],
        readTime: item['read_time'],
        difficulty: item['difficulty'],
        content: item['content'],
        imageUrl: item['image_url'],
        redFlags: List<String>.from(item['red_flags'] ?? []),
        whatToDo: item['what_to_do'] ?? '',
        latitude: item['latitude']?.toDouble(),
        longitude: item['longitude']?.toDouble(),
        isLocationBased: item['is_location_based'] ?? false,
        isCompleted: isCompleted,
      );
    }).toList();
  }

  Future<void> completeLesson(String lessonId) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    // Check if already completed to avoid double XP if we were awarding XP here
    final existing = await client
        .from('user_completed_lessons')
        .select('id')
        .eq('user_id', userId)
        .eq('lesson_id', lessonId)
        .maybeSingle();

    if (existing == null) {
      await client.from('user_completed_lessons').insert({
        'user_id': userId,
        'lesson_id': lessonId,
        'completed_at': DateTime.now().toIso8601String(),
      });
      
      // Award a small amount of XP for reading a lesson
      await updateXp(10);
    }
  }

  Future<List<Scenario>> getScenarios() async {
    final userId = client.auth.currentUser?.id;
    
    final response = await client
        .from('scenarios')
        .select('*, scenario_steps(*, scenario_options(*)), user_completed_scenarios(user_id)')
        .eq('is_active', true)
        .order('created_at');

    final List<dynamic> data = response as List<dynamic>;

    return data.map((s) {
      final List<dynamic> stepsData = s['scenario_steps'] ?? [];
      stepsData.sort((a, b) => (a['step_order'] as int).compareTo(b['step_order'] as int));

      final steps = stepsData.map((step) {
        final List<dynamic> optionsData = step['scenario_options'] ?? [];
        return ScenarioStep(
          situation: step['situation'],
          options: optionsData.map((opt) => ScenarioOption(
            text: opt['option_text'],
            isCorrect: opt['is_correct'],
            feedback: opt['feedback'],
          )).toList(),
        );
      }).toList();

      final List<dynamic> completedData = s['user_completed_scenarios'] ?? [];
      final bool isCompleted = userId != null && 
          completedData.any((c) => c['user_id'] == userId);

      return Scenario(
        id: s['id'].toString(),
        title: s['title'],
        description: s['description'],
        difficulty: s['difficulty'],
        status: isCompleted ? 'Completed' : 'Not Started',
        xpReward: s['xp_reward'] ?? 50,
        steps: steps,
      );
    }).toList();
  }

  Future<void> completeScenario(String scenarioId, int xpReward) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    await client.from('user_completed_scenarios').upsert({
      'user_id': userId,
      'scenario_id': scenarioId,
      'completed_at': DateTime.now().toIso8601String(),
    });

    await updateXp(xpReward);
  }

  Future<List<QuizQuestion>> getQuizQuestions() async {
    final response = await client
        .from('quiz_questions')
        .select('*')
        .eq('is_active', true)
        .limit(10);

    final List<dynamic> data = response as List<dynamic>;

    return data.map((q) => QuizQuestion(
      id: q['id'].toString(),
      question: q['question'],
      options: List<String>.from(q['options']),
      correctOptionIndex: q['correct_index'],
      explanation: q['explanation'],
    )).toList();
  }

  Future<void> updateXp(int xpEarned) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final profile = await client
        .from('profiles')
        .select('total_xp, current_level')
        .eq('id', userId)
        .single();

    int newTotalXp = (profile['total_xp'] ?? 0) + xpEarned;
    int currentLevel = profile['current_level'] ?? 1;
    
    // Level up logic: every 200 XP = 1 level
    int newLevel = (newTotalXp / 200).floor() + 1;
    if (newLevel < 1) newLevel = 1;

    await client.from('profiles').update({
      'total_xp': newTotalXp,
      'current_level': newLevel,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<List<RewardVoucher>> getVouchers() async {
    final userId = client.auth.currentUser?.id;
    final profile = userId != null ? await getUserProfile() : null;

    final response = await client
        .from('reward_vouchers')
        .select('*, user_claimed_vouchers(full_promo_code)')
        .eq('is_active', true);

    final List<dynamic> data = response as List<dynamic>;

    return data.map((v) {
      final List<dynamic> claimedData = v['user_claimed_vouchers'] ?? [];
      final bool isClaimed = claimedData.isNotEmpty;
      final String? fullCode = isClaimed ? claimedData.first['full_promo_code'] : null;
      final int requiredXp = v['required_xp'] ?? 0;

      return RewardVoucher(
        id: v['id'].toString(),
        partnerName: v['partner_name'],
        title: v['title'],
        discountAmount: v['discount_amount'],
        expiryDate: DateTime.parse(v['valid_until']),
        requiredXp: requiredXp,
        isUnlocked: profile != null && profile.totalXp >= requiredXp,
        isClaimed: isClaimed,
        promoCode: fullCode,
      );
    }).toList();
  }

  Future<String> claimVoucher(String voucherId) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated");

    // Generate a random promo code for simulation
    final String promoCode = 'VISIT1MY-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';

    await client.from('user_claimed_vouchers').insert({
      'user_id': userId,
      'voucher_id': voucherId,
      'full_promo_code': promoCode,
      'claimed_at': DateTime.now().toIso8601String(),
    });

    return promoCode;
  }
}
