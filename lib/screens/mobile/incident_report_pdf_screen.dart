import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/incident_report_models.dart';
import '../../services/incident_report_download_service.dart';
import 'incident_report_widgets.dart';

class IncidentReportPdfScreen extends StatefulWidget {
  const IncidentReportPdfScreen({
    required this.pdf,
    required this.downloadService,
    super.key,
  });

  final GeneratedIncidentPdf pdf;
  final IncidentReportDownloadService downloadService;

  @override
  State<IncidentReportPdfScreen> createState() =>
      _IncidentReportPdfScreenState();
}

class _IncidentReportPdfScreenState extends State<IncidentReportPdfScreen> {
  bool _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final path = await widget.downloadService.download(widget.pdf);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF saved: $path')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save the PDF: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IncidentReportShell(
      title: 'PDF Generated',
      onBack: () => Navigator.of(context).pop(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.greenSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.green,
                size: 29,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'PDF Report Generated',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your official incident report is ready for download.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate, fontSize: 11),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                Container(
                  width: 148,
                  height: 182,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E9F2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 8, color: const Color(0xFF91A2B9)),
                      const SizedBox(height: 7),
                      Container(
                        width: 83,
                        height: 6,
                        color: const Color(0xFF91A2B9),
                      ),
                      const SizedBox(height: 10),
                      for (final width in [110.0, 110.0, 82.0]) ...[
                        Container(
                          width: width,
                          height: 4,
                          color: const Color(0xFFC4CFDD),
                        ),
                        const SizedBox(height: 7),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  '${widget.pdf.fileName}.pdf',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PDF Document • ${widget.pdf.sizeLabel}',
                  style: const TextStyle(color: AppColors.slate, fontSize: 9),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _downloading ? null : _download,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Download PDF',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
