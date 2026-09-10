import 'package:flutter/material.dart';

import '../models/module_models.dart';
import 'app_theme.dart';

class MobileShell extends StatelessWidget {
  const MobileShell({
    required this.child,
    this.title,
    this.onBack,
    this.onAdmin,
    this.onHome,
    this.onMap,
    this.onVerify,
    this.onReport,
    this.onEmergency,
    this.onLearn,
    this.onProfile,
    this.currentNavigationIndex = 2,
    this.gpsActive,
    this.showBottomNavigation = true,
    this.darkBackground = false,
    this.statusLabel,
    this.titleColor = AppColors.blue,
    this.emergencyNavigation = false,
    super.key,
  });

  final Widget child;
  final String? title;
  final VoidCallback? onBack;
  final VoidCallback? onAdmin;
  final VoidCallback? onHome;
  final VoidCallback? onMap;
  final VoidCallback? onVerify;
  final VoidCallback? onReport;
  final VoidCallback? onEmergency;
  final VoidCallback? onLearn;
  final VoidCallback? onProfile;
  final int currentNavigationIndex;
  final bool? gpsActive;
  final bool showBottomNavigation;
  final bool darkBackground;
  final String? statusLabel;
  final Color titleColor;
  final bool emergencyNavigation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground
          ? const Color(0xFF090B10)
          : AppColors.canvas,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        shape: const Border(bottom: BorderSide(color: AppColors.line)),
        titleSpacing: 16,
        title: Row(
          children: [
            if (onBack != null) ...[
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(50),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_left, size: 22),
                ),
              ),
              const SizedBox(width: 6),
            ] else ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  title ?? 'Visit 1MY',
                  maxLines: 1,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          GpsStatusBadge(isActive: gpsActive, label: statusLabel),
          PopupMenuButton<String>(
            tooltip: 'Notifications',
            icon: const Icon(
              Icons.notifications_none_rounded,
              size: 21,
              color: AppColors.navy,
            ),
            onSelected: (value) {
              if (value == 'admin') {
                onAdmin?.call();
              }
            },
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                  value: 'notification',
                  child: Text('No new notifications'),
                ),
                if (onAdmin != null)
                  const PopupMenuItem(
                    value: 'admin',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings_outlined, size: 19),
                        SizedBox(width: 10),
                        Text('Open admin database'),
                      ],
                    ),
                  ),
              ];
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 393),
          child: child,
        ),
      ),
      bottomNavigationBar: showBottomNavigation
          ? VisitBottomNavigation(
              currentIndex: currentNavigationIndex,
              onHome: onHome,
              onMap: onMap,
              onVerify: onVerify,
              onReport: onReport,
              onEmergency: onEmergency,
              onLearn: onLearn,
              onProfile: onProfile,
              emergencyMode: emergencyNavigation,
            )
          : null,
    );
  }
}

class GpsStatusBadge extends StatelessWidget {
  const GpsStatusBadge({this.isActive, this.label, super.key});

  final bool? isActive;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive == false ? AppColors.amberSoft : AppColors.greenSoft,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 3,
            backgroundColor: isActive == false
                ? AppColors.amber
                : AppColors.green,
          ),
          SizedBox(width: 5),
          Text(
            label ?? (isActive == false ? 'GPS Paused' : 'GPS Active'),
            style: TextStyle(
              color: isActive == false ? AppColors.amber : AppColors.green,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class VisitBottomNavigation extends StatelessWidget {
  const VisitBottomNavigation({
    this.currentIndex = 2,
    this.onHome,
    this.onMap,
    this.onVerify,
    this.onReport,
    this.onEmergency,
    this.onLearn,
    this.onProfile,
    this.emergencyMode = false,
    super.key,
  });

  final int currentIndex;
  final VoidCallback? onHome;
  final VoidCallback? onMap;
  final VoidCallback? onVerify;
  final VoidCallback? onReport;
  final VoidCallback? onEmergency;
  final VoidCallback? onLearn;
  final VoidCallback? onProfile;
  final bool emergencyMode;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, 'Home'),
      (Icons.map_outlined, 'Map'),
      (Icons.verified_user_outlined, 'Verify'),
      (Icons.add_circle_outline, 'Report'),
      (Icons.phone_outlined, 'Emergency'),
      (Icons.menu_book_outlined, 'Learn'),
      (Icons.person_outline_rounded, 'Profile'),
    ];

    final callbacks = [
      onHome ?? () => Navigator.of(context).popUntil((route) => route.isFirst),
      onMap ??
          () {
            if (currentIndex != 1) Navigator.of(context).pushNamed('/map');
          },
      onVerify ??
          () {
            if (currentIndex != 2) Navigator.of(context).pushNamed('/verify');
          },
      onReport ??
          () {
            if (currentIndex != 3) Navigator.of(context).pushNamed('/report');
          },
      onEmergency ??
          () {
            if (currentIndex != 4) {
              Navigator.of(context).pushNamed('/emergency');
            }
          },
      onLearn ??
          () {
            if (currentIndex != 5) Navigator.of(context).pushNamed('/learn');
          },
      onProfile ?? () => Navigator.of(context).pushNamed('/profile'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 6,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (int index = 0; index < items.length; index++)
              Expanded(
                child: InkWell(
                  onTap: callbacks[index],
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (index == currentIndex)
                          Container(
                            width: 30,
                            height: 2,
                            margin: const EdgeInsets.only(bottom: 5),
                            color: AppColors.blue,
                          )
                        else
                          const SizedBox(height: 7),
                        Icon(
                          items[index].$1,
                          size: 21,
                          color: index == currentIndex
                              ? AppColors.blue
                              : AppColors.slate,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[index].$2,
                          style: TextStyle(
                            color: index == currentIndex
                                ? AppColors.blue
                                : AppColors.slate,
                            fontSize: 9,
                            fontWeight: index == currentIndex
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ],
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

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.borderColor = AppColors.line,
    this.radius = 12,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class RiskBadge extends StatelessWidget {
  const RiskBadge({required this.riskLevel, this.showPrefix = true, super.key});

  final RiskLevel riskLevel;
  final bool showPrefix;

  Color get foregroundColor {
    switch (riskLevel) {
      case RiskLevel.safe:
        return AppColors.green;
      case RiskLevel.suspicious:
        return AppColors.amber;
      case RiskLevel.highRisk:
        return AppColors.red;
    }
  }

  Color get backgroundColor {
    switch (riskLevel) {
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
    final prefix = showPrefix ? 'Risk Level: ' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$prefix${riskLevel.label}',
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    required this.label,
    required this.value,
    this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.slate, fontSize: 12),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? AppColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.blue,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: icon == null
          ? FilledButton(
              onPressed: onPressed,
              style: buttonStyle,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : FilledButton.icon(
              onPressed: onPressed,
              style: buttonStyle,
              icon: Icon(icon, size: 18),
              label: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
    );
  }
}
