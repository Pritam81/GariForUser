import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth firebaseauth = FirebaseAuth.instance;
User? currentuser;
var isLoggedin = false;
String userDropOffAddress = "";
String driverCarDetails = "";
String driverName = "";
double counrtRatingStars = 0.0;
String titleStarsRating = "";
List driversList=[];
String cloudMessaginServerToken = "";



