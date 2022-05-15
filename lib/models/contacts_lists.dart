import 'package:sharebits/models/contact.dart';

class ContactLists {
  final List<BitsContact> foundContacts;
  final List<BitsContact> notFoundContacts;

  ContactLists(this.foundContacts, this.notFoundContacts);
}
