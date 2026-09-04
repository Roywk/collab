import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../data/emergency_repository.dart';
import '../../models/emergency_models.dart';
import 'bank_call_screen.dart';

class BankHotlineDetailScreen extends StatefulWidget {
  const BankHotlineDetailScreen({
    required this.repository,
    required this.bank,
    super.key,
  });

  final EmergencyRepository repository;
  final BankHotline bank;

  @override
  State<BankHotlineDetailScreen> createState() =>
      _BankHotlineDetailScreenState();
}

class _BankHotlineDetailScreenState extends State<BankHotlineDetailScreen> {
  bool _submitting = false;

  Future<void> _confirmKillSwitch() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FreezeConfirmationDialog(bank: widget.bank),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _submitting = true);
    try {
      try {
        await widget.repository.recordKillSwitchCall(widget.bank);
      } catch (error) {
        // Audit logging must never prevent a tourist from reaching the bank.
        debugPrint('Kill switch call could not be logged: $error');
      }
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BankCallScreen(bank: widget.bank),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bank = widget.bank;
    return MobileShell(
      title: '${bank.name} Details',
      titleColor: AppColors.navy,
      statusLabel: 'KL: Active',
      onBack: () => Navigator.of(context).pop(),
      currentNavigationIndex: 3,
      emergencyNavigation: true,
      onMap: () => Navigator.of(context).popUntil((route) => route.isFirst),
      onVerify: () => Navigator.of(context).popUntil((route) => route.isFirst),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SurfaceCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      bank.isMalaysian ? '🇲🇾' : '🌐',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bank.name,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            bank.countryName,
                            style: const TextStyle(
                              color: AppColors.slate,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 16),
                const _DetailLabel('HOTLINE NUMBER'),
                const SizedBox(height: 3),
                Text(
                  bank.hotlineNumber,
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 13),
                const _DetailLabel('SERVICE TYPE'),
                const SizedBox(height: 3),
                Text(
                  bank.serviceType,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 13),
                const _DetailLabel('TARGET DEPARTMENT'),
                const SizedBox(height: 3),
                Text(
                  bank.targetDepartment,
                  style: const TextStyle(color: AppColors.navy, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _confirmKillSwitch,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE5252A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.shield_outlined, size: 18),
              label: const Text(
                'Freeze Account / Kill Switch',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.amberSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: Color(0xFFD97706),
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'The Kill Switch is a destructive operation. All virtual '
                    'cards may be deactivated by your bank.',
                    style: TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 10,
                      height: 1.3,
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

class _DetailLabel extends StatelessWidget {
  const _DetailLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.slate,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _FreezeConfirmationDialog extends StatelessWidget {
  const _FreezeConfirmationDialog({required this.bank});

  final BankHotline bank;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 34),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.redSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.red,
                size: 22,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Freeze Your Account?',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'This will connect you to ${bank.name} so the bank can freeze '
              'the cards linked to your account. Contact the bank to '
              'reactivate them.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.slate,
                fontSize: 11,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE5252A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Confirm Freeze',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
