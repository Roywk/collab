import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../models/incident_report_models.dart';

class IncidentReportShell extends StatelessWidget {
  const IncidentReportShell({
    required this.title,
    required this.child,
    required this.onBack,
    super.key,
  });

  final String title;
  final Widget child;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: title,
      titleColor: AppColors.navy,
      statusLabel: 'KL: Active',
      onBack: onBack,
      currentNavigationIndex: 4,
      emergencyNavigation: true,
      child: child,
    );
  }
}

class ReportLanguageSelector extends StatelessWidget {
  const ReportLanguageSelector({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final ReportInputLanguage value;
  final ValueChanged<ReportInputLanguage> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 43,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFE5EAF2),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          for (final language in ReportInputLanguage.values)
            Expanded(
              child: InkWell(
                onTap: enabled ? () => onChanged(language) : null,
                borderRadius: BorderRadius.circular(7),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == language
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    language.label,
                    style: TextStyle(
                      color: value == language
                          ? AppColors.blue
                          : AppColors.slate,
                      fontSize: 12,
                      fontWeight: value == language
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ReportFieldLabel extends StatelessWidget {
  const ReportFieldLabel(this.text, {this.required = false, super.key});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        required ? '$text *' : text,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ReportReadOnlyField extends StatelessWidget {
  const ReportReadOnlyField({
    required this.label,
    required this.value,
    this.icon,
    this.multiline = false,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReportFieldLabel(label),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: multiline ? 78 : 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            crossAxisAlignment: multiline
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: AppColors.slate),
                const SizedBox(width: 9),
              ],
              Expanded(
                child: Text(
                  value.trim().isEmpty ? '—' : value,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
