import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({
    required this.child,
    this.onBack,
    this.onSignOut,
    this.searchController,
    this.onSearchChanged,
    this.selectedMenuItem = 'Reports',
    this.onOpenDashboard,
    this.onOpenReports,
    this.onOpenHeatmap,
    this.onOpenPublishScamCase,
    this.onOpenVerifiedMerchants,
    this.onOpenThreatDatabase,
    this.onOpenAwarenessCms,
    this.onOpenSettings,
    super.key,
  });

  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onSignOut;
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useWideLayout = constraints.maxWidth >= 1000;

        if (!useWideLayout) {
          return Scaffold(
            backgroundColor: AppColors.canvas,
            appBar: AppBar(
              leading: onBack != null
                  ? IconButton(onPressed: onBack, icon: const Icon(Icons.chevron_left))
                  : Builder(builder: (context) => IconButton(onPressed: () => Scaffold.of(context).openDrawer(), icon: const Icon(Icons.menu))),
              title: Text(selectedMenuItem, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              actions: const [Padding(padding: EdgeInsets.only(right: 12), child: AdminLiveBadge())],
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
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 72,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(bottom: BorderSide(color: AppColors.line)),
                      ),
                      child: Row(
                        children: [
                          if (onBack != null) ...[
                            IconButton(onPressed: onBack, icon: const Icon(Icons.chevron_left)),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              selectedMenuItem,
                              style: const TextStyle(color: AppColors.navy, fontSize: 21, fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (onSearchChanged != null)
                            SizedBox(
                              width: 340,
                              height: 40,
                              child: TextField(
                                controller: searchController,
                                onChanged: onSearchChanged,
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'Search reports, users, locations...',
                                  prefixIcon: Icon(Icons.search, size: 18),
                                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                                ),
                              ),
                            ),
                          const SizedBox(width: 16),
                          const AdminLiveBadge(),
                          const SizedBox(width: 14),
                          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, size: 22)),
                        ],
                      ),
                    ),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AdminLiveBadge extends StatelessWidget {
  const AdminLiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(100)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 3, backgroundColor: AppColors.green),
          SizedBox(width: 6),
          Text('System Live & Syncing', style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    this.onSignOut,
    this.selectedMenuItem = 'Reports',
    this.onOpenDashboard,
    this.onOpenReports,
    this.onOpenHeatmap,
    this.onOpenPublishScamCase,
    this.onOpenVerifiedMerchants,
    this.onOpenThreatDatabase,
    this.onOpenAwarenessCms,
    this.onOpenSettings,
    super.key,
  });

  final VoidCallback? onSignOut;
  final String selectedMenuItem;
  final VoidCallback? onOpenDashboard;
  final VoidCallback? onOpenReports;
  final VoidCallback? onOpenHeatmap;
  final VoidCallback? onOpenPublishScamCase;
  final VoidCallback? onOpenVerifiedMerchants;
  final VoidCallback? onOpenThreatDatabase;
  final VoidCallback? onOpenAwarenessCms;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    const menuItems = [
      (Icons.dashboard_outlined, 'Dashboard Overview'),
      (Icons.description_outlined, 'Reports'),
      (Icons.map_outlined, 'Geospatial Heatmap'),
      (Icons.add_location_alt_outlined, 'Publish Scam Case'),
      (Icons.verified_outlined, 'Verified Merchants'),
      (Icons.shield_outlined, 'Threat Database'),
      (Icons.menu_book_outlined, 'Awareness CMS'),
      (Icons.settings_outlined, 'System Logs & Settings'),
    ];

    return Container(
      color: AppColors.adminNavy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.verified_user_outlined, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Visit 1MY', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    Text('ADMIN DASHBOARD', style: TextStyle(color: AppColors.muted, fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          for (final item in menuItems)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: InkWell(
                onTap: () {
                  switch (item.$2) {
                    case 'Dashboard Overview': onOpenDashboard?.call(); break;
                    case 'Reports': onOpenReports?.call(); break;
                    case 'Geospatial Heatmap': onOpenHeatmap?.call(); break;
                    case 'Publish Scam Case': onOpenPublishScamCase?.call(); break;
                    case 'Verified Merchants': onOpenVerifiedMerchants?.call(); break;
                    case 'Threat Database': onOpenThreatDatabase?.call(); break;
                    case 'Awareness CMS': onOpenAwarenessCms?.call(); break;
                    case 'System Logs & Settings': onOpenSettings?.call(); break;
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: item.$2 == selectedMenuItem ? AppColors.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(item.$1, color: item.$2 == selectedMenuItem ? Colors.white : Colors.white70, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        item.$2,
                        style: TextStyle(
                          color: item.$2 == selectedMenuItem ? Colors.white : Colors.white70,
                          fontSize: 12,
                          fontWeight: item.$2 == selectedMenuItem ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage('https://placeholder.com/alex_mercer'),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alex Mercer', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('Super Admin', style: TextStyle(color: AppColors.muted, fontSize: 9)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout, color: Colors.white70, size: 18),
                  tooltip: 'Sign Out',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
