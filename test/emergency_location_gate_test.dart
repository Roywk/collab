import 'package:collab/screens/mobile/emergency_location_gate.dart';
import 'package:collab/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

class _FakeLocationService extends LocationService {
  LocationAccessStatus status = LocationAccessStatus.denied;
  int permissionRequests = 0;

  @override
  Future<LocationAccessStatus> accessStatus() async => status;

  @override
  Future<LocationPermission> ensurePermission() async {
    permissionRequests++;
    status = LocationAccessStatus.granted;
    return LocationPermission.whileInUse;
  }
}

void main() {
  testWidgets('emergency service requests permission before showing content', (
    tester,
  ) async {
    final locationService = _FakeLocationService();

    await tester.pumpWidget(
      MaterialApp(
        home: EmergencyLocationGate(
          title: 'Incident Report Generator',
          description: 'Location is required.',
          locationService: locationService,
          child: const Scaffold(body: Text('Incident form ready')),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Allow Location Access'), findsWidgets);
    expect(find.text('Incident form ready'), findsNothing);

    await tester.tap(find.text('Allow Location Access').last);
    await tester.pumpAndSettle();

    expect(locationService.permissionRequests, 1);
    expect(find.text('Incident form ready'), findsOneWidget);
  });
}
