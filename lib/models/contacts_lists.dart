import 'package:contacts_service/contacts_service.dart';

class ContactLists {
  final List<Contact> foundContacts;
  final List<Contact> notFoundContacts;

  ContactLists(this.foundContacts, this.notFoundContacts);
}
