import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../data/incident_report_repository.dart';
import '../../models/incident_report_models.dart';
import 'incident_report_translated_screen.dart';
import 'incident_report_widgets.dart';

class IncidentReportVerifyScreen extends StatefulWidget {
  const IncidentReportVerifyScreen({
    required this.repository,
    required this.draft,
    super.key,
  });

  final IncidentReportRepository repository;
  final IncidentReportDraft draft;

  @override
  State<IncidentReportVerifyScreen> createState() =>
      _IncidentReportVerifyScreenState();
}

class _IncidentReportVerifyScreenState
    extends State<IncidentReportVerifyScreen> {
  bool _translating = false;

  Future<void> _translate() async {
    setState(() => _translating = true);
    try {
      final report = await widget.repository.translateAndSave(widget.draft);
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => IncidentReportTranslatedScreen(report: report),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Translation failed: $error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _translating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return IncidentReportShell(
      title: 'Incident Report Generator',
      onBack: () => Navigator.of(context).pop(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text(
            'Verify Information',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Review your details carefully before generating translation',
            style: TextStyle(color: AppColors.slate, fontSize: 10),
          ),
          const SizedBox(height: 16),
          ReportReadOnlyField(
            label: 'Incident Type',
            value: draft.incidentType,
          ),
          const SizedBox(height: 14),
          ReportReadOnlyField(
            label: 'Date & Time',
            value: DateFormat('dd MMM yyyy, HH:mm').format(draft.incidentAt),
          ),
          const SizedBox(height: 14),
          ReportReadOnlyField(
            label: 'Location',
            value: draft.location,
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 14),
          ReportReadOnlyField(
            label: 'Description',
            value: draft.description,
            multiline: true,
          ),
          const SizedBox(height: 14),
          ReportReadOnlyField(
            label: 'People Involved',
            value: draft.peopleInvolved,
          ),
          const SizedBox(height: 14),
          ReportReadOnlyField(
            label: 'Lost / Stolen Items',
            value: draft.lostItems,
          ),
          const SizedBox(height: 14),
          ReportReadOnlyField(
            label: 'Additional Information',
            value: draft.additionalInformation,
            multiline: true,
          ),
          const SizedBox(height: 14),
          const ReportFieldLabel('Source Language'),
          ReportLanguageSelector(
            value: draft.inputLanguage,
            onChanged: (_) {},
            enabled: false,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _translating ? null : _translate,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _translating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Translating report...'),
                      ],
                    )
                  : const Text(
                      'Confirm & Translate',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
