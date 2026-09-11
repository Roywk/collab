import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

class MerchantAppDemoScreen extends StatefulWidget {
  const MerchantAppDemoScreen({
    required this.partnerName,
    required this.voucherTitle,
    required this.benefit,
    required this.validCode,
    super.key,
  });

  final String partnerName;
  final String voucherTitle;
  final String benefit;
  final String validCode;

  @override
  State<MerchantAppDemoScreen> createState() => _MerchantAppDemoScreenState();
}

class _MerchantAppDemoScreenState extends State<MerchantAppDemoScreen> {
  final _code = TextEditingController();
  String? _message;
  bool _success = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _apply() {
    final matches =
        _code.text.trim().toUpperCase() ==
        widget.validCode.trim().toUpperCase();
    setState(() {
      _success = matches;
      _message = matches
          ? '${widget.benefit} applied successfully to ${widget.voucherTitle}.'
          : 'That code does not match this reward. Check the characters and try again.';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F8FC),
    appBar: AppBar(
      title: Text('${widget.partnerName} · Demo'),
      centerTitle: false,
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navy, AppColors.blue],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  color: Colors.white,
                  size: 34,
                ),
                const SizedBox(height: 18),
                Text(
                  widget.partnerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'Partner redemption simulator',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Apply your Visit 1MY reward',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This safe demo shows how your unique voucher would be validated by a partner app.',
            style: TextStyle(color: AppColors.slate.withValues(alpha: .9)),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Unique voucher code',
              prefixIcon: Icon(Icons.confirmation_number_outlined),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _apply(),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _apply,
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Apply code'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _success ? AppColors.greenSoft : AppColors.redSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _success ? AppColors.green : AppColors.red,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _success ? Icons.check_circle : Icons.info_outline,
                    color: _success ? AppColors.green : AppColors.red,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_message!)),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
