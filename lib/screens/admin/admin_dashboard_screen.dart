import 'package:flutter/material.dart';
import '../../data/admin_repository.dart';
import 'admin_shell.dart';
import 'reports_moderation_screen.dart';
import 'threat_database_screen.dart';
import 'threat_heatmap_screen.dart';
import 'awareness_cms_screen.dart';
import 'dashboard_overview_screen.dart';
import 'verified_merchants_screen.dart';
import 'system_settings_screen.dart';
import '../../data/scam_map_repository.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    required this.repository,
    required this.onSignOut,
    super.key,
  });

  final AdminRepository repository;
  final Future<void> Function() onSignOut;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedSection = 'Dashboard Overview';

  void _onSectionChanged(String section) {
    setState(() {
      _selectedSection = section;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scamMapRepo = ScamMapRepository(client: widget.repository.client);

    void onDashboard() => _onSectionChanged('Dashboard Overview');
    void onReports() => _onSectionChanged('Reports Moderation');
    void onHeatmap() => _onSectionChanged('Geospatial Heatmap');
    void onMerchants() => _onSectionChanged('Verified Merchants');
    void onThreatDb() => _onSectionChanged('Scam Moderation');
    void onAwareness() => _onSectionChanged('Awareness CMS');
    void onSettings() => _onSectionChanged('System Logs & Settings');
    void onPublish() => _onSectionChanged('Publish Scam Case');

    switch (_selectedSection) {
      case 'Dashboard Overview':
        return DashboardOverviewScreen(
          repository: widget.repository,
          onSignOut: widget.onSignOut,
          onOpenDashboard: onDashboard,
          onOpenReports: onReports,
          onOpenHeatmap: onHeatmap,
          onOpenVerifiedMerchants: onMerchants,
          onOpenThreatDatabase: onThreatDb,
          onOpenAwarenessCms: onAwareness,
          onOpenSettings: onSettings,
          onOpenPublishScamCase: onPublish,
        );
      case 'Reports Moderation':
        return ReportsModerationScreen(
          repository: widget.repository,
          onSignOut: widget.onSignOut,
          onOpenDashboard: onDashboard,
          onOpenReports: onReports,
          onOpenHeatmap: onHeatmap,
          onOpenVerifiedMerchants: onMerchants,
          onOpenThreatDatabase: onThreatDb,
          onOpenAwarenessCms: onAwareness,
          onOpenSettings: onSettings,
          onOpenPublishScamCase: onPublish,
        );
      case 'Geospatial Heatmap':
        return ThreatHeatmapScreen(
          repository: scamMapRepo,
          onSignOut: widget.onSignOut,
          onOpenDashboard: onDashboard,
          onOpenReports: onReports,
          onOpenHeatmap: onHeatmap,
          onOpenVerifiedMerchants: onMerchants,
          onOpenThreatDatabase: onThreatDb,
          onOpenAwarenessCms: onAwareness,
          onOpenSettings: onSettings,
          onOpenPublishScamCase: onPublish,
        );
      case 'Verified Merchants':
        return VerifiedMerchantsScreen(
          repository: widget.repository,
          onSignOut: widget.onSignOut,
          onOpenDashboard: onDashboard,
          onOpenReports: onReports,
          onOpenHeatmap: onHeatmap,
          onOpenVerifiedMerchants: onMerchants,
          onOpenThreatDatabase: onThreatDb,
          onOpenAwarenessCms: onAwareness,
          onOpenSettings: onSettings,
          onOpenPublishScamCase: onPublish,
        );
      case 'Scam Moderation':
        return ThreatDatabaseScreen(
          repository: widget.repository,
          onSignOut: widget.onSignOut,
          onOpenDashboard: onDashboard,
          onOpenReports: onReports,
          onOpenHeatmap: onHeatmap,
          onOpenVerifiedMerchants: onMerchants,
          onOpenThreatDatabase: onThreatDb,
          onOpenAwarenessCms: onAwareness,
          onOpenSettings: onSettings,
          onOpenPublishScamCase: onPublish,
        );
      case 'Awareness CMS':
        return AwarenessCmsScreen(
          repository: widget.repository,
          onSignOut: widget.onSignOut,
          onOpenDashboard: onDashboard,
          onOpenReports: onReports,
          onOpenHeatmap: onHeatmap,
          onOpenVerifiedMerchants: onMerchants,
          onOpenThreatDatabase: onThreatDb,
          onOpenAwarenessCms: onAwareness,
          onOpenSettings: onSettings,
          onOpenPublishScamCase: onPublish,
        );
      case 'System Logs & Settings':
        return SystemSettingsScreen(
          repository: widget.repository,
          onSignOut: widget.onSignOut,
          onOpenDashboard: onDashboard,
          onOpenReports: onReports,
          onOpenHeatmap: onHeatmap,
          onOpenVerifiedMerchants: onMerchants,
          onOpenThreatDatabase: onThreatDb,
          onOpenAwarenessCms: onAwareness,
          onOpenSettings: onSettings,
          onOpenPublishScamCase: onPublish,
        );
      default:
        return AdminShell(
          selectedMenuItem: _selectedSection,
          onSignOut: () => widget.onSignOut(),
          onOpenDashboard: onDashboard,
          onOpenReports: onReports,
          onOpenHeatmap: onHeatmap,
          onOpenThreatDatabase: onThreatDb,
          onOpenAwarenessCms: onAwareness,
          onOpenSettings: onSettings,
          onOpenPublishScamCase: onPublish,
          child: Center(
            child: Text('Section "$_selectedSection" is under development.'),
          ),
        );
    }
  }
}
