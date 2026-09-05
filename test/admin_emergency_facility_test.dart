import 'package:collab/core/app_theme.dart';
import 'package:collab/data/admin_facility_repository.dart';
import 'package:collab/models/admin_facility_models.dart';
import 'package:collab/models/help_nearby_models.dart';
import 'package:collab/screens/admin/admin_emergency_facility_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const policeStation = AdminFacilityRecord(
  id: 'facility-id',
  name: 'Balai Polis Bukit Bintang',
  type: EmergencyFacilityType.police,
  agencyLabel: 'PDRM POLICE',
  address: '45 Jalan Bukit Bintang, 55100 Kuala Lumpur',
  latitude: 3.1478,
  longitude: 101.7108,
  phoneNumber: '+603-2141-1999',
  availabilityLabel: 'Open 24 Hours',
  isActive: true,
  isVerified: true,
);

class _FakeAdminFacilityRepository implements AdminFacilityRepository {
  final List<AdminFacilityRecord> facilities = [policeStation];

  @override
  Future<List<AdminFacilityRecord>> getFacilities() async => facilities;

  @override
  Future<void> saveFacility(AdminFacilityRecord facility) async {}

  @override
  Future<void> deleteFacility(String facilityId) async {}
}

void main() {
  test('admin facility parses the shared mobile directory row', () {
    final parsed = AdminFacilityRecord.fromJson({
      'id': policeStation.id,
      'name': policeStation.name,
      'facility_type': 'police',
      'agency_label': policeStation.agencyLabel,
      'address': policeStation.address,
      'latitude': policeStation.latitude,
      'longitude': policeStation.longitude,
      'phone_number': policeStation.phoneNumber,
      'availability_label': policeStation.availabilityLabel,
      'is_active': true,
      'is_verified': true,
    });

    expect(parsed.name, 'Balai Polis Bukit Bintang');
    expect(parsed.type, EmergencyFacilityType.police);
    expect(parsed.latitude, 3.1478);
    expect(parsed.isActive, isTrue);
  });

  testWidgets('facility directory opens add, edit and delete dialogs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: AdminEmergencyFacilityScreen(
          repository: _FakeAdminFacilityRepository(),
          onSignOut: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Emergency Facility Management'), findsOneWidget);
    expect(find.text('Balai Polis Bukit Bintang'), findsOneWidget);
    expect(find.text('+603-2141-1999'), findsOneWidget);

    await tester.tap(find.text('Add Facility'));
    await tester.pumpAndSettle();
    expect(find.text('Add New Emergency Facility'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit Emergency Facility'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete').first);
    await tester.pumpAndSettle();
    expect(find.text('Delete Facility Record?'), findsOneWidget);
    expect(find.text('Delete Facility'), findsOneWidget);
  });
}
