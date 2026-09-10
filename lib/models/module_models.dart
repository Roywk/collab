enum RiskLevel { safe, suspicious, highRisk }

extension RiskLevelExtension on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.safe:
        return 'Safe';
      case RiskLevel.suspicious:
        return 'Suspicious';
      case RiskLevel.highRisk:
        return 'High Risk';
    }
  }

  static RiskLevel fromText(String? value) {
    final normalized = value?.trim().toLowerCase();

    if (normalized == 'high risk' || normalized == 'high_risk') {
      return RiskLevel.highRisk;
    }

    if (normalized == 'suspicious') {
      return RiskLevel.suspicious;
    }

    return RiskLevel.safe;
  }
}

class ThreatRecord {
  const ThreatRecord({
    required this.id,
    required this.recordCode,
    required this.businessName,
    required this.riskLevel,
    this.phone,
    this.email,
    this.officialUrl,
    this.qrData,
    this.locationTag,
    this.category = 'Other',
    this.flaggedActivities = '',
    this.registrationStatus,
    this.reportCount = 0,
    this.riskPoints = 0,
    this.matchDistance = 0,
    this.evidenceNotes,
    this.updatedAt,
  });

  final String id;
  final String recordCode;
  final String businessName;
  final RiskLevel riskLevel;

  final String? phone;
  final String? email;
  final String? officialUrl;
  final String? qrData;
  final String? locationTag;

  final String category;
  final String flaggedActivities;
  final String? registrationStatus;

  final int reportCount;
  final int riskPoints;
  final int matchDistance;

  final String? evidenceNotes;
  final DateTime? updatedAt;

  ThreatRecord copyWith({
    String? id,
    String? recordCode,
    String? businessName,
    RiskLevel? riskLevel,
    String? phone,
    String? email,
    String? officialUrl,
    String? qrData,
    String? locationTag,
    String? category,
    String? flaggedActivities,
    String? registrationStatus,
    int? reportCount,
    int? riskPoints,
    int? matchDistance,
    String? evidenceNotes,
    DateTime? updatedAt,
  }) {
    return ThreatRecord(
      id: id ?? this.id,
      recordCode: recordCode ?? this.recordCode,
      businessName: businessName ?? this.businessName,
      riskLevel: riskLevel ?? this.riskLevel,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      officialUrl: officialUrl ?? this.officialUrl,
      qrData: qrData ?? this.qrData,
      locationTag: locationTag ?? this.locationTag,
      category: category ?? this.category,
      flaggedActivities: flaggedActivities ?? this.flaggedActivities,
      registrationStatus: registrationStatus ?? this.registrationStatus,
      reportCount: reportCount ?? this.reportCount,
      riskPoints: riskPoints ?? this.riskPoints,
      matchDistance: matchDistance ?? this.matchDistance,
      evidenceNotes: evidenceNotes ?? this.evidenceNotes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ScamIncident {
  const ScamIncident({
    required this.reportCode,
    required this.category,
    required this.description,
    required this.reportedAt,
    required this.hasEvidence,
  });

  final String reportCode;
  final String category;
  final String description;
  final DateTime reportedAt;
  final bool hasEvidence;
}

class RecentSearch {
  const RecentSearch({
    required this.title,
    required this.inputType,
    required this.date,
    required this.query,
  });

  final String title;
  final String inputType;
  final DateTime date;
  final String query;
}

enum QrVerdict { safe, suspicious, highRisk, invalid, unknown }

extension QrVerdictExtension on QrVerdict {
  String get label {
    switch (this) {
      case QrVerdict.safe:
        return 'No Known Threat Detected';
      case QrVerdict.suspicious:
        return 'Caution Recommended';
      case QrVerdict.highRisk:
        return 'High-Risk Destination';
      case QrVerdict.invalid:
        return 'Invalid QR Destination';
      case QrVerdict.unknown:
        return 'Verification Incomplete';
    }
  }

  String? get historyStatus {
    switch (this) {
      case QrVerdict.safe:
        return 'Safe';
      case QrVerdict.suspicious:
        return 'Suspicious';
      case QrVerdict.highRisk:
        return 'High Risk';
      case QrVerdict.invalid:
      case QrVerdict.unknown:
        return null;
    }
  }
}

class QrVerificationResult {
  const QrVerificationResult({
    required this.rawValue,
    required this.verdict,
    required this.connectionDetail,
    required this.domainDetail,
    required this.phishingDetail,
    required this.databaseDetail,
    required this.reasons,
    this.merchantName,
    this.threatRecordId,
  });

  final String rawValue;
  final QrVerdict verdict;
  final String connectionDetail;
  final String domainDetail;
  final String phishingDetail;
  final String databaseDetail;
  final List<String> reasons;
  final String? merchantName;
  final String? threatRecordId;

  bool get isSafe => verdict == QrVerdict.safe;
  bool get isHighRisk => verdict == QrVerdict.highRisk;
  bool get canRetry => verdict == QrVerdict.unknown;
}
