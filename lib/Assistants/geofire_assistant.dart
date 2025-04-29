import 'package:gariforuser/screens/Home/acrive_nearby_available_drivers.dart';

class GeoFireAssistant{
     static List<ActiveNearByAvailableDrivers> activeNearByAvailableDriversList = [];
      static void deleteOfflineDriverFromList(String driverId){
        int indexNumber= activeNearByAvailableDriversList.indexWhere((element) => element.driverId == driverId);  
        activeNearByAvailableDriversList.removeAt(indexNumber);

      }
      static void updateActiveNearByAvailableDriversLocation(ActiveNearByAvailableDrivers driverWhoMove){
        int indexNumber= activeNearByAvailableDriversList.indexWhere((element) => element.driverId == driverWhoMove.driverId);  
        activeNearByAvailableDriversList[indexNumber].latitude = driverWhoMove.latitude;
        activeNearByAvailableDriversList[indexNumber].longitude = driverWhoMove.longitude;

      }
}