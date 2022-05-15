import 'package:flutter/cupertino.dart';

class CallState extends ChangeNotifier {
  // 0 For ideal
  // 1 For calling
  // 2 For in call
  int callState = 0;

  void changeCallState(int state) {
    callState = state;
    notifyListeners();
  }
}
