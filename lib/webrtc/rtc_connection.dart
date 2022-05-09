import 'package:flutter_webrtc/flutter_webrtc.dart';

class BitsConnection {
  final configuration = {
    "iceServers": [
      {
        "urls": "stun:openrelay.metered.ca:80",
      },
      {
        "urls": "turn:openrelay.metered.ca:80",
        "username": "openrelayproject",
        "credential": "openrelayproject",
      },
      {
        "urls": "turn:openrelay.metered.ca:443",
        "username": "openrelayproject",
        "credential": "openrelayproject",
      },
      {
        "urls": "turn:openrelay.metered.ca:443?transport=tcp",
        "username": "openrelayproject",
        "credential": "openrelayproject",
      },
    ],
  };

  final config = {
    "iceServers": [
      {"urls": "stun:stun.l.google.com:19302"},
      {
        "urls": "turn:numb.viagenie.ca",
        "username": "webrtc@live.com",
        "credential": "muazkh",
      },
    ],
  };

  late RTCPeerConnection callerPeerConnection;
  late RTCPeerConnection calleePeerConnection;

  static final BitsConnection _bitsConnection = BitsConnection.internal();

  factory BitsConnection() {
    return _bitsConnection;
  }

  BitsConnection.internal();

  Future initConnection(MediaStream localStream) async {
    callerPeerConnection = await createPeerConnection(configuration);
    calleePeerConnection = await createPeerConnection(configuration);
    await callerPeerConnection.addStream(localStream);
    await calleePeerConnection.addStream(localStream);
  }

  Future addStream(MediaStream localStream) async {
    await callerPeerConnection.addStream(localStream);
    await calleePeerConnection.addStream(localStream);
  }

  Future removeStream(MediaStream localStream) async {
    await callerPeerConnection.removeStream(localStream);
    await calleePeerConnection.removeStream(localStream);
  }

  Future changeTracks(MediaStream stream) async {
    if (callerPeerConnection.connectionState ==
        RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
      var callerSenders = await callerPeerConnection.getSenders();
      for (var sender in callerSenders) {
        var track = stream
            .getTracks()
            .where((track) => sender.track?.kind == track.kind);
        sender.replaceTrack(track.first);
      }
    } else {
      var calleeSenders = await calleePeerConnection.getSenders();
      for (var sender in calleeSenders) {
        var track = stream
            .getTracks()
            .where((track) => sender.track?.kind == track.kind);
        sender.replaceTrack(track.first);
      }
    }
  }
}
