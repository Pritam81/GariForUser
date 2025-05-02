import 'package:flutter/cupertino.dart';
import 'package:gariforuser/model/direction.dart';

class AppInfo extends ChangeNotifier {
  Directions? userPickUpLocation, userDropOffLocation;
  int countTotalTrips = 0;


  void   updatePickUpLocationAddress(Directions pickUpLocation) {
    userPickUpLocation = pickUpLocation;
    notifyListeners();
  }
  void updateDropOffLocationAddress(Directions dropOffLocation) {
    userDropOffLocation = dropOffLocation;
    notifyListeners();
  }





}
