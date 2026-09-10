import 'dart:math' as math;

const double earthRadiusMeters = 6371000;

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

bool isCoordinateInMalaysia(double latitude, double longitude) {
  const minimumLatitude = 0.85;
  const maximumLatitude = 7.36;
  const minimumLongitude = 99.64;
  const maximumLongitude = 119.27;

  return latitude >= minimumLatitude &&
      latitude <= maximumLatitude &&
      longitude >= minimumLongitude &&
      longitude <= maximumLongitude;
}
