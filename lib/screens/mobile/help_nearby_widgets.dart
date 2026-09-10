import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/help_nearby_models.dart';

Color facilityColor(EmergencyFacilityType type) {
  return switch (type) {
    EmergencyFacilityType.police => AppColors.blue,
    EmergencyFacilityType.fireRescue => AppColors.red,
    EmergencyFacilityType.rela => AppColors.green,
  };
}

Color facilitySoftColor(EmergencyFacilityType type) {
  return switch (type) {
    EmergencyFacilityType.police => AppColors.blueSoft,
    EmergencyFacilityType.fireRescue => AppColors.redSoft,
    EmergencyFacilityType.rela => AppColors.greenSoft,
  };
}

IconData facilityIcon(EmergencyFacilityType type) {
  return switch (type) {
    EmergencyFacilityType.police => Icons.shield_outlined,
    EmergencyFacilityType.fireRescue => Icons.local_fire_department_outlined,
    EmergencyFacilityType.rela => Icons.groups_outlined,
  };
}

class FacilityTypeBadge extends StatelessWidget {
  const FacilityTypeBadge({required this.facility, super.key});

  final EmergencyFacility facility;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: facilitySoftColor(facility.type),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        facility.agencyLabel,
        style: TextStyle(
          color: facilityColor(facility.type),
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class FacilityMapMarker extends StatelessWidget {
  const FacilityMapMarker({required this.type, super.key});

  final EmergencyFacilityType type;

  @override
  Widget build(BuildContext context) {
    final color = facilityColor(type);
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 7)],
      ),
      child: Icon(facilityIcon(type), color: color, size: 17),
    );
  }
}
