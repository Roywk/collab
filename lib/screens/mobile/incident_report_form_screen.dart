import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../data/incident_report_repository.dart';
import '../../models/incident_report_models.dart';
import 'incident_report_verify_screen.dart';
import 'incident_report_widgets.dart';

class IncidentReportFormScreen extends StatefulWidget {
  const IncidentReportFormScreen({required this.repository, super.key});

  final IncidentReportRepository repository;

  @override
  State<IncidentReportFormScreen> createState() =>
      _IncidentReportFormScreenState();
}

class _IncidentReportFormScreenState extends State<IncidentReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _peopleController = TextEditingController();
  final _lostItemsController = TextEditingController();
  final _additionalController = TextEditingController();

  String? _incidentType;
  DateTime? _incidentAt;
  ReportInputLanguage _inputLanguage = ReportInputLanguage.english;

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    _peopleController.dispose();
    _lostItemsController.dispose();
    _additionalController.dispose();
    super.dispose();
  }

  Future<void> _pickDateAndTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _incidentAt ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_incidentAt ?? now),
    );
    if (time == null) {
      return;
    }

    setState(() {
      _incidentAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _reviewReport() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_incidentAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select the incident date and time.')),
      );
      return;
    }

    final draft = IncidentReportDraft(
      incidentType: _incidentType!,
      incidentAt: _incidentAt!,
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      peopleInvolved: _peopleController.text.trim(),
      lostItems: _lostItemsController.text.trim(),
      additionalInformation: _additionalController.text.trim(),
      inputLanguage: _inputLanguage,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IncidentReportVerifyScreen(
          repository: widget.repository,
          draft: draft,
        ),
      ),
    );
  }

  String? _requiredText(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This information is required.'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return IncidentReportShell(
      title: 'Incident Report Generator',
      onBack: () => Navigator.of(context).pop(),
      child: Form(
        key: _formKey,
        child: ListView(
          key: const Key('incident-report-form-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const Text(
              'New Incident Report',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Prepare an official report for Royal Malaysia Police (PDRM)',
              style: TextStyle(color: AppColors.slate, fontSize: 10),
            ),
            const SizedBox(height: 16),
            const ReportFieldLabel('Incident Type', required: true),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _incidentType,
              hint: const Text('Select incident type'),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: [
                for (final type in IncidentTypes.values)
                  DropdownMenuItem(value: type, child: Text(type)),
              ],
              onChanged: (value) => setState(() => _incidentType = value),
              validator: _requiredText,
            ),
            const SizedBox(height: 14),
            const ReportFieldLabel('Date & Time', required: true),
            InkWell(
              onTap: _pickDateAndTime,
              borderRadius: BorderRadius.circular(9),
              child: InputDecorator(
                decoration: const InputDecoration(),
                child: Text(
                  _incidentAt == null
                      ? 'e.g. 15 Aug 2025, 14:30'
                      : DateFormat('dd MMM yyyy, HH:mm').format(_incidentAt!),
                  style: TextStyle(
                    color: _incidentAt == null
                        ? AppColors.muted
                        : AppColors.navy,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const ReportFieldLabel('Location', required: true),
            TextFormField(
              controller: _locationController,
              validator: _requiredText,
              decoration: const InputDecoration(
                hintText: 'Enter incident location',
                prefixIcon: Icon(Icons.location_on_outlined, size: 19),
              ),
            ),
            const SizedBox(height: 14),
            const ReportFieldLabel('Description', required: true),
            TextFormField(
              controller: _descriptionController,
              validator: _requiredText,
              minLines: 4,
              maxLines: 6,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: 'Describe what happened...',
                counterText: '',
              ),
            ),
            const SizedBox(height: 14),
            const ReportFieldLabel('People Involved'),
            TextFormField(
              controller: _peopleController,
              decoration: const InputDecoration(
                hintText: 'Names, physical descriptions, suspects...',
              ),
            ),
            const SizedBox(height: 14),
            const ReportFieldLabel('Lost / Stolen Items'),
            TextFormField(
              controller: _lostItemsController,
              decoration: const InputDecoration(
                hintText: 'Wallet, cash, electronics, phone...',
              ),
            ),
            const SizedBox(height: 14),
            const ReportFieldLabel('Additional Information'),
            TextFormField(
              controller: _additionalController,
              minLines: 3,
              maxLines: 5,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: 'Any extra clues, vehicle plates...',
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            const ReportFieldLabel('Report Language (Bahasa Laporan)'),
            ReportLanguageSelector(
              value: _inputLanguage,
              onChanged: (value) => setState(() => _inputLanguage = value),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _reviewReport,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Translate & Generate Report',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
