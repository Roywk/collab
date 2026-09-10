import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../data/incident_report_repository.dart';
import '../../models/incident_report_models.dart';
import 'incident_report_widgets.dart';

class TranslatedReportHistoryScreen extends StatefulWidget {
  const TranslatedReportHistoryScreen({required this.repository, super.key});

  final IncidentReportHistoryRepository repository;

  @override
  State<TranslatedReportHistoryScreen> createState() =>
      _TranslatedReportHistoryScreenState();
}

class _TranslatedReportHistoryScreenState
    extends State<TranslatedReportHistoryScreen> {
  late Future<List<TranslatedIncidentReport>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = widget.repository.getTranslatedReports();
  }

  Future<void> _refresh() async {
    final future = widget.repository.getTranslatedReports();
    setState(() => _reportsFuture = future);
    await future;
  }

  void _retry() {
    setState(() {
      _reportsFuture = widget.repository.getTranslatedReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Translated Report Records',
      titleColor: AppColors.navy,
      currentNavigationIndex: 6,
      onBack: () => Navigator.of(context).pop(),
      onProfile: () => Navigator.of(context).pop(),
      child: FutureBuilder<List<TranslatedIncidentReport>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          if (snapshot.hasError) {
            return _HistoryMessage(
              icon: Icons.error_outline_rounded,
              title: 'Records unavailable',
              message: snapshot.error.toString(),
              actionLabel: 'Try Again',
              onAction: _retry,
            );
          }

          final reports = snapshot.data ?? const <TranslatedIncidentReport>[];
          if (reports.isEmpty) {
            return const _HistoryMessage(
              icon: Icons.description_outlined,
              title: 'No translated reports yet',
              message:
                  'Reports generated through Incident Report Generator will appear here.',
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              itemCount: reports.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const _HistoryHeader();
                }
                final report = reports[index - 1];
                return _ReportRecordCard(
                  report: report,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          TranslatedReportRecordDetailScreen(report: report),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Report History',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'View your previous English and Bahasa Melayu translations.',
            style: TextStyle(color: AppColors.slate, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ReportRecordCard extends StatelessWidget {
  const _ReportRecordCard({required this.report, required this.onTap});

  final TranslatedIncidentReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final incidentType = report.english.incidentType.trim().isEmpty
        ? report.draft.incidentType
        : report.english.incidentType;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color: AppColors.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incidentType.trim().isEmpty
                          ? 'Incident Report'
                          : incidentType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      report.reference,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'd MMM yyyy, HH:mm',
                      ).format(report.generatedAt.toLocal()),
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenSoft,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'Translated',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TranslatedReportRecordDetailScreen extends StatefulWidget {
  const TranslatedReportRecordDetailScreen({required this.report, super.key});

  final TranslatedIncidentReport report;

  @override
  State<TranslatedReportRecordDetailScreen> createState() =>
      _TranslatedReportRecordDetailScreenState();
}

class _TranslatedReportRecordDetailScreenState
    extends State<TranslatedReportRecordDetailScreen> {
  ReportInputLanguage _language = ReportInputLanguage.malay;

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final localized = _language == ReportInputLanguage.malay
        ? report.malay
        : report.english;
    final malay = _language == ReportInputLanguage.malay;

    return MobileShell(
      title: 'Report Record',
      titleColor: AppColors.navy,
      currentNavigationIndex: 6,
      onBack: () => Navigator.of(context).pop(),
      onProfile: () => Navigator.of(
        context,
      ).popUntil((route) => route.settings.name == '/profile' || route.isFirst),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          SurfaceCard(
            color: AppColors.greenCanvas,
            borderColor: AppColors.greenSoft,
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.green,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Translation Complete',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        report.reference,
                        style: const TextStyle(
                          color: AppColors.slate,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('d MMM yyyy').format(report.generatedAt.toLocal()),
                  style: const TextStyle(color: AppColors.slate, fontSize: 9),
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
            ).format(report.draft.incidentAt.toLocal()),
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
        ],
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: AppColors.blueSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.blue, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate, fontSize: 11),
            ),
            if (onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
