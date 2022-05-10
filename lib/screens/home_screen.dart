import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sharebits/utils/notification_api.dart';
import 'package:sharebits/utils/socket_connection.dart';
import 'package:sharebits/webrtc/rtc_connection.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

String phone = FirebaseAuth.instance.currentUser!.phoneNumber!.substring(3);

Future<void> saveTokenToDatabase(String token) async {
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

  bool initialState = true;
  bool isDragging = false;
  bool inCall = false;
  bool isCalling = false;

  late IO.Socket socket;

  final List<MediaDeviceInfo> _videoDevices = [];
  final List<MediaDeviceInfo> _audioInDevices = [];
  final List<MediaDeviceInfo> _audioOutDevices = [];
  MediaStream? _localStream;

  int currentCam = 0;

  int buttonsState = 0;
  double xPosition = 0;
  double yPosition = 0;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  late BitsConnection bitsConnection;
  late RTCSessionDescription localOffer;

  final String socketServer = "https://sharebits.herokuapp.com";

  @override
  void initState() {
    super.initState();
    setupToken();
    BitsSignalling().setSocket(IO.io(
        // "http://10.0.2.2:3000",
        socketServer,
        IO.OptionBuilder().setTransports(['websocket']).setExtraHeaders({
          "type": 1,
          "phone": FirebaseAuth.instance.currentUser!.phoneNumber!.substring(3)
        }).build()));
    socket = BitsSignalling().getSocket();
    socket.onConnect((_) => {log("Socket Connected")});
    socket.on("call", (data) {
      if (data != null) {
        var callRequestInfo = jsonDecode(data);
        NotificationAPI.showNotification(
            title: "Incoming Video Call",
            body: callRequestInfo["from"],
            payload: data);
      } else {
        log("RECEIVED A NULL CALL");
      }
    });
    socket.on("cancelCall", (data) => {NotificationAPI.hideNotification()});
    socket.on("callDeclined", (_) {
      setState(() {
        isCalling = false;
      });
    });
    socket.on("callAccepted", (data) async {
      var info = jsonDecode(data);
      var remoteOffer =
          RTCSessionDescription(info["offer"]["sdp"], info["offer"]["type"]);

      bitsConnection.callerPeerConnection.onIceCandidate = (ice) {
        var data = {"to": info["from"], "ice": ice.toMap(), "role": "caller"};
        socket.emit("iceCandidate", jsonEncode(data));
      };

      await bitsConnection.callerPeerConnection.setLocalDescription(localOffer);
      await bitsConnection.callerPeerConnection
          .setRemoteDescription(remoteOffer);
    });

    socket.on("iceCandidate", (data) {
      log("ICE RECEIVED");
      var info = jsonDecode(data);
      var ice = RTCIceCandidate(info["ice"]["candidate"], info["ice"]["sdpMid"],
          info["ice"]["sdpMLineIndex"]);
      if (info["role"] == "caller") {
        log("ADDED TO CALLE");
        bitsConnection.calleePeerConnection.addCandidate(ice);
      } else {
        log("ADDED TO CALLER");
        bitsConnection.callerPeerConnection.addCandidate(ice);
      }
    });

    initPeer();
  }

  void initPeer() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    try {
      var mediaConstraints = <String, dynamic>{
        'audio': true,
        'video': {
          'facingMode': 'user',
          'optional': [],
        }
      };
      var stream = await _getStream(mediaConstraints);

      var devices = await navigator.mediaDevices.enumerateDevices();
      for (var element in devices) {
        if (element.kind != null) {
          log(element.kind!);
          switch (element.kind) {
            case "videoinput":
              _videoDevices.add(element);
              break;
            case "audioinput":
              _audioInDevices.add(element);
              break;
            case "audiooutput":
              _audioOutDevices.add(element);
              break;
          }
        }
      }
      _localStream = stream;
      _localRenderer.srcObject = _localStream;
      bitsConnection = BitsConnection();
      await bitsConnection.initConnection(_localStream!);

      bitsConnection.callerPeerConnection.onTrack = (event) {
        _remoteRenderer.srcObject = event.streams[0];
      };

      bitsConnection.calleePeerConnection.onTrack = (event) {
        _remoteRenderer.srcObject = event.streams[0];
      };

      bitsConnection.callerPeerConnection.onConnectionState = (event) {
        switch (event) {
          case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
            setState(() {
              isCalling = false;
              inCall = false;
            });
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
            setState(() {
              isCalling = false;
              inCall = false;
            });
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateNew:
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            setState(() {
              isCalling = false;
              inCall = true;
            });
            break;
        }
      };

      bitsConnection.calleePeerConnection.onConnectionState = (event) {
        switch (event) {
          case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
            setState(() {
              isCalling = false;
              inCall = false;
            });
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
            setState(() {
              isCalling = false;
              inCall = false;
            });
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateNew:
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            setState(() {
              isCalling = false;
              inCall = true;
            });
            break;
        }
      };

      setState(() {});
    } catch (e) {
      log("ERROR >>>>> ${e.toString()}");
    }
  }

  Future<MediaStream> _getStream(Map<String, dynamic> mediaConstraints) async {
    return await navigator.mediaDevices.getUserMedia(mediaConstraints);
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
              inCall ? _remoteRenderer : _localRenderer,
              mirror: inCall
                  ? false
                  : currentCam == 1
                      ? false
                      : true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          )),
          Visibility(
            visible: isCalling,
            child: Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Center(
                    child: Text(
                  "Calling",
                  style: TextStyle(shadows: const [
                    Shadow(
                      color: Colors.white,
                      blurRadius: 10,
                    )
                  ], fontSize: 100.sp),
                ))),
          ),
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
                      mirror: currentCam == 0 ? true : false,
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
                opacity: 1, //inCall ? buttonsState.toDouble() : 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Card(
                        shape: const CircleBorder(),
                        clipBehavior: Clip.hardEdge,
                        child: InkWell(
                            onTap: () async {
                              _localStream?.getTracks().forEach((track) async {
                                await track.stop();
                              });
                              currentCam = currentCam == 0 ? 1 : 0;
                              var mediaConstraints = <String, dynamic>{
                                'audio': true,
                                'video': {
                                  'facingMode':
                                      currentCam == 0 ? 'user' : 'environment',
                                  'optional': [],
                                }
                              };

                              _localStream = await _getStream(mediaConstraints);

                              setState(() {
                                _localRenderer.srcObject = _localStream;
                              });

                              await bitsConnection.changeTracks(_localStream!);
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
                            onTap: () async {
                              await bitsConnection.hideVideo(_localStream!);
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Icon(Icons.videocam),
                            ))),
                    Card(
                        shape: const CircleBorder(),
                        clipBehavior: Clip.hardEdge,
                        color: Colors.deepPurple,
                        child: InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return ListView.builder(
                                        itemCount: _audioOutDevices.length,
                                        itemBuilder: (context, index) {
                                          var device = _audioOutDevices[index];
                                          return ListTile(
                                            leading:
                                                const Icon(Icons.volume_up),
                                            title: Text(device.label),
                                          );
                                        });
                                  });
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Icon(
                                Icons.volume_up,
                                color: Colors.white,
                              ),
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
            backgroundColor: inCall || isCalling ? Colors.red : null,
            onPressed: inCall || isCalling
                ? () async {
                    await bitsConnection.calleePeerConnection.close();
                    await bitsConnection.callerPeerConnection.close();
                    setState(() {
                      inCall = false;
                      isCalling = false;
                    });
                    initPeer();
                  }
                : () {
                    requestCall();
                    // showModalBottomSheet(
                    //     constraints: BoxConstraints(
                    //       maxHeight: size.height - statusBarHeight,
                    //     ),
                    //     shape: const RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.vertical(
                    //             top: Radius.circular(20))),
                    //     clipBehavior: Clip.hardEdge,
                    //     isScrollControlled: true,
                    //     context: context,
                    //     builder: (context) {
                    //       return const ExplorerScreen();
                    //     });
                  },
            child: inCall || isCalling
                ? const Icon(Icons.call_end)
                : const Icon(Icons.call),
          );
        }),
      ),
    );
  }

  void requestCall() async {
    localOffer = await bitsConnection.callerPeerConnection.createOffer();
    var callRequestInfo;
    if (phone == "7016783094") {
      callRequestInfo = {"to": "9998082351", "offer": localOffer.toMap()};
    } else {
      callRequestInfo = {"to": "7016783094", "offer": localOffer.toMap()};
    }

    socket.emitWithAck("call", jsonEncode(callRequestInfo), ack: (ack) {
      log(ack.toString());
      setState(() {
        isCalling = true;
      });
    });
  }
}
