import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({
    required this.child,
    this.onBack,
    this.onSignOut,
    this.searchController,
    this.onSearchChanged,
    this.selectedMenuItem = 'Threat Database',
    this.onOpenDashboard,
    this.onOpenReports,
    this.onOpenHeatmap,
    this.onOpenPublishScamCase,
    this.onOpenVerifiedMerchants,
    this.onOpenThreatDatabase,
    this.onOpenAwarenessCms,
    this.onOpenSettings,
    this.onOpenBankHotlines,
    this.onOpenEmergencyFacilities,
    this.onOpenAwareness,
    this.headerTitle = 'Scam & Threat Database',
    this.showTopBar = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onBack;
  final Future<void> Function()? onSignOut;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final String selectedMenuItem;

  final VoidCallback? onOpenDashboard;
  final VoidCallback? onOpenReports;
  final VoidCallback? onOpenHeatmap;
  final VoidCallback? onOpenPublishScamCase;
  final VoidCallback? onOpenVerifiedMerchants;
  final VoidCallback? onOpenThreatDatabase;
  final VoidCallback? onOpenAwarenessCms;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenBankHotlines;
  final VoidCallback? onOpenEmergencyFacilities;
  final VoidCallback? onOpenAwareness;
  final String headerTitle;
  final bool showTopBar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useWideLayout = constraints.maxWidth >= 900;

        if (!useWideLayout) {
          return Scaffold(
            backgroundColor: AppColors.canvas,
            appBar: AppBar(
              leading: onBack != null
                  ? IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.chevron_left),
                    )
                  : Builder(
                      builder: (context) {
                        return IconButton(
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                          icon: const Icon(Icons.menu),
                        );
                      },
                    ),
              title: Text(
                headerTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              actions: [
                if (onOpenReports != null)
                  IconButton(
                    onPressed: onOpenReports,
                    icon: const Icon(
                      Icons.report_gmailerrorred_outlined,
                      size: 20,
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: AdminLiveBadge(),
                ),
              ],
            ),
            drawer: onBack == null
                ? Drawer(
                    child: SafeArea(
                      child: AdminSidebar(
                        onSignOut: onSignOut,
                        selectedMenuItem: selectedMenuItem,
                        onOpenDashboard: onOpenDashboard,
                        onOpenReports: onOpenReports,
                        onOpenHeatmap: onOpenHeatmap,
                        onOpenPublishScamCase: onOpenPublishScamCase,
                        onOpenVerifiedMerchants: onOpenVerifiedMerchants,
                        onOpenThreatDatabase: onOpenThreatDatabase,
                        onOpenAwarenessCms: onOpenAwarenessCms,
                        onOpenSettings: onOpenSettings,
                        onOpenBankHotlines: onOpenBankHotlines,
                        onOpenEmergencyFacilities: onOpenEmergencyFacilities,
                        onOpenAwareness: onOpenAwareness,
                      ),
                    ),
                  )
                : null,
            body: child,
          );
        }

        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: Row(
            children: [
              SizedBox(
                width: 260,
                child: AdminSidebar(
                  onSignOut: onSignOut,
                  selectedMenuItem: selectedMenuItem,
                  onOpenDashboard: onOpenDashboard,
                  onOpenReports: onOpenReports,
                  onOpenHeatmap: onOpenHeatmap,
                  onOpenPublishScamCase: onOpenPublishScamCase,
                  onOpenVerifiedMerchants: onOpenVerifiedMerchants,
                  onOpenThreatDatabase: onOpenThreatDatabase,
                  onOpenAwarenessCms: onOpenAwarenessCms,
                  onOpenSettings: onOpenSettings,
                  onOpenBankHotlines: onOpenBankHotlines,
                  onOpenEmergencyFacilities: onOpenEmergencyFacilities,
                  onOpenAwareness: onOpenAwareness,
                ),
              ),
              Expanded(
                child: showTopBar
                    ? Column(
                        children: [
                          Container(
                            height: 72,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                bottom: BorderSide(color: AppColors.line),
                              ),
                            ),
                            child: Row(
                              children: [
                                if (onBack != null) ...[
                                  IconButton(
                                    onPressed: onBack,
                                    icon: const Icon(Icons.chevron_left),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Expanded(
                                  child: Text(
                                    headerTitle,
                                    style: const TextStyle(
                                      color: AppColors.navy,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (onSearchChanged != null)
                                  SizedBox(
                                    width: 300,
                                    height: 40,
                                    child: TextField(
                                      controller: searchController,
                                      onChanged: onSearchChanged,
                                      decoration: const InputDecoration(
                                        hintText: 'Search...',
                                        prefixIcon: Icon(
                                          Icons.search,
                                          size: 18,
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 16),
                                if (onOpenReports != null)
                                  IconButton(
                                    tooltip: 'Reports Moderation',
                                    onPressed: onOpenReports,
                                    icon: const Icon(
                                      Icons.report_gmailerrorred_outlined,
                                      color: AppColors.blue,
                                      size: 22,
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                const AdminLiveBadge(),
                                const SizedBox(width: 14),
                                const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                          Expanded(child: child),
                        ],
                      )
                    : child,
              ),
            ],
          ),
        );
      },
    );
  }
}

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    this.onSignOut,
    this.selectedMenuItem = 'Scam Moderation',
    this.onOpenDashboard,
    this.onOpenReports,
    this.onOpenHeatmap,
    this.onOpenPublishScamCase,
    this.onOpenVerifiedMerchants,
    this.onOpenThreatDatabase,
    this.onOpenAwarenessCms,
    this.onOpenSettings,
    this.onOpenBankHotlines,
    this.onOpenEmergencyFacilities,
    this.onOpenAwareness,
    super.key,
  });

  final Future<void> Function()? onSignOut;
  final String selectedMenuItem;
  final VoidCallback? onOpenDashboard;
  final VoidCallback? onOpenReports;
  final VoidCallback? onOpenHeatmap;
  final VoidCallback? onOpenPublishScamCase;
  final VoidCallback? onOpenVerifiedMerchants;
  final VoidCallback? onOpenThreatDatabase;
  final VoidCallback? onOpenAwarenessCms;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenBankHotlines;
  final VoidCallback? onOpenEmergencyFacilities;
  final VoidCallback? onOpenAwareness;

  @override
  Widget build(BuildContext context) {
    const menuItems = [
      (Icons.dashboard_outlined, 'Dashboard Overview'),
      (Icons.fact_check_outlined, 'Scam Report Moderation'),
      (Icons.report_gmailerrorred_outlined, 'Reports Moderation'),
      (Icons.shield_outlined, 'Threat Database'),
      (Icons.flag_outlined, 'Scam Moderation'),
      (Icons.map_outlined, 'Geospatial Heatmap'),
      (Icons.verified_outlined, 'Verified Merchants'),
      (Icons.phone_outlined, 'Bank Hotline Mgmt'),
      (Icons.location_on_outlined, 'Emergency Facilities'),
      (Icons.menu_book_outlined, 'Awareness CMS'),
      (Icons.settings_outlined, 'System Logs & Settings'),
    ];

    return Container(
      color: AppColors.adminNavy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 9),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visit 1MY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'ADMIN DASHBOARD',
                      style: TextStyle(color: AppColors.muted, fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final item in menuItems)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    child: Material(
                      color: item.$2 == selectedMenuItem
                          ? AppColors.blue
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      child: ListTile(
                        onTap: () {
                          switch (item.$2) {
                            case 'Dashboard Overview':
                              onOpenDashboard?.call();
                              break;
                            case 'Reports Moderation':
                              onOpenReports?.call();
                              break;
                            case 'Scam Report Moderation':
                              onOpenPublishScamCase?.call();
                              break;
                            case 'Threat Database':
                              onOpenThreatDatabase?.call();
                              break;
                            case 'Geospatial Heatmap':
                              onOpenHeatmap?.call();
                              break;
                            case 'Verified Merchants':
                              onOpenVerifiedMerchants?.call();
                              break;
                            case 'Bank Hotline Mgmt':
                              onOpenBankHotlines?.call();
                              break;
                            case 'Emergency Facilities':
                              onOpenEmergencyFacilities?.call();
                              break;
                            case 'Awareness CMS':
                              if (onOpenAwareness != null) {
                                onOpenAwareness!.call();
                              } else if (onOpenAwarenessCms != null) {
                                onOpenAwarenessCms!.call();
                              } else {
                                Navigator.of(
                                  context,
                                ).pushNamed('/admin/awareness');
                              }
                              break;
                            case 'System Logs & Settings':
                              onOpenSettings?.call();
                              break;
                          }
                        },
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -3),
                        leading: Icon(
                          item.$1,
                          color: item.$2 == selectedMenuItem
                              ? Colors.white
                              : Colors.white70,
                          size: 18,
                        ),
                        title: Text(
                          item.$2,
                          style: TextStyle(
                            color: item.$2 == selectedMenuItem
                                ? Colors.white
                                : Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.amberSoft,
                  child: Icon(
                    Icons.person_outline,
                    color: AppColors.amber,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Administrator',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Threat Management',
                        style: TextStyle(color: AppColors.muted, fontSize: 9),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Sign out',
                  onPressed: onSignOut,
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminLiveBadge extends StatelessWidget {
  const AdminLiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 3, backgroundColor: AppColors.green),
          SizedBox(width: 5),
          Text(
            'LIVE',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
