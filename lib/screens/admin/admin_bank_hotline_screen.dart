import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/admin_bank_repository.dart';
import '../../models/admin_bank_models.dart';
import 'admin_shell.dart';

class AdminBankHotlineScreen extends StatefulWidget {
  const AdminBankHotlineScreen({
    required this.repository,
    required this.onSignOut,
    this.onOpenEmergencyFacilities,
    super.key,
  });

  final AdminBankRepository repository;
  final Future<void> Function() onSignOut;
  final VoidCallback? onOpenEmergencyFacilities;

  @override
  State<AdminBankHotlineScreen> createState() => _AdminBankHotlineScreenState();
}

class _AdminBankHotlineScreenState extends State<AdminBankHotlineScreen> {
  final TextEditingController _searchController = TextEditingController();

  late Future<List<AdminBankRecord>> _banksFuture;
  String _statusFilter = 'All Statuses';
  String _countryFilter = 'All Countries';
  String _search = '';
  bool _activeOnly = false;
  bool _busy = false;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    _banksFuture = widget.repository.getBanks();
  }

  void _openEmergencyFacilities() {
    if (widget.onOpenEmergencyFacilities == null) return;
    widget.onOpenEmergencyFacilities!();
  }

  List<AdminBankRecord> _filterBanks(List<AdminBankRecord> banks) {
    final query = _search.trim().toLowerCase();
    return banks
        .where((bank) {
          final matchesSearch =
              query.isEmpty ||
              bank.name.toLowerCase().contains(query) ||
              bank.hotlineNumber.toLowerCase().contains(query) ||
              bank.targetDepartment.toLowerCase().contains(query);
          final matchesStatus =
              _statusFilter == 'All Statuses' ||
              (_statusFilter == 'Active' && bank.isActive) ||
              (_statusFilter == 'Inactive' && !bank.isActive);
          final matchesCountry =
              _countryFilter == 'All Countries' ||
              (_countryFilter == 'Malaysia' && bank.isMalaysian) ||
              (_countryFilter == 'International' && !bank.isMalaysian);
          return matchesSearch &&
              matchesStatus &&
              matchesCountry &&
              (!_activeOnly || bank.isActive);
        })
        .toList(growable: false);
  }

  Future<void> _openBankForm([AdminBankRecord? bank]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _BankFormDialog(repository: widget.repository, bank: bank),
    );

    if (saved == true && mounted) {
      setState(() {
        _successMessage = bank == null
            ? 'Bank hotline added successfully.'
            : 'Bank hotline record updated successfully.';
        _reload();
      });
    }
  }

  Future<void> _confirmDelete(AdminBankRecord bank) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteBankDialog(bank: bank),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final result = await widget.repository.deleteBank(bank);
      if (!mounted) return;
      setState(() {
        _successMessage = result == AdminBankDeleteResult.deleted
            ? '${bank.name} was deleted.'
            : '${bank.name} was deactivated because user accounts still '
                  'reference it.';
        _reload();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not remove bank: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedMenuItem: 'Bank Hotline Mgmt',
      headerTitle: 'Bank Hotline Management',
      showTopBar: false,
      onOpenBankHotlines: () {},
      onOpenEmergencyFacilities: _openEmergencyFacilities,
      onSignOut: widget.onSignOut,
      child: Stack(
        children: [
          FutureBuilder<List<AdminBankRecord>>(
            future: _banksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (snapshot.hasError) {
                return _BankLoadError(
                  error: snapshot.error.toString(),
                  onRetry: () => setState(_reload),
                );
              }

              final banks = snapshot.data ?? const <AdminBankRecord>[];
              return _buildDirectory(context, banks);
            },
          ),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.10),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDirectory(BuildContext context, List<AdminBankRecord> banks) {
    final filtered = _filterBanks(banks);
    final malaysianCount = banks.where((bank) => bank.isMalaysian).length;
    final activeCount = banks.where((bank) => bank.isActive).length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_successMessage != null) ...[
          _SuccessBanner(
            message: _successMessage!,
            onDismiss: () => setState(() => _successMessage = null),
          ),
          const SizedBox(height: 12),
        ],
        _DirectoryHeader(onAdd: _openBankForm),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth >= 800
                ? (constraints.maxWidth - 36) / 4
                : constraints.maxWidth >= 480
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryCard(
                  width: cardWidth,
                  label: 'TOTAL BANKS',
                  value: banks.length,
                  detail: 'Registered Partners',
                ),
                _SummaryCard(
                  width: cardWidth,
                  label: 'MALAYSIAN BANKS',
                  value: malaysianCount,
                  detail: 'Local Operations',
                ),
                _SummaryCard(
                  width: cardWidth,
                  label: 'INTERNATIONAL BANKS',
                  value: banks.length - malaysianCount,
                  detail: 'Global Institutions',
                ),
                _SummaryCard(
                  width: cardWidth,
                  label: 'ACTIVE HOTLINES',
                  value: activeCount,
                  detail: 'Online & Functional',
                  valueColor: AppColors.green,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _buildFilters(),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) {
              return _MobileBankList(
                banks: filtered,
                onEdit: _openBankForm,
                onDelete: _confirmDelete,
              );
            }
            return _DesktopBankTable(
              banks: filtered,
              onEdit: _openBankForm,
              onDelete: _confirmDelete,
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final controls = <Widget>[
          SizedBox(
            width: compact ? constraints.maxWidth : 170,
            child: _CompactDropdown(
              value: _statusFilter,
              items: const ['All Statuses', 'Active', 'Inactive'],
              prefix: 'Status',
              onChanged: (value) => setState(() => _statusFilter = value),
            ),
          ),
          SizedBox(
            width: compact ? constraints.maxWidth : 180,
            child: _CompactDropdown(
              value: _countryFilter,
              items: const ['All Countries', 'Malaysia', 'International'],
              prefix: 'Country',
              onChanged: (value) => setState(() => _countryFilter = value),
            ),
          ),
          SizedBox(
            width: compact ? constraints.maxWidth : 240,
            height: 40,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _search = value),
              decoration: const InputDecoration(
                hintText: 'Search banks...',
                prefixIcon: Icon(Icons.search_rounded, size: 18),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          if (!compact) const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Active Operators Only',
                style: TextStyle(
                  color: AppColors.slate,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Switch(
                value: _activeOnly,
                onChanged: (value) => setState(() => _activeOnly = value),
              ),
            ],
          ),
        ];

        if (compact) {
          return Wrap(spacing: 10, runSpacing: 10, children: controls);
        }
        return SizedBox(height: 40, child: Row(children: controls));
      },
    );
  }
}

