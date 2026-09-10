import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_error_message.dart';
import '../models/module_models.dart';

class VerificationRepository {
  VerificationRepository({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  final SupabaseClient client;

  Future<List<RecentSearch>> getRecentSearches() async {
    final currentUser = client.auth.currentUser;

    if (currentUser == null) {
      return [];
    }

    final response = await client
        .from('verification_history')
        .select(
          'query_value, input_type, checked_at, '
          'threat_records(business_name)',
        )
        .eq('user_id', currentUser.id)
        .order('checked_at', ascending: false)
        .limit(20);

    final rows = response as List;
    final recentItems = <RecentSearch>[];
    final seenSearches = <String>{};

    for (final row in rows) {
      final data = Map<String, dynamic>.from(row as Map);

      final queryValue = data['query_value']?.toString() ?? '';

      final inputType = data['input_type']?.toString() ?? '';

      final uniqueKey =
          '${inputType.toLowerCase()}:'
          '${queryValue.toLowerCase()}';

      if (!seenSearches.add(uniqueKey)) {
        continue;
      }

      final relatedRecord = data['threat_records'];
      String title = queryValue;

      if (relatedRecord is Map && relatedRecord['business_name'] != null) {
        title = relatedRecord['business_name'].toString();
      }

      recentItems.add(
        RecentSearch(
          title: title,
          inputType: _inputTypeLabel(inputType),
          date:
              DateTime.tryParse(data['checked_at']?.toString() ?? '') ??
              DateTime.now(),
          query: queryValue,
        ),
      );

      if (recentItems.length == 3) {
        break;
      }
    }

    return recentItems;
  }

  Future<ThreatRecord> searchBusiness(String query) async {
    final cleanedQuery = query.trim();

    if (cleanedQuery.isEmpty) {
      throw ArgumentError('Enter a business name, phone, email or URL.');
    }

    final response = await client.rpc(
      'verify_business',
      params: {'p_query': cleanedQuery},
    );

    final rows = response is List ? response : <dynamic>[];

    late ThreatRecord result;

    if (rows.isEmpty) {
      result = ThreatRecord(
        id: '',
        recordCode: '—',
        businessName: cleanedQuery,
        riskLevel: RiskLevel.safe,
        registrationStatus: 'No official record found',
      );
    } else {
      final data = Map<String, dynamic>.from(rows.first as Map);

      result = ThreatRecord(
        id: data['threat_record_id']?.toString() ?? '',
        recordCode: data['record_code']?.toString() ?? '—',
        businessName: data['business_name']?.toString() ?? cleanedQuery,
        phone: data['phone']?.toString(),
        email: data['email']?.toString(),
        officialUrl: data['official_url']?.toString(),
        locationTag: data['location_tag']?.toString(),
        category: data['threat_category']?.toString() ?? 'Other',
        flaggedActivities: data['flagged_activities']?.toString() ?? '',
        registrationStatus: data['registration_status']?.toString(),
        reportCount: _toInteger(data['report_count']),
        riskPoints: _toInteger(data['risk_points']),
        matchDistance: _toInteger(data['match_distance']),
        riskLevel: RiskLevelExtension.fromText(
          data['calculated_risk']?.toString(),
        ),
      );
    }

    await _saveVerificationBestEffort(
      source: 'business_search',
      inputType: _detectInputType(cleanedQuery),
      queryValue: cleanedQuery,
      result: result,
    );

    return result;
  }

  Future<List<ScamIncident>> getScamHistory(String threatRecordId) async {
    if (threatRecordId.isEmpty) {
      return [];
    }

    final response = await client
        .from('scam_reports')
        .select(
          'report_code, category, description, '
          'evidence_urls, reported_at',
        )
        .eq('threat_record_id', threatRecordId)
        .eq('verification_status', 'Verified')
        .order('reported_at', ascending: false);

    final rows = response as List;

    return rows.map((row) {
      final data = Map<String, dynamic>.from(row as Map);
      final evidence = data['evidence_urls'];

      return ScamIncident(
        reportCode: data['report_code']?.toString() ?? '—',
        category: data['category']?.toString() ?? 'Report',
        description: data['description']?.toString() ?? '',
        reportedAt:
            DateTime.tryParse(data['reported_at']?.toString() ?? '') ??
            DateTime.now(),
        hasEvidence: evidence is List && evidence.isNotEmpty,
      );
    }).toList();
  }

  Future<void> _saveVerificationBestEffort({
    required String source,
    required String inputType,
    required String queryValue,
    required ThreatRecord result,
  }) async {
    final currentUser = client.auth.currentUser;

    if (currentUser == null || result.id.isEmpty) {
      return;
    }

    try {
      await client.from('verification_history').insert({
        'user_id': currentUser.id,
        'source': source,
        'input_type': inputType,
        'query_value': queryValue,
        'threat_record_id': result.id,
        'result_status': result.riskLevel.label,
      });
    } catch (error, stackTrace) {
      logDebugError('Save business verification history', error, stackTrace);
    }
  }

  static int _toInteger(dynamic value) {
    if (value is num) {
      return value.round();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _detectInputType(String value) {
    if (value.contains('@')) {
      return 'email';
    }

    if (RegExp(r'^[+\d\s()-]+$').hasMatch(value)) {
      return 'phone';
    }

    if (value.contains('://') ||
        RegExp(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}').hasMatch(value)) {
      return 'url';
    }

    return 'business_name';
  }

  static String _inputTypeLabel(String? value) {
    switch (value) {
      case 'url':
        return 'URL search';
      case 'phone':
        return 'Phone search';
      case 'email':
        return 'Email search';
      case 'qr_data':
        return 'QR scan';
      default:
        return 'Name search';
    }
  }
}
