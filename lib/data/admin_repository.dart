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

    final rows = (response as List?) ?? const [];
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
    final rows = (response as List?) ?? const [];
    return rows
        .map((json) => _mapScamReport(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> getModerationStats() async {
    final reportsResponse = await client
        .from('scam_reports')
        .select('verification_status, is_official, reported_at, created_at');
    final reports = (reportsResponse as List?) ?? const [];

    final total = reports.length;
    final pending = reports
        .where((r) => r['verification_status'] == 'Pending')
        .length;
    final verified = reports
        .where((r) => r['verification_status'] == 'Verified')
        .length;
    final official = reports.where((r) => r['is_official'] == true).length;
    final now = DateTime.now();
    final dailyCounts = List<int>.filled(7, 0);
    for (final report in reports) {
      final createdAt = DateTime.tryParse(
        report['created_at']?.toString() ?? '',
      );
      if (createdAt == null) continue;
      final dayDifference = DateTime(now.year, now.month, now.day)
          .difference(DateTime(createdAt.year, createdAt.month, createdAt.day))
          .inDays;
      if (dayDifference >= 0 && dayDifference < 7) {
        dailyCounts[6 - dayDifference]++;
      }
    }

    List<Map<String, dynamic>> notifications = const [];
    try {
      final notificationResponse = await client
          .from('traveller_notifications')
          .select('id, title, message, severity, published_at')
          .eq('is_active', true)
          .order('published_at', ascending: false)
          .limit(20);
      notifications = (notificationResponse as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } catch (_) {
      // The dashboard remains usable before the notification migration is run.
    }

    return {
      'total_reports': total,
      'pending_review': pending,
      'verified_reports': verified,
      'official_cases': official,
      'daily_counts': dailyCounts,
      'report_dates': reports
          .map(
            (report) =>
                report['reported_at']?.toString() ??
                report['created_at']?.toString(),
          )
          .whereType<String>()
          .toList(),
      'recent_notifications': notifications,
    };
  }

  Future<void> publishTravellerNotification({
    required String title,
    required String message,
    required String severity,
  }) async {
    await client.from('traveller_notifications').insert({
      'title': title.trim(),
      'message': message.trim(),
      'severity': severity,
      'published_by': client.auth.currentUser?.id,
      'is_active': true,
    });
  }

  Future<void> updateTravellerNotification({
    required String id,
    required String title,
    required String message,
    required String severity,
  }) async {
    await client
        .from('traveller_notifications')
        .update({
          'title': title.trim(),
          'message': message.trim(),
          'severity': severity,
        })
        .eq('id', id);
  }

  Future<void> removeTravellerNotification(String id) async {
    await client
        .from('traveller_notifications')
        .update({'is_active': false})
        .eq('id', id);
  }

  ScamReport _mapScamReport(Map<String, dynamic> json) {
    double numberOrZero(Object? value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    double? nullableNumber(Object? value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    DateTime dateOrNow(Object? value) {
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    }

    final evidenceValue = json['evidence_urls'];
    return ScamReport(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      latitude: numberOrZero(json['latitude']),
      longitude: numberOrZero(json['longitude']),
      locationName: json['location_name']?.toString(),
      amountLost: nullableNumber(json['amount_lost']),
      evidenceUrls: evidenceValue is List
          ? evidenceValue
                .map((value) => value?.toString() ?? '')
                .where((value) => value.isNotEmpty)
                .toList()
          : const [],
      verificationStatus: json['verification_status']?.toString() ?? 'Pending',
      isAnonymous: json['is_anonymous'] == true,
      adminNotes: json['admin_notes']?.toString(),
      createdAt: dateOrNow(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
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
