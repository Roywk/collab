import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/awareness_admin_models.dart';

class AwarenessAdminRepository {
  AwarenessAdminRepository({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  final SupabaseClient client;

  Future<AwarenessCmsSnapshot> getSnapshot() async {
    final responses = await Future.wait([
      client.from('learning_lessons').select(),
      client.from('quiz_questions').select(),
      client.from('scenarios').select(),
      client
          .from('reward_vouchers')
          .select(
            '*,'
            'voucher_codes(id,status)',
          ),
    ]);

    final contents = <AwarenessContentSummary>[
      ...(responses[0] as List).map(
        (row) => _content(row, AwarenessContentType.lesson, row['title']),
      ),
      ...(responses[1] as List).map(
        (row) => _content(row, AwarenessContentType.quiz, row['question']),
      ),
      ...(responses[2] as List).map(
        (row) => _content(row, AwarenessContentType.scenario, row['title']),
      ),
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final vouchers = (responses[3] as List).map((row) {
      final codes = (row['voucher_codes'] as List?) ?? const [];
      final available = codes
          .where((code) => code['status'] == 'available')
          .length;
      final claimed = codes.where((code) => code['status'] == 'claimed').length;
      return AdminVoucherRecord(
        id: row['id'].toString(),
        referenceCode: row['voucher_code'] ?? '',
        partnerName: row['partner_name'] ?? '',
        title: row['title'] ?? '',
        discountAmount: row['discount_amount'] ?? '',
        requiredXp: row['required_xp'] ?? 0,
        validUntil:
            DateTime.tryParse(row['valid_until'] ?? '') ?? DateTime.now(),
        status: row['status'] ?? 'draft',
        totalCodes: codes.length,
        availableCodes: available,
        claimedCodes: claimed,
      );
    }).toList();

    return AwarenessCmsSnapshot(contents: contents, vouchers: vouchers);
  }

  AwarenessContentSummary _content(
    dynamic row,
    AwarenessContentType type,
    dynamic title,
  ) {
    return AwarenessContentSummary(
      id: row['id'].toString(),
      referenceCode: switch (type) {
        AwarenessContentType.lesson => row['lesson_code'] ?? '',
        AwarenessContentType.quiz => row['question_code'] ?? '',
        AwarenessContentType.scenario => row['scenario_code'] ?? '',
      },
      title: title?.toString() ?? 'Untitled',
      type: type,
      category: row['category'] ?? 'General',
      status: row['status'] ?? 'draft',
      updatedAt: DateTime.tryParse(row['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Future<AdminLessonDraft> getLesson(String id) async {
    final row = await client
        .from('learning_lessons')
        .select()
        .eq('id', id)
        .single();
    return AdminLessonDraft(
      id: id,
      title: row['title'] ?? '',
      category: row['category'] ?? 'General',
      difficulty: row['difficulty'] ?? 'Beginner',
      readTime: row['read_time'] ?? '3 min',
      content: row['content'] ?? '',
      redFlags: List<String>.from(row['red_flags'] ?? const []),
      whatToDo: row['what_to_do'] ?? '',
      xpReward: row['xp_reward'] ?? 20,
      status: row['status'] ?? 'draft',
      imageUrl: row['image_url'],
      hotspotLabel: row['hotspot_label'],
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      isLocationBased: row['is_location_based'] ?? false,
    );
  }

  Future<void> saveLesson(AdminLessonDraft draft) async {
    final data = {
      'title': draft.title,
      'category': draft.category,
      'difficulty': draft.difficulty,
      'read_time': draft.readTime,
      'content': draft.content,
      'red_flags': draft.redFlags,
      'what_to_do': draft.whatToDo,
      'xp_reward': draft.xpReward,
      'status': draft.status,
      'is_active': draft.status == 'published',
      'image_url': _nullable(draft.imageUrl),
      'hotspot_label': _nullable(draft.hotspotLabel),
      'latitude': draft.latitude,
      'longitude': draft.longitude,
      'is_location_based': draft.isLocationBased,
      'published_at': draft.status == 'published'
          ? DateTime.now().toIso8601String()
          : null,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (draft.id == null) {
      await client.from('learning_lessons').insert(data);
    } else {
      await client.from('learning_lessons').update(data).eq('id', draft.id!);
    }
  }

  Future<AdminQuizDraft> getQuiz(String id) async {
    final row = await client
        .from('quiz_questions')
        .select()
        .eq('id', id)
        .single();
    return AdminQuizDraft(
      id: id,
      question: row['question'] ?? '',
      options: List<String>.from(row['options'] ?? const []),
      correctIndex: row['correct_index'] ?? 0,
      explanation: row['explanation'] ?? '',
      category: row['category'] ?? 'General',
      difficulty: row['difficulty'] ?? 'Beginner',
      timeLimitSeconds: row['time_limit_seconds'] ?? 15,
      status: row['status'] ?? 'draft',
      imageUrl: row['image_url'],
    );
  }

  Future<void> saveQuiz(AdminQuizDraft draft) async {
    final data = {
      'question': draft.question,
      'options': draft.options,
      'correct_index': draft.correctIndex,
      'explanation': draft.explanation,
      'category': draft.category,
      'difficulty': draft.difficulty,
      'time_limit_seconds': draft.timeLimitSeconds,
      'status': draft.status,
      'is_active': draft.status == 'published',
      'image_url': _nullable(draft.imageUrl),
      'published_at': draft.status == 'published'
          ? DateTime.now().toIso8601String()
          : null,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (draft.id == null) {
      await client.from('quiz_questions').insert(data);
    } else {
      await client.from('quiz_questions').update(data).eq('id', draft.id!);
    }
  }

  Future<AdminScenarioDraft> getScenario(String id) async {
    final row = await client
        .from('scenarios')
        .select('*,scenario_steps(*,scenario_options(*))')
        .eq('id', id)
        .single();
    final steps = (row['scenario_steps'] as List?) ?? const [];
    final step = steps.isEmpty ? null : steps.first;
    final optionRows = (step?['scenario_options'] as List?) ?? const [];
    return AdminScenarioDraft(
      id: id,
      title: row['title'] ?? '',
      description: row['description'] ?? '',
      category: row['category'] ?? 'General',
      difficulty: row['difficulty'] ?? 'Beginner',
      xpReward: row['xp_reward'] ?? 50,
      situation: step?['situation'] ?? '',
      options: optionRows
          .map<String>((item) => item['option_text'] ?? '')
          .toList(),
      correctIndex: optionRows
          .indexWhere((item) => item['is_correct'] == true)
          .clamp(0, 99),
      feedback: optionRows.isEmpty ? '' : optionRows.first['feedback'] ?? '',
      status: row['status'] ?? 'draft',
    );
  }

  Future<void> saveScenario(AdminScenarioDraft draft) async {
    final result = await client.rpc(
      'admin_save_awareness_scenario',
      params: {
        'scenario_payload': {
          'id': draft.id,
          'title': draft.title,
          'description': draft.description,
          'category': draft.category,
          'difficulty': draft.difficulty,
          'xp_reward': draft.xpReward,
          'situation': draft.situation,
          'options': draft.options,
          'correct_index': draft.correctIndex,
          'feedback': draft.feedback,
          'status': draft.status,
        },
      },
    );
    if (result == null) {
      throw const PostgrestException(message: 'Scenario could not be saved.');
    }
  }

  Future<void> setContentStatus(
    AwarenessContentSummary item,
    String status,
  ) async {
    final table = switch (item.type) {
      AwarenessContentType.lesson => 'learning_lessons',
      AwarenessContentType.quiz => 'quiz_questions',
      AwarenessContentType.scenario => 'scenarios',
    };
    await client
        .from(table)
        .update({
          'status': status,
          'is_active': status == 'published',
          'updated_at': DateTime.now().toIso8601String(),
          if (status == 'published')
            'published_at': DateTime.now().toIso8601String(),
        })
        .eq('id', item.id);
  }

  Future<void> archiveContent(AwarenessContentSummary item) =>
      setContentStatus(item, 'archived');

  Future<void> saveVoucher(AdminVoucherDraft draft) async {
    final data = {
      'partner_name': draft.partnerName,
      'title': draft.title,
      'discount_amount': draft.discountAmount,
      'required_xp': draft.requiredXp,
      'valid_until': draft.validUntil.toIso8601String(),
      'promo_code_prefix': _voucherPrefix(draft.partnerName),
      'status': draft.status,
      'is_active': draft.status == 'published',
      'updated_at': DateTime.now().toIso8601String(),
    };

    String voucherId;
    if (draft.id == null) {
      final row = await client
          .from('reward_vouchers')
          .insert(data)
          .select('id')
          .single();
      voucherId = row['id'].toString();
    } else {
      voucherId = draft.id!;
      await client.from('reward_vouchers').update(data).eq('id', voucherId);
    }

    final codes = draft.codes
        .map((code) => code.trim().toUpperCase())
        .where((code) => code.isNotEmpty)
        .toSet();
    if (codes.isNotEmpty) {
      await client
          .from('voucher_codes')
          .upsert(
            codes
                .map((code) => {'voucher_id': voucherId, 'code': code})
                .toList(),
            onConflict: 'code',
            ignoreDuplicates: true,
          );
    }
  }

  Future<void> setVoucherStatus(String id, String status) async {
    await client
        .from('reward_vouchers')
        .update({
          'status': status,
          'is_active': status == 'published',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  String? _nullable(String? value) {
    final clean = value?.trim();
    return clean == null || clean.isEmpty ? null : clean;
  }

  String _voucherPrefix(String partnerName) {
    final clean = partnerName.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    if (clean.isEmpty) return 'V1MY';
    return clean.substring(0, clean.length.clamp(1, 6));
  }
}
