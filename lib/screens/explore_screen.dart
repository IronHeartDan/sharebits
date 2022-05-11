import 'dart:convert';

import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:sharebits/models/contacts_lists.dart';
import 'package:sharebits/utils/custom_search.dart';

import '../utils/constants.dart';

class ExplorerScreen extends StatefulWidget {
  const ExplorerScreen({Key? key}) : super(key: key);

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen> {
  final _pageController = PageController();
  int currentPage = 0;

  late Future<ContactLists> _future;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {});
    });
    _future = _getContacts();
  }

  Future<ContactLists> _getContacts() async {
    List<Contact> contacts =
        await ContactsService.getContacts(withThumbnails: false);

    Map<String, Contact> filteredContacts = {};
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
              filteredContacts[number] = contact;
            } else {
              number = "+91$number";
              if (number.length == 13) {
                phoneNumbers.add({"phoneNumber": number});
                filteredContacts[number] = contact;
              }
            }
          }
        }
      }
    }

    var results = await http.post(Uri.parse(socketServer),
        headers: {
          "content-type": "application/json",
        },
        body: jsonEncode({"phoneNumbers": phoneNumbers}));
    var data = await jsonDecode(results.body) as List<dynamic>;

    var foundContacts = data.map((element) {
      var con = filteredContacts[element]!;
      filteredContacts.remove(element);
      return con;
    }).toList();

    var notFoundContacts = filteredContacts.values.toList();

    var contactLists = ContactLists(foundContacts, notFoundContacts);
    return contactLists;
  }

  Future<void> _refresh() async {
    _future = _getContacts();
    await _future;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              width: 30,
              height: 10,
              decoration: const BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.all(Radius.circular(10))),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(30.w),
            child: GestureDetector(
              onTap: () {
                showSearch(context: context, delegate: CustomSearch());
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                height: 60,
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                    border: Border.all(width: 2, color: Colors.deepPurple)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Search Friends"),
                    Icon(
                      Icons.search,
                      color: Colors.deepPurple,
                    )
                  ],
                ),
              ),
            ),
          ),
          const Divider(
            thickness: 1,
            height: 0,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics:
                  const ScrollPhysics(parent: NeverScrollableScrollPhysics()),
              children: [
                ListView.builder(
                    itemCount: 50,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.account_circle_rounded),
                        title: Text(index.toString()),
                      );
                    }),
                RefreshIndicator(
                  onRefresh: () async {
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
                          var contacts = data.data as ContactLists;
                          return CustomScrollView(
                            slivers: [
                              SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                var contact = contacts.foundContacts[index];
                                return ListTile(
                                  title: Text("${contact.displayName}"),
                                  trailing: InkWell(
                                    onTap: () {},
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(Icons.videocam),
                                    ),
                                  ),
                                );
                              }, childCount: contacts.foundContacts.length)),
                              SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                var contact = contacts.notFoundContacts[index];
                                return ListTile(
                                  title: Text("${contact.displayName}"),
                                  trailing: TextButton(
                                    onPressed: () {},
                                    child: const Text(
                                      "Invite",
                                      style:
                                          TextStyle(color: Colors.deepPurple),
                                    ),
                                  ),
                                );
                              }, childCount: contacts.notFoundContacts.length)),
                            ],
                          );
                        }

                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: ((value) {
          _pageController.jumpToPage(value);
          setState(() {
            currentPage = value;
          });
        }),
        currentIndex: currentPage,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(
                Icons.av_timer,
              ),
              label: "Recent"),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.contacts,
              ),
              label: "Contacts")
        ],
      ),
    );
  }
}
