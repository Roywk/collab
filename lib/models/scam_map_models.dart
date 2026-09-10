abstract final class ScamCategories {
  static const currencyExchange = 'Currency Exchange Scam';
  static const taxi = 'Taxi Scam';
  static const pickpocket = 'Pickpocket';
  static const overcharging = 'Overcharging';
  static const photo = 'Photo Scam';
  static const transport = 'Transport Scam';
  static const qrCodeFraud = 'QR Code Fraud';
  static const giftCard = 'Gift Card Scam';
  static const fakeServices = 'Fake Services';
  static const phishing = 'Phishing';
  static const serviceComplaint = 'Service Complaint';
  static const other = 'Other';

  static const values = <String>[
    currencyExchange,
    taxi,
    pickpocket,
    overcharging,
    photo,
    transport,
    qrCodeFraud,
    giftCard,
    fakeServices,
    phishing,
    serviceComplaint,
    other,
  ];
}

enum ScamVerificationStatus { verified, pending }

extension ScamVerificationStatusExtension on ScamVerificationStatus {
  String get databaseValue {
    switch (this) {
      case ScamVerificationStatus.verified:
        return 'Verified';
      case ScamVerificationStatus.pending:
        return 'Pending';
    }
  }

  String get label => databaseValue;

  static ScamVerificationStatus fromValue(Object? value) {
    return value?.toString().trim().toLowerCase() == 'verified'
        ? ScamVerificationStatus.verified
        : ScamVerificationStatus.pending;
  }
}

class ScamMapReport {
  const ScamMapReport({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.reportedAt,
    this.reportCode,
    this.locationName,
    this.isOfficial = false,
    this.sourceReference,
    this.evidenceUrls = const [],
    this.amountLost,
  });

  final String id;
  final String? reportCode;
  final String title;
  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final ScamVerificationStatus status;
  final DateTime reportedAt;
  final String? locationName;
  final bool isOfficial;
  final String? sourceReference;
  final List<String> evidenceUrls;
  final double? amountLost;

  bool get isVerified => status == ScamVerificationStatus.verified;

  String get analyticsLocation {
    final namedLocation = (locationName ?? '').trim();
    if (namedLocation.isNotEmpty) return namedLocation;

    const areas = <(String, double, double)>[
      ('TAR UMT / Setapak', 3.2159, 101.7304),
      ('Sentul', 3.1833, 101.6950),
      ('Chow Kit', 3.1674, 101.6980),
      ('KLCC', 3.1579, 101.7123),
      ('Bukit Bintang', 3.1466, 101.7108),
      ('Central Market', 3.1457, 101.6953),
      ('Brickfields / KL Sentral', 3.1343, 101.6861),
      ('Bangsar', 3.1292, 101.6784),
      ('Taman Shamelin', 3.1240, 101.7365),
      ('Cheras', 3.1068, 101.7259),
      ('Bukit Jalil', 3.0582, 101.6917),
    ];

    var nearest = areas.first;
    var nearestScore = double.infinity;
    for (final area in areas) {
      final latitudeDifference = latitude - area.$2;
      final longitudeDifference = (longitude - area.$3) * 0.998;
      final score =
          latitudeDifference * latitudeDifference +
          longitudeDifference * longitudeDifference;
      if (score < nearestScore) {
        nearest = area;
        nearestScore = score;
      }
    }
    return nearest.$1;
  }

  factory ScamMapReport.fromMap(Map<String, dynamic> map) {
    return ScamMapReport(
      id: map['id']?.toString() ?? '',
      reportCode: map['report_code']?.toString(),
      title: _text(map['title'], fallback: 'Reported scam incident'),
      category: _text(map['category'], fallback: 'Other'),
      description: _text(map['description']),
      latitude: _double(map['latitude']),
      longitude: _double(map['longitude']),
      status: ScamVerificationStatusExtension.fromValue(
        map['verification_status'],
      ),
      reportedAt:
          DateTime.tryParse(map['reported_at']?.toString() ?? '') ??
          DateTime.now(),
      locationName: map['location_name']?.toString(),
      isOfficial: map['is_official'] == true,
      sourceReference: map['source_reference']?.toString(),
      evidenceUrls: _stringList(map['evidence_urls']),
      amountLost: _nullableDouble(map['amount_lost']),
    );
  }

  Map<String, dynamic> toCacheMap() {
    return {
      'id': id,
      'report_code': reportCode,
      'title': title,
      'category': category,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'verification_status': status.databaseValue,
      'reported_at': reportedAt.toIso8601String(),
      'location_name': locationName,
      'is_official': isOfficial,
      'source_reference': sourceReference,
      'evidence_urls': evidenceUrls,
      'amount_lost': amountLost,
    };
  }

  static String _text(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static double _double(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _nullableDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}

class ManualScamCase {
  const ManualScamCase({
    required this.title,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.sourceReference,
  });

  final String title;
  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final String? locationName;
  final String? sourceReference;
}

class ScamThreatAnalytics {
  const ScamThreatAnalytics({
    required this.totalReports,
    required this.verifiedReports,
    required this.pendingReports,
    required this.categoryCounts,
    required this.locationCounts,
  });

  final int totalReports;
  final int verifiedReports;
  final int pendingReports;
  final Map<String, int> categoryCounts;
  final Map<String, int> locationCounts;

  factory ScamThreatAnalytics.fromReports(List<ScamMapReport> reports) {
    final categoryCounts = <String, int>{};
    final locationCounts = <String, int>{};

    for (final report in reports) {
      categoryCounts.update(
        report.category,
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      locationCounts.update(
        report.analyticsLocation,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    return ScamThreatAnalytics(
      totalReports: reports.length,
      verifiedReports: reports.where((report) => report.isVerified).length,
      pendingReports: reports.where((report) => !report.isVerified).length,
      categoryCounts: categoryCounts,
      locationCounts: locationCounts,
    );
  }
}
