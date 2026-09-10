import 'package:flutter/material.dart';

import '../../core/app_error_message.dart';
import '../../core/app_theme.dart';
import '../../data/admin_repository.dart';
import '../../models/module_models.dart';
import '../../services/input_validation_service.dart';
import 'admin_shell.dart';

class ThreatFormScreen extends StatefulWidget {
  const ThreatFormScreen({required this.repository, this.record, super.key});

  final AdminRepository repository;
  final ThreatRecord? record;

  @override
  State<ThreatFormScreen> createState() {
    return _ThreatFormScreenState();
  }
}

class _ThreatFormScreenState extends State<ThreatFormScreen> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController businessController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late final TextEditingController urlController;
  late final TextEditingController qrController;
  late final TextEditingController locationController;
  late final TextEditingController activityController;
  late final TextEditingController registrationController;
  late final TextEditingController evidenceController;

  late String selectedCategory;
  late RiskLevel selectedRisk;

  bool isSaving = false;
  String? identifierError;

  bool get isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();

    final record = widget.record;

    businessController = TextEditingController(
      text: record?.businessName ?? '',
    );
    phoneController = TextEditingController(text: record?.phone ?? '');
    emailController = TextEditingController(text: record?.email ?? '');
    urlController = TextEditingController(text: record?.officialUrl ?? '');
    qrController = TextEditingController(text: record?.qrData ?? '');
    locationController = TextEditingController(text: record?.locationTag ?? '');
    activityController = TextEditingController(
      text: record?.flaggedActivities ?? '',
    );
    registrationController = TextEditingController(
      text: record?.registrationStatus ?? '',
    );
    evidenceController = TextEditingController(
      text: record?.evidenceNotes ?? '',
    );

    selectedCategory = record?.category ?? 'Select Category';

    selectedRisk = record?.riskLevel ?? RiskLevel.suspicious;
  }

  @override
  void dispose() {
    businessController.dispose();
    phoneController.dispose();
    emailController.dispose();
    urlController.dispose();
    qrController.dispose();
    locationController.dispose();
    activityController.dispose();
    registrationController.dispose();
    evidenceController.dispose();
    super.dispose();
  }

  Future<void> saveRecord() async {
    setState(() {
      identifierError = null;
    });

    if (!formKey.currentState!.validate()) {
      return;
    }

    final hasIdentifier =
        phoneController.text.trim().isNotEmpty ||
        emailController.text.trim().isNotEmpty ||
        urlController.text.trim().isNotEmpty ||
        qrController.text.trim().isNotEmpty;

    if (!hasIdentifier) {
      setState(() {
        identifierError =
            'Enter at least one phone number, email, URL or QR value.';
      });
      return;
    }

    if (selectedCategory == 'Select Category') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a threat category.')),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final previousRecord = widget.record;

      final record = ThreatRecord(
        id: previousRecord?.id ?? '',
        recordCode: previousRecord?.recordCode ?? '',
        businessName: businessController.text.trim(),
        riskLevel: selectedRisk,
        phone: phoneController.text.trim(),
        email: emailController.text.trim(),
        officialUrl: urlController.text.trim(),
        qrData: qrController.text.trim(),
        locationTag: locationController.text.trim(),
        category: selectedCategory,
        flaggedActivities: activityController.text.trim(),
        registrationStatus: registrationController.text.trim(),
        reportCount: previousRecord?.reportCount ?? 0,
        riskPoints: previousRecord?.riskPoints ?? 0,
        evidenceNotes: evidenceController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await widget.repository.saveThreatRecord(record);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      logDebugError('Save threat record', error, stackTrace);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyErrorMessage(
              error,
              fallback: 'The threat record could not be saved. Try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      onBack: () => Navigator.of(context).pop(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing
                    ? 'Edit ${widget.record!.recordCode}'
                    : 'Add New Threat Record',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                isEditing
                    ? 'Update the existing threat-registry information.'
                    : 'Register a suspicious business, URL or QR destination.',
                style: const TextStyle(color: AppColors.slate, fontSize: 12),
              ),
              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isEditing) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'RECORD ID: '
                          '${widget.record!.recordCode}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    LabeledAdminField(
                      label: 'BUSINESS NAME / ENTITY *',
                      child: TextFormField(
                        controller: businessController,
                        decoration: const InputDecoration(
                          hintText: 'Example: Kuala Lumpur Tour Service',
                        ),
                        validator: (value) {
                          return InputValidationService.validateBusinessName(
                            value,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    ResponsiveAdminRow(
                      left: LabeledAdminField(
                        label: 'PHONE NUMBER',
                        child: TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: '+60 12-345 6789',
                          ),
                          validator: InputValidationService.validatePhone,
                        ),
                      ),
                      right: LabeledAdminField(
                        label: 'EMAIL ADDRESS',
                        child: TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'contact@example.com',
                          ),
                          validator: InputValidationService.validateEmail,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    ResponsiveAdminRow(
                      left: LabeledAdminField(
                        label: 'OFFICIAL OR MALICIOUS URL',
                        child: TextFormField(
                          controller: urlController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            hintText: 'https://example.com/payment',
                          ),
                          validator: InputValidationService.validateWebUrl,
                        ),
                      ),
                      right: LabeledAdminField(
                        label: 'QR CODE DATA',
                        child: TextFormField(
                          controller: qrController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            hintText: 'QR URL or encoded value',
                          ),
                        ),
                      ),
                    ),

                    if (identifierError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        identifierError!,
                        style: const TextStyle(
                          color: AppColors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    ResponsiveAdminRow(
                      left: LabeledAdminField(
                        label: 'LOCATION TAG',
                        child: TextFormField(
                          controller: locationController,
                          decoration: const InputDecoration(
                            hintText: 'Bukit Bintang, Kuala Lumpur',
                          ),
                        ),
                      ),
                      right: LabeledAdminField(
                        label: 'THREAT CATEGORY *',
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          items:
                              const [
                                'Select Category',
                                'Verified Merchant',
                                'Currency Exchange Scam',
                                'QR Code Fraud',
                                'Taxi Scam',
                                'Transport Scam',
                                'Overcharging',
                                'Gift Card Scam',
                                'Fake Services',
                                'Phishing',
                                'Restaurant',
                                'Other',
                              ].map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value ?? selectedCategory;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    ResponsiveAdminRow(
                      left: LabeledAdminField(
                        label: 'RISK LEVEL *',
                        child: DropdownButtonFormField<RiskLevel>(
                          initialValue: selectedRisk,
                          items: RiskLevel.values.map((risk) {
                            return DropdownMenuItem<RiskLevel>(
                              value: risk,
                              child: Text(risk.label),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedRisk = value ?? selectedRisk;
                            });
                          },
                        ),
                      ),
                      right: LabeledAdminField(
                        label: 'REGISTRATION STATUS',
                        child: TextFormField(
                          controller: registrationController,
                          decoration: const InputDecoration(
                            hintText: 'Verified, unverified or fraudulent',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    LabeledAdminField(
                      label: 'FLAGGED ACTIVITIES',
                      child: TextFormField(
                        controller: activityController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Example: Overcharging, fake rates',
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    LabeledAdminField(
                      label: 'EVIDENCE / ADMIN VERIFICATION NOTES',
                      child: TextFormField(
                        controller: evidenceController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText:
                              'Tourist statements, investigation notes or evidence summary',
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: isSaving
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: isSaving ? null : saveRecord,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.red,
                          ),
                          icon: isSaving
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined, size: 18),
                          label: Text(
                            isEditing ? 'Save Changes' : 'Save Threat Record',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResponsiveAdminRow extends StatelessWidget {
  const ResponsiveAdminRow({
    required this.left,
    required this.right,
    super.key,
  });

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(children: [left, const SizedBox(height: 16), right]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 16),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class LabeledAdminField extends StatelessWidget {
  const LabeledAdminField({
    required this.label,
    required this.child,
    super.key,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.slate,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}
