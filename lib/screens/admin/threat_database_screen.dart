import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../data/admin_repository.dart';
import '../../data/admin_bank_repository.dart';
import '../../data/admin_facility_repository.dart';
import '../../data/scam_map_repository.dart';
import '../../models/module_models.dart';
import 'admin_shell.dart';
import 'admin_bank_hotline_screen.dart';
import 'admin_emergency_facility_screen.dart';
import 'threat_form_screen.dart';
import 'manual_scam_case_screen.dart';
import 'threat_heatmap_screen.dart';

class ThreatDatabaseScreen extends StatefulWidget {
  const ThreatDatabaseScreen({
    required this.repository,
    required this.onSignOut,
    super.key,
  });

  final AdminRepository repository;
  final Future<void> Function() onSignOut;

  @override
  State<ThreatDatabaseScreen> createState() {
    return _ThreatDatabaseScreenState();
  }
}

class _ThreatDatabaseScreenState extends State<ThreatDatabaseScreen> {
  final TextEditingController searchController = TextEditingController();

  late Future<List<ThreatRecord>> recordsFuture;

  String searchText = '';
  String selectedRisk = 'All Risk Levels';
  String selectedCategory = 'All Categories';
  String? successMessage;

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void loadRecords() {
    recordsFuture = widget.repository.getThreatRecords();
  }

