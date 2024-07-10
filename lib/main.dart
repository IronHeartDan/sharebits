import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sharebits/screens/authentication_screen.dart';
import 'package:sharebits/screens/home_screen.dart';
import 'package:sharebits/states/call_state.dart';
import 'package:sharebits/utils/constants.dart';

import 'models/contact.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  var callRequestInfo = jsonDecode(message.data["payload"]);

  var params = CallKitParams(
        id: callRequestInfo["from"],
        nameCaller: "Video Call ${callRequestInfo['from']}",
        appName: 'Sharebits',
        avatar: 'https://i.pravatar.cc/100',
        handle: callRequestInfo["from"],
        type: 1,
        textAccept: 'Accept',
        textDecline: 'Decline',
        // textMissedCall: 'Missed call',
        // textCallback: 'Call back',
        duration: 30000,
        extra: callRequestInfo,
        android: const AndroidParams(
              isCustomNotification: false,
              isShowLogo: false,
              // isShowCallback: false,
              // isShowMissedCallNotification: true,
              ringtonePath: 'system_ringtone_default',
              backgroundColor: '#0955fa',
              backgroundUrl: 'https://i.pravatar.cc/500',
              actionColor: '#4CAF50'
        ),
        ios: const IOSParams(
            iconName: 'CallKitLogo',
            handleType: 'generic',
            supportsVideo: true,
            maximumCallGroups: 2,
            maximumCallsPerCallGroup: 1,
            audioSessionMode: 'default',
            audioSessionActive: true,
            audioSessionPreferredSampleRate: 44100.0,
            audioSessionPreferredIOBufferDuration: 0.005,
            supportsDTMF: true,
            supportsHolding: true,
            supportsGrouping: false,
            supportsUngrouping: false,
            ringtonePath: 'system_ringtone_default'
        )
  );

  // FlutterCallkitIncoming.onEvent.listen((event) async {
  //   switch (event!.name) {
  //     case CallEvent.ACTION_CALL_DECLINE:
  //       http.post(Uri.parse("$bitsServer/rejectCall"),
  //           headers: {
  //             "content-type": "application/json",
  //           },
  //           body: jsonEncode({"who": callRequestInfo["from"]}));
  //       break;
  //   }
  // });

  await FlutterCallkitIncoming.showCallkitIncoming(params);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });

  await Hive.initFlutter();
  Hive.registerAdapter(BitsContactAdapter());
  await Hive.openBox("contacts");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  Future<bool> _checkPermission() async {
    var permissionStatus = await Permission.camera.status;
    if (permissionStatus.isGranted) {
      return true;
    } else if (permissionStatus.isDenied) {
      var res = await Permission.camera.request();
      return res.isGranted;
    } else {
      return false;
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
        designSize: const Size(1080, 1920),
        builder: (context, _) {
          return MultiProvider(
            providers: [ChangeNotifierProvider(create: (_) => BitsCallState())],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'WebRTC Based Communication',
              theme: ThemeData(
                // This is the theme of your application.
                //
                // Try running your application with "flutter run". You'll see the
                // application has a blue toolbar. Then, without quitting the app, try
                // changing the primarySwatch below to Colors.green and then invoke
                // "hot reload" (press "r" in the console where you ran "flutter run",
                // or simply save your changes to "hot reload" in a Flutter IDE).
                // Notice that the counter didn't reset back to zero; the application
                // is not restarted.
                primarySwatch: Colors.deepPurple,
              ),
              home: // return const HomeScreen();
                  FirebaseAuth.instance.currentUser != null
                      ? const HomeScreen()
                      : const AuthScreen(),
            ),
          );
        });
  }
}
