import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      loginstatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Image.asset(
              "assets/images/taxilogo.png",
              width: 180,
              height: 130,
            ),
          ),
          Text(
            'Gari For User',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 55, right: 55),
            child: Divider(
              color: Colors.black,
              height: 10,
              thickness: 01,
              indent: 20,
              endIndent: 20,
            ),
          ),
        ],
      ),
    );
  }

  void loginstatus() async {
    var prefs = await SharedPreferences.getInstance();
    var islogin = prefs.getBool('islogin');
    if (islogin != null && islogin == true) {
      Navigator.pushReplacementNamed(context, '/homescreen');
    } else {
      Navigator.pushReplacementNamed(context, '/mainscreen');
    }
  }
}
