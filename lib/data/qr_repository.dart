import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_error_message.dart';
import '../models/module_models.dart';
import '../services/qr_analysis_service.dart';

class QrRepository {
  QrRepository({SupabaseClient? client})
    : client = client ?? Supabase.instance.client;

  final SupabaseClient client;

  Future<QrVerificationResult> verifyQrData(String rawValue) async {
    final value = rawValue.trim();
    final destination = QrAnalysisService.analyseDestination(value);

    if (!destination.isValid) {
      return QrVerificationResult(
        rawValue: value,
        verdict: QrVerdict.invalid,
        connectionDetail: 'Not checked',
        domainDetail: destination.invalidReason ?? 'Invalid destination',
        phishingDetail: 'Not checked',
        databaseDetail: 'Not checked',
        reasons: [
          destination.invalidReason ??
              'The QR code does not contain a supported website destination.',
        ],
      );
    }

    try {
      final extension = QrAnalysisService.domainExtension(destination.host);

      final matchingRecordFuture = _findMatchingThreatRecord(value);
      final suspiciousExtensionFuture = _hasSuspiciousExtension(extension);
      final protectedBrandsFuture = _loadProtectedBrands();

      final matchedRecord = await matchingRecordFuture;
      final hasSuspiciousExtension = await suspiciousExtensionFuture;
      final protectedBrands = await protectedBrandsFuture;

      final impersonatedBrand = QrAnalysisService.findImpersonatedBrand(
        destination.host,
        protectedBrands,
      );

      final reasons = <String>[];
      final matchedHighRisk = matchedRecord?.riskLevel == RiskLevel.highRisk;
      final matchedSuspicious =
          matchedRecord?.riskLevel == RiskLevel.suspicious;

      final QrVerdict verdict;

      if (matchedHighRisk ||
          hasSuspiciousExtension ||
          impersonatedBrand != null) {
        verdict = QrVerdict.highRisk;

        if (matchedHighRisk) {
          reasons.add('The destination matches an active high-risk record.');
        }
        if (hasSuspiciousExtension) {
          reasons.add('The domain uses the flagged extension $extension.');
        }
        if (impersonatedBrand != null) {
          reasons.add('The domain may be impersonating $impersonatedBrand.');
        }
      } else if (matchedSuspicious ||
          !destination.usesHttps ||
          destination.isIpAddress ||
          destination.usesPunycode) {
        verdict = QrVerdict.suspicious;

        if (matchedSuspicious) {
          reasons.add('The destination matches an active suspicious record.');
        }
        if (!destination.usesHttps) {
          reasons.add('The destination does not use an encrypted HTTPS link.');
        }
        if (destination.isIpAddress) {
          reasons.add(
            'The destination uses an IP address instead of a domain.',
          );
        }
        if (destination.usesPunycode) {
          reasons.add(
            'The destination contains an encoded international domain.',
          );
        }
      } else {
        verdict = QrVerdict.safe;
        reasons.add('The HTTPS and current database checks found no warning.');
      }

      final result = QrVerificationResult(
        rawValue: value,
        verdict: verdict,
        connectionDetail: destination.usesHttps
            ? 'Secure HTTPS connection'
            : 'Unencrypted HTTP connection',
        domainDetail: hasSuspiciousExtension
            ? 'Flagged extension detected: $extension'
            : 'No flagged extension detected',
        phishingDetail: impersonatedBrand == null
            ? 'No protected-brand impersonation detected'
            : 'Possible impersonation of $impersonatedBrand',
        databaseDetail: matchedRecord == null
            ? 'No active threat record matched'
            : 'Matched ${matchedRecord.recordCode}: '
                  '${matchedRecord.riskLevel.label}',
        reasons: reasons,
        merchantName: matchedRecord?.businessName,
        threatRecordId: matchedRecord?.id,
      );

      await _saveQrHistoryBestEffort(result);
      return result;
    } catch (error, stackTrace) {
      logDebugError('QR online verification', error, stackTrace);

      return QrVerificationResult(
        rawValue: value,
        verdict: QrVerdict.unknown,
        connectionDetail: destination.usesHttps
            ? 'Secure HTTPS connection'
            : 'Unencrypted HTTP connection',
        domainDetail: 'Online domain check unavailable',
        phishingDetail: 'Online phishing check unavailable',
        databaseDetail: 'Threat database check unavailable',
        reasons: const [
          'The online security checks could not be completed.',
          'Do not treat this destination as safe until verification succeeds.',
        ],
      );
    }
  }

  Future<bool> _hasSuspiciousExtension(String extension) async {
    if (extension.isEmpty) {
      return false;
    }

    final response = await client
        .from('suspicious_domain_extensions')
        .select('extension')
        .eq('extension', extension)
        .eq('is_active', true)
        .limit(1);

    return (response as List).isNotEmpty;
  }

  Future<List<ProtectedBrand>> _loadProtectedBrands() async {
    final response = await client
        .from('threat_records')
        .select('business_name, official_url')
        .eq('is_active', true)
        .eq('admin_risk_level', 'Safe')
        .eq('threat_category', 'Verified Merchant')
        .not('official_url', 'is', null);

    final rows = response as List;
    final brands = <ProtectedBrand>[];

    for (final row in rows) {
      final data = Map<String, dynamic>.from(row as Map);
      final name = data['business_name']?.toString().trim() ?? '';
      final officialUrl = data['official_url']?.toString().trim() ?? '';
      final uri = Uri.tryParse(
        officialUrl.contains('://') ? officialUrl : 'https://$officialUrl',
      );

      if (name.isNotEmpty && uri != null && uri.host.isNotEmpty) {
        brands.add(ProtectedBrand(name: name, officialDomain: uri.host));
      }
    }

    return brands;
  }

  Future<ThreatRecord?> _findMatchingThreatRecord(String value) async {
    final selectedColumns =
        'id, record_code, business_name, admin_risk_level, phone, email, '
        'official_url, qr_data, location_tag, threat_category, '
        'flagged_activities, registration_status, updated_at';

    final qrResponse = await client
        .from('threat_records')
        .select(selectedColumns)
        .eq('qr_data', value)
        .eq('is_active', true)
        .limit(1);

    List rows = qrResponse as List;

    if (rows.isEmpty) {
      final urlResponse = await client
          .from('threat_records')
          .select(selectedColumns)
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

  Future<void> _saveQrHistoryBestEffort(QrVerificationResult result) async {
    final currentUser = client.auth.currentUser;
    final historyStatus = result.verdict.historyStatus;

    if (currentUser == null || historyStatus == null) {
      return;
    }

    try {
      await client.from('verification_history').insert({
        'user_id': currentUser.id,
        'source': 'qr_scan',
        'input_type': 'qr_data',
        'query_value': result.rawValue,
        'threat_record_id': result.threatRecordId,
        'result_status': historyStatus,
      });
    } catch (error, stackTrace) {
      logDebugError('Save QR verification history', error, stackTrace);
    }
  }
}
