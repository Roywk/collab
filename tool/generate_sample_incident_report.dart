import 'dart:io';

import 'package:collab/models/incident_report_models.dart';
import 'package:collab/services/incident_report_pdf_service.dart';

Future<void> main() async {
  final draft = IncidentReportDraft(
    incidentType: 'Theft / Pickpocket',
    incidentAt: DateTime(2025, 8, 15, 14, 30),
    location: 'Jalan Alor, Bukit Bintang, Kuala Lumpur',
    description:
        'My wallet was stolen from my back pocket while walking through the '
        'night market. I noticed it missing after about 10 minutes.',
    peopleInvolved: 'One victim (self), unknown suspect',
    lostItems: 'Brown leather wallet, RM 350 cash, Visa debit card',
    additionalInformation: 'The suspect may have worn a dark hoodie.',
    inputLanguage: ReportInputLanguage.english,
  );

  final report = TranslatedIncidentReport(
    id: 'sample-report',
    reference: '1MY-PDRM-20250815-000001',
    generatedAt: DateTime(2025, 8, 15, 14, 45),
    draft: draft,
    english: const LocalizedIncidentReport(
      incidentType: 'Theft / Pickpocket',
      location: 'Jalan Alor, Bukit Bintang, Kuala Lumpur',
      description:
          'My wallet was stolen from my back pocket while walking through the '
          'night market. I noticed it missing after about 10 minutes.',
      peopleInvolved: 'One victim (self), unknown suspect',
      lostItems: 'Brown leather wallet, RM 350 cash, Visa debit card',
      additionalInformation: 'The suspect may have worn a dark hoodie.',
    ),
    malay: const LocalizedIncidentReport(
      incidentType: 'Kecurian / Pencopet',
      location: 'Jalan Alor, Bukit Bintang, Kuala Lumpur',
      description:
          'Dompet saya telah dicuri dari poket belakang semasa berjalan '
          'melalui pasar malam. Saya menyedari kehilangannya selepas kira-kira '
          '10 minit.',
      peopleInvolved: 'Seorang mangsa (diri sendiri), suspek tidak dikenali',
      lostItems: 'Dompet kulit coklat, wang tunai RM 350, kad debit Visa',
      additionalInformation:
          'Suspek mungkin memakai baju hoodie berwarna gelap.',
    ),
  );

  final generated = await IncidentReportPdfService().generate(report);
  final directory = Directory('output/pdf')..createSync(recursive: true);
  final file = File('${directory.path}/sample_pdrm_incident_report.pdf');
  await file.writeAsBytes(generated.bytes, flush: true);
  stdout.writeln(file.absolute.path);
}
