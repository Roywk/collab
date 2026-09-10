import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/app_theme.dart';
import '../../../core/app_widgets.dart';
import '../../../data/learning_repository.dart';
import '../../../models/learning_models.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({required this.repository, super.key});
  final LearningRepository repository;
  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late Future<List<dynamic>> _data;
  String? _claimingId;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _data = Future.wait([
      widget.repository.getUserProfile(),
      widget.repository.getVouchers(),
    ]);
  }

  Future<void> _claim(RewardVoucher voucher) async {
    if (voucher.isClaimed && voucher.promoCode != null) {
      _showCode(voucher, voucher.promoCode!);
      return;
    }
    setState(() => _claimingId = voucher.id);
    try {
      final code = await widget.repository.claimVoucher(voucher.id);
      if (!mounted) return;
      _showCode(voucher, code);
      setState(() {
        _reload();
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.toString().contains('out of stock')
                  ? 'This reward has just sold out. Please choose another reward.'
                  : 'Voucher could not be claimed. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _claimingId = null);
    }
  }

  void _showCode(RewardVoucher voucher, String code) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.greenSoft,
                child: Icon(Icons.redeem, color: AppColors.green, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                voucher.isClaimed ? 'Your voucher' : 'Reward unlocked!',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                voucher.title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.slate, fontSize: 11),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  children: [
                    const Text(
                      'PRESENT THIS CODE TO THE PARTNER',
                      style: TextStyle(
                        color: AppColors.slate,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      code,
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Valid until ${DateFormat('dd MMM yyyy').format(voucher.expiryDate)}',
                style: const TextStyle(color: AppColors.slate, fontSize: 9),
              ),
              const SizedBox(height: 18),
              PrimaryActionButton(
                label: 'Done',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MobileShell(
    title: 'My Rewards & Badges',
    onBack: () => Navigator.pop(context),
    currentNavigationIndex: 5,
    child: FutureBuilder<List<dynamic>>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Rewards could not be loaded: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final profile = snapshot.data![0] as UserLearningProfile;
        final vouchers = snapshot.data![1] as List<RewardVoucher>;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF16A34A)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_outlined,
                        color: Colors.white,
                        size: 23,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'SAFETY PASSPORT',
                        style: TextStyle(
                          color: Color(0xFFBBF7D0),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .7,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile.rankTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Level ${profile.currentLevel} · ${profile.totalXp} XP earned',
                    style: const TextStyle(
                      color: Color(0xFFDCFCE7),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      _HeroStat(value: '${profile.totalXp}', label: 'TOTAL XP'),
                      const SizedBox(width: 9),
                      _HeroStat(
                        value: '${profile.vouchersCount}',
                        label: 'CLAIMED',
                      ),
                      const SizedBox(width: 9),
                      _HeroStat(
                        value:
                            '${vouchers.where((v) => v.isUnlocked && v.isAvailable && !v.isClaimed).length}',
                        label: 'READY',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Partner rewards',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Complete safety activities to unlock verified travel perks.',
              style: TextStyle(color: AppColors.slate, fontSize: 10),
            ),
            const SizedBox(height: 12),
            if (vouchers.isEmpty)
              const SurfaceCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        color: AppColors.muted,
                        size: 38,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No partner rewards are live yet.',
                        style: TextStyle(color: AppColors.slate),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final voucher in vouchers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RewardCard(
                    voucher: voucher,
                    profile: profile,
                    busy: _claimingId == voucher.id,
                    onClaim: () => _claim(voucher),
                  ),
                ),
          ],
        );
      },
    ),
  );
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFBBF7D0),
              fontSize: 7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.voucher,
    required this.profile,
    required this.busy,
    required this.onClaim,
  });
  final RewardVoucher voucher;
  final UserLearningProfile profile;
  final bool busy;
  final VoidCallback onClaim;
  @override
  Widget build(BuildContext context) {
    final remaining = (voucher.requiredXp - profile.totalXp).clamp(
      0,
      voucher.requiredXp,
    );
    final progress = voucher.requiredXp == 0
        ? 1.0
        : (profile.totalXp / voucher.requiredXp).clamp(0, 1).toDouble();
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    !voucher.isUnlocked
                        ? Icons.lock_outline
                        : voucher.isAvailable
                        ? Icons.local_activity_outlined
                        : Icons.event_busy_outlined,
                    color: voucher.isUnlocked && voucher.isAvailable
                        ? AppColors.blue
                        : AppColors.slate,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${voucher.referenceCode} · ${voucher.partnerName.toUpperCase()}',
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .4,
                        ),
                      ),
                      Text(
                        voucher.title,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        voucher.discountAmount,
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      voucher.isClaimed
                          ? 'Already claimed'
                          : !voucher.isAvailable
                          ? 'Currently out of stock'
                          : voucher.isUnlocked
                          ? 'Unlocked and ready'
                          : '$remaining XP to unlock',
                      style: TextStyle(
                        color: voucher.isUnlocked && voucher.isAvailable
                            ? AppColors.green
                            : AppColors.slate,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${voucher.requiredXp} XP',
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: AppColors.line,
                  color: voucher.isUnlocked ? AppColors.green : AppColors.blue,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        !voucher.isUnlocked || !voucher.isAvailable || busy
                        ? null
                        : onClaim,
                    icon: busy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            voucher.isClaimed
                                ? Icons.visibility_outlined
                                : Icons.redeem,
                            size: 17,
                          ),
                    label: Text(
                      voucher.isClaimed
                          ? 'View my code'
                          : !voucher.isAvailable
                          ? 'Out of stock'
                          : voucher.isUnlocked
                          ? 'Claim reward'
                          : 'Locked',
                    ),
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
