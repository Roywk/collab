import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/module_models.dart';

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
          'evidence_notes, police_report_reference'
          '), '
          'scam_reports(report_code)',
        )
        .eq('is_active', true)
        .order('updated_at', ascending: false);

    final rows = response as List;

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
      await client.from('threat_records').update(payload).eq('id', record.id);

      threatRecordId = record.id;
    }

    final hasAdminDetails =
        (record.evidenceNotes ?? '').trim().isNotEmpty ||
        (record.policeReportReference ?? '').trim().isNotEmpty;

    if (hasAdminDetails) {
      await client.from('threat_record_admin_details').upsert({
        'threat_record_id': threatRecordId,
        'evidence_notes': _nullableText(record.evidenceNotes),
        'police_report_reference': _nullableText(record.policeReportReference),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'threat_record_id');
    }
  }

  Future<void> deactivateThreatRecord(String recordId) async {
    await client
        .from('threat_records')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', recordId);
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
      policeReportReference: adminDetails?['police_report_reference']
          ?.toString(),
      updatedAt: DateTime.tryParse(data['updated_at']?.toString() ?? ''),
    );
  }

  static String? _nullableText(String? value) {
    final cleanedValue = value?.trim() ?? '';

    return cleanedValue.isEmpty ? null : cleanedValue;
  }
}
