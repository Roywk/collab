import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/report_models.dart';
import '../../services/report_service.dart';
import '../../services/location_service.dart';
import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';

class ReportScamScreen extends StatefulWidget {
  const ReportScamScreen({super.key});

  @override
  State<ReportScamScreen> createState() => _ReportScamScreenState();
}

class _ReportScamScreenState extends State<ReportScamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<File> _evidenceFiles = [];

  String _category = 'Taxi Touts';
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  bool get _isDirty =>
      _descController.text.isNotEmpty ||
      _amountController.text.isNotEmpty ||
      _customCategoryController.text.isNotEmpty ||
      _evidenceFiles.isNotEmpty;

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _evidenceFiles.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _evidenceFiles.removeAt(index);
    });
  }

  Future<void> _handleBack() async {
    if (_isDirty && !_isSubmitting) {
      final bool? discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to exit?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _showResultDialog({
    required bool success,
    String? message,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          success ? Icons.check_circle_outline : Icons.error_outline,
          color: success ? AppColors.green : AppColors.red,
          size: 48,
        ),
        title: Text(
          success ? 'Submission Successful' : 'Submission Failed',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          message ??
              (success
                  ? 'Your report has been submitted and is pending moderation. Thank you for keeping the community safe.'
                  : 'Something went wrong while submitting your report. Please try again later.'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                if (success) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Exit report screen
                        Navigator.pushNamed(context, '/report-history');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('View My Reports'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      if (success) {
                        Navigator.pop(context); // Exit report screen
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Submission'),
        content: const Text(
          'Are you sure you want to submit this scam report?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final pos = await LocationService().currentPosition();

      final finalCategory = _category == 'Other'
          ? _customCategoryController.text.trim()
          : _category;

      final report = ScamReport(
        title: 'Incident: $finalCategory',
        category: finalCategory,
        description: _descController.text.trim(),
        latitude: pos.latitude,
        longitude: pos.longitude,
        amountLost: double.tryParse(_amountController.text),
        isAnonymous: _isAnonymous,
      );

      await ReportService().submitReport(report, evidenceFiles: _evidenceFiles);

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await _showResultDialog(success: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      String errorMsg = e.toString();
      if (errorMsg.contains('admin notes') ||
          errorMsg.contains('admin_notes')) {
        errorMsg =
            'Database mapping error: Column "admin_notes" not found. Please notify the system administrator.';
      }

      await _showResultDialog(success: false, message: errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: (!_isDirty || _isSubmitting),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: MobileShell(
        title: 'Report a Scam',
        onBack: _handleBack,
        currentNavigationIndex: 3,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text(
                  'Report Anonymously',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Your identity will be hidden on public maps',
                ),
                value: _isAnonymous,
                onChanged: _isSubmitting
                    ? null
                    : (v) => setState(() => _isAnonymous = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items:
                    [
                          'Taxi Touts',
                          'Fake Tickets',
                          'Overcharging',
                          'Pickpocket',
                          'Other',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (v) => setState(() => _category = v!),
                decoration: const InputDecoration(
                  labelText: 'Scam Category',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_category == 'Other') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _customCategoryController,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Specify Category',
                    hintText: 'e.g. Identity Theft, Rental Scam',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (_category == 'Other' && (v == null || v.isEmpty))
                      ? 'Please specify'
                      : null,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Describe what happened...',
                ),
                maxLines: 3,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Amount Lost (RM)',
                  border: OutlineInputBorder(),
                  prefixText: 'RM ',
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 24),
              const Text(
                'Evidence (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add photos of receipts, conversations, or the incident location.',
                style: TextStyle(fontSize: 12, color: AppColors.slate),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < _evidenceFiles.length; i++)
                    Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_evidenceFiles[i]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (!_isSubmitting)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: GestureDetector(
                              onTap: () => _removeImage(i),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppColors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (_evidenceFiles.length < 5 && !_isSubmitting)
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.line,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              color: AppColors.blue,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Scam Report',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
