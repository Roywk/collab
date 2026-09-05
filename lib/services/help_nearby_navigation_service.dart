import '../models/help_nearby_models.dart';

Uri buildGoogleMapsDirectionsUri({
  required double originLatitude,
  required double originLongitude,
  required EmergencyFacility destination,
}) {
  return Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'origin': '$originLatitude,$originLongitude',
    'destination': '${destination.name}, ${destination.address}',
    'travelmode': 'driving',
    'dir_action': 'navigate',
  });
}

Uri buildTelephoneUri(String phoneNumber) {
  return Uri(scheme: 'tel', path: phoneNumber);
}
