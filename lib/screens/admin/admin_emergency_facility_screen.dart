import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/admin_facility_repository.dart';
import '../../models/admin_facility_models.dart';
import '../../models/help_nearby_models.dart';
import 'admin_shell.dart';

class AdminEmergencyFacilityScreen extends StatefulWidget {
  const AdminEmergencyFacilityScreen({
    required this.repository,
    required this.onSignOut,
    this.onOpenBankHotlines,
    super.key,
  });

  final AdminFacilityRepository repository;
  final Future<void> Function() onSignOut;
  final VoidCallback? onOpenBankHotlines;

  @override
  State<AdminEmergencyFacilityScreen> createState() =>
      _AdminEmergencyFacilityScreenState();
}

class _AdminEmergencyFacilityScreenState
    extends State<AdminEmergencyFacilityScreen> {
  final TextEditingController _searchController = TextEditingController();

  late Future<List<AdminFacilityRecord>> _facilitiesFuture;
  String _typeFilter = 'All Types';
  String _statusFilter = 'All Statuses';
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
    _facilitiesFuture = widget.repository.getFacilities();
  }

  void _openBankHotlines() {
    if (widget.onOpenBankHotlines == null) return;
    Navigator.of(context).pop();
    widget.onOpenBankHotlines!();
  }

  List<AdminFacilityRecord> _filterFacilities(
    List<AdminFacilityRecord> facilities,
  ) {
    final query = _search.trim().toLowerCase();
    return facilities
        .where((facility) {
          final matchesSearch =
              query.isEmpty ||
              facility.name.toLowerCase().contains(query) ||
              facility.address.toLowerCase().contains(query) ||
              (facility.phoneNumber?.toLowerCase().contains(query) ?? false);
          final matchesType =
              _typeFilter == 'All Types' ||
              (_typeFilter == 'Police' &&
                  facility.type == EmergencyFacilityType.police) ||
              (_typeFilter == 'Fire & Rescue' &&
                  facility.type == EmergencyFacilityType.fireRescue) ||
              (_typeFilter == 'RELA' &&
                  facility.type == EmergencyFacilityType.rela);
          final matchesStatus =
              _statusFilter == 'All Statuses' ||
              (_statusFilter == 'Active' && facility.isActive) ||
              (_statusFilter == 'Inactive' && !facility.isActive);
          return matchesSearch &&
              matchesType &&
              matchesStatus &&
              (!_activeOnly || facility.isActive);
        })
        .toList(growable: false);
  }

  Future<void> _openForm([AdminFacilityRecord? facility]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FacilityFormDialog(
        repository: widget.repository,
        facility: facility,
      ),
    );

    if (saved == true && mounted) {
      setState(() {
        _successMessage = facility == null
            ? 'Emergency facility record added successfully. Mobile proximity '
                  'directory synchronized.'
            : 'Emergency facility record updated successfully. Mobile '
                  'proximity directory synchronized.';
        _reload();
      });
    }
  }

  Future<void> _confirmDelete(AdminFacilityRecord facility) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteFacilityDialog(facility: facility),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await widget.repository.deleteFacility(facility.id);
      if (!mounted) return;
      setState(() {
        _successMessage =
            '${facility.name} was removed from the emergency '
            'facility directory.';
        _reload();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete facility: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedMenuItem: 'Emergency Facilities',
      headerTitle: 'Emergency Facility Management',
      showTopBar: false,
      onOpenThreatDatabase: () => Navigator.of(context).pop(),
      onOpenBankHotlines: _openBankHotlines,
      onOpenEmergencyFacilities: () {},
      onSignOut: widget.onSignOut,
      child: Stack(
        children: [
          FutureBuilder<List<AdminFacilityRecord>>(
            future: _facilitiesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (snapshot.hasError) {
                return _FacilityLoadError(
                  error: snapshot.error.toString(),
                  onRetry: () => setState(_reload),
                );
              }

              final facilities = snapshot.data ?? const <AdminFacilityRecord>[];
              return _buildDirectory(facilities);
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

  Widget _buildDirectory(List<AdminFacilityRecord> facilities) {
    final filtered = _filterFacilities(facilities);
    final policeCount = facilities
        .where((item) => item.type == EmergencyFacilityType.police)
        .length;
    final fireCount = facilities
        .where((item) => item.type == EmergencyFacilityType.fireRescue)
        .length;
    final relaCount = facilities
        .where((item) => item.type == EmergencyFacilityType.rela)
        .length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_successMessage != null) ...[
          _FacilitySuccessBanner(
            message: _successMessage!,
            onDismiss: () => setState(() => _successMessage = null),
          ),
          const SizedBox(height: 12),
        ],
        _FacilityDirectoryHeader(onAdd: _openForm),
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
                _FacilitySummaryCard(
                  width: cardWidth,
                  label: 'TOTAL FACILITIES',
                  value: '${facilities.length}',
                  detail: 'Active Directory Records',
                ),
                _FacilitySummaryCard(
                  width: cardWidth,
                  label: 'PDRM POLICE',
                  value: '$policeCount Stations',
                  detail: 'Local Law Enforcement',
                  valueColor: AppColors.blue,
                ),
                _FacilitySummaryCard(
                  width: cardWidth,
                  label: 'BOMBA FIRE & RESCUE',
                  value: '$fireCount Stations',
                  detail: 'Emergency Responders',
                  valueColor: AppColors.red,
                ),
                _FacilitySummaryCard(
                  width: cardWidth,
                  label: 'RELA POSTS',
                  value: '$relaCount Posts',
                  detail: 'Community Volunteers',
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
            if (constraints.maxWidth < 800) {
              return _MobileFacilityList(
                facilities: filtered,
                onEdit: _openForm,
                onDelete: _confirmDelete,
              );
            }
            return _DesktopFacilityTable(
              facilities: filtered,
              onEdit: _openForm,
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
        final compact = constraints.maxWidth < 800;
        final controls = <Widget>[
          SizedBox(
            width: compact ? constraints.maxWidth : 160,
            child: _FacilityDropdown(
              value: _typeFilter,
              prefix: 'Type',
              items: const ['All Types', 'Police', 'Fire & Rescue', 'RELA'],
              onChanged: (value) => setState(() => _typeFilter = value),
            ),
          ),
          SizedBox(
            width: compact ? constraints.maxWidth : 170,
            child: _FacilityDropdown(
              value: _statusFilter,
              prefix: 'Status',
              items: const ['All Statuses', 'Active', 'Inactive'],
              onChanged: (value) => setState(() => _statusFilter = value),
            ),
          ),
          SizedBox(
            width: compact ? constraints.maxWidth : 250,
            height: 40,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _search = value),
              decoration: const InputDecoration(
                hintText: 'Search facilities...',
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
                'Active Facilities Only',
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

class _FacilityDirectoryHeader extends StatelessWidget {
  const _FacilityDirectoryHeader({required this.onAdd});

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
                  'Emergency Facility Management',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Manage PDRM, Bomba & RELA facility records for tourism '
                  'proximity alerts',
                  style: TextStyle(color: AppColors.slate, fontSize: 10),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Facility'),
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

class _FacilitySummaryCard extends StatelessWidget {
  const _FacilitySummaryCard({
    required this.width,
    required this.label,
    required this.value,
    required this.detail,
    this.valueColor = AppColors.navy,
  });

  final double width;
  final String label;
  final String value;
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
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 20,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    detail,
                    maxLines: 2,
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

class _FacilityDropdown extends StatelessWidget {
  const _FacilityDropdown({
    required this.value,
    required this.prefix,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final String prefix;
  final List<String> items;
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

class _DesktopFacilityTable extends StatelessWidget {
  const _DesktopFacilityTable({
    required this.facilities,
    required this.onEdit,
    required this.onDelete,
  });

  final List<AdminFacilityRecord> facilities;
  final ValueChanged<AdminFacilityRecord> onEdit;
  final ValueChanged<AdminFacilityRecord> onDelete;

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
      child: facilities.isEmpty
          ? const _EmptyFacilityDirectory()
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1000),
                child: DataTable(
                  headingRowHeight: 40,
                  dataRowMinHeight: 47,
                  dataRowMaxHeight: 54,
                  columnSpacing: 20,
                  horizontalMargin: 14,
                  headingTextStyle: const TextStyle(
                    color: AppColors.slate,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                  dataTextStyle: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 9,
                  ),
                  columns: const [
                    DataColumn(label: Text('Facility Name')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Address')),
                    DataColumn(label: Text('Coordinates')),
                    DataColumn(label: Text('Contact Number')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: facilities
                      .map(
                        (facility) => DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 145,
                                child: Text(
                                  facility.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(_FacilityTypeBadge(type: facility.type)),
                            DataCell(
                              SizedBox(
                                width: 185,
                                child: Text(
                                  facility.address,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${facility.latitude.toStringAsFixed(5)}, '
                                '${facility.longitude.toStringAsFixed(5)}',
                              ),
                            ),
                            DataCell(Text(facility.phoneNumber ?? '—')),
                            DataCell(
                              _OperatingStatusBadge(
                                label: facility.availabilityLabel,
                                active: facility.isActive,
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () => onEdit(facility),
                                    child: const Text('Edit'),
                                  ),
                                  TextButton(
                                    onPressed: () => onDelete(facility),
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

class _MobileFacilityList extends StatelessWidget {
  const _MobileFacilityList({
    required this.facilities,
    required this.onEdit,
    required this.onDelete,
  });

  final List<AdminFacilityRecord> facilities;
  final ValueChanged<AdminFacilityRecord> onEdit;
  final ValueChanged<AdminFacilityRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    if (facilities.isEmpty) return const _EmptyFacilityDirectory();
    return Column(
      children: [
        for (final facility in facilities) ...[
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
                        facility.name,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _FacilityTypeBadge(type: facility.type),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  facility.address,
                  style: const TextStyle(color: AppColors.slate, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  '${facility.latitude.toStringAsFixed(5)}, '
                  '${facility.longitude.toStringAsFixed(5)}  •  '
                  '${facility.phoneNumber ?? 'No contact number'}',
                  style: const TextStyle(color: AppColors.slate, fontSize: 10),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _OperatingStatusBadge(
                      label: facility.availabilityLabel,
                      active: facility.isActive,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => onEdit(facility),
                      child: const Text('Edit'),
                    ),
                    TextButton(
                      onPressed: () => onDelete(facility),
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

class _FacilityTypeBadge extends StatelessWidget {
  const _FacilityTypeBadge({required this.type});

  final EmergencyFacilityType type;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (type) {
      EmergencyFacilityType.police => (
        'PDRM',
        AppColors.blue,
        AppColors.blueSoft,
      ),
      EmergencyFacilityType.fireRescue => (
        'Bomba',
        AppColors.red,
        AppColors.redSoft,
      ),
      EmergencyFacilityType.rela => (
        'RELA',
        AppColors.green,
        AppColors.greenSoft,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OperatingStatusBadge extends StatelessWidget {
  const _OperatingStatusBadge({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final limited = label.toLowerCase().contains('limited');
    final color = !active
        ? AppColors.slate
        : limited
        ? AppColors.amber
        : AppColors.green;
    final background = !active
        ? const Color(0xFFE8EDF5)
        : limited
        ? AppColors.amberSoft
        : AppColors.greenSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        active ? label : 'Inactive',
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FacilityFormDialog extends StatefulWidget {
  const _FacilityFormDialog({required this.repository, this.facility});

  final AdminFacilityRepository repository;
  final AdminFacilityRecord? facility;

  @override
  State<_FacilityFormDialog> createState() => _FacilityFormDialogState();
}

class _FacilityFormDialogState extends State<_FacilityFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _phoneController;
  late EmergencyFacilityType _type;
  late String _operatingStatus;
  bool _saving = false;
  String? _error;

  static const _operatingStatuses = [
    'Open 24 Hours',
    'Limited Hours',
    'Emergency Service',
    'Temporarily Closed',
  ];

  @override
  void initState() {
    super.initState();
    final facility = widget.facility;
    _nameController = TextEditingController(text: facility?.name ?? '');
    _addressController = TextEditingController(text: facility?.address ?? '');
    _latitudeController = TextEditingController(
      text: facility == null ? '' : facility.latitude.toString(),
    );
    _longitudeController = TextEditingController(
      text: facility == null ? '' : facility.longitude.toString(),
    );
    _phoneController = TextEditingController(text: facility?.phoneNumber ?? '');
    _type = facility?.type ?? EmergencyFacilityType.police;
    _operatingStatus = _initialOperatingStatus(facility);
  }

  String _initialOperatingStatus(AdminFacilityRecord? facility) {
    if (facility == null) return 'Open 24 Hours';
    if (!facility.isActive) return 'Temporarily Closed';
    final value = facility.availabilityLabel.toLowerCase();
    if (value.contains('24')) return 'Open 24 Hours';
    if (value.contains('limited') || value.contains('unavailable')) {
      return 'Limited Hours';
    }
    return 'Emergency Service';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String get _agencyLabel => switch (_type) {
    EmergencyFacilityType.police => 'PDRM POLICE',
    EmergencyFacilityType.fireRescue => 'FIRE & RESCUE',
    EmergencyFacilityType.rela => 'RELA CIVIL',
  };

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final original = widget.facility;
    final facility = AdminFacilityRecord(
      id: original?.id ?? '',
      name: _nameController.text.trim(),
      type: _type,
      agencyLabel: _agencyLabel,
      address: _addressController.text.trim(),
      latitude: double.parse(_latitudeController.text.trim()),
      longitude: double.parse(_longitudeController.text.trim()),
      phoneNumber: _phoneController.text.trim(),
      availabilityLabel: _operatingStatus,
      isActive: _operatingStatus != 'Temporarily Closed',
      isVerified: true,
    );

    try {
      await widget.repository.saveFacility(facility);
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
    final editing = widget.facility != null;
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  editing
                      ? 'Edit Emergency Facility'
                      : 'Add New Emergency Facility',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  editing
                      ? 'Updating active directory node coordinates directly '
                            'updates the mobile GPS tracker config.'
                      : 'Ensure GPS coordinates are highly precise for '
                            'proximity alert accuracy.',
                  style: const TextStyle(color: AppColors.slate, fontSize: 10),
                ),
                const SizedBox(height: 18),
                const _FacilityFormLabel('FACILITY NAME'),
                TextFormField(
                  controller: _nameController,
                  autofocus: !editing,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Balai Polis Bukit Bintang',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 10),
                const _FacilityFormLabel('FACILITY TYPE'),
                DropdownButtonFormField<EmergencyFacilityType>(
                  initialValue: _type,
                  items: const [
                    DropdownMenuItem(
                      value: EmergencyFacilityType.police,
                      child: Text('PDRM (Police)'),
                    ),
                    DropdownMenuItem(
                      value: EmergencyFacilityType.fireRescue,
                      child: Text('Bomba (Fire & Rescue)'),
                    ),
                    DropdownMenuItem(
                      value: EmergencyFacilityType.rela,
                      child: Text('RELA'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _type = value);
                  },
                ),
                const SizedBox(height: 10),
                const _FacilityFormLabel('ADDRESS'),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    hintText: 'Enter street and postal code address',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FacilityFormLabel('LATITUDE'),
                          TextFormField(
                            controller: _latitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              signed: true,
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'e.g. 3.1478',
                            ),
                            validator: (value) => _coordinateValidator(
                              value,
                              minimum: -90,
                              maximum: 90,
                              label: 'latitude',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FacilityFormLabel('LONGITUDE'),
                          TextFormField(
                            controller: _longitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              signed: true,
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'e.g. 101.7108',
                            ),
                            validator: (value) => _coordinateValidator(
                              value,
                              minimum: -180,
                              maximum: 180,
                              label: 'longitude',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const _FacilityFormLabel('CONTACT NUMBER'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'e.g. +603-2141-1999',
                  ),
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) return null;
                    if (!RegExp(r'^\+[0-9][0-9 -]{6,20}$').hasMatch(phone)) {
                      return 'Use international format beginning with +.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                const _FacilityFormLabel('OPERATING STATUS'),
                DropdownButtonFormField<String>(
                  initialValue: _operatingStatus,
                  items: _operatingStatuses
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _operatingStatus = value);
                    }
                  },
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
                          : Text(editing ? 'Save Changes' : 'Add Facility'),
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

  String? _coordinateValidator(
    String? value, {
    required double minimum,
    required double maximum,
    required String label,
  }) {
    final coordinate = double.tryParse(value?.trim() ?? '');
    if (coordinate == null) return 'Enter a valid $label.';
    if (coordinate < minimum || coordinate > maximum) {
      return '$label must be $minimum to $maximum.';
    }
    return null;
  }
}

class _FacilityFormLabel extends StatelessWidget {
  const _FacilityFormLabel(this.text);

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

class _DeleteFacilityDialog extends StatelessWidget {
  const _DeleteFacilityDialog({required this.facility});

  final AdminFacilityRecord facility;

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
        'Delete Facility Record?',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 390,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to remove ${facility.name} from the '
              'Emergency Assistance directory? This cannot be undone.',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    facility.name,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    facility.phoneNumber ?? 'No contact number',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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
          child: const Text('Delete Facility'),
        ),
      ],
    );
  }
}

class _FacilitySuccessBanner extends StatelessWidget {
  const _FacilitySuccessBanner({
    required this.message,
    required this.onDismiss,
  });

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

class _EmptyFacilityDirectory extends StatelessWidget {
  const _EmptyFacilityDirectory();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(38),
      child: Column(
        children: [
          Icon(Icons.location_off_outlined, color: AppColors.slate, size: 34),
          SizedBox(height: 9),
          Text(
            'No emergency facilities match the current filters.',
            style: TextStyle(color: AppColors.slate, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _FacilityLoadError extends StatelessWidget {
  const _FacilityLoadError({required this.error, required this.onRetry});

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
              'Emergency facility directory unavailable',
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
