import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../models/awareness_admin_models.dart';

class PartnerEditorDialog extends StatefulWidget {
  const PartnerEditorDialog({this.partner, super.key});
  final AdminPartnerRecord? partner;

  @override
  State<PartnerEditorDialog> createState() => _PartnerEditorDialogState();
}

class _PartnerEditorDialogState extends State<PartnerEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _legal;
  late final TextEditingController _display;
  late final TextEditingController _registration;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _website;
  late final TextEditingController _notes;
  late String _category;
  late String _status;

  @override
  void initState() {
    super.initState();
    final partner = widget.partner;
    _legal = TextEditingController(text: partner?.legalName ?? '');
    _display = TextEditingController(text: partner?.displayName ?? '');
    _registration = TextEditingController(
      text: partner?.registrationNumber ?? '',
    );
    _email = TextEditingController(text: partner?.contactEmail ?? '');
    _phone = TextEditingController(text: partner?.contactPhone ?? '');
    _website = TextEditingController(text: partner?.websiteUrl ?? '');
    _notes = TextEditingController(text: partner?.verificationNotes ?? '');
    _category = partner?.category ?? 'Hotel';
    _status = partner?.verificationStatus ?? 'pending';
  }

  @override
  void dispose() {
    for (final controller in [
      _legal,
      _display,
      _registration,
      _email,
      _phone,
      _website,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      AdminPartnerDraft(
        id: widget.partner?.id,
        legalName: _legal.text.trim(),
        displayName: _display.text.trim(),
        registrationNumber: _registration.text.trim(),
        category: _category,
        contactEmail: _email.text.trim(),
        contactPhone: _phone.text.trim(),
        websiteUrl: _website.text.trim(),
        verificationStatus: _status,
        verificationNotes: _notes.text.trim(),
        isActive: widget.partner?.isActive ?? true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.partner == null ? 'Add reward partner' : 'Review reward partner',
    ),
    content: SizedBox(
      width: 620,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Field(
                controller: _legal,
                label: 'Registered legal name',
                required: true,
              ),
              _Field(
                controller: _display,
                label: 'Public display name',
                required: true,
              ),
              _Field(
                controller: _registration,
                label: 'SSM / registration number',
                required: true,
              ),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Partner category',
                      ),
                      items:
                          const [
                                'Hotel',
                                'Restaurant',
                                'Transport',
                                'Retail',
                                'Attraction',
                                'Other',
                              ]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                      onChanged: (value) =>
                          setState(() => _category = value ?? _category),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Partnership status',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('Pending review'),
                        ),
                        DropdownMenuItem(
                          value: 'verified',
                          child: Text('Verified partner'),
                        ),
                        DropdownMenuItem(
                          value: 'rejected',
                          child: Text('Rejected'),
                        ),
                        DropdownMenuItem(
                          value: 'suspended',
                          child: Text('Suspended'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _status = value ?? _status),
                    ),
                  ),
                ],
              ),
              _Field(
                controller: _email,
                label: 'Business contact email',
                required: true,
                email: true,
              ),
              _Field(controller: _phone, label: 'Business contact phone'),
              _Field(controller: _website, label: 'Official website'),
              _Field(
                controller: _notes,
                label: 'Verification evidence and approval notes',
                required: _status == 'verified',
                lines: 3,
              ),
              if (_status == 'verified')
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.amberSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'By saving as Verified, you confirm the business identity and sponsorship authority were checked.',
                    style: TextStyle(color: AppColors.navy, fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: _save,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save partner'),
      ),
    ],
  );
}

class VoucherEditorDialog extends StatefulWidget {
  const VoucherEditorDialog({required this.partners, this.draft, super.key});
  final List<AdminPartnerRecord> partners;
  final AdminVoucherDraft? draft;

  @override
  State<VoucherEditorDialog> createState() => _VoucherEditorDialogState();
}

class _VoucherEditorDialogState extends State<VoucherEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _discount;
  late final TextEditingController _xp;
  late final TextEditingController _codes;
  late String _partnerId;
  late String _status;
  late DateTime _validUntil;

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    _title = TextEditingController(text: draft?.title ?? '');
    _discount = TextEditingController(text: draft?.discountAmount ?? '');
    _xp = TextEditingController(text: '${draft?.requiredXp ?? 300}');
    _codes = TextEditingController(text: draft?.codes.join('\n') ?? '');
    _partnerId = draft?.partnerId.isNotEmpty == true
        ? draft!.partnerId
        : widget.partners.first.id;
    _status = draft?.status ?? 'draft';
    _validUntil =
        draft?.validUntil ?? DateTime.now().add(const Duration(days: 90));
  }

  @override
  void dispose() {
    _title.dispose();
    _discount.dispose();
    _xp.dispose();
    _codes.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final partner = widget.partners.firstWhere((item) => item.id == _partnerId);
    Navigator.pop(
      context,
      AdminVoucherDraft(
        id: widget.draft?.id,
        partnerId: partner.id,
        partnerName: partner.displayName,
        title: _title.text.trim(),
        discountAmount: _discount.text.trim(),
        requiredXp: int.parse(_xp.text.trim()),
        validUntil: _validUntil,
        status: _status,
        codes: _codes.text
            .split(RegExp(r'[\n,;]+'))
            .map((code) => code.trim())
            .where((code) => code.isNotEmpty)
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.draft == null ? 'Deploy partner voucher' : 'Edit partner voucher',
    ),
    content: SizedBox(
      width: 600,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _partnerId,
                decoration: const InputDecoration(
                  labelText: 'Verified sponsor',
                ),
                items: widget.partners
                    .map(
                      (partner) => DropdownMenuItem(
                        value: partner.id,
                        child: Text(
                          '${partner.partnerCode} · ${partner.displayName}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _partnerId = value ?? _partnerId),
              ),
              _Field(controller: _title, label: 'Reward title', required: true),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      controller: _discount,
                      label: 'Benefit (e.g. 15% OFF)',
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Field(
                      controller: _xp,
                      label: 'XP cost',
                      required: true,
                      number: true,
                    ),
                  ),
                ],
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Valid until',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(DateFormat('dd MMM yyyy').format(_validUntil)),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _validUntil,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 1825)),
                  );
                  if (date != null) {
                    setState(
                      () => _validUntil = date.add(
                        const Duration(hours: 23, minutes: 59),
                      ),
                    );
                  }
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Deployment status',
                ),
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(
                    value: 'published',
                    child: Text('Published'),
                  ),
                  DropdownMenuItem(value: 'archived', child: Text('Archived')),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? _status),
              ),
              _Field(
                controller: _codes,
                label: 'Unique voucher codes — one per line',
                required: _status == 'published',
                lines: 5,
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Existing claimed codes are protected. New codes are appended and duplicates are ignored.',
                  style: TextStyle(color: AppColors.slate, fontSize: 9),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: _save,
        icon: const Icon(Icons.rocket_launch_outlined),
        label: const Text('Save voucher'),
      ),
    ],
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.required = false,
    this.email = false,
    this.number = false,
    this.lines = 1,
  });
  final TextEditingController controller;
  final String label;
  final bool required;
  final bool email;
  final bool number;
  final int lines;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextFormField(
      controller: controller,
      minLines: lines,
      maxLines: lines,
      keyboardType: number
          ? TextInputType.number
          : email
          ? TextInputType.emailAddress
          : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) return '$label is required.';
        if (email && text.isNotEmpty && !text.contains('@')) {
          return 'Enter a valid email address.';
        }
        if (number && (int.tryParse(text) ?? 0) <= 0) {
          return 'Enter a positive amount.';
        }
        return null;
      },
    ),
  );
}
