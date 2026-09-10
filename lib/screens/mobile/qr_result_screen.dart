import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../models/module_models.dart';

class QrResultScreen extends StatelessWidget {
  const QrResultScreen({required this.result, super.key});

  final QrVerificationResult result;

  @override
  Widget build(BuildContext context) {
    final accentColor = result.isSafe ? AppColors.green : AppColors.red;

    final backgroundColor = result.isSafe
        ? AppColors.greenSoft
        : AppColors.redSoft;

    return MobileShell(
      title: 'Scan Result',
      onBack: () => Navigator.of(context).pop(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'SCANNED URL DESTINATION',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          SurfaceCard(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              result.rawValue,
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),

          SurfaceCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    result.isSafe
                        ? Icons.verified_user_outlined
                        : Icons.warning_amber_rounded,
                    color: accentColor,
                    size: 31,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  result.isSafe
                      ? 'Domain Verified Safe'
                      : 'Suspicious Domain Detected',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if ((result.merchantName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    result.merchantName!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.isSafe
                      ? 'Domain Analysis Details'
                      : 'Threat Indicators',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                KeyValueRow(
                  label: 'Connection Security',
                  value: result.connectionDetail,
                  valueColor: accentColor,
                ),
                KeyValueRow(
                  label: 'Domain Extension',
                  value: result.domainDetail,
                  valueColor: accentColor,
                ),
                KeyValueRow(
                  label: 'Phishing Check',
                  value: result.phishingDetail,
                  valueColor: accentColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SurfaceCard(
            color: result.isSafe ? AppColors.greenCanvas : AppColors.redSoft,
            borderColor: backgroundColor,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  result.isSafe
                      ? Icons.verified_outlined
                      : Icons.gpp_bad_outlined,
                  size: 19,
                  color: accentColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.isSafe
                        ? '${result.merchantName ?? 'This destination'} '
                              'passed the current security checks. '
                              'Confirm the merchant name before payment.'
                        : 'DO NOT proceed with this payment. '
                              'The destination contains one or more '
                              'security or phishing indicators.',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (!result.isSafe) ...[
            const SizedBox(height: 16),
            PrimaryActionButton(
              label: 'Report This QR Code',
              icon: Icons.flag_outlined,
              color: AppColors.red,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'The QR details are ready for the '
                      'team Report module.',
                    ),
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
