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

  late RTCPeerConnection peerConnection;

  static final BitsConnection _bitsConnection = BitsConnection.internal();

  factory BitsConnection() {
    return _bitsConnection;
  }

  BitsConnection.internal();

  Future initConnection(MediaStream localStream) async {
    peerConnection = await createPeerConnection(configuration);
    await peerConnection.addStream(localStream);
  }

  Future addStream(MediaStream localStream) async {
    await peerConnection.addStream(localStream);
  }

  Future removeStream(MediaStream localStream) async {
    await peerConnection.removeStream(localStream);
  }

  Future changeTracks(MediaStream stream) async {
      var calleeSenders = await peerConnection.getSenders();
      for (var sender in calleeSenders) {
        var track = stream
            .getTracks()
            .where((track) => sender.track?.kind == track.kind);
        if(track.isNotEmpty){
          sender.replaceTrack(track.first);
        }
      }
  }

  Future toggleVideo(MediaStream stream) async {
    stream.getVideoTracks().forEach((track) {
      track.enabled = !track.enabled;
    });
  }

  Future toggleAudio(MediaStream stream) async {
    stream.getAudioTracks().forEach((track) {
      track.enabled = !track.enabled;
    });
  }
}
