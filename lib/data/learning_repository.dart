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
        .select('total_xp, available_xp, current_level')
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
      vouchersCount: vouchersResponse.count,
      rankTitle: _getRankTitle(profileData['current_level'] ?? 1),
      availableXp: profileData['available_xp'] ?? profileData['total_xp'] ?? 0,
    );
  }

  String _getRankTitle(int level) {
    if (level >= 10) return 'Scam-Proof Guardian';
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
      final bool isCompleted =
          userId != null && completedData.any((c) => c['user_id'] == userId);

      return LearningLesson(
        id: item['id'].toString(),
        referenceCode: item['lesson_code'] ?? '',
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
        xpReward: item['xp_reward'] ?? 20,
        hotspotLabel: item['hotspot_label'],
      );
    }).toList();
  }

  Future<void> completeLesson(String lessonId) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    await client.rpc(
      'complete_learning_lesson',
      params: {'target_lesson_id': lessonId},
    );
  }

  Future<List<Scenario>> getScenarios() async {
    final userId = client.auth.currentUser?.id;

    final response = await client
        .from('scenarios')
        .select(
          '*, scenario_steps(*, scenario_options(*)), user_completed_scenarios(user_id)',
        )
        .eq('is_active', true)
        .order('created_at');

    final List<dynamic> data = response as List<dynamic>;

    return data.map((s) {
      final List<dynamic> stepsData = s['scenario_steps'] ?? [];
      stepsData.sort(
        (a, b) => (a['step_order'] as int).compareTo(b['step_order'] as int),
      );

      final steps = stepsData.map((step) {
        final List<dynamic> optionsData = step['scenario_options'] ?? [];
        return ScenarioStep(
          situation: step['situation'],
          options: optionsData
              .map(
                (opt) => ScenarioOption(
                  text: opt['option_text'],
                  isCorrect: opt['is_correct'],
                  feedback: opt['feedback'],
                ),
              )
              .toList(),
        );
      }).toList();

      final List<dynamic> completedData = s['user_completed_scenarios'] ?? [];
      final bool isCompleted =
          userId != null && completedData.any((c) => c['user_id'] == userId);

      return Scenario(
        id: s['id'].toString(),
        referenceCode: s['scenario_code'] ?? '',
        title: s['title'],
        description: s['description'],
        difficulty: s['difficulty'],
        status: isCompleted ? 'Completed' : 'Not Started',
        xpReward: s['xp_reward'] ?? 50,
        steps: steps,
        category: s['category'] ?? 'General',
        mediaType: s['media_type'] ?? 'none',
        mediaUrl: s['media_url'],
        mediaCaption: s['media_caption'],
      );
    }).toList();
  }

  Future<bool> completeScenario(String scenarioId) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return false;

    final result = await client.rpc(
      'complete_learning_scenario',
      params: {'target_scenario_id': scenarioId},
    );
    return result == true;
  }

  Future<List<QuizQuestion>> getQuizQuestions() async {
    final response = await client
        .from('quiz_questions')
        .select('*')
        .eq('is_active', true)
        .limit(10);

    final List<dynamic> data = response as List<dynamic>;

    return data
        .map(
          (q) => QuizQuestion(
            id: q['id'].toString(),
            referenceCode: q['question_code'] ?? '',
            question: q['question'],
            options: List<String>.from(q['options']),
            correctOptionIndex: q['correct_index'],
            explanation: q['explanation'],
            category: q['category'] ?? 'General',
            imageUrl: q['image_url'],
            timeLimitSeconds: q['time_limit_seconds'] ?? 15,
          ),
        )
        .toList();
  }

  Future<int> submitQuizAttempt({
    required int score,
    required int total,
    required Duration timeTaken,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null || total == 0) return 0;

    final result = await client.rpc(
      'record_quiz_attempt',
      params: {
        'answer_score': score,
        'question_total': total,
        'elapsed_seconds': timeTaken.inSeconds,
      },
    );
    return result is num ? result.toInt() : 0;
  }

  Future<List<RewardVoucher>> getVouchers() async {
    final userId = client.auth.currentUser?.id;
    final profile = userId != null ? await getUserProfile() : null;

    final response = await client
        .from('reward_vouchers')
        .select('*, user_claimed_vouchers(user_id, full_promo_code)')
        .eq('is_active', true);

    final inventoryByVoucher = <String, int>{};
    try {
      final inventory = await client.rpc('get_reward_inventory');
      for (final row in inventory as List) {
        inventoryByVoucher[row['voucher_id'].toString()] =
            (row['available_codes'] as num?)?.toInt() ?? 0;
      }
    } on PostgrestException {
      // The inventory migration may not have been applied yet.
    }

    final List<dynamic> data = response as List<dynamic>;

    return data.map((v) {
      final List<dynamic> claimedData = v['user_claimed_vouchers'] ?? [];
      final ownClaims = claimedData
          .where((claim) => claim['user_id'] == userId)
          .toList();
      final bool isClaimed = ownClaims.isNotEmpty;
      final String? fullCode = isClaimed
          ? ownClaims.first['full_promo_code']
          : null;
      final int requiredXp = v['required_xp'] ?? 0;

      return RewardVoucher(
        id: v['id'].toString(),
        referenceCode: v['voucher_code'] ?? '',
        partnerName: v['partner_name'],
        title: v['title'],
        discountAmount: v['discount_amount'],
        expiryDate: DateTime.parse(v['valid_until']),
        requiredXp: requiredXp,
        isUnlocked: profile != null && profile.spendableXp >= requiredXp,
        isClaimed: isClaimed,
        promoCode: fullCode,
        availableCodes: inventoryByVoucher[v['id'].toString()] ?? 0,
      );
    }).toList();
  }

  Future<String> claimVoucher(String voucherId) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated");

    final result = await client.rpc(
      'claim_reward_voucher',
      params: {'target_voucher_id': voucherId},
    );
    if (result is String) return result;
    return result.toString();
  }

  Future<LearningOverview> getOverview() async {
    final results = await Future.wait([
      client.from('learning_lessons').select('id').eq('is_active', true),
      client.from('scenarios').select('id').eq('is_active', true),
      client.from('quiz_questions').select('id').eq('is_active', true),
      client.from('reward_vouchers').select('id').eq('is_active', true),
    ]);
    return LearningOverview(
      lessons: (results[0] as List).length,
      scenarios: (results[1] as List).length,
      questions: (results[2] as List).length,
      rewards: (results[3] as List).length,
    );
  }
}
