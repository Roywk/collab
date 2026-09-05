import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../data/user_account_repository.dart';
import '../../models/user_profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.repository, super.key});

  final UserAccountRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<UserProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.repository.getProfile();
  }

  Future<void> _refresh() async {
    setState(() => _profileFuture = widget.repository.getProfile());
    await _profileFuture;
  }

  void _open(String route) => Navigator.of(context).pushNamed(route);

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      currentNavigationIndex: 0,
      statusLabel: 'KL: Active',
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            FutureBuilder<UserProfile>(
              future: _profileFuture,
              builder: (context, snapshot) {
                final name = snapshot.data?.fullName.trim();
                final firstName = name == null || name.isEmpty
                    ? 'Traveller'
                    : name.split(RegExp(r'\s+')).first;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $firstName',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Everything you need for a safer journey in Malaysia.',
                      style: TextStyle(color: AppColors.slate, fontSize: 12),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF173EAE), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2A1E40AF),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x2BFFFFFF),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Text(
                            'KUALA LUMPUR · ACTIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Travel with confidence',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Verify businesses, view local alerts and reach emergency help quickly.',
                          style: TextStyle(
                            color: Color(0xFFDCE7FF),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 66,
                    height: 66,
                    decoration: const BoxDecoration(
                      color: Color(0x2BFFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.travel_explore_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _SectionTitle(
              title: 'Quick actions',
              subtitle: 'Choose a service to get started',
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.34,
              children: [
                _HomeActionCard(
                  icon: Icons.verified_user_outlined,
                  title: 'Verify a Business',
                  subtitle: 'Check before you pay',
                  color: AppColors.blue,
                  softColor: AppColors.blueSoft,
                  onTap: () => _open('/verify'),
                ),
                _HomeActionCard(
                  icon: Icons.map_outlined,
                  title: 'Scam Map',
                  subtitle: 'See nearby alerts',
                  color: const Color(0xFF7C3AED),
                  softColor: const Color(0xFFEDE9FE),
                  onTap: () => _open('/map'),
                ),
                _HomeActionCard(
                  icon: Icons.phone_in_talk_outlined,
                  title: 'Emergency',
                  subtitle: 'Get immediate help',
                  color: AppColors.red,
                  softColor: AppColors.redSoft,
                  onTap: () => _open('/emergency'),
                ),
                _HomeActionCard(
                  icon: Icons.person_outline_rounded,
                  title: 'My Profile',
                  subtitle: 'Banks & contacts',
                  color: AppColors.green,
                  softColor: AppColors.greenSoft,
                  onTap: () => _open('/profile'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _SectionTitle(
              title: 'Safety centre',
              subtitle: 'Useful guidance while you travel',
            ),
            const SizedBox(height: 10),
            SurfaceCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.amberSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.amber,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today’s travel tip',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Never share an OTP, PIN or banking password. Official staff will not request them.',
                          style: TextStyle(
                            color: AppColors.slate,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.slate, fontSize: 9),
        ),
      ],
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.softColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color softColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: softColor,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.muted,
                    size: 13,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.slate, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
