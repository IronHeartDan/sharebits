import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationAPI {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }

  static Future showNotification(
      {int id = 0, String? title, String? body, String? payload}) async {
    _notifications.show(
        id,
        title,
        body,
        const NotificationDetails(
            android: AndroidNotificationDetails('CALL_CHANNEL', 'Call',
                channelDescription: 'Required to show incoming calls',
                importance: Importance.max),
            iOS: IOSNotificationDetails()),
        payload: payload);
  }
}
