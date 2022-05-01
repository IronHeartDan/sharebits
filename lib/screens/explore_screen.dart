import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {});
    });
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
                ListView.builder(itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.account_circle_rounded),
                    title: Text(index.toString()),
                  );
                }),
                const Center(
                  child: Icon(Icons.list),
                )
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
              label: "Friends")
        ],
      ),
    );
  }
}
