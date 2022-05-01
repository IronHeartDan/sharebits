import 'package:flutter/material.dart';
import 'package:sharebits/utils/notification_api.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    var size = mediaQuery.size;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Notification"),
      ),
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
                onPressed: () {
                  NotificationAPI.showNotification(
                    title: "New Notification",
                    body: "This is a new notification from flutter",
                  );
                },
                child: const Text("Show")),
            ElevatedButton(onPressed: () {}, child: const Text("Show")),
            ElevatedButton(onPressed: () {}, child: const Text("Show")),
          ],
        ),
      ),
    );
  }
}
