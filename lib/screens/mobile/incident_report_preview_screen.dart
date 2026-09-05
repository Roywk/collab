import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../models/incident_report_models.dart';
import '../../services/incident_report_download_service.dart';
import '../../services/incident_report_pdf_service.dart';
import 'incident_report_pdf_screen.dart';
import 'incident_report_widgets.dart';

class IncidentReportPreviewScreen extends StatefulWidget {
  const IncidentReportPreviewScreen({required this.report, super.key});

  final TranslatedIncidentReport report;

  @override
  State<IncidentReportPreviewScreen> createState() =>
      _IncidentReportPreviewScreenState();
}

class _IncidentReportPreviewScreenState
    extends State<IncidentReportPreviewScreen> {
  bool _generating = false;

  Future<void> _generatePdf() async {
    setState(() => _generating = true);
    try {
      final service = IncidentReportPdfService();
      final pdf = await service.generate(widget.report);
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => IncidentReportPdfScreen(
            pdf: pdf,
            downloadService: IncidentReportDownloadService(),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate the PDF: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return IncidentReportShell(
      title: 'Report Preview',
      onBack: () => Navigator.of(context).pop(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'LAPORAN POLIS / POLICE REPORT',
                    style: TextStyle(
                      color: AppColors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                const Center(
                  child: Text(
                    'VISIT 1MY AUTOMATED REPORT TRANSLATION',
                    style: TextStyle(color: AppColors.slate, fontSize: 8),
                  ),
                ),
                const SizedBox(height: 9),
                const Divider(height: 1),
                const SizedBox(height: 13),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Ref: '),
                      TextSpan(
                        text: report.reference,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  style: const TextStyle(color: AppColors.navy, fontSize: 9),
                ),
                const SizedBox(height: 3),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Date/Time Generated: '),
                      TextSpan(
                        text: DateFormat(
                          'dd MMM yyyy, HH:mm',
                        ).format(report.generatedAt.toLocal()),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  style: const TextStyle(color: AppColors.navy, fontSize: 9),
                ),
                const SizedBox(height: 14),
                _PreviewField(
                  label: 'JENIS INSIDEN',
                  value: report.malay.incidentType,
                ),
                _PreviewField(
                  label: 'TARIKH & MASA',
                  value: _malayDate(report.draft.incidentAt),
                ),
                _PreviewField(label: 'LOKASI', value: report.malay.location),
                _PreviewField(
                  label: 'PENERANGAN KEJADIAN',
                  value: report.malay.description,
                ),
                _PreviewField(
                  label: 'INDIVIDU TERLIBAT',
                  value: report.malay.peopleInvolved,
                ),
                _PreviewField(
                  label: 'BARANGAN HILANG',
                  value: report.malay.lostItems,
                ),
                if (report.malay.additionalInformation.trim().isNotEmpty)
                  _PreviewField(
                    label: 'MAKLUMAT TAMBAHAN',
                    value: report.malay.additionalInformation,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _generating ? null : _generatePdf,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Generate PDF',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _malayDate(DateTime value) {
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

class _PreviewField extends StatelessWidget {
  const _PreviewField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value.trim().isEmpty ? '—' : value,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 10,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
