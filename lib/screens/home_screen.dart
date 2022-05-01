import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sharebits/screens/explore_screen.dart';

Future<void> saveTokenToDatabase(String token) async {
  String phone = FirebaseAuth.instance.currentUser!.phoneNumber!.substring(3);

  var fireStore = FirebaseFirestore.instance;
  var check = await fireStore.collection("users").doc(phone).get();
  if (check.exists) {
    await fireStore.collection('users').doc(phone).update({
      'tokens': FieldValue.arrayUnion([token]),
    });
  } else {
    await fireStore.collection('users').doc(phone).set({
      'tokens': FieldValue.arrayUnion([token]),
    });
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool initialState = true;
  bool isDragging = false;
  bool inCall = false;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  List<MediaDeviceInfo>? _mediaDevicesList;
  MediaStream? _localStream;

  int currentCam = 0;

  int buttonsState = 0;
  double xPosition = 0;
  double yPosition = 0;

  Future<void> setupToken() async {
    // Get the token each time the application loads
    String? token = await FirebaseMessaging.instance.getToken();

    // Save the initial token to the database
    if (token != null) {
      await saveTokenToDatabase(token);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text("Something Went Wrong Please Restart The Application")));
    }

    // Any time the token refreshes, store this in the database too.
    FirebaseMessaging.instance.onTokenRefresh.listen(saveTokenToDatabase);
  }

  @override
  void initState() {
    super.initState();
    setupToken();
    // initRenderer();
  }

  void initRenderer() async {
    await _localRenderer.initialize();
    try {
      var mediaConstraints = <String, dynamic>{
        'audio': false,
        'video': {
          'facingMode': currentCam == 0 ? 'user' : 'environment',
          'optional': [],
        }
      };
      var stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _mediaDevicesList = await navigator.mediaDevices.enumerateDevices();
      _localStream = stream;
      _localRenderer.srcObject = _localStream;
      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    var size = mediaQuery.size;
    var statusBarHeight = mediaQuery.padding.top;
    if (initialState) {
      setState(() {
        xPosition = 10;
        yPosition = Platform.isIOS
            ? size.height - 160 - mediaQuery.padding.bottom
            : size.height - 160;
        initialState = false;
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
              child: InkWell(
            onTap: inCall
                ? () {
                    setState(() {
                      buttonsState = buttonsState == 0 ? 1 : 0;
                    });
                  }
                : null,
            child: RTCVideoView(
              _localRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          )),
          Visibility(
            visible: inCall,
            child: AnimatedPositioned(
              duration: isDragging
                  ? const Duration()
                  : const Duration(milliseconds: 100),
              top: yPosition,
              left: xPosition,
              child: GestureDetector(
                onPanStart: (info) {
                  setState(() {
                    isDragging = true;
                  });
                },
                onPanEnd: (info) {
                  setState(() {
                    isDragging = false;
                    xPosition =
                        xPosition > (size.width / 2) ? size.width - 110 : 10;
                    yPosition = yPosition > (size.height / 2)
                        ? Platform.isIOS
                            ? size.height - 160 - mediaQuery.padding.bottom
                            : size.height - 160
                        : statusBarHeight + 10;
                  });
                },
                onPanUpdate: (tapInfo) {
                  setState(() {
                    buttonsState = buttonsState == 1 ? 0 : 0;
                    xPosition += tapInfo.delta.dx;
                    yPosition += tapInfo.delta.dy;
                  });
                },
                child: SizedBox(
                  width: 100,
                  height: 150,
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(boxShadow: [
                      BoxShadow(color: Colors.black, blurRadius: 2)
                    ], borderRadius: BorderRadius.all(Radius.circular(10))),
                    child: RTCVideoView(
                      _localRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
              left: 10,
              right: 10,
              top: AppBar().preferredSize.height,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: inCall ? buttonsState.toDouble() : 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Card(
                        shape: const CircleBorder(),
                        clipBehavior: Clip.hardEdge,
                        child: InkWell(
                            onTap: () {
                              setState(() {
                                currentCam = currentCam == 0 ? 1 : 0;
                              });
                              initRenderer();
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Icon(Icons.cameraswitch),
                            ))),
                    Card(
                        shape: const CircleBorder(),
                        clipBehavior: Clip.hardEdge,
                        child: InkWell(
                            onTap: () {},
                            child: const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Icon(Icons.flash_off),
                            ))),
                    Card(
                        shape: const CircleBorder(),
                        clipBehavior: Clip.hardEdge,
                        child: InkWell(
                            onTap: () {},
                            child: const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Icon(Icons.videocam),
                            ))),
                  ],
                ),
              )),
        ],
      ),
      floatingActionButton: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: inCall ? buttonsState.toDouble() : 1,
        child: Builder(builder: (context) {
          return FloatingActionButton(
            heroTag: "HERO_FAB",
            backgroundColor: inCall ? Colors.red : null,
            onPressed: inCall
                ? () {
                    setState(() {
                      inCall = false;
                    });
                  }
                : () {
                    showModalBottomSheet(
                        constraints: BoxConstraints(
                          maxHeight: size.height - statusBarHeight,
                        ),
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20))),
                        clipBehavior: Clip.hardEdge,
                        isScrollControlled: true,
                        context: context,
                        builder: (context) {
                          return const ExplorerScreen();
                        });
                  },
            child: inCall ? const Icon(Icons.call_end) : const Icon(Icons.call),
          );
        }),
      ),
    );
  }
}
