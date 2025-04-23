import 'package:flutter/material.dart';
import 'package:gariforuser/screens/forgot_password.dart';
import 'package:gariforuser/screens/login_screen.dart';
import 'package:gariforuser/screens/main_page.dart';
import 'package:gariforuser/screens/register_screen.dart';
import 'package:gariforuser/splashscreen/splash_screen.dart';
import 'package:device_preview/device_preview.dart';

void main() {
  runApp(DevicePreview(enabled: true, builder: (context) => MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(),
      routes: {
        '/mainpage': (context) => MainPage(),
        '/forgotpassword': (context) => ForgotPasswordScreen(),
        '/loginscreen': (context) => LoginScreen(),
        '/registerscreen': (context) => RegisterScreen(),
      },
    );
  }
}
