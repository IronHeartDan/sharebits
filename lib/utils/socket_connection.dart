import 'dart:developer';

import 'package:socket_io_client/socket_io_client.dart';

class BitsSignalling {
  static final BitsSignalling _bitsSignalling = BitsSignalling._internal();

  late Socket socket;

  Socket getSocket() => socket;

  void setSocket(Socket socket) => this.socket = socket;


  factory BitsSignalling() {
    return _bitsSignalling;
  }

  BitsSignalling._internal(){
    log("INIT");
  }
}
