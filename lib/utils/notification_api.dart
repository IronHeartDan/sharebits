import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationAPI {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings,
        onDidReceiveNotificationResponse: (response) async {
      log("${response.payload}");
    }, onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse,
    );
  }

  static void onDidReceiveBackgroundNotificationResponse(response){
    log("${response.payload}");
  }

  static Future showNotification(
      {int id = 0, String? title, String? body, String? payload}) async {
    _notifications.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'CALL_CHANNEL',
            'Call',
            channelDescription: 'Required to show incoming calls',
            importance: Importance.max,
            priority: Priority.max,
            // category: "CATEGORY_CALL",
            playSound: true,
            // sound: const RawResourceAndroidNotificationSound("incoming_call"),
            enableVibration: true,
            vibrationPattern: Int64List.fromList([1111, 1111]),
            ongoing: true,
            autoCancel: false,
            fullScreenIntent: true,
            channelShowBadge: false,
            actions: const [
              AndroidNotificationAction("ACCEPT", "Accept"),
              AndroidNotificationAction("DECLINE", "Decline"),
            ],
          ),
        ),
        payload: payload);
  }

  static Future hideNotification() async {
    _notifications.cancel(0);
  }
}
