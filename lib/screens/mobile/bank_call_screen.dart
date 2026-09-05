import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/emergency_models.dart';

class BankCallScreen extends StatefulWidget {
  const BankCallScreen({required this.bank, super.key});

  final BankHotline bank;

  @override
  State<BankCallScreen> createState() => _BankCallScreenState();
}

class _BankCallScreenState extends State<BankCallScreen> {
  String _status = 'SIM Card Detected — Dialing...';

  @override
  void initState() {
    super.initState();
    unawaited(_openDialer());
  }

  Future<void> _openDialer() async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 550));
      final uri = Uri(scheme: 'tel', path: widget.bank.hotlineNumber);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        setState(() => _status = 'Unable to open the phone dialer');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Unable to open the phone dialer');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: Color(0xFF13275B),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 47,
                    height: 47,
                    decoration: const BoxDecoration(
                      color: Color(0xFF254BC4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_in_talk_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Connecting to Bank',
                  style: TextStyle(color: Color(0xFFA7B0C2), fontSize: 12),
                ),
                const SizedBox(height: 12),
                Text(
                  'Calling ${widget.bank.name} Emergency\nLine',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.bank.hotlineNumber,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF063F3B),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xFF00B894)),
                  ),
                  child: Text(
                    _status,
                    style: const TextStyle(
                      color: Color(0xFF1DE9B6),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE5252A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_disabled_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Tap red button to return to bank details',
                  style: TextStyle(color: Color(0xFF697386), fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
