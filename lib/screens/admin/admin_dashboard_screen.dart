import 'package:flutter/material.dart';

import '../../data/admin_bank_repository.dart';
import '../../data/admin_facility_repository.dart';
import '../../data/admin_repository.dart';
import '../../data/scam_map_repository.dart';
import 'admin_bank_hotline_screen.dart';
import 'admin_emergency_facility_screen.dart';
import 'admin_shell.dart';
import 'awareness_cms_screen.dart';
import 'dashboard_overview_screen.dart';
import 'manual_scam_case_screen.dart';
import 'reports_moderation_screen.dart';
import 'system_settings_screen.dart';
import 'threat_database_screen.dart';
import 'threat_heatmap_screen.dart';
import 'verified_merchants_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    required this.repository,
    required this.onSignOut,
    this.initialSection = 'Dashboard Overview',
    super.key,
  });

  final AdminRepository repository;
  final Future<void> Function() onSignOut;
  final String initialSection;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late String _selectedSection;

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.initialSection;
  }

  void _onSectionChanged(String section) {
    if (_selectedSection == section) return;
    setState(() => _selectedSection = section);
  }

  @override
  Widget build(BuildContext context) {
    final scamMapRepository = ScamMapRepository(
      client: widget.repository.client,
    );

    void openDashboard() => _onSectionChanged('Dashboard Overview');
    void openReports() => _onSectionChanged('Reports Moderation');
    void openHeatmap() => _onSectionChanged('Geospatial Heatmap');
    void openMerchants() => _onSectionChanged('Verified Merchants');
    void openThreatDatabase() => _onSectionChanged('Threat Database');
    void openAwareness() => _onSectionChanged('Awareness CMS');
    void openSettings() => _onSectionChanged('System Logs & Settings');
    void openBanks() => _onSectionChanged('Bank Hotline Mgmt');
    void openFacilities() => _onSectionChanged('Emergency Facilities');

    void openPublish() => _onSectionChanged('Publish Official Cases');

    final commonCallbacks = _AdminCallbacks(
      dashboard: openDashboard,
      reports: openReports,
      heatmap: openHeatmap,
      merchants: openMerchants,
      threatDatabase: openThreatDatabase,
      awareness: openAwareness,
      settings: openSettings,
      publish: openPublish,
    );

    final Widget screen;
    switch (_selectedSection) {
      case 'Publish Official Cases':
        screen = ManualScamCaseScreen(
          repository: scamMapRepository,
          onSignOut: widget.onSignOut,
          onBack: openDashboard,
          popOnSuccess: false,
          onPublished: openDashboard,
          onOpenDashboard: commonCallbacks.dashboard,
          onOpenReports: commonCallbacks.reports,
          onOpenHeatmap: commonCallbacks.heatmap,
          onOpenVerifiedMerchants: commonCallbacks.merchants,
          onOpenThreatDatabase: commonCallbacks.threatDatabase,
          onOpenAwarenessCms: commonCallbacks.awareness,
          onOpenSettings: commonCallbacks.settings,
          onOpenBankHotlines: openBanks,
          onOpenEmergencyFacilities: openFacilities,
        );
      case 'Reports Moderation':
        screen = ReportsModerationScreen(
          repository: widget.repository,
          onSignOut: widget.onSignOut,
          onOpenDashboard: commonCallbacks.dashboard,
          onOpenReports: commonCallbacks.reports,
          onOpenHeatmap: commonCallbacks.heatmap,
          onOpenVerifiedMerchants: commonCallbacks.merchants,
          onOpenThreatDatabase: commonCallbacks.threatDatabase,
          onOpenAwarenessCms: commonCallbacks.awareness,
          onOpenSettings: commonCallbacks.settings,
          onOpenPublishScamCase: commonCallbacks.publish,
        );
      case 'Geospatial Heatmap':
        screen = ThreatHeatmapScreen(
          repository: scamMapRepository,
          onSignOut: widget.onSignOut,
          onOpenDashboard: commonCallbacks.dashboard,
          onOpenReports: commonCallbacks.reports,
          onOpenHeatmap: commonCallbacks.heatmap,
          onOpenVerifiedMerchants: commonCallbacks.merchants,
          onOpenThreatDatabase: commonCallbacks.threatDatabase,
          onOpenAwarenessCms: commonCallbacks.awareness,
          onOpenSettings: commonCallbacks.settings,
          onOpenPublishScamCase: commonCallbacks.publish,
        );
      case 'Verified Merchants':
        screen = VerifiedMerchantsScreen(
          repository: widget.repository,
          onSignOut: widget.onSignOut,
          onOpenDashboard: commonCallbacks.dashboard,
          onOpenReports: commonCallbacks.reports,
          onOpenHeatmap: commonCallbacks.heatmap,
          onOpenVerifiedMerchants: commonCallbacks.merchants,
          onOpenThreatDatabase: commonCallbacks.threatDatabase,
          onOpenAwarenessCms: commonCallbacks.awareness,
          onOpenSettings: commonCallbacks.settings,
          onOpenPublishScamCase: commonCallbacks.publish,
        );
      case 'Threat Database':
        screen = ThreatDatabaseScreen(
          repository: widget.repository,
          onSignOut: widget.onSignOut,
          onOpenDashboard: commonCallbacks.dashboard,
          onOpenReports: commonCallbacks.reports,
          onOpenHeatmap: commonCallbacks.heatmap,
          onOpenVerifiedMerchants: commonCallbacks.merchants,
          onOpenThreatDatabase: commonCallbacks.threatDatabase,
          onOpenAwarenessCms: commonCallbacks.awareness,
          onOpenSettings: commonCallbacks.settings,
          onOpenPublishScamCase: commonCallbacks.publish,
        );
      case 'Awareness CMS':
        screen = AwarenessCmsScreen(
          repository: widget.repository,
          onSignOut: widget.onSignOut,
          onOpenDashboard: commonCallbacks.dashboard,
          onOpenReports: commonCallbacks.reports,
          onOpenHeatmap: commonCallbacks.heatmap,
          onOpenVerifiedMerchants: commonCallbacks.merchants,
          onOpenThreatDatabase: commonCallbacks.threatDatabase,
          onOpenAwarenessCms: commonCallbacks.awareness,
          onOpenSettings: commonCallbacks.settings,
          onOpenPublishScamCase: commonCallbacks.publish,
        );
      case 'System Logs & Settings':
        screen = SystemSettingsScreen(
          repository: widget.repository,
          onSignOut: widget.onSignOut,
          onOpenDashboard: commonCallbacks.dashboard,
          onOpenReports: commonCallbacks.reports,
          onOpenHeatmap: commonCallbacks.heatmap,
          onOpenVerifiedMerchants: commonCallbacks.merchants,
          onOpenThreatDatabase: commonCallbacks.threatDatabase,
          onOpenAwarenessCms: commonCallbacks.awareness,
          onOpenSettings: commonCallbacks.settings,
          onOpenPublishScamCase: commonCallbacks.publish,
        );
      case 'Bank Hotline Mgmt':
        screen = AdminBankHotlineScreen(
          repository: SupabaseAdminBankRepository(
            client: widget.repository.client,
          ),
          onSignOut: widget.onSignOut,
          onOpenEmergencyFacilities: openFacilities,
        );
      case 'Emergency Facilities':
        screen = AdminEmergencyFacilityScreen(
          repository: SupabaseAdminFacilityRepository(
            client: widget.repository.client,
          ),
          onSignOut: widget.onSignOut,
          onOpenBankHotlines: openBanks,
        );
      case 'Dashboard Overview':
      default:
        screen = DashboardOverviewScreen(
          repository: widget.repository,
          onSignOut: widget.onSignOut,
          onOpenDashboard: commonCallbacks.dashboard,
          onOpenReports: commonCallbacks.reports,
          onOpenHeatmap: commonCallbacks.heatmap,
          onOpenVerifiedMerchants: commonCallbacks.merchants,
          onOpenThreatDatabase: commonCallbacks.threatDatabase,
          onOpenAwarenessCms: commonCallbacks.awareness,
          onOpenSettings: commonCallbacks.settings,
          onOpenPublishScamCase: commonCallbacks.publish,
        );
    }

    return AdminNavigationScope(onNavigate: _onSectionChanged, child: screen);
  }
}

class _AdminCallbacks {
  const _AdminCallbacks({
    required this.dashboard,
    required this.reports,
    required this.heatmap,
    required this.merchants,
    required this.threatDatabase,
    required this.awareness,
    required this.settings,
    required this.publish,
  });

  final VoidCallback dashboard;
  final VoidCallback reports;
  final VoidCallback heatmap;
  final VoidCallback merchants;
  final VoidCallback threatDatabase;
  final VoidCallback awareness;
  final VoidCallback settings;
  final VoidCallback publish;
}
