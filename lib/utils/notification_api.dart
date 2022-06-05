import 'dart:convert';
import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:sharebits/utils/constants.dart';
import 'package:sharebits/utils/socket_connection.dart';
import 'package:sharebits/webrtc/rtc_connection.dart';

void onDidReceiveBackgroundNotificationResponse(response) async {
  var notificationResponse = response as NotificationResponse;

  log("Background CLick");

  var action = notificationResponse.actionId;
  var payload = jsonDecode(notificationResponse.payload!);

  if (action == "DECLINE") {
    http.post(Uri.parse("$bitsServer/rejectCall"),
        headers: {
          "content-type": "application/json",
        },
        body: jsonEncode({"who": payload["from"]}));
  }
}

class NotificationAPI {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final iosSettings = DarwinInitializationSettings(notificationCategories: [
      DarwinNotificationCategory(
        "Call",
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain("ACCEPT", "Accept",
              options: {DarwinNotificationActionOption.foreground})
        ],
        options: <DarwinNotificationCategoryOption>{
          DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
        },
      ),
    ]);
    final initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );
  }

  static void onDidReceiveNotificationResponse(response) async {
    var notificationResponse = response as NotificationResponse;
    var action = notificationResponse.actionId;
    var payload = jsonDecode(notificationResponse.payload!);

    var offer = RTCSessionDescription(
        payload["offer"]["sdp"], payload["offer"]["type"]);

    var socket = BitsSignalling().getSocket();

    switch (action) {
      case "DECLINE":
        socket.emit("callDeclined", payload["from"]);
        break;
      case "ACCEPT":
        var bitsConnection = BitsConnection();
        bitsConnection.connectedPeer = payload["from"];
        await bitsConnection.peerConnection.setRemoteDescription(offer);
        var remoteOffer = await bitsConnection.peerConnection.createAnswer();
        var answer = {"to": payload["from"], "offer": remoteOffer.toMap()};
        socket.emit("callAccepted", jsonEncode(answer));
        bitsConnection.peerConnection.onIceCandidate = (ice) {
          var data = {"to": payload["from"], "ice": ice.toMap()};
          socket.emit("iceCandidate", jsonEncode(data));
        };
        bitsConnection.peerConnection.setLocalDescription(remoteOffer);
        break;
    }
  }

  static Future showNotification(
      {int id = 0, String? title, String? body, String? payload}) async {
    _notifications.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'CALL_CHANNEL',
            'Call',
            channelDescription: 'Required to show incoming calls',
            importance: Importance.max,
            priority: Priority.max,
            // category: "CATEGORY_CALL",
            playSound: true,
            sound: RawResourceAndroidNotificationSound("incoming_call"),
            ongoing: true,
            autoCancel: false,
            fullScreenIntent: true,
            channelShowBadge: false,
            actions: [
              AndroidNotificationAction("ACCEPT", "Accept",
                  showsUserInterface: true),
              AndroidNotificationAction(
                "DECLINE",
                "Decline",
              ),
            ],
            // timeoutAfter: 6000
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: "Call",
          ),
        ),
        payload: payload);
  }

  static Future hideNotification() async {
    _notifications.cancel(0);
  }
}
