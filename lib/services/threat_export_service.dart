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
        'Amount Lost (RM)',
        'Evidence Count',
        'Source Reference',
      ],
      for (final report in reports)
        [
          report.reportCode ?? report.id,
          report.title,
          report.category,
          report.status.label,
          report.analyticsLocation,
          report.latitude,
          report.longitude,
          report.reportedAt.toIso8601String(),
          report.isOfficial ? 'Yes' : 'No',
          report.amountLost ?? 0,
          report.evidenceUrls.length,
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
    final categories = analytics.categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final hotspots = analytics.locationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalLoss = reports.fold<double>(
      0,
      (sum, report) => sum + (report.amountLost ?? 0),
    );
    final verificationRate = analytics.totalReports == 0
        ? 0
        : analytics.verifiedReports / analytics.totalReports * 100;
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
              'Visit 1MY - Kuala Lumpur Threat Analytics',
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
              _summaryBox('Hotspot areas', analytics.locationCounts.length),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Executive summary',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Bullet(
            text:
                '${verificationRate.toStringAsFixed(0)}% of reports are verified.',
          ),
          pw.Bullet(
            text: hotspots.isEmpty
                ? 'No hotspot location data are available.'
                : '${hotspots.first.key} has the highest activity (${hotspots.first.value} reports).',
          ),
          pw.Bullet(
            text: categories.isEmpty
                ? 'No category data are available.'
                : '${categories.first.key} is the most reported scam type (${categories.first.value} reports).',
          ),
          pw.Bullet(
            text:
                'Total reported financial loss: RM ${NumberFormat('#,##0.00').format(totalLoss)}.',
          ),
          pw.SizedBox(height: 16),
          _distributionChart(
            'Reports by category',
            categories.take(6).toList(),
            PdfColors.blue700,
          ),
          pw.SizedBox(height: 16),
          _distributionChart(
            'Top hotspot areas',
            hotspots.take(6).toList(),
            PdfColors.red700,
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Highest-impact cases',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const ['Title', 'Category', 'Area', 'Status', 'Loss (RM)'],
            data:
                (reports.toList()..sort(
                      (a, b) =>
                          (b.amountLost ?? 0).compareTo(a.amountLost ?? 0),
                    ))
                    .take(10)
                    .map(
                      (report) => [
                        report.title,
                        report.category,
                        report.analyticsLocation,
                        report.status.label,
                        NumberFormat('#,##0.00').format(report.amountLost ?? 0),
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

  pw.Widget _distributionChart(
    String title,
    List<MapEntry<String, int>> entries,
    PdfColor color,
  ) {
    final maximum = entries.isEmpty ? 1 : entries.first.value;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 7),
        if (entries.isEmpty)
          pw.Text('No data available.')
        else
          for (final entry in entries) ...[
            pw.Row(
              children: [
                pw.SizedBox(
                  width: 120,
                  child: pw.Text(
                    entry.key,
                    maxLines: 1,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Container(
                  width: 230,
                  height: 8,
                  color: PdfColors.grey200,
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Container(
                    width: 230 * entry.value / maximum,
                    height: 8,
                    color: color,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  '${entry.value}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
          ],
      ],
    );
  }

  String _fileName(String prefix) {
    return '${prefix}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
  }
}
