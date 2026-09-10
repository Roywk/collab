import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/scam_map_models.dart';

class ThreatExportService {
  Future<String> exportCsv(List<ScamMapReport> reports) async {
    final rows = <List<dynamic>>[
      [
        'Report Code',
        'Title',
        'Category',
        'Status',
        'Location',
        'Latitude',
        'Longitude',
        'Reported At',
        'Official',
        'Source Reference',
      ],
      for (final report in reports)
        [
          report.reportCode ?? report.id,
          report.title,
          report.category,
          report.status.label,
          report.locationName ?? '',
          report.latitude,
          report.longitude,
          report.reportedAt.toIso8601String(),
          report.isOfficial ? 'Yes' : 'No',
          report.sourceReference ?? '',
        ],
    ];

    final content = excel.encode(rows);
    return FileSaver.instance.saveFile(
      name: _fileName('visit1my_threat_analytics'),
      bytes: Uint8List.fromList(utf8.encode(content)),
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
  }

  Future<String> exportPdf(List<ScamMapReport> reports) async {
    final analytics = ScamThreatAnalytics.fromReports(reports);
    final document = pw.Document(
      title: 'Visit 1MY Threat Analytics',
      author: 'Visit 1MY',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Visit 1MY - Threat Analytics',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.Text(
              'Generated ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ),
        build: (context) => [
          pw.Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _summaryBox('Total reports', analytics.totalReports),
              _summaryBox('Verified', analytics.verifiedReports),
              _summaryBox('Pending', analytics.pendingReports),
              _summaryBox('Locations', analytics.locationCounts.length),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Incident records',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Title',
              'Category',
              'Status',
              'Location',
              'Coordinates',
              'Date',
            ],
            data: reports
                .map(
                  (report) => [
                    report.title,
                    report.category,
                    report.status.label,
                    report.locationName ?? '-',
                    '${report.latitude.toStringAsFixed(5)}, '
                        '${report.longitude.toStringAsFixed(5)}',
                    DateFormat('dd MMM yyyy').format(report.reportedAt),
                  ],
                )
                .toList(),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    return FileSaver.instance.saveFile(
      name: _fileName('visit1my_threat_analytics'),
      bytes: await document.save(),
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  pw.Widget _summaryBox(String label, int value) {
    return pw.Container(
      width: 115,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$value',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  String _fileName(String prefix) {
    return '${prefix}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
  }
}
