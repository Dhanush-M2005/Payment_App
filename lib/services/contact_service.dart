import 'package:flutter_contacts/flutter_contacts.dart';

class ContactService {
  static Future<Contact?> findContactByPhone(String upiId) async {
    // Extract the part before @ if present
    String prefix = upiId.split('@')[0];

    // Clean the prefix (remove non-digits if it's supposed to be a phone number)
    String cleanPrefix = prefix.replaceAll(RegExp(r'\D'), '');

    // If the clean prefix is too short to be a phone number, it's probably not one
    if (cleanPrefix.length < 10) return null;

    if (await FlutterContacts.requestPermission()) {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      for (var contact in contacts) {
        for (var phone in contact.phones) {
          String cleanPhone = phone.number.replaceAll(RegExp(r'\D'), '');
          // Check if cleanPhone ends with cleanPrefix (to handle country codes)
          if (cleanPhone.endsWith(cleanPrefix) ||
              cleanPrefix.endsWith(cleanPhone)) {
            return contact;
          }
        }
      }
    }
    return null;
  }

  static bool startsWithNumber(String upiId) {
    if (upiId.isEmpty) return false;
    return RegExp(r'^\d').hasMatch(upiId);
  }
}
