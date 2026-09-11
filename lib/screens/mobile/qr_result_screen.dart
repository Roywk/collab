import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../models/module_models.dart';
import 'report_scam_screen.dart';

class QrResultScreen extends StatelessWidget {
  const QrResultScreen({required this.result, super.key});

  final QrVerificationResult result;

  Color get accentColor {
    switch (result.verdict) {
      case QrVerdict.safe:
        return AppColors.green;
      case QrVerdict.suspicious:
        return AppColors.amber;
      case QrVerdict.highRisk:
        return AppColors.red;
      case QrVerdict.invalid:
      case QrVerdict.unknown:
        return AppColors.blue;
    }
  }

  Color get backgroundColor {
    switch (result.verdict) {
      case QrVerdict.safe:
        return AppColors.greenSoft;
      case QrVerdict.suspicious:
        return AppColors.amberSoft;
      case QrVerdict.highRisk:
        return AppColors.redSoft;
      case QrVerdict.invalid:
      case QrVerdict.unknown:
        return AppColors.blueSoft;
    }
  }

  IconData get verdictIcon {
    switch (result.verdict) {
      case QrVerdict.safe:
        return Icons.verified_user_outlined;
      case QrVerdict.suspicious:
        return Icons.report_problem_outlined;
      case QrVerdict.highRisk:
        return Icons.gpp_bad_outlined;
      case QrVerdict.invalid:
        return Icons.link_off_outlined;
      case QrVerdict.unknown:
        return Icons.help_outline_rounded;
    }
  }

  String get recommendation {
    switch (result.verdict) {
      case QrVerdict.safe:
        return 'The current checks found no known threat. Confirm the merchant '
            'name and payment amount before continuing.';
      case QrVerdict.suspicious:
        return 'Pause before continuing. Confirm the destination using the '
            'merchant’s official website or another trusted source.';
      case QrVerdict.highRisk:
        return 'Do not proceed with this payment. If you have already paid, '
            'contact your bank immediately.';
      case QrVerdict.invalid:
        return 'This QR code does not contain a valid supported website. '
            'Check the QR code or scan a different one.';
      case QrVerdict.unknown:
        return 'The online checks were incomplete. Retry when your Internet '
            'connection and the threat database are available.';
    }
  }

  Future<void> copyDestination(BuildContext context) async {
    if (result.rawValue.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: result.rawValue));
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Destination copied.')));
  }

  String buildReportDescription() {
    final lines = <String>[
      'QR verification result: ${result.verdict.label}',
      'Scanned destination: ${result.rawValue}',
    ];

    final merchantName = result.merchantName?.trim() ?? '';
    if (merchantName.isNotEmpty) {
      lines.add('Matched merchant or entity: $merchantName');
    }

    if (result.reasons.isNotEmpty) {
      lines.add('Verification findings:');
      lines.addAll(result.reasons.map((reason) => '- $reason'));
    }

    lines.add('');
    lines.add('Additional incident details:');
    return lines.join('\n');
  }

  void reportQrCode(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReportScamScreen(
          initialCategory: 'QR Code Scam',
          initialDescription: buildReportDescription(),
          prefillSource: 'QR verification',
          initialThreatRecordId: result.threatRecordId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'QR Verification Result',
      onBack: () => Navigator.of(context).pop(),
      showBottomNavigation: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'SCANNED DESTINATION',
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
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    result.rawValue.isEmpty
                        ? 'No destination detected'
                        : result.rawValue,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (result.rawValue.isNotEmpty)
                  IconButton(
                    tooltip: 'Copy destination',
                    onPressed: () => copyDestination(context),
                    icon: const Icon(Icons.copy_outlined, size: 18),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SurfaceCard(
            padding: const EdgeInsets.all(24),
            borderColor: backgroundColor,
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(verdictIcon, color: accentColor, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  result.verdict.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 17,
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
                  'Security Analysis',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                KeyValueRow(
                  label: 'Connection',
                  value: result.connectionDetail,
                ),
                KeyValueRow(
                  label: 'Domain Extension',
                  value: result.domainDetail,
                ),
                KeyValueRow(
                  label: 'Threat Database',
                  value: result.databaseDetail,
                ),
                KeyValueRow(
                  label: 'Impersonation',
                  value: result.phishingDetail,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SurfaceCard(
            color: backgroundColor,
            borderColor: backgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(verdictIcon, size: 19, color: accentColor),
                    const SizedBox(width: 8),
                    Text(
                      'Why this result?',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final reason in result.reasons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.circle, size: 6, color: accentColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reason,
                            style: const TextStyle(
                              color: AppColors.slate,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  recommendation,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),

          if (result.isHighRisk) ...[
            const SizedBox(height: 16),
            PrimaryActionButton(
              label: 'Contact Bank Immediately',
              icon: Icons.phone_in_talk_outlined,
              color: AppColors.red,
              onPressed: () => Navigator.of(context).pushNamed('/emergency'),
            ),
          ],

          if (result.rawValue.isNotEmpty &&
              result.verdict != QrVerdict.invalid) ...[
            const SizedBox(height: 12),
            PrimaryActionButton(
              label: 'Report This QR Code',
              icon: Icons.flag_outlined,
              color: AppColors.red,
              onPressed: () => reportQrCode(context),
            ),
          ],

          const SizedBox(height: 12),

          PrimaryActionButton(
            label: result.canRetry
                ? 'Try Verification Again'
                : 'Scan Another QR Code',
            icon: result.canRetry ? Icons.refresh : Icons.qr_code_scanner,
            color: accentColor,
            onPressed: () => Navigator.of(context).pop(),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: result.rawValue.isEmpty
                  ? null
                  : () => copyDestination(context),
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: const Text('Copy Destination'),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
