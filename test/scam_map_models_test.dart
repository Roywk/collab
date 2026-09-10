import 'package:collab/models/scam_map_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('official scam categories are unique and consistently named', () {
    expect(ScamCategories.values, contains(ScamCategories.taxi));
    expect(ScamCategories.values, isNot(contains('Taxi Tout')));
    expect(ScamCategories.values.toSet().length, ScamCategories.values.length);
  });

  test('dashboard analytics separates verified and pending map reports', () {
    final now = DateTime(2026, 9, 10);
    final reports = [
      ScamMapReport(
        id: 'verified',
        title: 'Verified case',
        category: ScamCategories.taxi,
        description: 'Demo',
        latitude: 3.1340,
        longitude: 101.6869,
        status: ScamVerificationStatus.verified,
        reportedAt: now,
        isOfficial: true,
      ),
      ScamMapReport(
        id: 'pending',
        title: 'Pending case',
        category: ScamCategories.other,
        description: 'Demo',
        latitude: 3.2379,
        longitude: 101.6840,
        status: ScamVerificationStatus.pending,
        reportedAt: now,
      ),
    ];

    final analytics = ScamThreatAnalytics.fromReports(reports);

    expect(analytics.totalReports, 2);
    expect(analytics.verifiedReports, 1);
    expect(analytics.pendingReports, 1);
    expect(analytics.categoryCounts[ScamCategories.taxi], 1);
  });
}
