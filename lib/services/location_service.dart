import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationUnavailableException implements Exception {
  const LocationUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocationService {
  Future<LocationPermission> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailableException(
        'Location tracking paused. Please enable GPS.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationUnavailableException(
        'Location permission is required for nearby scam alerts.',
      );
    }

    return permission;
  }

  Future<Position> currentPosition() async {
    await ensurePermission();
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  Stream<Position> watchPosition() async* {
    await ensurePermission();
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
