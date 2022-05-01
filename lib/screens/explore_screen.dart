import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExplorerScreen extends StatefulWidget {
  const ExplorerScreen({Key? key}) : super(key: key);

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen> {
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
            child: TextFormField(
              decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.search),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  label: Text("Search Friends"),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(50)))),
            ),
          ),
          const Divider(
            thickness: 1,
            height: 0,
          ),
          Expanded(
            child: PageView(
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
          BottomNavigationBar(items: const [
            BottomNavigationBarItem(
                icon: Icon(
                  Icons.av_timer,
                  color: Colors.black,
                ),
                label: "Recent"),
            BottomNavigationBarItem(
                icon: Icon(
                  Icons.contacts,
                  color: Colors.black,
                ),
                label: "Friends")
          ])
        ],
      ),
    );
  }
}
