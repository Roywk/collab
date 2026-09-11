import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../data/admin_repository.dart';
import 'admin_shell.dart';

class VerifiedMerchantsScreen extends StatelessWidget {
  const VerifiedMerchantsScreen({
    required this.repository,
    required this.onSignOut,
    this.onOpenDashboard,
    this.onOpenReports,
    this.onOpenHeatmap,
    this.onOpenThreatDatabase,
    this.onOpenAwarenessCms,
    this.onOpenSettings,
    this.onOpenPublishScamCase,
    this.onOpenVerifiedMerchants,
    super.key,
  });

  final AdminRepository repository;
  final Future<void> Function() onSignOut;
  final VoidCallback? onOpenDashboard;
  final VoidCallback? onOpenReports;
  final VoidCallback? onOpenHeatmap;
  final VoidCallback? onOpenThreatDatabase;
  final VoidCallback? onOpenAwarenessCms;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenPublishScamCase;
  final VoidCallback? onOpenVerifiedMerchants;

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedMenuItem: 'Verified Merchants',
      onSignOut: onSignOut,
      onOpenDashboard: onOpenDashboard,
      onOpenReports: onOpenReports,
      onOpenHeatmap: onOpenHeatmap,
      onOpenThreatDatabase: onOpenThreatDatabase,
      onOpenAwarenessCms: onOpenAwarenessCms,
      onOpenPublishScamCase: onOpenPublishScamCase,
      onOpenVerifiedMerchants: onOpenVerifiedMerchants,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verified Merchants',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Whitelisted businesses with official safety certification.',
                    style: TextStyle(color: AppColors.slate, fontSize: 13),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add Verified Merchant'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Merchant Name')),
                DataColumn(label: Text('Registration No.')),
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Trust Score')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: [
                _buildDataRow(
                  'Grand Hyatt Kuala Lumpur',
                  'SSM-2023-8842',
                  'Hotel',
                  '98/100',
                  'Verified',
                ),
                _buildDataRow(
                  'Pavilion Kuala Lumpur',
                  'SSM-2023-1120',
                  'Shopping Mall',
                  '95/100',
                  'Verified',
                ),
                _buildDataRow(
                  'OldTown White Coffee',
                  'SSM-2023-0091',
                  'Restaurant',
                  '92/100',
                  'Verified',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(
    String name,
    String reg,
    String cat,
    String score,
    String status,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataCell(Text(reg)),
        DataCell(Text(cat)),
        DataCell(
          Text(
            score,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.blue,
                  size: 20,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.remove_moderator_outlined,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
