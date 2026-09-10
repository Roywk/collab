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

  Color get riskColor {
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
    final isSafe = record.riskLevel == RiskLevel.safe;

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
                    isSafe
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
                RiskBadge(riskLevel: record.riskLevel),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSafe
                      ? 'Official Record Details'
                      : 'Reported Entity Details',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 9),

                KeyValueRow(
                  label: isSafe ? 'Entity Name' : 'Reported Name',
                  value: record.businessName,
                ),

                if ((record.phone ?? '').isNotEmpty)
                  KeyValueRow(label: 'Phone', value: record.phone!),

                if ((record.email ?? '').isNotEmpty)
                  KeyValueRow(label: 'Email', value: record.email!),

                if ((record.officialUrl ?? '').isNotEmpty)
                  KeyValueRow(label: 'Website', value: record.officialUrl!),

                if ((record.locationTag ?? '').isNotEmpty)
                  KeyValueRow(label: 'Location', value: record.locationTag!),

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

          if (isSafe)
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
              onPressed: record.id.isEmpty
                  ? null
                  : () {
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
