import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/module_models.dart';
import '../models/report_models.dart';

class AdminRepository {
  AdminRepository({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  final SupabaseClient client;

  Future<bool> hasAdminSession() async {
    final user = client.auth.currentUser;

    if (user == null || user.email == null) {
      return false;
    }

    return await _adminAccountStatus(user.id) == true;
  }

  Future<bool?> _adminAccountStatus(String userId) async {
    final response = await client
        .from('admin_accounts')
        .select('is_active')
        .eq('id', userId)
        .limit(1);

    final rows = response as List;
    if (rows.isEmpty) return null;
    return rows.first['is_active'] == true;
  }

  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {
    if (client.auth.currentSession != null) {
      await client.auth.signOut();
    }

    try {
      await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = client.auth.currentUser;
      final adminStatus = user == null
          ? null
          : await _adminAccountStatus(user.id);

      if (adminStatus == null) {
        throw const AuthException(
          'User accounts cannot sign in here. Use the User Login page.',
        );
      }
      if (!adminStatus) {
        throw const AuthException('This administrator account is disabled.');
      }
    } catch (error) {
      if (client.auth.currentSession != null) {
        await client.auth.signOut();
      }
      rethrow;
    }
  }

  Future<void> signOutAdmin() async {
    if (client.auth.currentSession != null) {
      await client.auth.signOut();
    }
  }

  Future<List<ThreatRecord>> getThreatRecords() async {
    final response = await client
        .from('threat_records')
        .select(
          '*, '
          'threat_record_admin_details('
          'evidence_notes'
          '), '
          'scam_reports(report_code)',
        )
        .eq('is_active', true)
        .order('updated_at', ascending: false);

    final rows = (response as List?) ?? [];

    return rows.map((row) {
      return _mapThreatRecord(Map<String, dynamic>.from(row as Map));
    }).toList();
  }

  Future<void> saveThreatRecord(ThreatRecord record) async {
    final payload = <String, dynamic>{
      'business_name': record.businessName,
      'phone': _nullableText(record.phone),
      'email': _nullableText(record.email),
      'official_url': _nullableText(record.officialUrl),
      'qr_data': _nullableText(record.qrData),
      'location_tag': _nullableText(record.locationTag),
      'threat_category': record.category,
      'flagged_activities': _nullableText(record.flaggedActivities),
      'admin_risk_level': record.riskLevel.label,
      'registration_status': _nullableText(record.registrationStatus),
      'is_active': true,
      'updated_at': DateTime.now().toIso8601String(),
    };

    late String threatRecordId;

    if (record.id.isEmpty) {
      final insertedRecord = await client
          .from('threat_records')
          .insert(payload)
          .select('id')
          .single();

      threatRecordId = insertedRecord['id'].toString();
    } else {
      final updatedRecord = await client
          .from('threat_records')
          .update(payload)
          .eq('id', record.id)
          .eq('is_active', true)
          .select('id')
          .maybeSingle();

      if (updatedRecord == null) {
        throw StateError('The selected threat record no longer exists.');
      }

      threatRecordId = record.id;
    }

    await client.from('threat_record_admin_details').upsert({
      'threat_record_id': threatRecordId,
      'evidence_notes': _nullableText(record.evidenceNotes),
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'threat_record_id');
  }

  Future<void> deactivateThreatRecord(String recordId) async {
    final updatedRecord = await client
        .from('threat_records')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', recordId)
        .eq('is_active', true)
        .select('id')
        .maybeSingle();

    if (updatedRecord == null) {
      throw StateError(
        'The selected record no longer exists or has already been deactivated.',
      );
    }
  }

  // Scam Report Moderation
  Future<List<ScamReport>> getAllScamReports() async {
    final response = await client
        .from('scam_reports')
        .select()
        .order('created_at', ascending: false);

    final rows = (response as List?) ?? [];
    return rows
        .map((json) => _mapScamReport(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    String? adminNotes,
  }) async {
    await client
        .from('scam_reports')
        .update({
          'verification_status': status,
          'admin_notes': adminNotes,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', reportId);
  }

  Future<void> deleteScamReport(String reportId) async {
    await client.from('scam_reports').delete().eq('id', reportId);
  }

  Future<List<ScamReport>> getNearbyReports(
    double lat,
    double lng, {
    String? excludeId,
  }) async {
    // Basic bounding box search for nearby reports (~1km)
    final double delta = 0.01;
    var query = client
        .from('scam_reports')
        .select()
        .gte('latitude', lat - delta)
        .lte('latitude', lat + delta)
        .gte('longitude', lng - delta)
        .lte('longitude', lng + delta);

    if (excludeId != null) {
      query = query.neq('id', excludeId);
    }

    final response = await query.limit(5);
    final rows = (response as List?) ?? [];
    return rows
        .map((json) => _mapScamReport(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> getModerationStats() async {
    try {
      final reportsResponse = await client
          .from('scam_reports')
          .select('verification_status');
      final reports = (reportsResponse as List?) ?? [];

      final total = reports.length;
      final pending = reports
          .where((r) => r is Map && r['verification_status'] == 'Pending')
          .length;

      return {
        'total_reports': total,
        'pending_review': pending,
        'accuracy_rate': 94.2,
        'community_reach': '12.4k',
      };
    } catch (e) {
      return {
        'total_reports': 0,
        'pending_review': 0,
        'accuracy_rate': 0,
        'community_reach': '0',
      };
    }
  }

  ScamReport _mapScamReport(Map<String, dynamic> json) {
    // Helper to safely parse numbers and avoid "null is not a subtype of num"
    double toDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    double? toNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return ScamReport(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      locationName: json['location_name']?.toString(),
      amountLost: toNullableDouble(json['amount_lost']),
      evidenceUrls: json['evidence_urls'] != null
          ? List<String>.from(json['evidence_urls'])
          : [],
      verificationStatus: json['verification_status']?.toString() ?? 'Pending',
      isAnonymous: json['is_anonymous'] ?? false,
      adminNotes: json['admin_notes']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  ThreatRecord _mapThreatRecord(Map<String, dynamic> data) {
    final detailsValue = data['threat_record_admin_details'];

    Map<String, dynamic>? adminDetails;

    if (detailsValue is List && detailsValue.isNotEmpty) {
      adminDetails = Map<String, dynamic>.from(detailsValue.first as Map);
    } else if (detailsValue is Map) {
      adminDetails = Map<String, dynamic>.from(detailsValue);
    }

    final reportValue = data['scam_reports'];

    return ThreatRecord(
      id: data['id']?.toString() ?? '',
      recordCode: data['record_code']?.toString() ?? '—',
      businessName: data['business_name']?.toString() ?? 'Unnamed record',
      riskLevel: RiskLevelExtension.fromText(
        data['admin_risk_level']?.toString(),
      ),
      phone: data['phone']?.toString(),
      email: data['email']?.toString(),
      officialUrl: data['official_url']?.toString(),
      qrData: data['qr_data']?.toString(),
      locationTag: data['location_tag']?.toString(),
      category: data['threat_category']?.toString() ?? 'Other',
      flaggedActivities: data['flagged_activities']?.toString() ?? '',
      registrationStatus: data['registration_status']?.toString(),
      reportCount: reportValue is List ? reportValue.length : 0,
      evidenceNotes: adminDetails?['evidence_notes']?.toString(),
      updatedAt: DateTime.tryParse(data['updated_at']?.toString() ?? ''),
    );
  }

  static String? _nullableText(String? value) {
    final cleanedValue = value?.trim() ?? '';

    return cleanedValue.isEmpty ? null : cleanedValue;
  }
}
