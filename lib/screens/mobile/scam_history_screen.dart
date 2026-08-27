import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../data/verification_repository.dart';
import '../../models/module_models.dart';

class ScamHistoryScreen extends StatelessWidget {
  const ScamHistoryScreen({
    required this.repository,
    required this.record,
    super.key,
  });

  final VerificationRepository repository;
  final ThreatRecord record;

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Scam History',
      onBack: () => Navigator.of(context).pop(),
      child: FutureBuilder<List<ScamIncident>>(
        future: repository.getScamHistory(record.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SurfaceCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        size: 42,
                        color: AppColors.red,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'History unavailable',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final incidents = snapshot.data ?? <ScamIncident>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.businessName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${incidents.length} verified incidents logged',
                          style: const TextStyle(
                            color: AppColors.slate,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RiskBadge(riskLevel: record.riskLevel, showPrefix: false),
                ],
              ),
              const SizedBox(height: 18),
              if (incidents.isEmpty)
                const SurfaceCard(
                  child: Text('No verified scam incidents were found.'),
                )
              else
                for (int index = 0; index < incidents.length; index++)
                  IncidentTimelineItem(
                    incident: incidents[index],
                    isLast: index == incidents.length - 1,
                  ),
            ],
          );
        },
      ),
    );
  }
}

class IncidentTimelineItem extends StatelessWidget {
  const IncidentTimelineItem({
    required this.incident,
    required this.isLast,
    super.key,
  });

  final ScamIncident incident;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 1, color: AppColors.line)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SurfaceCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${incident.reportCode} • '
                            '${DateFormat('MMM dd, yyyy').format(incident.reportedAt)}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.redSoft,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            incident.category,
                            style: const TextStyle(
                              color: AppColors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      incident.description,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
                    if (incident.hasEvidence) ...[
                      const SizedBox(height: 9),
                      const Row(
                        children: [
                          Icon(
                            Icons.attach_file,
                            size: 14,
                            color: AppColors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Report evidence attached',
                            style: TextStyle(
                              color: AppColors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
