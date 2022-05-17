import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sharebits/screens/contacts_screen.dart';
import 'package:sharebits/utils/custom_search.dart';

class ExplorerScreen extends StatefulWidget {
  const ExplorerScreen({Key? key}) : super(key: key);

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen> {
  final _pageController = PageController();
  int currentPage = 0;

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
            child: PageView.builder(
              controller: _pageController,
              itemCount: 2,
              physics:
                  const ScrollPhysics(parent: NeverScrollableScrollPhysics()),
              itemBuilder: (BuildContext context, int index) {
                return index == 0
                    ? const Center(
                        child: Text("RECENT"),
                      )
                    : const ContactsScreen();
              },
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
