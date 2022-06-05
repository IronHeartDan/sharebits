import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sharebits/states/call_state.dart';
import 'package:sharebits/utils/notification_api.dart';
import 'package:sharebits/utils/socket_connection.dart';
import 'package:sharebits/webrtc/rtc_connection.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../utils/constants.dart';
import 'explore_screen.dart';

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
  late int callState;

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

  @override
  void initState() {
    super.initState();
    setupToken();
    BitsSignalling().setSocket(IO.io(
        // "http://10.0.2.2:3000",
        bitsServer,
        IO.OptionBuilder().setTransports(['websocket']).setExtraHeaders({
          "type": 1,
          "phone": FirebaseAuth.instance.currentUser!.phoneNumber!.substring(3)
        }).build()));
    socket = BitsSignalling().getSocket();
    socket.onConnect((_) => {log("Socket Connected")});
    socket.on("call", (data) async {
      if (data != null) {
        var callRequestInfo = jsonDecode(data);
        var params = <String, dynamic>{
          'id': callRequestInfo["from"],
          'nameCaller': "Incoming Video Call ${callRequestInfo['from']}",
          'appName': 'Sharebits',
          'avatar': 'https://i.pravatar.cc/100',
          'handle': callRequestInfo["from"],
          'type': 1,
          'textAccept': 'Accept',
          'textDecline': 'Decline',
          'textMissedCall': 'Missed call',
          'textCallback': 'Call back',
          'duration': 30000,
          'extra': callRequestInfo,
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
        FlutterCallkitIncoming.onEvent.listen((event) async {
          switch (event!.name) {
            case CallEvent.ACTION_CALL_ACCEPT:
              socket.emit("callAccepted", callRequestInfo["from"]);
              break;
            case CallEvent.ACTION_CALL_DECLINE:
              socket.emit("callDeclined", callRequestInfo["from"]);
              break;
          }
        });

        await FlutterCallkitIncoming.showCallkitIncoming(params);
      } else {
        log("RECEIVED A NULL CALL");
      }
    });
    socket.on("cancelCall", (data) => {NotificationAPI.hideNotification()});
    socket.on("callDeclined", (_) {
      context.read<BitsCallState>().changeCallState(0);
    });
    socket.on("callAccepted", (_) async {
      await bitsConnection.createOffer();
      var localOffer = bitsConnection.localOffer;
      var callOffer = {
        "to": bitsConnection.connectedPeer,
        "offer": localOffer.toMap()
      };

      socket.emit("callOffer", jsonEncode(callOffer));
    });

    socket.on("callOffer", (data) async {
      var info = jsonDecode(data);
      var offer =
          RTCSessionDescription(info["offer"]["sdp"], info["offer"]["type"]);

      bitsConnection.connectedPeer = info["from"];
      await bitsConnection.peerConnection.setRemoteDescription(offer);
      var remoteOffer = await bitsConnection.peerConnection.createAnswer();
      var answer = {"to": info["from"], "offer": remoteOffer.toMap()};
      socket.emit("answerOffer", jsonEncode(answer));
      bitsConnection.peerConnection.onIceCandidate = (ice) {
        var data = {"to": info["from"], "ice": ice.toMap()};
        socket.emit("iceCandidate", jsonEncode(data));
      };
      bitsConnection.peerConnection.setLocalDescription(remoteOffer);
    });

    socket.on("answerOffer", (data) async {
      var info = jsonDecode(data);
      var remoteOffer =
          RTCSessionDescription(info["offer"]["sdp"], info["offer"]["type"]);

      bitsConnection.peerConnection.onIceCandidate = (ice) {
        var data = {"to": info["from"], "ice": ice.toMap()};
        socket.emit("iceCandidate", jsonEncode(data));
      };

      await bitsConnection.peerConnection
          .setLocalDescription(bitsConnection.localOffer);
      await bitsConnection.peerConnection.setRemoteDescription(remoteOffer);
    });

    socket.on("iceCandidate", (data) {
      var info = jsonDecode(data);
      var ice = RTCIceCandidate(info["ice"]["candidate"], info["ice"]["sdpMid"],
          info["ice"]["sdpMLineIndex"]);
      bitsConnection.peerConnection.addCandidate(ice);
    });

    initPeer();
    getCurrentCall();
  }

  getCurrentCall() async {
    //check current call from pushkit if possible
    var calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is List) {
      if (calls.isNotEmpty) {
        print('DATA: ${calls[0]["id"]}');
        var from = calls[0]["id"];
        socket.emit("callAccepted", from);
      }
    }
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
      await bitsConnection.initConnection(stream);

      bitsConnection.peerConnection.onTrack = (event) {
        _remoteRenderer.srcObject = event.streams[0];
      };

      bitsConnection.peerConnection.onConnectionState = (event) async {
        switch (event) {
          case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
            bitsConnection.connectedPeer = null;
            context.read<BitsCallState>().changeCallState(0);
            await FlutterCallkitIncoming.endAllCalls();
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
            bitsConnection.connectedPeer = null;
            context.read<BitsCallState>().changeCallState(0);
            await FlutterCallkitIncoming.endAllCalls();
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateNew:
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            context.read<BitsCallState>().changeCallState(2);
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

  Future<bool> _checkContactsPermission() async {
    var check = await Permission.contacts.status;
    if (check.isGranted) {
      return true;
    }

    if (check.isPermanentlyDenied) {
      return false;
    }

    check = await Permission.contacts.request();
    return check.isGranted;
  }

  @override
  Widget build(BuildContext context) {
    callState = context.watch<BitsCallState>().callState;
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
            onTap: callState == 2
                ? () {
                    setState(() {
                      buttonsState = buttonsState == 0 ? 1 : 0;
                    });
                  }
                : null,
            child: RTCVideoView(
              callState == 2 ? _remoteRenderer : _localRenderer,
              mirror: callState == 2
                  ? false
                  : currentCam == 1
                      ? false
                      : true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          )),
          Visibility(
            visible: callState == 1,
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
                      blurRadius: 5,
                    )
                  ], fontSize: 100.sp),
                ))),
          ),
          Visibility(
            visible: callState == 2,
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
                opacity: callState == 1 || callState == 2
                    ? buttonsState.toDouble()
                    : 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Card(
                        shape: const CircleBorder(),
                        clipBehavior: Clip.hardEdge,
                        child: InkWell(
                            onTap: () async {
                              _localStream!
                                  .getVideoTracks()
                                  .forEach((track) async {
                                await track.stop();
                              });
                              currentCam = currentCam == 0 ? 1 : 0;
                              var mediaConstraints = <String, dynamic>{
                                'video': {
                                  'facingMode':
                                      currentCam == 0 ? 'user' : 'environment',
                                  'optional': [],
                                }
                              };

                              var stream = await _getStream(mediaConstraints);
                              await bitsConnection.changeVideoTracks(stream);

                              await stream
                                  .addTrack(_localStream!.getAudioTracks()[0]);

                              _localStream = stream;
                              _localRenderer.srcObject = _localStream;

                              setState(() {});
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Icon(Icons.cameraswitch),
                            ))),
                    Card(
                        shape: const CircleBorder(),
                        clipBehavior: Clip.hardEdge,
                        color: _localStream != null &&
                                _localStream!.getAudioTracks()[0].enabled
                            ? Colors.deepPurple
                            : Colors.white,
                        child: InkWell(
                            onTap: () async {
                              await bitsConnection.toggleAudio(_localStream!);
                              setState(() {});
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: _localStream != null &&
                                      _localStream!.getAudioTracks()[0].enabled
                                  ? const Icon(
                                      Icons.mic,
                                      color: Colors.white,
                                    )
                                  : const Icon(Icons.mic_off),
                            ))),
                    Card(
                        shape: const CircleBorder(),
                        clipBehavior: Clip.hardEdge,
                        color: _localStream != null &&
                                _localStream!.getVideoTracks()[0].enabled
                            ? Colors.deepPurple
                            : Colors.white,
                        child: InkWell(
                            onTap: () async {
                              await bitsConnection.toggleVideo(_localStream!);
                              setState(() {});
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: _localStream != null &&
                                      _localStream!.getVideoTracks()[0].enabled
                                  ? const Icon(
                                      Icons.videocam,
                                      color: Colors.white,
                                    )
                                  : const Icon(Icons.videocam_off),
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
        scale: callState == 2 ? buttonsState.toDouble() : 1,
        child: Builder(builder: (context) {
          return FloatingActionButton(
            heroTag: "HERO_FAB",
            backgroundColor:
                callState == 1 || callState == 2 ? Colors.red : null,
            onPressed: callState == 1 || callState == 2
                ? () async {
                    if (callState == 1) {
                      // end call
                      socket.emit("cancelCall", bitsConnection.connectedPeer);
                      context.read<BitsCallState>().changeCallState(0);
                    } else if (callState == 2) {
                      bitsConnection.connectedPeer = null;
                      await bitsConnection.peerConnection.close();
                      await FlutterCallkitIncoming.endAllCalls();
                      initPeer();
                    }
                  }
                : () async {
                    if (!(await _checkContactsPermission())) {
                      return;
                    } else {
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
                    }
                  },
            child: callState == 1 || callState == 2
                ? const Icon(Icons.call_end)
                : const Icon(Icons.call),
          );
        }),
      ),
    );
  }
}
