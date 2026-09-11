import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';

class ForgotPasswordHelpScreen extends StatelessWidget {
  const ForgotPasswordHelpScreen({super.key});

  static final Uri _emailUri = Uri(
    scheme: 'mailto',
    path: 'visit1my@gmail.com',
    queryParameters: {'subject': 'Visit 1MY password assistance'},
  );
  static final Uri _phoneUri = Uri(scheme: 'tel', path: '+0167691520');

  Future<void> _openContact(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No compatible email or phone application was found.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.canvas,
    appBar: AppBar(
      title: const Text('Forgot Password'),
      leading: BackButton(onPressed: () => Navigator.of(context).pop()),
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SurfaceCard(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.blueSoft,
                    child: Icon(
                      Icons.support_agent_outlined,
                      color: AppColors.blue,
                      size: 31,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Please contact our customer service if you have forgotten your password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ListTile(
                    leading: const Icon(
                      Icons.email_outlined,
                      color: AppColors.blue,
                    ),
                    title: const Text('Email'),
                    subtitle: const Text('visit1my@gmail.com'),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _openContact(context, _emailUri),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.phone_outlined,
                      color: AppColors.green,
                    ),
                    title: const Text('Phone Number'),
                    subtitle: const Text('+0167691520'),
                    trailing: const Icon(Icons.call_outlined, size: 18),
                    onTap: () => _openContact(context, _phoneUri),
                  ),
                  const SizedBox(height: 20),
                  PrimaryActionButton(
                    label: 'Return to Login',
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
