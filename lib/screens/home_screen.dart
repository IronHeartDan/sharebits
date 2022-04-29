import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool initialState = true;
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
    initRenderer();
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

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    if (initialState) {
      setState(() {
        xPosition = 10;
        yPosition = size.height - 160;
        initialState = false;
      });
    }
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
              child: InkWell(
            onTap: () {
              setState(() {
                buttonsState = buttonsState == 0 ? 1 : 0;
              });
            },
            child: RTCVideoView(
              _localRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          )),
          Positioned(
              left: 10,
              right: 10,
              top: AppBar().preferredSize.height,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: buttonsState.toDouble(),
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
          AnimatedPositioned(
            duration: const Duration(milliseconds: 50),
            top: yPosition,
            left: xPosition,
            child: GestureDetector(
              onPanUpdate: (tapInfo) {
                setState(() {
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
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: buttonsState.toDouble(),
        child: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.call),
        ),
      ),
    );
  }
}
