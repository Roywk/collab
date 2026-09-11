import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class DashboardReportExportService {
  Future<String> exportCsv({
    required String periodTitle,
    required List<String> labels,
    required List<int> counts,
  }) async {
    final rows = <List<dynamic>>[
      ['Visit 1MY Report Analytics', periodTitle],
      ['Period', 'Reports Created'],
      for (var index = 0; index < labels.length; index++)
        [labels[index], counts[index]],
      ['Total', counts.fold<int>(0, (sum, value) => sum + value)],
    ];
    final content = excel.encode(rows);
    return FileSaver.instance.saveFile(
      name: _fileName('visit1my_report_analytics'),
      bytes: Uint8List.fromList(utf8.encode(content)),
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
  }

  Future<String> exportPdf({
    required String periodTitle,
    required List<String> labels,
    required List<int> counts,
  }) async {
    final total = counts.fold<int>(0, (sum, value) => sum + value);
    final maximum = counts.isEmpty
        ? 1
        : counts.reduce((first, second) => first > second ? first : second);
    final document = pw.Document(
      title: 'Visit 1MY Report Analytics',
      author: 'Visit 1MY',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'Visit 1MY - Report Analytics',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(periodTitle),
          pw.Text(
            'Generated ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Text(
              'Total reports created: $total',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 18),
          for (var index = 0; index < labels.length; index++) ...[
            pw.Row(
              children: [
                pw.SizedBox(
                  width: 75,
                  child: pw.Text(
                    labels[index],
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Container(
                  width: 330,
                  height: 9,
                  color: PdfColors.grey200,
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Container(
                    width: maximum == 0 ? 0 : 330 * counts[index] / maximum,
                    height: 9,
                    color: PdfColors.blue600,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text('${counts[index]}'),
              ],
            ),
            pw.SizedBox(height: 7),
          ],
        ],
      ),
    );

    return FileSaver.instance.saveFile(
      name: _fileName('visit1my_report_analytics'),
      bytes: await document.save(),
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  String _fileName(String prefix) {
    return '${prefix}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
  }
}
