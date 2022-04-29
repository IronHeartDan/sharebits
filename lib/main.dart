import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sharebits/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    return MaterialApp(
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
      home: FutureBuilder(
        future: _checkPermission(),
        builder: (context, data) {
          if (data.hasError) {
            return Center(
              child: Text("An Error Occurred ${data.error.toString()}"),
            );
          }

          if (data.connectionState == ConnectionState.done) {
            if (data.hasData) {
              var status = data.data;
              if (status == true) {
                return const HomeScreen();
              } else {
                return const Center(
                  child: Text("Camera Permission Denied!"),
                );
              }
            } else {
              return const Center(
                child: Text("An Error Occurred"),
              );
            }
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
