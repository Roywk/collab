import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/awareness_admin_models.dart';

class AwarenessReportExportService {
  Future<String> exportPdf({
    required AwarenessAnalytics data,
    required String period,
    required String category,
    List<AwarenessActivityEvent>? activities,
  }) async {
    final document = pw.Document(
      title: 'Visit 1MY Awareness Performance Report',
      author: 'Visit 1MY',
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          pw.Text(
            'Visit 1MY - Awareness Performance Report',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text('$period | Activity type: $category'),
          pw.Text(
            'Generated ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metric('Active learners', data.activeLearners),
              _metric('Lessons', data.lessonCompletions),
              _metric('Scenarios', data.scenarioCompletions),
              _metric('Quiz attempts', data.quizAttempts),
              _metric('Voucher claims', data.voucherClaims),
              _metric('Voucher uses', data.voucherUses),
              _metric('XP awarded', data.xpAwarded),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Detailed activity audit',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Date',
              'User',
              'Activity',
              'Content',
              'Category',
              'Voucher status',
            ],
            data: (activities ?? data.activities)
                .map(
                  (event) => [
                    DateFormat(
                      'dd MMM yyyy HH:mm',
                    ).format(event.occurredAt.toLocal()),
                    event.userName,
                    event.activityType,
                    event.contentTitle,
                    event.category,
                    event.activityType == 'Voucher'
                        ? (event.voucherUsed ? 'Used' : 'Claimed')
                        : '-',
                  ],
                )
                .toList(),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellPadding: const pw.EdgeInsets.all(5),
          ),
        ],
      ),
    );
    return FileSaver.instance.saveFile(
      name:
          'visit1my_awareness_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}',
      bytes: await document.save(),
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  pw.Widget _metric(String label, int value) => pw.Container(
    width: 125,
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: PdfColors.blue50,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '$value',
          style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
      ],
    ),
  );
}
