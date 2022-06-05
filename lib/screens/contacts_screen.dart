import 'dart:convert';

import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/contact.dart';
import '../states/call_state.dart';
import '../utils/constants.dart';
import '../utils/socket_connection.dart';
import '../webrtc/rtc_connection.dart';

Future<List<BitsContact>> _syncContacts(List<Contact> contacts) async {
  Map<String, BitsContact> filteredContacts = {};
  var phoneNumbers = [];

  for (var contact in contacts) {
    if (contact.phones != null && contact.phones!.isNotEmpty) {
      for (var phone in contact.phones!) {
        if (phone.value != null) {
          var number = phone.value!.replaceAll(" ", "");
          number = number.replaceAll("-", "");
          if (number.startsWith("0")) {
            number = number.substring(1);
          }
          if (number.startsWith("+91") && number[3] == "0") {
            number = number.substring(0, 2) + number.substring(4);
          }
          if (number.startsWith("+91") && number.length == 13) {
            phoneNumbers.add({"phoneNumber": number});
            filteredContacts[number] = BitsContact(
                contact.displayName != null
                    ? contact.displayName!
                    : number.substring(3),
                number.substring(3));
          } else {
            number = "+91$number";
            if (number.length == 13) {
              phoneNumbers.add({"phoneNumber": number});
              filteredContacts[number] = BitsContact(
                  contact.displayName != null
                      ? contact.displayName!
                      : number.substring(3),
                  number.substring(3));
            }
          }
        }
      }
    }
  }

  var results = await http.post(Uri.parse("$bitsServer/users"),
      headers: {
        "content-type": "application/json",
      },
      body: jsonEncode({"phoneNumbers": phoneNumbers}));
  var data = await jsonDecode(results.body) as List<dynamic>;

  data.map((element) {
    filteredContacts[element]!.isAccount = true;
  }).toList();

  var processed = filteredContacts.values.toList();

  return processed;
}

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen>
    with AutomaticKeepAliveClientMixin {
  var bitsSignalling = BitsSignalling();
  var bitsConnection = BitsConnection();

  late Box box;
  late Future<List<BitsContact>> _future;

  @override
  void initState() {
    super.initState();
    _future = _getContacts(sync: false);
  }

  Future<List<BitsContact>> _getContacts({required bool sync}) async {
    box = Hive.box("contacts");
    var localContacts = box.get("contacts");

    if (!sync && localContacts != null) {
      return List<BitsContact>.from(localContacts);
    }

    List<Contact> contacts =
        await ContactsService.getContacts(withThumbnails: false);

    var bitsContacts = await compute(_syncContacts, contacts);
    await box.put("contacts", bitsContacts);
    return bitsContacts;
  }

  Future<void> _refresh() async {
    _future = _getContacts(sync: true);
    await _future;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () {
        return _refresh();
      },
      child: FutureBuilder(
          future: _future,
          builder: (context, data) {
            if (data.hasError) {
              return const Center(
                child: Text("An Error Occured"),
              );
            }

            if (data.hasData) {
              var contacts = data.data as List<BitsContact>;
              var found =
                  contacts.where((element) => element.isAccount).toList();
              var notFound =
                  contacts.where((element) => !element.isAccount).toList();
              return CustomScrollView(
                slivers: [
                  SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                    var contact = found[index];
                    return ListTile(
                      title: Text(contact.name),
                      trailing: InkWell(
                        onTap: () async {
                          bitsSignalling.socket.emitWithAck(
                              "call", contact.phone, ack: (ack) {
                            context.read<BitsCallState>().changeCallState(1);
                            bitsConnection.connectedPeer = contact.phone;
                            Navigator.of(context).pop();
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.videocam),
                        ),
                      ),
                    );
                  }, childCount: found.length)),
                  SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                    var contact = notFound[index];
                    return ListTile(
                      title: Text(contact.name),
                      trailing: TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Invite",
                          style: TextStyle(color: Colors.deepPurple),
                        ),
                      ),
                    );
                  }, childCount: notFound.length)),
                ],
              );
            }

            return const Center(
              child: CircularProgressIndicator(),
            );
          }),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
