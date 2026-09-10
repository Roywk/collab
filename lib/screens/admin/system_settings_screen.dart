import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../data/admin_repository.dart';
import 'admin_shell.dart';

class SystemSettingsScreen extends StatelessWidget {
  const SystemSettingsScreen({
    required this.repository,
    required this.onSignOut,
    this.onOpenDashboard,
    this.onOpenReports,
    this.onOpenHeatmap,
    this.onOpenVerifiedMerchants,
    this.onOpenThreatDatabase,
    this.onOpenAwarenessCms,
    this.onOpenSettings,
    this.onOpenPublishScamCase,
    super.key,
  });

  final AdminRepository repository;
  final Future<void> Function() onSignOut;
  final VoidCallback? onOpenDashboard;
  final VoidCallback? onOpenReports;
  final VoidCallback? onOpenHeatmap;
  final VoidCallback? onOpenVerifiedMerchants;
  final VoidCallback? onOpenThreatDatabase;
  final VoidCallback? onOpenAwarenessCms;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenPublishScamCase;

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedMenuItem: 'System Logs & Settings',
      onSignOut: onSignOut,
      onOpenDashboard: onOpenDashboard,
      onOpenReports: onOpenReports,
      onOpenHeatmap: onOpenHeatmap,
      onOpenVerifiedMerchants: onOpenVerifiedMerchants,
      onOpenThreatDatabase: onOpenThreatDatabase,
      onOpenAwarenessCms: onOpenAwarenessCms,
      onOpenSettings: onOpenSettings,
      onOpenPublishScamCase: onOpenPublishScamCase,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'System Logs & Settings',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('Global System Configuration'),
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              children: [
                _buildSettingToggle(
                  'Live Witness Consensus',
                  'Automatically verify reports based on proximity and timing.',
                  true,
                ),
                const Divider(height: 32),
                _buildSettingToggle(
                  'Maintenance Mode',
                  'Disable public submissions while performing updates.',
                  false,
                ),
                const Divider(height: 32),
                _buildSettingToggle(
                  'Auto-Archive Resolved Reports',
                  'Move resolved reports to history after 30 days.',
                  true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          _buildSectionTitle('Security & Access Control'),
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              children: [
                _buildActionTile(
                  Icons.admin_panel_settings_outlined,
                  'Manage Admin Accounts',
                  'Add or remove moderator permissions.',
                ),
                const Divider(height: 1),
                _buildActionTile(
                  Icons.vpn_key_outlined,
                  'API Access Keys',
                  'Configure keys for map services and analytics.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          _buildSectionTitle('System Audit Logs'),
          const SizedBox(height: 16),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildLogEntry(
                  'Admin Sarah updated report #RPT-2024-0847 status to Verified.',
                  '2 mins ago',
                ),
                _buildLogEntry(
                  'System automatically verified 3 reports via Witness Consensus.',
                  '1 hour ago',
                ),
                _buildLogEntry(
                  'Admin Mercer signed in from IP 192.168.1.105.',
                  '3 hours ago',
                ),
                _buildLogEntry(
                  'Database backup completed successfully.',
                  '12 hours ago',
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('View Full Audit Trail'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.slate,
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingToggle(String title, String subtitle, bool value) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: (v) {},
          activeThumbColor: AppColors.blue,
        ),
      ],
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.blue, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {},
    );
  }

  Widget _buildLogEntry(String message, String time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.navy),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            time,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
