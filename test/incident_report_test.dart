import 'package:collab/models/incident_report_models.dart';
import 'package:collab/services/incident_report_pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final draft = IncidentReportDraft(
    incidentType: 'Theft / Pickpocket',
    incidentAt: DateTime(2025, 8, 15, 14, 30),
    location: 'Jalan Alor, Bukit Bintang, Kuala Lumpur',
    description:
        'My wallet was stolen while I was walking through the night market.',
    peopleInvolved: 'One victim, unknown suspect',
    lostItems: 'Brown wallet, RM 350 cash, Visa debit card',
    additionalInformation: 'The suspect wore a dark hoodie.',
    inputLanguage: ReportInputLanguage.english,
  );

  const english = LocalizedIncidentReport(
    incidentType: 'Theft / Pickpocket',
    location: 'Jalan Alor, Bukit Bintang, Kuala Lumpur',
    description:
        'My wallet was stolen while I was walking through the night market.',
    peopleInvolved: 'One victim, unknown suspect',
    lostItems: 'Brown wallet, RM 350 cash, Visa debit card',
    additionalInformation: 'The suspect wore a dark hoodie.',
  );

  const malay = LocalizedIncidentReport(
    incidentType: 'Kecurian / Pencopet',
    location: 'Jalan Alor, Bukit Bintang, Kuala Lumpur',
    description:
        'Dompet saya telah dicuri semasa saya berjalan melalui pasar malam.',
    peopleInvolved: 'Seorang mangsa, suspek tidak dikenali',
    lostItems: 'Dompet coklat, wang tunai RM 350, kad debit Visa',
    additionalInformation: 'Suspek memakai baju hoodie berwarna gelap.',
  );

  test('translation payload preserves all tourist-entered fields', () {
    final json = draft.toTranslationJson();

    expect(json['source_language'], 'en');
    expect(json['location'], contains('Jalan Alor'));
    expect(json['lost_items'], contains('RM 350'));
    expect(json['additional_information'], contains('hoodie'));
  });

  test('incident PDF generator creates a valid bilingual PDF', () async {
    final report = TranslatedIncidentReport(
      id: 'report-id',
      reference: '1MY-PDRM-20250815-000001',
      generatedAt: DateTime(2025, 8, 15, 14, 45),
      draft: draft,
      english: english,
      malay: malay,
    );

    final pdf = await IncidentReportPdfService().generate(report);

    expect(String.fromCharCodes(pdf.bytes.take(4)), '%PDF');
    expect(pdf.fileName, 'PDRM_Report_20250815');
    expect(pdf.bytes.length, greaterThan(1000));
  });
}
