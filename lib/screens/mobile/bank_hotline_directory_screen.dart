import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../data/emergency_repository.dart';
import '../../models/emergency_models.dart';
import 'bank_hotline_detail_screen.dart';

class BankHotlineDirectoryScreen extends StatefulWidget {
  const BankHotlineDirectoryScreen({required this.repository, super.key});

  final EmergencyRepository repository;

  @override
  State<BankHotlineDirectoryScreen> createState() =>
      _BankHotlineDirectoryScreenState();
}

class _BankHotlineDirectoryScreenState
    extends State<BankHotlineDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<BankHotline>> _banks;
  BankDirectoryFilter _filter = BankDirectoryFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _banks = widget.repository.getUserBanks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() => _banks = widget.repository.getUserBanks());
  }

  List<BankHotline> _filtered(List<BankHotline> banks) {
    return banks
        .where((bank) {
          final matchesQuery = bank.name.toLowerCase().contains(
            _query.toLowerCase(),
          );
          final matchesFilter = switch (_filter) {
            BankDirectoryFilter.all => true,
            BankDirectoryFilter.malaysian => bank.isMalaysian,
            BankDirectoryFilter.international => !bank.isMalaysian,
          };
          return matchesQuery && matchesFilter;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Bank Hotline & Kill Switch',
      titleColor: AppColors.navy,
      statusLabel: 'KL: Active',
      onBack: () => Navigator.of(context).pop(),
      currentNavigationIndex: 3,
      emergencyNavigation: true,
      onMap: () => Navigator.of(context).pop(),
      onVerify: () => Navigator.of(context).popUntil((route) => route.isFirst),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Search and contact your bank's emergency line or freeze "
                  'your account instantly.',
                  style: TextStyle(
                    color: AppColors.slate,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: const InputDecoration(
                    hintText: 'Search banks...',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in BankDirectoryFilter.values) ...[
                        _FilterChip(
                          label: filter.label,
                          selected: _filter == filter,
                          onTap: () => setState(() => _filter = filter),
                        ),
                        if (filter != BankDirectoryFilter.values.last)
                          const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<BankHotline>>(
              future: _banks,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                if (snapshot.hasError) {
                  return _DirectoryMessage(
                    icon: Icons.cloud_off_outlined,
                    title: 'Could not load your banks',
                    message: '${snapshot.error}',
                    actionLabel: 'Try Again',
                    onAction: _retry,
                  );
                }

                final allBanks = snapshot.data ?? const <BankHotline>[];
                final banks = _filtered(allBanks);
                if (allBanks.isEmpty) {
                  return const _DirectoryMessage(
                    icon: Icons.account_balance_outlined,
                    title: 'No banks registered',
                    message:
                        'Add your personal bank during account registration '
                        'to see its emergency hotline here.',
                  );
                }

                if (banks.isEmpty) {
                  return const _DirectoryMessage(
                    icon: Icons.search_off_rounded,
                    title: 'No matching bank',
                    message: 'Try another name or bank category.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final future = widget.repository.getUserBanks();
                    setState(() => _banks = future);
                    await future;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: banks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final bank = banks[index];
                      return _BankHotlineCard(
                        bank: bank,
                        onOpen: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => BankHotlineDetailScreen(
                                repository: widget.repository,
                                bank: bank,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: selected ? AppColors.blue : AppColors.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.slate,
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _BankHotlineCard extends StatelessWidget {
  const _BankHotlineCard({required this.bank, required this.onOpen});

  final BankHotline bank;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(12),
      child: SurfaceCard(
        padding: const EdgeInsets.all(13),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bank.isMalaysian ? '🇲🇾' : '🌐',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bank.name,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        bank.countryName,
                        style: const TextStyle(
                          color: AppColors.slate,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                if (bank.supportsKillSwitch)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.greenSoft,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      bank.availabilityLabel,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Hotline: ',
                  style: TextStyle(color: AppColors.slate, fontSize: 10),
                ),
                Text(
                  bank.hotlineNumber,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 34,
              child: FilledButton(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE5252A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Kill Switch',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectoryMessage extends StatelessWidget {
  const _DirectoryMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.slate, size: 38),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate, fontSize: 11),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 14),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