class _DirectoryHeader extends StatelessWidget {
  const _DirectoryHeader({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bank Hotline Management',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Manage emergency bank hotline directory & freeze-card '
                  'quick-access lines',
                  style: TextStyle(color: AppColors.slate, fontSize: 10),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Bank'),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.greenSoft,
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, size: 6, color: AppColors.green),
                SizedBox(width: 5),
                Text(
                  'Live Directory',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.search_rounded, color: AppColors.slate, size: 20),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.width,
    required this.label,
    required this.value,
    required this.detail,
    this.valueColor = AppColors.navy,
  });

  final double width;
  final String label;
  final int value;
  final String detail;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 78,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  color: valueColor,
                  fontSize: 24,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    detail,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.slate, fontSize: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactDropdown extends StatelessWidget {
  const _CompactDropdown({
    required this.value,
    required this.items,
    required this.prefix,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final String prefix;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isDense: true,
      decoration: InputDecoration(
        prefixText: '$prefix:  ',
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      ),
      style: const TextStyle(
        color: AppColors.navy,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(growable: false),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _DesktopBankTable extends StatelessWidget {
  const _DesktopBankTable({
    required this.banks,
    required this.onEdit,
    required this.onDelete,
  });

  final List<AdminBankRecord> banks;
  final ValueChanged<AdminBankRecord> onEdit;
  final ValueChanged<AdminBankRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: banks.isEmpty
          ? const _EmptyDirectory()
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 900),
                child: DataTable(
                  headingRowHeight: 40,
                  dataRowMinHeight: 47,
                  dataRowMaxHeight: 54,
                  columnSpacing: 22,
                  horizontalMargin: 14,
                  headingTextStyle: const TextStyle(
                    color: AppColors.slate,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                  dataTextStyle: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 10,
                  ),
                  columns: const [
                    DataColumn(label: Text('Bank Name')),
                    DataColumn(label: Text('Country')),
                    DataColumn(label: Text('Hotline Number')),
                    DataColumn(label: Text('Emergency Dept')),
                    DataColumn(label: Text('Service Type')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: banks
                      .map(
                        (bank) => DataRow(
                          cells: [
                            DataCell(
                              Text(
                                bank.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                bank.isMalaysian ? 'Malaysia' : 'International',
                              ),
                            ),
                            DataCell(
                              Text(
                                bank.hotlineNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 150,
                                child: Text(
                                  bank.targetDepartment,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(Text(bank.serviceType)),
                            DataCell(_BankStatusBadge(active: bank.isActive)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () => onEdit(bank),
                                    child: const Text('Edit'),
                                  ),
                                  TextButton(
                                    onPressed: () => onDelete(bank),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.red,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
    );
  }
}

class _MobileBankList extends StatelessWidget {
  const _MobileBankList({
    required this.banks,
    required this.onEdit,
    required this.onDelete,
  });

  final List<AdminBankRecord> banks;
  final ValueChanged<AdminBankRecord> onEdit;
  final ValueChanged<AdminBankRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    if (banks.isEmpty) return const _EmptyDirectory();
    return Column(
      children: [
        for (final bank in banks) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bank.name,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _BankStatusBadge(active: bank.isActive),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  '${bank.isMalaysian ? 'Malaysia' : 'International'}  •  '
                  '${bank.hotlineNumber}',
                  style: const TextStyle(color: AppColors.slate, fontSize: 11),
                ),
                const SizedBox(height: 3),
                Text(
                  '${bank.targetDepartment}  •  ${bank.serviceType}',
                  style: const TextStyle(color: AppColors.slate, fontSize: 10),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => onEdit(bank),
                      child: const Text('Edit'),
                    ),
                    TextButton(
                      onPressed: () => onDelete(bank),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.red,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _BankStatusBadge extends StatelessWidget {
  const _BankStatusBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.greenSoft : const Color(0xFFE8EDF5),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          color: active ? AppColors.green : AppColors.slate,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BankFormDialog extends StatefulWidget {
  const _BankFormDialog({required this.repository, this.bank});

  final AdminBankRepository repository;
  final AdminBankRecord? bank;

  @override
  State<_BankFormDialog> createState() => _BankFormDialogState();
}

class _BankFormDialogState extends State<_BankFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _hotlineController;
  late final TextEditingController _departmentController;
  late String _country;
  late String _serviceType;
  late bool _active;
  bool _saving = false;
  String? _error;

  static const _serviceTypes = ['Both', '24/7 Hotline', 'Card Freeze'];

  @override
  void initState() {
    super.initState();
    final bank = widget.bank;
    _nameController = TextEditingController(text: bank?.name ?? '');
    _hotlineController = TextEditingController(text: bank?.hotlineNumber ?? '');
    _departmentController = TextEditingController(
      text: bank?.targetDepartment ?? '',
    );
    _country = bank?.isMalaysian == false ? 'International' : 'Malaysia';
    _serviceType = _initialServiceType(bank);
    _active = bank?.isActive ?? true;
  }

  String _initialServiceType(AdminBankRecord? bank) {
    if (bank == null) return 'Both';
    if (_serviceTypes.contains(bank.serviceType)) return bank.serviceType;
    return bank.supportsKillSwitch ? 'Both' : '24/7 Hotline';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hotlineController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final supportsKillSwitch = _serviceType != '24/7 Hotline';
    final original = widget.bank;
    final record = AdminBankRecord(
      id: original?.id ?? '',
      slug: original?.slug ?? '',
      name: _nameController.text.trim(),
      countryCode: _country == 'Malaysia' ? 'MY' : 'XX',
      countryName: _country,
      hotlineNumber: _hotlineController.text.trim(),
      serviceType: _serviceType,
      targetDepartment: _departmentController.text.trim(),
      supportsKillSwitch: supportsKillSwitch,
      availabilityLabel: supportsKillSwitch
          ? 'Card Freeze Available'
          : '24/7 Hotline',
      isActive: _active,
    );

    try {
      await widget.repository.saveBank(record);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.bank != null;
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  editing ? 'Edit Bank Hotline' : 'Add New Bank Hotline',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  editing
                      ? 'Modify emergency contact details and configuration'
                      : 'Enter emergency card freeze and helpline details',
                  style: const TextStyle(color: AppColors.slate, fontSize: 10),
                ),
                const SizedBox(height: 19),
                _FormLabel('BANK NAME'),
                TextFormField(
                  controller: _nameController,
                  autofocus: !editing,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Alliance Bank',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 11),
                _FormLabel('COUNTRY'),
                DropdownButtonFormField<String>(
                  initialValue: _country,
                  items: const [
                    DropdownMenuItem(
                      value: 'Malaysia',
                      child: Text('Malaysia'),
                    ),
                    DropdownMenuItem(
                      value: 'International',
                      child: Text('International'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _country = value);
                  },
                ),
                const SizedBox(height: 11),
                _FormLabel('HOTLINE NUMBER'),
                TextFormField(
                  controller: _hotlineController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: '+603-XXXX-XXXX'),
                  validator: (value) {
                    final number = value?.trim() ?? '';
                    if (number.isEmpty) return 'Enter the hotline number.';
                    if (!RegExp(r'^\+[0-9][0-9 -]{6,20}$').hasMatch(number)) {
                      return 'Use international format beginning with +.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 11),
                _FormLabel('EMERGENCY DEPARTMENT'),
                TextFormField(
                  controller: _departmentController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Card Operations Bureau',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 11),
                _FormLabel('SERVICE TYPE'),
                DropdownButtonFormField<String>(
                  initialValue: _serviceType,
                  items: _serviceTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) setState(() => _serviceType = value);
                  },
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Set as immediately visible to tourists',
                            style: TextStyle(
                              color: AppColors.slate,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _active,
                      onChanged: (value) => setState(() => _active = value),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.red, fontSize: 10),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 9),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(editing ? 'Save Changes' : 'Add Bank'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    return (value ?? '').trim().isEmpty ? 'This field is required.' : null;
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.slate,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DeleteBankDialog extends StatelessWidget {
  const _DeleteBankDialog({required this.bank});

  final AdminBankRecord bank;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      iconPadding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      icon: const Align(
        alignment: Alignment.centerLeft,
        child: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.redSoft,
          child: Icon(Icons.warning_amber_rounded, color: AppColors.red),
        ),
      ),
      title: const Text(
        'Delete Bank Record?',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 390,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remove ${bank.name} from the hotline directory? If a user '
              'account references this bank, it will be safely deactivated '
              'instead of breaking that account link.',
              style: const TextStyle(
                color: AppColors.slate,
                fontSize: 11,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bank.name,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          bank.hotlineNumber,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    bank.isMalaysian ? 'Malaysia' : 'International',
                    style: const TextStyle(
                      color: AppColors.slate,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.red),
          child: const Text('Delete Bank'),
        ),
      ],
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.greenCanvas,
        border: Border.all(color: AppColors.green),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.green,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }
}

class _EmptyDirectory extends StatelessWidget {
  const _EmptyDirectory();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(38),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_outlined,
            color: AppColors.slate,
            size: 34,
          ),
          SizedBox(height: 9),
          Text(
            'No bank hotlines match the current filters.',
            style: TextStyle(color: AppColors.slate, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _BankLoadError extends StatelessWidget {
  const _BankLoadError({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.red,
              size: 42,
            ),
            const SizedBox(height: 10),
            const Text(
              'Bank directory unavailable',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate, fontSize: 11),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}
