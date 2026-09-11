import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/awareness_admin_models.dart';

class AwarenessAdminRepository {
  AwarenessAdminRepository({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  final SupabaseClient client;

  Future<AwarenessCmsSnapshot> getSnapshot() async {
    final responses = await Future.wait([
      client.from('learning_lessons').select(),
      client.from('quiz_sets').select(),
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
        (row) => _content(row, AwarenessContentType.quiz, row['title']),
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
        partnerId: row['partner_id']?.toString(),
      );
    }).toList();

    final partners = await getPartners();

    return AwarenessCmsSnapshot(
      contents: contents,
      vouchers: vouchers,
      partners: partners,
    );
  }

  Future<List<AdminPartnerRecord>> getPartners() async {
    try {
      final response = await client
          .from('reward_partners')
          .select()
          .order('updated_at', ascending: false);
      return (response as List)
          .map(
            (row) => AdminPartnerRecord(
              id: row['id'].toString(),
              partnerCode: row['partner_code'] ?? '',
              legalName: row['legal_name'] ?? '',
              displayName: row['display_name'] ?? '',
              category: row['category'] ?? 'Other',
              verificationStatus: row['verification_status'] ?? 'pending',
              isActive: row['is_active'] ?? true,
              registrationNumber: row['registration_number'],
              contactEmail: row['contact_email'],
              contactPhone: row['contact_phone'],
              websiteUrl: row['website_url'],
              verificationNotes: row['verification_notes'],
            ),
          )
          .toList();
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST205' || error.code == '42P01') return const [];
      rethrow;
    }
  }

  Future<void> savePartner(AdminPartnerDraft draft) async {
    final data = {
      'legal_name': draft.legalName.trim(),
      'display_name': draft.displayName.trim(),
      'category': draft.category,
      'registration_number': _nullable(draft.registrationNumber),
      'contact_email': _nullable(draft.contactEmail),
      'contact_phone': _nullable(draft.contactPhone),
      'website_url': _nullable(draft.websiteUrl),
      'verification_status': draft.verificationStatus,
      'verification_notes': _nullable(draft.verificationNotes),
      'is_active': draft.isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (draft.id == null) {
      await client.from('reward_partners').insert(data);
    } else {
      await client.from('reward_partners').update(data).eq('id', draft.id!);
    }
  }

  Future<void> archivePartner(String id) async {
    await client
        .from('reward_partners')
        .update({
          'is_active': false,
          'verification_status': 'suspended',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<AdminVoucherDraft> getVoucher(String id) async {
    final row = await client
        .from('reward_vouchers')
        .select('*,voucher_codes(code,status)')
        .eq('id', id)
        .single();
    final codes = (row['voucher_codes'] as List?) ?? const [];
    return AdminVoucherDraft(
      id: id,
      partnerId: row['partner_id']?.toString() ?? '',
      partnerName: row['partner_name'] ?? '',
      title: row['title'] ?? '',
      discountAmount: row['discount_amount'] ?? '',
      requiredXp: row['required_xp'] ?? 0,
      validUntil:
          DateTime.tryParse(row['valid_until'] ?? '') ??
          DateTime.now().add(const Duration(days: 30)),
      status: row['status'] ?? 'draft',
      codes: codes
          .where((code) => code['status'] == 'available')
          .map<String>((code) => code['code'].toString())
          .toList(),
    );
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
        AwarenessContentType.quiz => row['quiz_code'] ?? '',
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
      hotspotRadiusMeters: row['hotspot_radius_meters'] ?? 250,
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
      'hotspot_radius_meters': draft.hotspotRadiusMeters,
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
        .from('quiz_sets')
        .select('*,quiz_questions(*)')
        .eq('id', id)
        .single();
    final questionRows = List<dynamic>.from(row['quiz_questions'] ?? const [])
      ..sort(
        (a, b) => ((a['question_order'] ?? a['sort_order'] ?? 0) as int)
            .compareTo((b['question_order'] ?? b['sort_order'] ?? 0) as int),
      );
    return AdminQuizDraft(
      id: id,
      title: row['title'] ?? '',
      description: row['description'] ?? '',
      category: row['category'] ?? 'General',
      difficulty: row['difficulty'] ?? 'Beginner',
      xpReward: row['xp_reward'] ?? 80,
      status: row['status'] ?? 'draft',
      questions: questionRows
          .map(
            (question) => AdminQuizQuestionDraft(
              id: question['id']?.toString(),
              question: question['question'] ?? '',
              options: List<String>.from(question['options'] ?? const []),
              correctIndex: question['correct_index'] ?? 0,
              explanation: question['explanation'] ?? '',
              timeLimitSeconds: question['time_limit_seconds'] ?? 15,
              imageUrl: question['image_url'],
            ),
          )
          .toList(),
    );
  }

  Future<void> saveQuiz(AdminQuizDraft draft) async {
    final result = await client.rpc(
      'admin_save_quiz_set',
      params: {
        'quiz_payload': {
          'id': draft.id,
          'title': draft.title,
          'description': draft.description,
          'category': draft.category,
          'difficulty': draft.difficulty,
          'xp_reward': draft.xpReward,
          'status': draft.status,
          'questions': draft.questions
              .map(
                (question) => {
                  'question': question.question,
                  'options': question.options,
                  'correct_index': question.correctIndex,
                  'explanation': question.explanation,
                  'time_limit_seconds': question.timeLimitSeconds,
                  'image_url': _nullable(question.imageUrl),
                },
              )
              .toList(),
        },
      },
    );
    if (result == null) {
      throw const PostgrestException(message: 'Quiz could not be saved.');
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
      mediaType: row['media_type'] ?? 'none',
      mediaUrl: row['media_url'],
      mediaCaption: row['media_caption'],
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
          'media_type': draft.mediaType,
          'media_url': _nullable(draft.mediaUrl),
          'media_caption': _nullable(draft.mediaCaption),
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
    if (item.type == AwarenessContentType.quiz) {
      await client.rpc(
        'set_quiz_set_status',
        params: {'target_quiz_set_id': item.id, 'target_status': status},
      );
      return;
    }
    final table = switch (item.type) {
      AwarenessContentType.lesson => 'learning_lessons',
      AwarenessContentType.quiz => throw StateError('Handled above'),
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

  Future<void> deleteContent(AwarenessContentSummary item) async {
    if (item.status == 'published') {
      throw StateError('Published content must be archived before deletion.');
    }
    final table = switch (item.type) {
      AwarenessContentType.lesson => 'learning_lessons',
      AwarenessContentType.quiz => 'quiz_sets',
      AwarenessContentType.scenario => 'scenarios',
    };
    await client.from(table).delete().eq('id', item.id);
  }

  Future<void> saveVoucher(AdminVoucherDraft draft) async {
    final codes = draft.codes
        .map((code) => code.trim().toUpperCase())
        .where((code) => code.isNotEmpty)
        .toSet();
    if (draft.status == 'published' && codes.isEmpty) {
      throw StateError(
        'A published voucher must have at least one unique code.',
      );
    }
    final partner = await client
        .from('reward_partners')
        .select('display_name,verification_status,is_active')
        .eq('id', draft.partnerId)
        .maybeSingle();
    if (partner == null ||
        partner['verification_status'] != 'verified' ||
        partner['is_active'] != true) {
      throw StateError(
        'Only an active, verified reward partner can sponsor a voucher.',
      );
    }
    final data = {
      'partner_id': draft.partnerId,
      'partner_name': partner['display_name'],
      'title': draft.title,
      'discount_amount': draft.discountAmount,
      'required_xp': draft.requiredXp,
      'valid_until': draft.validUntil.toIso8601String(),
      'promo_code_prefix': _voucherPrefix(draft.partnerName),
      'status': draft.id == null ? 'draft' : draft.status,
      'is_active': draft.id == null ? false : draft.status == 'published',
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

    final existingRows = await client
        .from('voucher_codes')
        .select('code,status')
        .eq('voucher_id', voucherId);
    final existing = {
      for (final row in existingRows as List)
        row['code'].toString().toUpperCase(): row['status'].toString(),
    };
    final newCodes = codes
        .where((code) => !existing.containsKey(code))
        .toList();
    final restoreCodes = codes
        .where((code) => existing[code] == 'disabled')
        .toList();
    final disableCodes = existing.entries
        .where(
          (entry) => entry.value == 'available' && !codes.contains(entry.key),
        )
        .map((entry) => entry.key)
        .toList();
    if (newCodes.isNotEmpty) {
      await client
          .from('voucher_codes')
          .insert(
            newCodes
                .map((code) => {'voucher_id': voucherId, 'code': code})
                .toList(),
          );
    }
    if (restoreCodes.isNotEmpty) {
      await client
          .from('voucher_codes')
          .update({'status': 'available'})
          .eq('voucher_id', voucherId)
          .inFilter('code', restoreCodes);
    }
    if (disableCodes.isNotEmpty) {
      await client
          .from('voucher_codes')
          .update({'status': 'disabled'})
          .eq('voucher_id', voucherId)
          .inFilter('code', disableCodes);
    }
    if (draft.id == null && draft.status != 'draft') {
      await setVoucherStatus(voucherId, draft.status);
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

  Future<void> archiveVoucher(String id) => setVoucherStatus(id, 'archived');

  Future<String> uploadAwarenessMedia({
    required Uint8List bytes,
    required String fileName,
    required String folder,
    required String contentType,
  }) async {
    const bucket = 'awareness-media';
    final safeName = fileName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9._-]'),
      '-',
    );
    final userId = client.auth.currentUser?.id ?? 'admin';
    final path =
        '$folder/$userId/${DateTime.now().microsecondsSinceEpoch}-$safeName';
    await client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    return client.storage.from(bucket).getPublicUrl(path);
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
