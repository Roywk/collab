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
    this.onOpenHeatmap,
    this.onPublishScamCase,
    this.onOpenThreatDatabase,
    super.key,
  });

  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onSignOut;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final String selectedMenuItem;
  final VoidCallback? onOpenHeatmap;
  final VoidCallback? onPublishScamCase;
  final VoidCallback? onOpenThreatDatabase;

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
              title: const Text(
                'Scam & Threat Database',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              actions: const [
                Padding(
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
                        onOpenHeatmap: onOpenHeatmap,
                        onPublishScamCase: onPublishScamCase,
                        onOpenThreatDatabase: onOpenThreatDatabase,
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
                  onOpenHeatmap: onOpenHeatmap,
                  onPublishScamCase: onPublishScamCase,
                  onOpenThreatDatabase: onOpenThreatDatabase,
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
                          const Expanded(
                            child: Text(
                              'Scam & Threat Database',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (searchController != null)
                            SizedBox(
                              width: 300,
                              height: 40,
                              child: TextField(
                                controller: searchController,
                                onChanged: onSearchChanged,
                                decoration: const InputDecoration(
                                  hintText: 'Search record, phone or URL...',
                                  prefixIcon: Icon(Icons.search, size: 18),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 3, backgroundColor: AppColors.green),
          SizedBox(width: 6),
          Text(
            'Core Live',
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

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    this.onSignOut,
    this.selectedMenuItem = 'Threat Database',
    this.onOpenHeatmap,
    this.onPublishScamCase,
    this.onOpenThreatDatabase,
    super.key,
  });

  final VoidCallback? onSignOut;
  final String selectedMenuItem;
  final VoidCallback? onOpenHeatmap;
  final VoidCallback? onPublishScamCase;
  final VoidCallback? onOpenThreatDatabase;

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
      (Icons.settings_outlined, 'System Settings'),
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

          for (final item in menuItems)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: Container(
                decoration: BoxDecoration(
                  color: item.$2 == selectedMenuItem
                      ? AppColors.blue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: ListTile(
                  onTap: () {
                    switch (item.$2) {
                      case 'Geospatial Heatmap':
                        onOpenHeatmap?.call();
                        break;
                      case 'Publish Scam Case':
                        onPublishScamCase?.call();
                        break;
                      case 'Threat Database':
                        onOpenThreatDatabase?.call();
                        break;
                    }
                  },
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -3),
                  leading: Icon(item.$1, color: Colors.white70, size: 18),
                  title: Text(
                    item.$2,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ),

          const Spacer(),

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
