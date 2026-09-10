import 'dart:math' as math;

const double earthRadiusMeters = 6371000;

// Rectangular operating boundary used by Visit 1MY's Kuala Lumpur pilot.
// It intentionally covers DBKL and a small boundary tolerance for GPS drift.
const double kualaLumpurMinimumLatitude = 3.03;
const double kualaLumpurMaximumLatitude = 3.25;
const double kualaLumpurMinimumLongitude = 101.60;
const double kualaLumpurMaximumLongitude = 101.80;

double haversineDistanceMeters({
  required double startLatitude,
  required double startLongitude,
  required double endLatitude,
  required double endLongitude,
}) {
  final latitudeDelta = _toRadians(endLatitude - startLatitude);
  final longitudeDelta = _toRadians(endLongitude - startLongitude);
  final startLatitudeRadians = _toRadians(startLatitude);
  final endLatitudeRadians = _toRadians(endLatitude);

  final a =
      math.pow(math.sin(latitudeDelta / 2), 2) +
      math.cos(startLatitudeRadians) *
          math.cos(endLatitudeRadians) *
          math.pow(math.sin(longitudeDelta / 2), 2);

  final angularDistance = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusMeters * angularDistance;
}

double _toRadians(double degrees) => degrees * math.pi / 180;

bool isCoordinateInKualaLumpur(double latitude, double longitude) {
  return latitude >= kualaLumpurMinimumLatitude &&
      latitude <= kualaLumpurMaximumLatitude &&
      longitude >= kualaLumpurMinimumLongitude &&
      longitude <= kualaLumpurMaximumLongitude;
}
