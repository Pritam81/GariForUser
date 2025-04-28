import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:gariforuser/model/usermodel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class DrawerScreen extends StatefulWidget {
  const DrawerScreen({super.key});

  @override
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  Usermodel? userModel;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  // Function to Share App
  void shareApp() {
    Share.share(
      'Check out this amazing app: Gari ! Download now: google.com/store/apps/details?id=com.example.yourapp',
      subject: 'Amazing App!',
    );
  }

  // Function to Rate App
  void rateApp() async {
    const url = 'https://play.google.com'; // Change package ID
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> fetchUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      DatabaseReference userRef = FirebaseDatabase.instance
          .ref()
          .child("users")
          .child(currentUser.uid);

      userRef.once().then((DatabaseEvent event) {
        DataSnapshot snapshot = event.snapshot;

        if (snapshot.exists) {
          setState(() {
            userModel = Usermodel.fromSnapshot(snapshot);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.green.shade700),
            accountName: Text(
              userModel?.name ?? "Loading...",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              userModel?.email ?? "",
              style: TextStyle(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: Colors.green.shade700),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: Colors.green),
            title: Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.share, color: Colors.green),
            title: Text('Share App'),
            onTap: () {
              shareApp(); // Call the share function
              // Share functionality
            },
          ),
          ListTile(
            leading: Icon(Icons.star_rate, color: Colors.green),
            title: Text('Rate Our App'),
            onTap: () {
              rateApp(); // Call the rate function
              // Rate functionality
            },
          ),

          Divider(
            thickness: 1,
            color: Colors.grey[300],
            indent: 15,
            endIndent: 15,
          ),

          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Logout'),
            onTap: () {
              FirebaseAuth.instance.signOut();
              var prefs = SharedPreferences.getInstance();
              prefs.then((value) {
                value.setBool('islogin', false);
              });
              Navigator.pushReplacementNamed(context, '/mainscreen');
            },
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'App Version 1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
