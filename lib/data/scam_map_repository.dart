import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/scam_map_models.dart';
import 'scam_map_cache.dart';

class ScamMapLoadResult {
  const ScamMapLoadResult({
    required this.reports,
    required this.loadedFromCache,
  });

  final List<ScamMapReport> reports;
  final bool loadedFromCache;
}

class ScamMapRepository {
  ScamMapRepository({SupabaseClient? client, ScamMapCache? cache})
    : client = client ?? Supabase.instance.client,
      cache = cache ?? ScamMapCache();

  final SupabaseClient client;
  final ScamMapCache cache;

  Future<List<String>> getActiveCategories() async {
    try {
      final response = await client
          .from('scam_categories')
          .select('name')
          .eq('is_active', true)
          .order('display_order')
          .order('name');

      final categories = (response as List)
          .map((row) => (row as Map)['name']?.toString().trim() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      return categories.isEmpty ? ScamCategories.values : categories;
    } catch (_) {
      return ScamCategories.values;
    }
  }

  Future<ScamMapLoadResult> getActiveScamReports() async {
    try {
      final response = await client.rpc('get_scam_map_reports');

      final reports = (response as List)
          .map(
            (row) =>
                ScamMapReport.fromMap(Map<String, dynamic>.from(row as Map)),
          )
          .where((report) => report.isVerified)
          .toList();

      await cache.replaceReports(reports);
      return ScamMapLoadResult(reports: reports, loadedFromCache: false);
    } catch (_) {
      final cachedReports = (await cache.readReports())
          .where((report) => report.isVerified)
          .toList();
      if (cachedReports.isNotEmpty) {
        return ScamMapLoadResult(reports: cachedReports, loadedFromCache: true);
      }
      rethrow;
    }
  }

  Future<ScamMapLoadResult> getThreatAnalyticsReports() async {
    final response = await client
        .from('scam_reports')
        .select(
          'id, report_code, title, category, description, latitude, '
          'longitude, verification_status, reported_at, location_name, '
          'is_official, source_reference, is_active',
        )
        .eq('is_active', true)
        .inFilter('verification_status', ['Verified', 'Pending'])
        .not('latitude', 'is', null)
        .not('longitude', 'is', null)
        .order('reported_at', ascending: false);

    final reports = (response as List)
        .map(
          (row) => ScamMapReport.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();

    return ScamMapLoadResult(reports: reports, loadedFromCache: false);
  }

  Future<ScamMapReport> publishOfficialCase(ManualScamCase scamCase) async {
    final user = client.auth.currentUser;
    if (user == null || user.email == null) {
      throw const AuthException('An administrator session is required.');
    }

    final publishedAt = DateTime.now();

    final inserted = await client
        .from('scam_reports')
        .insert({
          'title': scamCase.title.trim(),
          'category': scamCase.category,
          'description': scamCase.description.trim(),
          'latitude': scamCase.latitude,
          'longitude': scamCase.longitude,
          'location_name': _nullableText(scamCase.locationName),
          'source_reference': _nullableText(scamCase.sourceReference),
          'verification_status': 'Verified',
          'is_official': true,
          'is_active': true,
          'reported_at': publishedAt.toIso8601String(),
        })
        .select(
          'id, report_code, title, category, description, latitude, '
          'longitude, verification_status, reported_at, location_name, '
          'is_official, source_reference',
        )
        .single();

    return ScamMapReport.fromMap(inserted);
  }

  static String? _nullableText(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
