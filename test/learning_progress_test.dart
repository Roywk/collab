import 'package:collab/models/learning_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserLearningProfile progression', () {
    test('starts at zero progress for a new traveller', () {
      final profile = UserLearningProfile(
        userId: 'traveller-1',
        totalXp: 0,
        currentLevel: 1,
        vouchersCount: 0,
        rankTitle: 'Vigilant Voyager',
      );

      expect(profile.xpIntoCurrentLevel, 0);
      expect(profile.progressToNextLevel, 0);
      expect(profile.xpForNextLevel, 200);
    });

    test('measures progress inside the current 200 XP level', () {
      final profile = UserLearningProfile(
        userId: 'traveller-2',
        totalXp: 450,
        currentLevel: 3,
        vouchersCount: 1,
        rankTitle: 'Vigilant Voyager',
      );

      expect(profile.xpIntoCurrentLevel, 50);
      expect(profile.progressToNextLevel, .25);
      expect(profile.xpForNextLevel, 600);
    });

    test('clamps inconsistent remote values to a safe progress range', () {
      final profile = UserLearningProfile(
        userId: 'traveller-3',
        totalXp: 999,
        currentLevel: 1,
        vouchersCount: 0,
        rankTitle: 'Scam-Proof Guardian',
      );

      expect(profile.progressToNextLevel, 1);
    });

    test('keeps lifetime rank XP separate from the redeemable balance', () {
      final profile = UserLearningProfile(
        userId: 'traveller-4',
        totalXp: 650,
        availableXp: 250,
        currentLevel: 4,
        vouchersCount: 1,
        rankTitle: 'Safety Sentinel',
      );

      expect(profile.totalXp, 650);
      expect(profile.spendableXp, 250);
      expect(profile.currentLevel, 4);
    });

    test('uses lifetime XP as a safe fallback before migration', () {
      final profile = UserLearningProfile(
        userId: 'traveller-5',
        totalXp: 180,
        currentLevel: 1,
        vouchersCount: 0,
        rankTitle: 'Vigilant Voyager',
      );

      expect(profile.spendableXp, 180);
    });
  });

  group('RewardVoucher inventory', () {
    test('does not expose an unclaimed reward with no available codes', () {
      final reward = RewardVoucher(
        id: 'internal-uuid',
        referenceCode: 'VCH-000001',
        partnerName: 'Partner',
        title: 'Travel reward',
        discountAmount: '10% OFF',
        expiryDate: DateTime(2027),
        requiredXp: 100,
        isUnlocked: true,
      );

      expect(reward.isAvailable, isFalse);
    });

    test(
      'keeps a previously claimed code viewable after stock reaches zero',
      () {
        final reward = RewardVoucher(
          id: 'internal-uuid',
          referenceCode: 'VCH-000001',
          partnerName: 'Partner',
          title: 'Travel reward',
          discountAmount: '10% OFF',
          expiryDate: DateTime(2027),
          requiredXp: 100,
          isUnlocked: true,
          isClaimed: true,
          promoCode: 'PARTNER-0001',
        );

        expect(reward.isAvailable, isTrue);
      },
    );
  });
}
