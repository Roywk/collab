import 'dart:typed_data';

enum ReportInputLanguage { malay, english }

extension ReportInputLanguageDetails on ReportInputLanguage {
  String get label =>
      this == ReportInputLanguage.malay ? 'Bahasa Melayu' : 'English';

  String get apiValue => this == ReportInputLanguage.malay ? 'ms' : 'en';
}

abstract final class IncidentTypes {
  static const values = <String>[
    'Theft / Pickpocket',
    'Lost Property',
    'Fraud / Scam',
    'Assault',
    'Traffic Accident',
    'Other',
  ];
}

class IncidentReportDraft {
  const IncidentReportDraft({
    required this.incidentType,
    required this.incidentAt,
    required this.location,
    required this.description,
    required this.peopleInvolved,
    required this.lostItems,
    required this.additionalInformation,
    required this.inputLanguage,
  });

  final String incidentType;
  final DateTime incidentAt;
  final String location;
  final String description;
  final String peopleInvolved;
  final String lostItems;
  final String additionalInformation;
  final ReportInputLanguage inputLanguage;

  Map<String, dynamic> toTranslationJson() {
    return {
      'source_language': inputLanguage.apiValue,
      'incident_type': incidentType,
      'location': location,
      'description': description,
      'people_involved': peopleInvolved,
      'lost_items': lostItems,
      'additional_information': additionalInformation,
    };
  }
}

class LocalizedIncidentReport {
  const LocalizedIncidentReport({
    required this.incidentType,
    required this.location,
    required this.description,
    required this.peopleInvolved,
    required this.lostItems,
    required this.additionalInformation,
  });

  final String incidentType;
  final String location;
  final String description;
  final String peopleInvolved;
  final String lostItems;
  final String additionalInformation;

  factory LocalizedIncidentReport.fromJson(Map<String, dynamic> json) {
    return LocalizedIncidentReport(
      incidentType: json['incident_type']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      peopleInvolved: json['people_involved']?.toString() ?? '',
      lostItems: json['lost_items']?.toString() ?? '',
      additionalInformation: json['additional_information']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'incident_type': incidentType,
      'location': location,
      'description': description,
      'people_involved': peopleInvolved,
      'lost_items': lostItems,
      'additional_information': additionalInformation,
    };
  }
}

class TranslatedIncidentReport {
  const TranslatedIncidentReport({
    required this.id,
    required this.reference,
    required this.generatedAt,
    required this.draft,
    required this.english,
    required this.malay,
  });

  final String id;
  final String reference;
  final DateTime generatedAt;
  final IncidentReportDraft draft;
  final LocalizedIncidentReport english;
  final LocalizedIncidentReport malay;

  factory TranslatedIncidentReport.fromDatabaseJson(Map<String, dynamic> json) {
    final source = _jsonObject(json['source_report']);
    final inputLanguage = json['input_language']?.toString() == 'ms'
        ? ReportInputLanguage.malay
        : ReportInputLanguage.english;

    return TranslatedIncidentReport(
      id: json['id']?.toString() ?? '',
      reference: json['report_reference']?.toString() ?? '—',
      generatedAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      draft: IncidentReportDraft(
        incidentType: source['incident_type']?.toString() ?? '',
        incidentAt:
            DateTime.tryParse(json['incident_at']?.toString() ?? '') ??
            DateTime.now(),
        location: source['location']?.toString() ?? '',
        description: source['description']?.toString() ?? '',
        peopleInvolved: source['people_involved']?.toString() ?? '',
        lostItems: source['lost_items']?.toString() ?? '',
        additionalInformation:
            source['additional_information']?.toString() ?? '',
        inputLanguage: inputLanguage,
      ),
      english: LocalizedIncidentReport.fromJson(
        _jsonObject(json['english_report']),
      ),
      malay: LocalizedIncidentReport.fromJson(
        _jsonObject(json['malay_report']),
      ),
    );
  }

  static Map<String, dynamic> _jsonObject(dynamic value) {
    return value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }
}

class GeneratedIncidentPdf {
  const GeneratedIncidentPdf({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;

  String get sizeLabel {
    final kilobytes = bytes.length / 1024;
    return '${kilobytes.ceil()} KB';
  }
}
