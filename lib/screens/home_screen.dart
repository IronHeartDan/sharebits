import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sharebits/screens/explore_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool initialState = true;
  bool inCall = false;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  List<MediaDeviceInfo>? _mediaDevicesList;
  MediaStream? _localStream;

  int currentCam = 0;

  int buttonsState = 1;
  double xPosition = 0;
  double yPosition = 0;

  @override
  void initState() {
    super.initState();
    // initRenderer();
  }

  void initRenderer() async {
    await _localRenderer.initialize();
    try {
      var mediaConstraints = <String, dynamic>{
        'audio': false,
        'video': {
          'facingMode': currentCam == 0 ? 'environment' : 'user',
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

  Future<void> hideInTime() async {
    await Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        buttonsState = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var statusBarHeight = MediaQuery.of(context).padding.top;
    if (initialState) {
      setState(() {
        xPosition = 10;
        yPosition = size.height - 160;
        initialState = false;
      });
    }
    if (buttonsState == 1) {
      hideInTime();
    }
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
              child: GestureDetector(
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
              duration: const Duration(milliseconds: 100),
              top: yPosition,
              left: xPosition,
              child: GestureDetector(
                onPanEnd: (info) {
                  setState(() {
                    xPosition =
                        xPosition > (size.width / 2) ? size.width - 110 : 10;
                    yPosition = yPosition > (size.height / 2)
                        ? size.height - 160
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
                ? null
                : () {
                    Scaffold.of(context).showBottomSheet(
                      (context) {
                        return const ExplorerScreen();
                      },
                      clipBehavior: Clip.hardEdge,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20))),
                    );
                  },
            child: inCall ? const Icon(Icons.call_end) : const Icon(Icons.call),
          );
        }),
      ),
    );
  }
}
