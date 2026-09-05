import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/incident_report_models.dart';

class IncidentReportPdfService {
  Future<GeneratedIncidentPdf> generate(TranslatedIncidentReport report) async {
    final document = pw.Document(
      title: 'PDRM Incident Report ${report.reference}',
      author: 'Visit 1MY',
      subject: 'Automated bilingual incident report translation',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 42, 42, 38),
        header: (_) => _header(),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Visit 1MY - Tourist Emergency Assistance',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
        build: (_) => [
          _referenceBlock(report),
          pw.SizedBox(height: 18),
          _sectionTitle('LAPORAN BAHASA MELAYU'),
          pw.SizedBox(height: 10),
          _reportFields(report, report.malay, malay: true),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 14),
          _sectionTitle('ENGLISH TRANSLATION / SOURCE'),
          pw.SizedBox(height: 10),
          _reportFields(report, report.english, malay: false),
          pw.SizedBox(height: 22),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            color: PdfColor.fromHex('#FFF7D6'),
            child: pw.Text(
              'Important: This document is an automated translation prepared '
              'to assist communication. Police officers may verify or amend '
              'the wording when the official report is lodged.',
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.brown),
            ),
          ),
        ],
      ),
    );

    final date = DateFormat('yyyyMMdd').format(report.draft.incidentAt);
    return GeneratedIncidentPdf(
      bytes: await document.save(),
      fileName: 'PDRM_Report_$date',
    );
  }

  pw.Widget _header() {
    return pw.Column(
      children: [
        pw.Text(
          'LAPORAN POLIS / POLICE REPORT',
          style: pw.TextStyle(
            color: PdfColors.blue900,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'VISIT 1MY AUTOMATED REPORT TRANSLATION',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 8),
      ],
    );
  }

  pw.Widget _referenceBlock(TranslatedIncidentReport report) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F7FB'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Reference: ${report.reference}',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Generated: ${DateFormat('dd MMM yyyy, HH:mm').format(report.generatedAt.toLocal())}',
            style: const pw.TextStyle(fontSize: 8.5),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        color: PdfColors.blue900,
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  pw.Widget _reportFields(
    TranslatedIncidentReport report,
    LocalizedIncidentReport localized, {
    required bool malay,
  }) {
    final date = malay
        ? _formatMalayDate(report.draft.incidentAt)
        : DateFormat('dd MMM yyyy, HH:mm').format(report.draft.incidentAt);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _field(
          malay ? 'JENIS INSIDEN' : 'INCIDENT TYPE',
          localized.incidentType,
        ),
        _field(malay ? 'TARIKH & MASA' : 'DATE & TIME', date),
        _field(malay ? 'LOKASI' : 'LOCATION', localized.location),
        _field(
          malay ? 'PENERANGAN KEJADIAN' : 'INCIDENT DESCRIPTION',
          localized.description,
        ),
        _field(
          malay ? 'INDIVIDU TERLIBAT' : 'PEOPLE INVOLVED',
          localized.peopleInvolved,
        ),
        _field(
          malay ? 'BARANGAN HILANG' : 'LOST / STOLEN ITEMS',
          localized.lostItems,
        ),
        if (localized.additionalInformation.trim().isNotEmpty)
          _field(
            malay ? 'MAKLUMAT TAMBAHAN' : 'ADDITIONAL INFORMATION',
            localized.additionalInformation,
          ),
      ],
    );
  }

  pw.Widget _field(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: PdfColors.blueGrey700,
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9.5, height: 1.3)),
        ],
      ),
    );
  }

  String _formatMalayDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mac',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ogos',
      'Sep',
      'Okt',
      'Nov',
      'Dis',
    ];
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.day} ${months[value.month - 1]} ${value.year}, '
        '${value.hour}:$minute';
  }
}
