import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
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
                      payload: "PAYLOAD");
                },
                child: const Text("Show")),
            ElevatedButton(
                onPressed: () {
                  NotificationAPI.hideNotification();
                },
                child: const Text("Cancel")),
            ElevatedButton(onPressed: () async{
              var params = <String, dynamic>{
                'id': "121212",
                'nameCaller': 'Hien Nguyen',
                'appName': 'Callkit',
                'avatar': 'https://i.pravatar.cc/100',
                'handle': '0123456789',
                'type': 1,
                'textAccept': 'Accept',
                'textDecline': 'Decline',
                'textMissedCall': 'Missed call',
                'textCallback': 'Call back',
                'duration': 30000,
                'extra': <String, dynamic>{'userId': '1a2b3c4d'},
                'headers': <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
                'android': <String, dynamic>{
                  'isCustomNotification': false,
                  'isShowLogo': false,
                  'isShowCallback': false,
                  'isShowMissedCallNotification': true,
                  'ringtonePath': 'system_ringtone_default',
                  'backgroundColor': '#0955fa',
                  'backgroundUrl': 'https://i.pravatar.cc/500',
                  'actionColor': '#4CAF50'
                },
                'ios': <String, dynamic>{
                  'iconName': 'CallKitLogo',
                  'handleType': 'generic',
                  'supportsVideo': true,
                  'maximumCallGroups': 2,
                  'maximumCallsPerCallGroup': 1,
                  'audioSessionMode': 'default',
                  'audioSessionActive': true,
                  'audioSessionPreferredSampleRate': 44100.0,
                  'audioSessionPreferredIOBufferDuration': 0.005,
                  'supportsDTMF': true,
                  'supportsHolding': true,
                  'supportsGrouping': false,
                  'supportsUngrouping': false,
                  'ringtonePath': 'system_ringtone_default'
                }
              };
              await FlutterCallkitIncoming.showCallkitIncoming(params);

              FlutterCallkitIncoming.onEvent.listen((event) {
                switch (event!.name) {
                  case CallEvent.ACTION_CALL_INCOMING:
                  // TODO: received an incoming call
                    break;
                  case CallEvent.ACTION_CALL_START:
                  // TODO: started an outgoing call
                  // TODO: show screen calling in Flutter
                    break;
                  case CallEvent.ACTION_CALL_ACCEPT:
                    print("Accepted ${event.body}");
                    break;
                  case CallEvent.ACTION_CALL_DECLINE:
                    print("Declined ${event.body}");
                    break;
                  case CallEvent.ACTION_CALL_ENDED:
                  // TODO: ended an incoming/outgoing call
                    break;
                  case CallEvent.ACTION_CALL_TIMEOUT:
                  // TODO: missed an incoming call
                    break;
                  case CallEvent.ACTION_CALL_CALLBACK:
                  // TODO: only Android - click action `Call back` from missed call notification
                    break;
                  case CallEvent.ACTION_CALL_TOGGLE_HOLD:
                  // TODO: only iOS
                    break;
                  case CallEvent.ACTION_CALL_TOGGLE_MUTE:
                  // TODO: only iOS
                    break;
                  case CallEvent.ACTION_CALL_TOGGLE_DMTF:
                  // TODO: only iOS
                    break;
                  case CallEvent.ACTION_CALL_TOGGLE_GROUP:
                  // TODO: only iOS
                    break;
                  case CallEvent.ACTION_CALL_TOGGLE_AUDIO_SESSION:
                  // TODO: only iOS
                    break;
                  case CallEvent.ACTION_DID_UPDATE_DEVICE_PUSH_TOKEN_VOIP:
                  // TODO: only iOS
                    break;
                }
              });
            }, child: const Text("Show")),
          ],
        ),
      ),
    );
  }
}
