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
