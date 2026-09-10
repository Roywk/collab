import 'package:collab/core/haversine.dart';
import 'package:collab/models/help_nearby_models.dart';
import 'package:collab/services/help_nearby_navigation_service.dart';
import 'package:flutter_test/flutter_test.dart';

const facility = EmergencyFacility(
  id: 'facility-id',
  name: 'Balai Polis Bukit Bintang',
  type: EmergencyFacilityType.police,
  agencyLabel: 'PDRM POLICE',
  address: '45, Jalan Bukit Bintang, 55100 Kuala Lumpur',
  phoneNumber: '+603-2141-9999',
  latitude: 3.146783,
  longitude: 101.710663,
  availabilityLabel: 'Open 24 Hours',
  isVerified: true,
);

void main() {
  test('facility parser preserves database-backed contact details', () {
    final parsed = EmergencyFacility.fromJson({
      'id': facility.id,
      'name': facility.name,
      'facility_type': 'police',
      'agency_label': facility.agencyLabel,
      'address': facility.address,
      'phone_number': facility.phoneNumber,
      'latitude': facility.latitude,
      'longitude': facility.longitude,
      'availability_label': facility.availabilityLabel,
      'is_verified': true,
    });

    expect(parsed.name, facility.name);
    expect(parsed.type, EmergencyFacilityType.police);
    expect(parsed.phoneNumber, facility.phoneNumber);
    expect(parsed.isVerified, isTrue);
    expect(parsed.matches('bukit bintang'), isTrue);
  });

  test('nearby distance is calculated from the live user coordinates', () {
    final distance = haversineDistanceMeters(
      startLatitude: 3.1480,
      startLongitude: 101.7110,
      endLatitude: facility.latitude,
      endLongitude: facility.longitude,
    );

    expect(distance, greaterThan(100));
    expect(distance, lessThan(200));
  });

  test('navigation URL sends current location and address to Google Maps', () {
    final uri = buildGoogleMapsDirectionsUri(
      originLatitude: 3.1480,
      originLongitude: 101.7110,
      destination: facility,
    );

    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters['api'], '1');
    expect(uri.queryParameters['origin'], '3.148,101.711');
    expect(
      uri.queryParameters['destination'],
      '${facility.name}, ${facility.address}',
    );
    expect(uri.queryParameters['dir_action'], 'navigate');
  });
}
