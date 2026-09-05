import '../models/sos_models.dart';

String buildGoogleMapsLocationUrl({
  required double latitude,
  required double longitude,
}) {
  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': '$latitude,$longitude',
  }).toString();
}

String buildSosMessage({required double latitude, required double longitude}) {
  final locationUrl = buildGoogleMapsLocationUrl(
    latitude: latitude,
    longitude: longitude,
  );
  return 'Emergency! I need assistance. My current GPS location is: '
      '$locationUrl. Please contact me or emergency services immediately.';
}

String internationalPhoneDigits(String phoneNumber) {
  return phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
}

Uri buildWhatsAppSosUri({
  required EmergencyContact contact,
  required String message,
}) {
  return Uri.https(
    'wa.me',
    '/${internationalPhoneDigits(contact.phoneNumber)}',
    {'text': message},
  );
}

Uri buildSmsSosUri({
  required EmergencyContact contact,
  required String message,
}) {
  return Uri(
    scheme: 'sms',
    path: contact.phoneNumber,
    queryParameters: {'body': message},
  );
}
