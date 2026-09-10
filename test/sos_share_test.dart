import 'package:collab/models/sos_models.dart';
import 'package:collab/services/sos_share_service.dart';
import 'package:flutter_test/flutter_test.dart';

const contact = EmergencyContact(
  id: 'contact-id',
  name: 'Sarah Johnson',
  phoneNumber: '+44 7700 900123',
  relationship: 'Family',
  isPrimary: true,
);

void main() {
  test('emergency contact is parsed from database data', () {
    final parsed = EmergencyContact.fromJson({
      'id': contact.id,
      'name': contact.name,
      'phone_number': contact.phoneNumber,
      'relationship': contact.relationship,
      'is_primary': true,
    });

    expect(parsed.name, 'Sarah Johnson');
    expect(parsed.phoneNumber, '+44 7700 900123');
    expect(parsed.isPrimary, isTrue);
  });

  test('SOS message contains an encoded Google Maps location URL', () {
    final message = buildSosMessage(latitude: 3.1478, longitude: 101.7108);

    expect(message, contains('Emergency! I need assistance.'));
    expect(message, contains('https://www.google.com/maps/search/'));
    expect(message, contains('query=3.1478%2C101.7108'));
  });

  test('SOS message keeps precise GPS link and adds readable address', () {
    final message = buildSosMessage(
      latitude: 3.1478,
      longitude: 101.7108,
      address: '45 Jalan Bukit Bintang, Kuala Lumpur, Malaysia',
    );

    expect(message, contains('query=3.1478%2C101.7108'));
    expect(
      message,
      contains('Address: 45 Jalan Bukit Bintang, Kuala Lumpur, Malaysia.'),
    );
  });

  test('WhatsApp URI targets the database contact with pre-filled text', () {
    final uri = buildWhatsAppSosUri(
      contact: contact,
      message: 'Emergency test message',
    );

    expect(uri.scheme, 'https');
    expect(uri.host, 'wa.me');
    expect(uri.path, '/447700900123');
    expect(uri.queryParameters['text'], 'Emergency test message');
  });
}
