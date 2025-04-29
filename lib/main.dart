import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gariforuser/infoHandler/app_info.dart';
import 'package:gariforuser/screens/Home/homescreen.dart';
import 'package:gariforuser/screens/Home/precisepickuplocation.dart';
import 'package:gariforuser/screens/Home/searchplaces.dart';
import 'package:gariforuser/screens/forgot_password.dart';
import 'package:gariforuser/screens/login_screen.dart';
import 'package:gariforuser/screens/main_page.dart';
import 'package:gariforuser/screens/register_screen.dart';
import 'package:gariforuser/splashscreen/splash_screen.dart';
import 'package:device_preview/device_preview.dart';
import 'package:provider/provider.dart';

void main() async {
   WidgetsFlutterBinding.ensureInitialized();
  print("Firebase initializing...");
  await Firebase.initializeApp();
  print("Firebase initialized successfully.");
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppInfo(),
      child: MaterialApp(
        useInheritedMediaQuery: true,
        debugShowCheckedModeBanner: false,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        title: 'Flutter Demo',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const SplashScreen(),
        routes: {
          '/searchplaces': (context) => const SearchPlacesScreen(),
          '/mainscreen': (context) => const MainPage(),
          '/forgotpassword': (context) => const ForgotPasswordScreen(),
          '/loginscreen': (context) => const LoginScreen(),
          '/registerscreen': (context) => const RegisterScreen(),
          '/homescreen': (context) => const HomeScreen(),
          '/precisepickuplocation': (context) => const PrecisePickUpScreen(),
        },
      ),
    );
  }
}
