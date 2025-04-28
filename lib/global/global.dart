import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth firebaseauth = FirebaseAuth.instance;
User? currentuser;
var isLoggedin = false;
String userDropOffAddress = "";

