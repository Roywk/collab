import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../core/app_widgets.dart';
import '../../../data/learning_repository.dart';
import '../../../models/learning_models.dart';
import 'package:intl/intl.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({required this.repository, super.key});

  final LearningRepository repository;

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late Future<UserLearningProfile> userProfile;
  late Future<List<RewardVoucher>> vouchers;

  @override
  void initState() {
    super.initState();
    userProfile = widget.repository.getUserProfile();
    vouchers = widget.repository.getVouchers();
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'My Rewards Profile',
      onBack: () => Navigator.pop(context),
      currentNavigationIndex: 4,
      child: FutureBuilder<List<dynamic>>(
        future: Future.wait([userProfile, vouchers]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data![0] as UserLearningProfile;
          final voucherList = snapshot.data![1] as List<RewardVoucher>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Card
              SurfaceCard(
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=alex'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Alex Mercer',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                          const Text(
                            'Tourist Member',
                            style: TextStyle(color: AppColors.slate, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.blueSoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified, color: AppColors.blue, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  profile.rankTitle,
                                  style: const TextStyle(
                                    color: AppColors.blue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Stats
              Row(
                children: [
                  Expanded(child: _buildStatCard('450', 'Total XP')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Lv. 3', 'Current Level')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('2', 'Vouchers')),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Available Rewards',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
              const SizedBox(height: 16),

              ...voucherList.map((voucher) => _buildVoucherCard(context, voucher, profile)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.blue),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.slate, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(BuildContext context, RewardVoucher voucher, UserLearningProfile profile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voucher.partnerName,
                        style: const TextStyle(color: AppColors.blue, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        voucher.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy),
                      ),
                    ],
                  ),
                ),
                if (!voucher.isUnlocked)
                  const Icon(Icons.lock_outline, color: AppColors.muted, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (voucher.isUnlocked) ...[
                  const Icon(Icons.check, color: AppColors.green, size: 14),
                  const SizedBox(width: 4),
                  const Text(
                    'Unlocked & Available',
                    style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ] else ...[
                  Text(
                    'Need ${voucher.requiredXp - profile.totalXp} more XP',
                    style: const TextStyle(color: AppColors.slate, fontSize: 10),
                  ),
                ],
                const Spacer(),
                ElevatedButton(
                  onPressed: voucher.isUnlocked ? () => _showVoucherModal(context, voucher) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: voucher.isUnlocked ? AppColors.blue : AppColors.line,
                    foregroundColor: voucher.isUnlocked ? Colors.white : AppColors.muted,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(voucher.isUnlocked ? 'Claim Now' : 'Locked', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showVoucherModal(BuildContext context, RewardVoucher voucher) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.greenSoft,
                child: Icon(Icons.check, color: AppColors.green),
              ),
              const SizedBox(height: 16),
              const Text(
                'Voucher Claimed!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Image.network(
                      'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${voucher.promoCode}',
                      height: 120,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      voucher.promoCode ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                voucher.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                'Valid until ${DateFormat('MMM dd, yyyy').format(voucher.expiryDate)}',
                style: const TextStyle(color: AppColors.slate, fontSize: 12),
              ),
              const SizedBox(height: 24),
              PrimaryActionButton(
                label: 'Save to Wallet',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: AppColors.slate, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