  Future<void> openForm([ThreatRecord? record]) async {
    final wasSaved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) {
          return ThreatFormScreen(
            repository: widget.repository,
            record: record,
          );
        },
      ),
    );

    if (wasSaved == true && mounted) {
      setState(() {
        successMessage = record == null
            ? 'Threat record added successfully.'
            : '${record.recordCode} updated successfully.';

        loadRecords();
      });
    }
  }

  ScamMapRepository get _scamMapRepository =>
      ScamMapRepository(client: widget.repository.client);

  Future<void> openThreatHeatmap() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            ThreatHeatmapScreen(repository: _scamMapRepository),
      ),
    );
  }

  Future<void> openManualScamCase() async {
    final published = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) =>
            ManualScamCaseScreen(repository: _scamMapRepository),
      ),
    );

    if (published == true && mounted) {
      setState(() {
        successMessage = 'Official scam case published as Verified.';
      });
    }
  }

  Future<void> openBankHotlineManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AdminBankHotlineScreen(
          repository: SupabaseAdminBankRepository(
            client: widget.repository.client,
          ),
          onSignOut: widget.onSignOut,
          onOpenEmergencyFacilities: openEmergencyFacilityManagement,
        ),
      ),
    );
  }

  Future<void> openEmergencyFacilityManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AdminEmergencyFacilityScreen(
          repository: SupabaseAdminFacilityRepository(
            client: widget.repository.client,
          ),
          onSignOut: widget.onSignOut,
          onOpenBankHotlines: openBankHotlineManagement,
        ),
      ),
    );
  }

  Future<void> confirmDeactivate(ThreatRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: AppColors.redSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.red,
              size: 30,
            ),
          ),
          title: const Text('Deactivate Threat Record?'),
          content: Text(
            '${record.recordCode} – '
            '${record.businessName}\n\n'
            'The record will be removed from public '
            'searches but retained for auditing.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              child: const Text('Deactivate'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await widget.repository.deactivateThreatRecord(record.id);

      if (!mounted) {
        return;
      }

      setState(() {
        successMessage = '${record.recordCode} was deactivated.';
        loadRecords();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not deactivate record: $error')),
      );
    }
  }

  List<ThreatRecord> filterRecords(List<ThreatRecord> records) {
    final query = searchText.trim().toLowerCase();

    return records.where((record) {
      final matchesSearch =
          query.isEmpty ||
          record.recordCode.toLowerCase().contains(query) ||
          record.businessName.toLowerCase().contains(query) ||
          (record.phone?.toLowerCase().contains(query) ?? false) ||
          (record.email?.toLowerCase().contains(query) ?? false) ||
          (record.officialUrl?.toLowerCase().contains(query) ?? false);

      final matchesRisk =
          selectedRisk == 'All Risk Levels' ||
          record.riskLevel.label == selectedRisk;

      final matchesCategory =
          selectedCategory == 'All Categories' ||
          record.category == selectedCategory;

      return matchesSearch && matchesRisk && matchesCategory;
    }).toList();
  }

  Future<void> signOut() async {
    await widget.onSignOut();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedMenuItem: 'Scam Moderation',
      onOpenHeatmap: openThreatHeatmap,
      onPublishScamCase: openManualScamCase,
      onOpenThreatDatabase: () {},
      onOpenBankHotlines: openBankHotlineManagement,
      onOpenEmergencyFacilities: openEmergencyFacilityManagement,
      searchController: searchController,
      onSearchChanged: (value) {
        setState(() {
          searchText = value;
        });
      },
      onSignOut: signOut,
      child: FutureBuilder<List<ThreatRecord>>(
        future: recordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SurfaceCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        color: AppColors.red,
                        size: 44,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Threat database unavailable',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () {
                          setState(loadRecords);
                        },
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final allRecords = snapshot.data ?? <ThreatRecord>[];

          final categories = {
            'All Categories',
            ...allRecords.map((record) => record.category),
          }.toList()..sort();

          if (!categories.contains(selectedCategory)) {
            selectedCategory = 'All Categories';
          }

          final filteredRecords = filterRecords(allRecords);

          final highRiskCount = allRecords
              .where((record) => record.riskLevel == RiskLevel.highRisk)
              .length;

          final suspiciousCount = allRecords
              .where((record) => record.riskLevel == RiskLevel.suspicious)
              .length;

          final safeCount = allRecords
              .where((record) => record.riskLevel == RiskLevel.safe)
              .length;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Threat Registry',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage suspicious businesses, '
                          'URLs and payment QR destinations.',
                          style: TextStyle(
                            color: AppColors.slate,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: openThreatHeatmap,
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text('Threat Heatmap'),
                      ),
                      FilledButton.icon(
                        onPressed: openManualScamCase,
                        icon: const Icon(
                          Icons.add_location_alt_outlined,
                          size: 18,
                        ),
                        label: const Text('Publish Scam Case'),
                      ),
                      FilledButton.icon(
                        onPressed: openForm,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.red,
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Threat Record'),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  RegistrySummaryCard(
                    label: 'Active Records',
                    value: '${allRecords.length}',
                    color: AppColors.blue,
                    icon: Icons.shield_outlined,
                  ),
                  RegistrySummaryCard(
                    label: 'High Risk',
                    value: '$highRiskCount',
                    color: AppColors.red,
                    icon: Icons.warning_amber_rounded,
                  ),
                  RegistrySummaryCard(
                    label: 'Suspicious',
                    value: '$suspiciousCount',
                    color: AppColors.amber,
                    icon: Icons.report_problem_outlined,
                  ),
                  RegistrySummaryCard(
                    label: 'Safe',
                    value: '$safeCount',
                    color: AppColors.green,
                    icon: Icons.verified_outlined,
                  ),
                ],
              ),

              if (successMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.greenSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          successMessage!,
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            successMessage = null;
                          });
                        },
                        icon: const Icon(Icons.close, size: 17),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = MediaQuery.sizeOf(context).width < 900;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (isNarrow)
                        SizedBox(
                          width: constraints.maxWidth,
                          child: TextField(
                            controller: searchController,
                            onChanged: (value) {
                              setState(() {
                                searchText = value;
                              });
                            },
                            decoration: const InputDecoration(
                              hintText: 'Search record, phone or URL...',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),

                      SizedBox(
                        width: 230,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: selectedRisk,
                          decoration: const InputDecoration(
                            labelText: 'Risk level',
                          ),
                          items:
                              const [
                                'All Risk Levels',
                                'Safe',
                                'Suspicious',
                                'High Risk',
                              ].map((risk) {
                                return DropdownMenuItem<String>(
                                  value: risk,
                                  child: Text(
                                    risk,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedRisk = value ?? selectedRisk;
                            });
                          },
                        ),
                      ),

                      SizedBox(
                        width: 280,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                          items: categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(
                                category,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value ?? selectedCategory;
                            });
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              SurfaceCard(
                padding: EdgeInsets.zero,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 760) {
                      return ThreatRecordCards(
                        records: filteredRecords,
                        onEdit: openForm,
                        onDeactivate: confirmDeactivate,
                      );
                    }

                    return ThreatRecordTable(
                      records: filteredRecords,
                      onEdit: openForm,
                      onDeactivate: confirmDeactivate,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class RegistrySummaryCard extends StatelessWidget {
  const RegistrySummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    super.key,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: AppColors.slate, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ThreatRecordTable extends StatelessWidget {
  const ThreatRecordTable({
    required this.records,
    required this.onEdit,
    required this.onDeactivate,
    super.key,
  });

  final List<ThreatRecord> records;
  final ValueChanged<ThreatRecord> onEdit;
  final ValueChanged<ThreatRecord> onDeactivate;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No matching records found.'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Record ID')),
          DataColumn(label: Text('Business')),
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('Risk')),
          DataColumn(label: Text('Reports')),
          DataColumn(label: Text('Updated')),
          DataColumn(label: Text('Actions')),
        ],
        rows: records.map((record) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  record.recordCode,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 190,
                  child: Text(
                    record.businessName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(record.category)),
              DataCell(
                RiskBadge(riskLevel: record.riskLevel, showPrefix: false),
              ),
              DataCell(Text('${record.reportCount}')),
              DataCell(Text(formatAdminDate(record.updatedAt))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit record',
                      onPressed: () {
                        onEdit(record);
                      },
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.blue,
                        size: 18,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Deactivate record',
                      onPressed: () {
                        onDeactivate(record);
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.red,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class ThreatRecordCards extends StatelessWidget {
  const ThreatRecordCards({
    required this.records,
    required this.onEdit,
    required this.onDeactivate,
    super.key,
  });

  final List<ThreatRecord> records;
  final ValueChanged<ThreatRecord> onEdit;
  final ValueChanged<ThreatRecord> onDeactivate;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('No matching records found.'),
      );
    }

    return Column(
      children: [
        for (int index = 0; index < records.length; index++) ...[
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            title: Text(
              '${records[index].recordCode} • '
              '${records[index].businessName}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  RiskBadge(
                    riskLevel: records[index].riskLevel,
                    showPrefix: false,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${records[index].category} • '
                      '${records[index].reportCount} reports',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            trailing: Wrap(
              spacing: 2,
              children: [
                IconButton(
                  onPressed: () {
                    onEdit(records[index]);
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.blue,
                    size: 18,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    onDeactivate(records[index]);
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.red,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          if (index < records.length - 1) const Divider(height: 1),
        ],
      ],
    );
  }
}

String formatAdminDate(DateTime? date) {
  if (date == null) {
    return '—';
  }

  return DateFormat('MMM dd, yyyy').format(date);
}
