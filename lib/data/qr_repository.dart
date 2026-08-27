import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/module_models.dart';

class QrRepository {
  QrRepository({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  final SupabaseClient client;

  Future<QrVerificationResult> verifyQrData(String rawValue) async {
    final value = rawValue.trim();
    final uri = Uri.tryParse(value);

    final hasValidHost = uri != null && uri.host.isNotEmpty;

    final usesHttps = hasValidHost && uri.scheme.toLowerCase() == 'https';

    final host = hasValidHost ? uri.host.toLowerCase() : '';

    final extension = host.contains('.') ? '.${host.split('.').last}' : '';

    final matchedRecord = await _findMatchingThreatRecord(value);

    bool hasSuspiciousExtension = false;

    if (extension.isNotEmpty) {
      final extensionResponse = await client
          .from('suspicious_domain_extensions')
          .select('extension')
          .eq('extension', extension)
          .eq('is_active', true)
          .limit(1);

      hasSuspiciousExtension = (extensionResponse as List).isNotEmpty;
    }

    final impersonatesMaybank =
        host.contains('maybank2u') &&
        host != 'maybank2u.com.my' &&
        !host.endsWith('.maybank2u.com.my');

    final recordIsSafe =
        matchedRecord == null || matchedRecord.riskLevel == RiskLevel.safe;

    final isSafe =
        usesHttps &&
        !hasSuspiciousExtension &&
        !impersonatesMaybank &&
        recordIsSafe;

    final result = QrVerificationResult(
      rawValue: value,
      isSafe: isSafe,
      connectionDetail: usesHttps
          ? 'Secure HTTPS connection'
          : 'Unencrypted or invalid connection',
      domainDetail: hasSuspiciousExtension
          ? 'Suspicious extension detected: $extension'
          : extension.isEmpty
          ? 'No valid website domain detected'
          : 'No suspicious extension detected',
      phishingDetail: impersonatesMaybank
          ? 'Domain appears to impersonate Maybank2U'
          : 'No bank impersonation detected',
      merchantName: matchedRecord?.businessName,
    );

    await _saveQrHistory(
      queryValue: value,
      threatRecordId: matchedRecord?.id,
      resultStatus:
          matchedRecord?.riskLevel.label ?? (isSafe ? 'Safe' : 'High Risk'),
    );

    return result;
  }

  Future<ThreatRecord?> _findMatchingThreatRecord(String value) async {
    final qrResponse = await client
        .from('threat_records')
        .select()
        .eq('qr_data', value)
        .eq('is_active', true)
        .limit(1);

    List rows = qrResponse as List;

    if (rows.isEmpty) {
      final urlResponse = await client
          .from('threat_records')
          .select()
          .eq('official_url', value)
          .eq('is_active', true)
          .limit(1);

      rows = urlResponse as List;
    }

    if (rows.isEmpty) {
      return null;
    }

    final data = Map<String, dynamic>.from(rows.first as Map);

    return ThreatRecord(
      id: data['id']?.toString() ?? '',
      recordCode: data['record_code']?.toString() ?? '—',
      businessName: data['business_name']?.toString() ?? 'Unknown merchant',
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
      updatedAt: DateTime.tryParse(data['updated_at']?.toString() ?? ''),
    );
  }

  Future<void> _saveQrHistory({
    required String queryValue,
    required String resultStatus,
    String? threatRecordId,
  }) async {
    final currentUser = client.auth.currentUser;

    if (currentUser == null) {
      return;
    }

    await client.from('verification_history').insert({
      'user_id': currentUser.id,
      'source': 'qr_scan',
      'input_type': 'qr_data',
      'query_value': queryValue,
      'threat_record_id': threatRecordId,
      'result_status': resultStatus,
    });
  }
}
