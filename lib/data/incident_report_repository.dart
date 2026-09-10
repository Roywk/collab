import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/incident_report_models.dart';

abstract interface class IncidentReportRepository {
  Future<TranslatedIncidentReport> translateAndSave(IncidentReportDraft draft);
}

abstract interface class IncidentReportHistoryRepository {
  Future<List<TranslatedIncidentReport>> getTranslatedReports();
}

class SupabaseIncidentReportRepository
    implements IncidentReportRepository, IncidentReportHistoryRepository {
  SupabaseIncidentReportRepository({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  final SupabaseClient client;

  @override
  Future<List<TranslatedIncidentReport>> getTranslatedReports() async {
    final user = client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw const AuthException('Sign in to view translated reports.');
    }

    final response = await client
        .from('incident_reports')
        .select(
          'id, report_reference, input_language, incident_at, source_report, '
          'english_report, malay_report, created_at',
        )
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (row) => TranslatedIncidentReport.fromDatabaseJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<TranslatedIncidentReport> translateAndSave(
    IncidentReportDraft draft,
  ) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in before generating a report.');
    }

    final response = await client.functions.invoke(
      'quick-service',
      body: draft.toTranslationJson(),
    );

    if (response.status < 200 || response.status >= 300) {
      final message = response.data is Map
          ? (response.data as Map)['error']?.toString()
          : null;
      throw StateError(
        message ?? 'The report translation service is unavailable.',
      );
    }

    final payload = Map<String, dynamic>.from(response.data as Map);
    final english = LocalizedIncidentReport.fromJson(
      Map<String, dynamic>.from(payload['english'] as Map),
    );
    final malay = LocalizedIncidentReport.fromJson(
      Map<String, dynamic>.from(payload['malay'] as Map),
    );

    final inserted = await client
        .from('incident_reports')
        .insert({
          'user_id': user.id,
          'input_language': draft.inputLanguage.apiValue,
          'incident_at': draft.incidentAt.toUtc().toIso8601String(),
          'source_report': draft.toTranslationJson(),
          'english_report': english.toJson(),
          'malay_report': malay.toJson(),
          'translation_model': payload['model']?.toString(),
          'status': 'translated',
        })
        .select('id, report_reference, created_at')
        .single();

    return TranslatedIncidentReport(
      id: inserted['id'].toString(),
      reference: inserted['report_reference'].toString(),
      generatedAt:
          DateTime.tryParse(inserted['created_at']?.toString() ?? '') ??
          DateTime.now(),
      draft: draft,
      english: english,
      malay: malay,
    );
  }
}
