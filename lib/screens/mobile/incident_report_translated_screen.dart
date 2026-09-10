import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../models/incident_report_models.dart';
import 'incident_report_preview_screen.dart';
import 'incident_report_widgets.dart';

class IncidentReportTranslatedScreen extends StatefulWidget {
  const IncidentReportTranslatedScreen({required this.report, super.key});

  final TranslatedIncidentReport report;

  @override
  State<IncidentReportTranslatedScreen> createState() =>
      _IncidentReportTranslatedScreenState();
}

class _IncidentReportTranslatedScreenState
    extends State<IncidentReportTranslatedScreen> {
  ReportInputLanguage _language = ReportInputLanguage.malay;

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final localized = _language == ReportInputLanguage.malay
        ? report.malay
        : report.english;
    final malay = _language == ReportInputLanguage.malay;

    return IncidentReportShell(
      title: 'Translated Report',
      onBack: () => Navigator.of(context).pop(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.greenSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.green,
                  size: 19,
                ),
                SizedBox(width: 9),
                Text(
                  'Translation Complete',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const ReportFieldLabel('Report Language (Bahasa Laporan)'),
          ReportLanguageSelector(
            value: _language,
            onChanged: (value) => setState(() => _language = value),
          ),
          const SizedBox(height: 16),
          ReportReadOnlyField(
            label: malay ? 'Jenis Insiden (Incident Type)' : 'Incident Type',
            value: localized.incidentType,
          ),
          const SizedBox(height: 14),
          ReportReadOnlyField(
            label: malay ? 'Tarikh & Masa (Date & Time)' : 'Date & Time',
            value: DateFormat(
              'dd MMM yyyy, HH:mm',
            ).format(report.draft.incidentAt),
          ),
          const SizedBox(height: 14),
          ReportReadOnlyField(
            label: malay ? 'Lokasi (Location)' : 'Location',
            value: localized.location,
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 14),
          ReportReadOnlyField(
            label: malay
                ? 'Penerangan Kejadian (Description)'
                : 'Incident Description',
            value: localized.description,
            multiline: true,
          ),
          const SizedBox(height: 14),
          ReportReadOnlyField(
            label: malay
                ? 'Individu Terlibat (People Involved)'
                : 'People Involved',
            value: localized.peopleInvolved,
          ),
          const SizedBox(height: 14),
          ReportReadOnlyField(
            label: malay
                ? 'Barangan Hilang (Lost / Stolen Items)'
                : 'Lost / Stolen Items',
            value: localized.lostItems,
          ),
          const SizedBox(height: 14),
          ReportReadOnlyField(
            label: malay
                ? 'Maklumat Tambahan (Additional Information)'
                : 'Additional Information',
            value: localized.additionalInformation,
            multiline: true,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => IncidentReportPreviewScreen(report: report),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Preview Report',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
