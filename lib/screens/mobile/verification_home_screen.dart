import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../data/verification_repository.dart';
import '../../data/qr_repository.dart';
import '../../data/admin_repository.dart';
import '../../data/scam_map_repository.dart';
import '../../data/emergency_repository.dart';
import '../../data/help_nearby_repository.dart';
import '../../data/incident_report_repository.dart';
import '../../data/sos_repository.dart';
import '../admin/admin_gate.dart';
import '../../models/module_models.dart';
import 'verification_result_screen.dart';
import 'qr_scanner_screen.dart';
import 'scam_map_screen.dart';
import 'emergency_dashboard_screen.dart';

class VerificationHomeScreen extends StatefulWidget {
  const VerificationHomeScreen({required this.repository, super.key});

  final VerificationRepository repository;

  @override
  State<VerificationHomeScreen> createState() {
    return _VerificationHomeScreenState();
  }
}

class _VerificationHomeScreenState extends State<VerificationHomeScreen> {
  final TextEditingController queryController = TextEditingController();

  late Future<List<RecentSearch>> recentSearches;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    recentSearches = widget.repository.getRecentSearches();
  }

  @override
  void dispose() {
    queryController.dispose();
    super.dispose();
  }

  Future<void> searchBusiness([String? suppliedQuery]) async {
    final query = (suppliedQuery ?? queryController.text).trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a business name, phone, email or URL.'),
        ),
      );
      return;
    }

    setState(() {
      isSearching = true;
    });

    try {
      final result = await widget.repository.searchBusiness(query);

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) {
            return VerificationResultScreen(
              repository: widget.repository,
              record: result,
            );
          },
        ),
      );

      if (mounted) {
        setState(() {
          recentSearches = widget.repository.getRecentSearches();
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Search failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
      }
    }
  }

  Future<void> openQrScanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return QrScannerScreen(
            repository: QrRepository(client: widget.repository.client),
          );
        },
      ),
    );

    if (mounted) {
      setState(() {
        recentSearches = widget.repository.getRecentSearches();
      });
    }
  }

  Future<void> openAdmin() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return AdminGate(
            repository: AdminRepository(client: widget.repository.client),
          );
        },
      ),
    );

    if (mounted) {
      setState(() {
        recentSearches = widget.repository.getRecentSearches();
      });
    }
  }

  Future<void> openScamMap() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return ScamMapScreen(
            repository: ScamMapRepository(client: widget.repository.client),
            onOpenVerification: () => Navigator.of(context).pop(),
          );
        },
      ),
    );
  }

  Future<void> openEmergencyAssistance() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return EmergencyDashboardScreen(
            repository: SupabaseEmergencyRepository(
              client: widget.repository.client,
            ),
            incidentReportRepository: SupabaseIncidentReportRepository(
              client: widget.repository.client,
            ),
            helpNearbyRepository: SupabaseHelpNearbyRepository(
              client: widget.repository.client,
            ),
            sosRepository: SupabaseSosRepository(
              client: widget.repository.client,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      onAdmin: openAdmin,
      onMap: openScamMap,
      onEmergency: openEmergencyAssistance,
      currentNavigationIndex: 2,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Scam Verification',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          const Text(
            'Protect yourself from tourist traps and '
            'deceptive traders.',
            style: TextStyle(color: AppColors.slate, fontSize: 13),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: queryController,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              searchBusiness(value);
            },
            decoration: InputDecoration(
              hintText: 'Search business name, phone, email, or URL...',
              prefixIcon: const Icon(Icons.search, size: 19),
              suffixIcon: isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Search',
                      onPressed: searchBusiness,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 19),
                    ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: HomeActionCard(
                  icon: Icons.search,
                  iconColor: AppColors.blue,
                  iconBackground: AppColors.blueSoft,
                  title: 'Search Business',
                  subtitle: 'Query threat database',
                  onTap: searchBusiness,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HomeActionCard(
                  icon: Icons.qr_code_2_rounded,
                  iconColor: AppColors.red,
                  iconBackground: AppColors.redSoft,
                  title: 'Scan QR Code',
                  subtitle: 'Verify payment codes',
                  onTap: openQrScanner,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            'Recent Searches',
            style: Theme.of(context).textTheme.titleSmall,
          ),

          const SizedBox(height: 12),

          FutureBuilder<List<RecentSearch>>(
            future: recentSearches,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SurfaceCard(
                  child: Text(
                    'Could not load recent searches.\n'
                    '${snapshot.error}',
                    style: const TextStyle(color: AppColors.red),
                  ),
                );
              }

              final items = snapshot.data ?? <RecentSearch>[];

              if (items.isEmpty) {
                return const SurfaceCard(
                  child: Text(
                    'Your recent verification searches '
                    'will appear here.',
                  ),
                );
              }

              return Column(
                children: [
                  for (int index = 0; index < items.length; index++) ...[
                    RecentSearchTile(
                      item: items[index],
                      onTap: () {
                        queryController.text = items[index].query;
                        searchBusiness(items[index].query);
                      },
                    ),
                    if (index < items.length - 1) const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class HomeActionCard extends StatelessWidget {
  const HomeActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 21),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.slate, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class RecentSearchTile extends StatelessWidget {
  const RecentSearchTile({required this.item, required this.onTap, super.key});

  final RecentSearch item;
  final VoidCallback onTap;

  IconData get icon {
    if (item.inputType.startsWith('URL')) {
      return Icons.language;
    }

    if (item.inputType.startsWith('Email')) {
      return Icons.email_outlined;
    }

    if (item.inputType.startsWith('Phone')) {
      return Icons.phone_outlined;
    }

    return Icons.storefront_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SurfaceCard(
        padding: const EdgeInsets.all(12),
        radius: 10,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: AppColors.slate, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.inputType} • '
                    '${DateFormat('MMM dd, yyyy').format(item.date)}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
          ],
        ),
      ),
    );
  }
}
