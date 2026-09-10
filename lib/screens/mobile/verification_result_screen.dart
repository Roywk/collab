import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../data/verification_repository.dart';
import '../../models/module_models.dart';
import 'scam_history_screen.dart';

class VerificationResultScreen extends StatelessWidget {
  const VerificationResultScreen({
    required this.repository,
    required this.record,
    super.key,
  });

  final VerificationRepository repository;
  final ThreatRecord record;

  bool get isUnknown => record.id.isEmpty;

  bool get isApproximateMatch => !isUnknown && record.matchDistance > 0;

  Color get riskColor {
    if (isUnknown) {
      return AppColors.blue;
    }

    switch (record.riskLevel) {
      case RiskLevel.safe:
        return AppColors.green;
      case RiskLevel.suspicious:
        return AppColors.amber;
      case RiskLevel.highRisk:
        return AppColors.red;
    }
  }

  Color get riskBackground {
    if (isUnknown) {
      return AppColors.blueSoft;
    }

    switch (record.riskLevel) {
      case RiskLevel.safe:
        return AppColors.greenSoft;
      case RiskLevel.suspicious:
        return AppColors.amberSoft;
      case RiskLevel.highRisk:
        return AppColors.redSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSafe = !isUnknown && record.riskLevel == RiskLevel.safe;

    final detailsTitle = isUnknown
        ? 'Search Details'
        : isSafe
        ? 'Official Record Details'
        : 'Reported Entity Details';

    final entityLabel = isUnknown
        ? 'Search Query'
        : isSafe
        ? 'Entity Name'
        : 'Reported Name';

    return MobileShell(
      title: 'Verification Detail',
      onBack: () => Navigator.of(context).pop(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SurfaceCard(
            padding: const EdgeInsets.all(24),
            radius: 16,
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: riskBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUnknown
                        ? Icons.help_outline_rounded
                        : isSafe
                        ? Icons.verified_user_outlined
                        : Icons.warning_amber_rounded,
                    color: riskColor,
                    size: 33,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  record.businessName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  record.recordCode == '—'
                      ? 'No database record'
                      : 'Record ${record.recordCode}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                const SizedBox(height: 10),

                if (isUnknown)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blueSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'UNKNOWN • NO MATCH',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                else
                  RiskBadge(riskLevel: record.riskLevel),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (isApproximateMatch) ...[
            SurfaceCard(
              color: AppColors.blueSoft,
              borderColor: AppColors.blue,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Approximate match found',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fuzzy search found this record with '
                          '${record.matchDistance} character '
                          'difference'
                          '${record.matchDistance == 1 ? '' : 's'}.',
                          style: const TextStyle(
                            color: AppColors.slate,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detailsTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 9),

                KeyValueRow(label: entityLabel, value: record.businessName),

                if ((record.phone ?? '').isNotEmpty)
                  KeyValueRow(label: 'Phone', value: record.phone!),

                if ((record.email ?? '').isNotEmpty)
                  KeyValueRow(label: 'Email', value: record.email!),

                if ((record.officialUrl ?? '').isNotEmpty)
                  KeyValueRow(label: 'Website', value: record.officialUrl!),

                if ((record.locationTag ?? '').isNotEmpty)
                  KeyValueRow(label: 'Location', value: record.locationTag!),

                if (!isUnknown)
                  KeyValueRow(label: 'Category', value: record.category),

                if (record.flaggedActivities.isNotEmpty)
                  KeyValueRow(
                    label: 'Flagged Activities',
                    value: record.flaggedActivities,
                    valueColor: riskColor,
                  ),

                if ((record.registrationStatus ?? '').isNotEmpty)
                  KeyValueRow(
                    label: 'Registration',
                    value: record.registrationStatus!,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (isUnknown)
            SurfaceCard(
              color: AppColors.blueSoft,
              borderColor: AppColors.blue,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.blue,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No matching threat record found',
                          style: TextStyle(
                            color: AppColors.blue,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 9),
                  Text(
                    'This result is Unknown, not Safe. The absence '
                    'of a database match does not guarantee that '
                    'the business is legitimate. Check the spelling '
                    'and continue carefully.',
                    style: TextStyle(
                      color: AppColors.slate,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            )
          else if (isSafe)
            SurfaceCard(
              color: AppColors.greenCanvas,
              borderColor: AppColors.greenSoft,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 18,
                        color: AppColors.green,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No matching verified threat reports',
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 9),
                  Text(
                    'The database currently contains no verified '
                    'complaints that increase this entity’s risk. '
                    'This does not guarantee absolute safety, so '
                    'continue using normal precautions.',
                    style: TextStyle(
                      color: AppColors.slate,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Risk Analysis',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 9),
                  KeyValueRow(
                    label: 'Verified Reports',
                    value: '${record.reportCount} reports',
                    valueColor: riskColor,
                  ),
                  KeyValueRow(
                    label: 'Risk Points',
                    value: '${record.riskPoints} points',
                    valueColor: riskColor,
                  ),
                  KeyValueRow(
                    label: 'Calculated Result',
                    value: record.riskLevel.label,
                    valueColor: riskColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryActionButton(
              label: 'View Scam History',
              icon: Icons.history,
              color: riskColor,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) {
                      return ScamHistoryScreen(
                        repository: repository,
                        record: record,
                      );
                    },
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
