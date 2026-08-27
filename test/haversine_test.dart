import 'package:flutter_test/flutter_test.dart';

import 'package:collab/core/haversine.dart';

void main() {
  group('haversineDistanceMeters', () {
    test('returns zero for the same coordinate', () {
      final distance = haversineDistanceMeters(
        startLatitude: 3.1478,
        startLongitude: 101.7134,
        endLatitude: 3.1478,
        endLongitude: 101.7134,
      );

      expect(distance, closeTo(0, 0.001));
    });

    test('calculates a known short distance accurately', () {
      final distance = haversineDistanceMeters(
        startLatitude: 3.1478,
        startLongitude: 101.7134,
        endLatitude: 3.1490,
        endLongitude: 101.7134,
      );

      expect(distance, closeTo(133.4, 1));
    });
  });

  group('isCoordinateInMalaysia', () {
    test('accepts Kuala Lumpur coordinates', () {
      expect(isCoordinateInMalaysia(3.1478, 101.7134), isTrue);
    });

    test('rejects coordinates outside the configured borders', () {
      expect(isCoordinateInMalaysia(35.6762, 139.6503), isFalse);
    });
  });
}
