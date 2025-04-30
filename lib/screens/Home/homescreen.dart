import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gariforuser/Assistants/assistants_methods.dart';
import 'package:gariforuser/Assistants/geofire_assistant.dart';
import 'package:gariforuser/global/global.dart';
import 'package:gariforuser/global/map_key.dart';
import 'package:gariforuser/infoHandler/app_info.dart';
import 'package:gariforuser/model/direction.dart';
import 'package:gariforuser/model/usermodel.dart';
import 'package:gariforuser/screens/Fare/payfareamount.dart';
import 'package:gariforuser/screens/Home/acrive_nearby_available_drivers.dart';
import 'package:gariforuser/screens/drawer/drawerscreen.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:async';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? pickupLocation;
  loc.Location? currentLocation;
  String? _address;
  double suggestedRideContainerHeight = 0.0;
  // 60 to 600 inclusive

  final Completer<GoogleMapController> _controllerGoogleMap =
      Completer<GoogleMapController>();

  GoogleMapController? newGoogleMapController;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  double searchLocationContainerHeight = 220.0;
  double waitingResponsefromDriverContainerHeight = 0.0;
  double assignedDriverInfoContainerHeight = 0.0;

  Position? userCurrentPosition;
  var geolocator = Geolocator();
  LocationPermission? _locationPermission;
  double bottomPaddingOfMap = 0.0;

  List<LatLng> pLineCoordinatesList = [];
  Set<Polyline> polylineSet = {};
  Set<Marker> markersSet = {};
  Set<Circle> circleSet = {};
  String userName = "";
  String userEmail = "";
  bool openNavigation = true;
  bool openNavigationDrawer = false;
  bool activeNearbyDriverkeysLoaded = false;
  BitmapDescriptor? activeNearbyIcon;

  locateuserPosition() async {
    Position cPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    userCurrentPosition = cPosition;
    LatLng latLngPosition = LatLng(
      userCurrentPosition!.latitude,
      userCurrentPosition!.longitude,
    );
    CameraPosition cameraPosition = CameraPosition(
      target: latLngPosition,
      zoom: 15,
    );
    newGoogleMapController!.animateCamera(
      CameraUpdate.newCameraPosition(cameraPosition),
    );

    String humanReadableAddress =
        await AssistantsMethods.searchAddressForGeographicCoordinates(
          userCurrentPosition!,
          context,
        );
    print("This is your address: " + humanReadableAddress);

    Usermodel userModelInstance =
        Usermodel(); // Create an instance of Usermodel
    userName = userModelInstance.name!;
    userEmail = userModelInstance.email!;

    initializeGeoFireListener(); // Access the name property through the instance
  }

  void showSuggestedRideContainer() {
    setState(() {
      suggestedRideContainerHeight = 400.0;
      bottomPaddingOfMap = 400.0;
    });
  }

  initializeGeoFireListener() async {
    // Initialize GeoFire listener here
    // Example: await GeoFire.initializeGeoFireListener();
    Geofire.initialize("activeDrivers");
    Geofire.queryAtLocation(
      userCurrentPosition!.latitude,
      userCurrentPosition!.longitude,
      10.0, // radius in km
    )?.listen((map) {
      if (map != null) {
        var callBack = map["callBack"];
        switch (callBack) {
          case Geofire.onKeyEntered:
            ActiveNearByAvailableDrivers activeNearByAvailableDrivers =
                ActiveNearByAvailableDrivers();
            activeNearByAvailableDrivers.driverId = map["key"];
            activeNearByAvailableDrivers.latitude = map["latitude"];

            activeNearByAvailableDrivers.longitude = map["longitude"];
            GeoFireAssistant.activeNearByAvailableDriversList.add(
              activeNearByAvailableDrivers,
            );
            if (activeNearbyDriverkeysLoaded == true) {
              displayActiveDriversOnUsersMap();
            }

            break;
          case Geofire.onKeyExited:
            GeoFireAssistant.deleteOfflineDriverFromList(map["key"]);
            displayActiveDriversOnUsersMap();

            break;
          case Geofire.onKeyMoved:
            ActiveNearByAvailableDrivers activeNearByAvailableDrivers =
                ActiveNearByAvailableDrivers();
            activeNearByAvailableDrivers.driverId = map["key"];
            activeNearByAvailableDrivers.latitude = map["latitude"];
            activeNearByAvailableDrivers.longitude = map["longitude"];
            GeoFireAssistant.updateActiveNearByAvailableDriversLocation(
              activeNearByAvailableDrivers,
            );

            break;
          case Geofire.onGeoQueryReady:
            activeNearbyDriverkeysLoaded = true;
            displayActiveDriversOnUsersMap();
            break;
        }
      }
      setState(() {});
    });
  }

  displayActiveDriversOnUsersMap() {
    setState(() {
      markersSet.clear();
      circleSet.clear();

      Set<Marker> driverMarkersSet = Set<Marker>();

      for (ActiveNearByAvailableDrivers eachDriver
          in GeoFireAssistant.activeNearByAvailableDriversList) {
        LatLng driverActivePosition = LatLng(
          eachDriver.latitude!,
          eachDriver.longitude!,
        );
        Marker marker = Marker(
          markerId: MarkerId("driver${eachDriver.driverId}"),
          position: driverActivePosition,
          icon: activeNearbyIcon!,
          rotation: 360,
          infoWindow: InfoWindow(
            title: eachDriver.driverId,
            snippet: "Driver is Here",
          ),
        );
        driverMarkersSet.add(marker);
      }
      setState(() {
        markersSet = driverMarkersSet;
      });
    });
  }

  createActiveNearByDriverMarker() {
    if (activeNearbyIcon == null) {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(
        context,
        size: Size(0.2, 0.2),
      );
      BitmapDescriptor.fromAssetImage(
        imageConfiguration,
        "assets/images/car_topview.png",
      ).then((value) {
        activeNearbyIcon = value;
      });
    }
  }

  // initializeGeoFireListener() async {
  //   // Initialize GeoFire listener here
  // }
  // AssistantsMethods.readTripKeyForCurrentUser(context);

  getAddressFromLatLng() async {
    try {
      GeoData data = await Geocoder2.getDataFromCoordinates(
        latitude: pickupLocation!.latitude,
        longitude: pickupLocation!.longitude,
        googleMapApiKey: mapKey,
      );
      setState(() {
        Directions userPickUpAddress = Directions();
        userPickUpAddress.locationLatitude = pickupLocation?.latitude;
        userPickUpAddress.locationLongitude = pickupLocation?.longitude;

        userPickUpAddress.locationName = data.address;
        Provider.of<AppInfo>(
          context,
          listen: false,
        ).updatePickUpLocationAddress(userPickUpAddress);
      });
    } catch (e) {
      print(e);
    }
  }

  checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();
    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  Future<void> drawPolyLineFromOriginToDestination() async {
    var origin = LatLng(
      userCurrentPosition!.latitude,
      userCurrentPosition!.longitude,
    );
    var destination = LatLng(
      Provider.of<AppInfo>(
        context,
        listen: false,
      ).userDropOffLocation!.locationLatitude!,
      Provider.of<AppInfo>(
        context,
        listen: false,
      ).userDropOffLocation!.locationLongitude!,
    );

    // Get Route Points
    var result = await PolylinePoints().getRouteBetweenCoordinates(
      mapKey,
      PointLatLng(origin.latitude, origin.longitude),
      PointLatLng(destination.latitude, destination.longitude),
    );

    if (result.points.isNotEmpty) {
      pLineCoordinatesList.clear();
      for (var point in result.points) {
        pLineCoordinatesList.add(LatLng(point.latitude, point.longitude));
      }
    }

    polylineSet.clear();
    setState(() {
      // Draw the polyline
      Polyline polyline = Polyline(
        color: Colors.blueAccent,
        polylineId: const PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoordinatesList,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );
      polylineSet.add(polyline);

      // Add a marker for the origin
      Marker originMarker = Marker(
        markerId: MarkerId("origin"),
        position: origin,
        infoWindow: InfoWindow(title: "Your Location"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );
      markersSet.add(originMarker);

      // Add a custom marker for the destination
      Marker destinationMarker = Marker(
        markerId: MarkerId("destination"),
        position: destination,
        infoWindow: InfoWindow(title: "Destination"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
      markersSet.add(destinationMarker);
    });
  }

  DatabaseReference? referenceRideRequest;
  String driverRideStatus = "Driver is Coming";
  StreamSubscription<DatabaseEvent>? tripRideRequestInfoStreamSubscription;
  String userRideRequesrtStatus = "";
  List<ActiveNearByAvailableDrivers> onlineNearbyAvailableDriversList = [];
  saveRideRequestInformation() {
    referenceRideRequest =
        FirebaseDatabase.instance.ref().child(" All Ride Requests").push();
    var originLocation =
        Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationLocation =
        Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    Map originLocationMap = {
      "latitude": originLocation!.locationLatitude.toString(),
      "longitude": originLocation.locationLongitude.toString(),
    };
    Map destinationLocationMap = {
      "latitude": destinationLocation!.locationLatitude.toString(),
      "longitude": destinationLocation.locationLongitude.toString(),
    };
    Map userInformationMap = {
      "origin": originLocationMap,
      "destination": destinationLocationMap,
      "time": DateTime.now().toString(),
      "userName": Usermodel().name,
      "userPhone": Usermodel().phone,
      "originAddress": originLocation.locationName,
      "destinationAddress": destinationLocation.locationName,
      "driverId": "waiting",
    };
    referenceRideRequest!.set(userInformationMap);
    tripRideRequestInfoStreamSubscription = referenceRideRequest!.onValue
        .listen((eventsnap) async {
          if (eventsnap.snapshot.value == null) {
            return;
          }
          if ((eventsnap.snapshot.value as Map)["car_details"] != null) {
            setState(() {
              driverCarDetails =
                  (eventsnap.snapshot.value as Map)["car_details"].toString();
            });
          }
          if ((eventsnap.snapshot.value as Map)["driverName"] != null) {
            setState(() {
              driverCarDetails =
                  (eventsnap.snapshot.value as Map)["driverName"].toString();
            });
          }
          if ((eventsnap.snapshot.value as Map)["driverPhone"] != null) {
            setState(() {
              driverCarDetails =
                  (eventsnap.snapshot.value as Map)["driverPhone"].toString();
            });
          }
          if ((eventsnap.snapshot.value as Map)["status"] != null) {
            setState(() {
              userRideRequesrtStatus =
                  (eventsnap.snapshot.value as Map)["status"].toString();
            });
          }
          if ((eventsnap.snapshot.value as Map)["driverLocation"] != null) {
            double driverCurrentPositionLat = double.parse(
              (eventsnap.snapshot.value as Map)["driverLocation"]["latitude"]
                  .toString(),
            );
            double driverCurrentPositionLng = double.parse(
              (eventsnap.snapshot.value as Map)["driverLocation"]["longitude"]
                  .toString(),
            );

            LatLng driverCurrentPositionLatLng = LatLng(
              driverCurrentPositionLat,
              driverCurrentPositionLng,
            );

            if (userRideRequesrtStatus == "accepted") {
              updateArrivalTimeToUserPickUpLocation(
                driverCurrentPositionLatLng,
              );
            }
            if (userRideRequesrtStatus == "arrived") {
              setState(() {
                driverRideStatus = "Driver has arrived";
              });
            }
            if (userRideRequesrtStatus == "ontrip") {
              updateReachingTimeToUserDropOffLocation(
                driverCurrentPositionLatLng,
              );
            }
            if (userRideRequesrtStatus == "ended") {
              if ((eventsnap.snapshot.value as Map)["FareAmount"] != null) {
                double fareAmount = double.parse(
                  (eventsnap.snapshot.value as Map)["FareAmount"].toString(),
                );

                var response = await showDialog(
                  context: context,
                  builder:
                      (BuildContext context) =>
                          PayFareAmountDialog(fareAmount: fareAmount),
                );

                if (response == "Cash Paid") {
                  if ((eventsnap.snapshot.value as Map)["driverId"] != null) {
                    String assignedDriverId =
                        (eventsnap.snapshot.value as Map)["driverId"]
                            .toString();
                    //navigate to rate screen
                    referenceRideRequest!.onDisconnect();
                    tripRideRequestInfoStreamSubscription!.cancel();
                  }
                }
              }
            }
          }
        });

    onlineNearbyAvailableDriversList =
        GeoFireAssistant.activeNearByAvailableDriversList;
    searchNearestOnlineDrivers();
  }

  bool requestPostionInfo = true;
  updateArrivalTimeToUserPickUpLocation(
    LatLng driverCurrentPositionLatLng,
  ) async {
    if (requestPostionInfo == true) {
      requestPostionInfo = false;
      LatLng userPickUpPosition = LatLng(
        userCurrentPosition!.latitude,
        userCurrentPosition!.longitude,
      );
      var directiondetailsinfo =
          await AssistantsMethods.obtainOriginToDestinationDirectionDetails(
            driverCurrentPositionLatLng,
            userPickUpPosition,
          );
      if (directiondetailsinfo == null) {
        return;
      }
      setState(() {
        driverRideStatus =
            "Driver is Coming" +
            " " +
            directiondetailsinfo.durationText.toString();
      });
      requestPostionInfo = true;
    }
  }

  updateReachingTimeToUserDropOffLocation(
    LatLng driverCurrentPositionLatLng,
  ) async {
    if (requestPostionInfo == true) {
      requestPostionInfo = false;
      var dropOffLocation =
          Provider.of<AppInfo>(context, listen: false).userDropOffLocation;
      LatLng userDestinationPosition = LatLng(
        dropOffLocation!.locationLatitude!,
        dropOffLocation.locationLongitude!,
      );
      var directiondetailsinfo =
          await AssistantsMethods.obtainOriginToDestinationDirectionDetails(
            driverCurrentPositionLatLng,
            userDestinationPosition,
          );
      if (directiondetailsinfo == null) {
        return;
      }
      setState(() {
        driverRideStatus =
            "Going Towards Destination" +
            " " +
            directiondetailsinfo.durationText.toString();
      });
      requestPostionInfo = true;
    }
  }

  double searchingForDriverContainerHeight = 0.0;

  void showSearchingForDriverContainer() {
    setState(() {
      searchingForDriverContainerHeight = 200.0;
    });
  }

  searchNearestOnlineDrivers() async {
    if (onlineNearbyAvailableDriversList == 0) {
      referenceRideRequest!.remove();
      setState(() {
        polylineSet.clear();
        markersSet.clear();
        circleSet.clear();
        pLineCoordinatesList.clear();
      });

      Fluttertoast.showToast(
        msg: "No Online Driver Found",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      Fluttertoast.showToast(
        msg: "Please try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      referenceRideRequest!.remove();
      return;
    }
    await retrieveOnlineDriverInformation(onlineNearbyAvailableDriversList);
    print("Driver List" + driversList.toString());

    for (int i = 0; i < driversList.length; i++) {
      AssistantsMethods.sendNotificationToDriverNow(
        driversList[i]["token"],
        referenceRideRequest!.key ?? '',
        context,
      );
    }
    Fluttertoast.showToast(
      msg: "Notification Sent to Driver",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
    showSearchingForDriverContainer();

    await FirebaseDatabase.instance
        .ref()
        .child("All Ride Requests")
        .child(referenceRideRequest!.key!)
        .child("driverId")
        .onValue
        .listen((eventRideRequestSnapshot) {
          print(
            "event snapshot" +
                eventRideRequestSnapshot.snapshot.value.toString(),
          );
          if (eventRideRequestSnapshot.snapshot.value != null) {
            if (eventRideRequestSnapshot.snapshot.value != "waiting") {
              showUIforassignerDriverInfo();
            }
          }
        });
  }

  retrieveOnlineDriverInformation(List onlineNearestDriverList) async {
    driversList.clear();
    DatabaseReference ref = FirebaseDatabase.instance.ref().child("drivers");
    for (int i = 0; i < onlineNearestDriverList.length; i++) {
      await ref
          .child(onlineNearestDriverList[i].driverId!.toString())
          .once()
          .then((dataSnapshot) {
            var driverKeyInfo = dataSnapshot.snapshot.value;
            driversList.add(driverKeyInfo);

            print("Driver Key: ${driverKeyInfo}");
          });
    }
  }

  void showUIforassignerDriverInfo() {
    setState(() {
      waitingResponsefromDriverContainerHeight = 0;
      searchLocationContainerHeight = 0;
      assignedDriverInfoContainerHeight = 200.0;
      bottomPaddingOfMap = 200.0;
      suggestedRideContainerHeight = 0.0;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    checkIfLocationPermissionAllowed();
  }

  @override
  Widget build(BuildContext context) {
    createActiveNearByDriverMarker();
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Dismiss the keyboard
      },
      child: Scaffold(
        drawer: DrawerScreen(),
        key: _scaffoldKey,
        body: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomControlsEnabled: true,
              zoomGesturesEnabled: true,
              polylines: polylineSet,
              markers: markersSet,
              circles: circleSet,
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controllerGoogleMap.complete(controller);
                newGoogleMapController = controller;
                setState(() {});
                locateuserPosition();
              },
              onCameraMove: (CameraPosition? position) {
                if (pickupLocation != position?.target) {
                  setState(() {
                    pickupLocation = position?.target;
                  });
                }
              },
              onCameraIdle: () {
                if (pickupLocation != null) {
                  // Call the function to get address from LatLng
                  getAddressFromLatLng();
                }
              },
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 35),
                child: Icon(Icons.location_on, size: 45, color: Colors.blue),
              ),
            ),

            //ui for searching location
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.location_on, color: Colors.redAccent),
                            SizedBox(width: 10),
                            Text(
                              "Search Location",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Pickup location (read-only)
                        TextField(
                          readOnly: true,
                          controller: TextEditingController(
                            text:
                                Provider.of<AppInfo>(
                                          context,
                                        ).userPickUpLocation !=
                                        null
                                    ? "${Provider.of<AppInfo>(context).userPickUpLocation!.locationName?.substring(0, 24)}...."
                                    : "Not getting address",
                          ),
                          decoration: InputDecoration(
                            hintText: "Pickup location",
                            prefixIcon: Icon(Icons.my_location),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 15,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Drop location (tap navigates to search screen)
                        GestureDetector(
                          onTap: () async {
                            var responseFromSearchScreen =
                                await Navigator.pushNamed(
                                  context,
                                  '/searchplaces',
                                );

                            if (responseFromSearchScreen == "obtainDropOff") {
                              setState(() {
                                openNavigationDrawer = true;
                              });
                            }
                            await drawPolyLineFromOriginToDestination();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 15,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  Provider.of<AppInfo>(
                                            context,
                                          ).userDropOffLocation !=
                                          null
                                      ? "${Provider.of<AppInfo>(context).userDropOffLocation!.locationName?.substring(0, Provider.of<AppInfo>(context).userDropOffLocation!.locationName!.length > 35 ? 35 : Provider.of<AppInfo>(context).userDropOffLocation!.locationName!.length)}...."
                                      : "Where to?",

                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    197,
                                    167,
                                    243,
                                  ),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/precisepickuplocation',
                                  );
                                },
                                child: Text("Change Pickup"),
                              ),
                            ),

                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  103,
                                  239,
                                  112,
                                ),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              onPressed: () {
                                if (Provider.of<AppInfo>(
                                      context,
                                      listen: false,
                                    ).userDropOffLocation !=
                                    null) {
                                  showSuggestedRideContainer();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please select a drop-off location.",
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text("Request Ride"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Center(
            //   child: Container(
            //     decoration: BoxDecoration(
            //       border: Border.all(
            //         color: const Color.fromARGB(255, 198, 10, 10),
            //       ),
            //     ),
            //     padding: EdgeInsets.all(20),
            //     child: Text(
            //       Provider.of<AppInfo>(context).userPickUpLocation != null
            //           ? "${Provider.of<AppInfo>(context).userPickUpLocation!.locationName?.substring(0, 24)}...."
            //           : "not getting address",
            //       overflow: TextOverflow.visible,
            //       style: const TextStyle(
            //         fontSize: 20,
            //         //color: Color.fromARGB(255, 198, 10, 10),
            //         fontWeight: FontWeight.bold,
            //       ),
            //       softWrap: true,
            //     ),
            //   ),
            // ),
            Positioned(
              left: 20,
              top: 500,
              child: Container(
                child: GestureDetector(
                  onTap: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 25,
                    child: Icon(Icons.menu, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: suggestedRideContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),

                    // ORIGIN & DESTINATION ROW
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "Suggested Rides",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 240,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Sedan Ride",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  "assets/images/taxilogo.png",
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.directions_car,
                                    color: Colors.blueGrey,
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text("Sedan • AC"),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 18,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 4),
                                  Text("4.5 ★"),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "₹ 560",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      saveRideRequestInformation();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      backgroundColor: Colors.blueAccent,
                                    ),
                                    child: Text("Select"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // CLOSE BUTTON
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8,
                      ),
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              suggestedRideContainerHeight = 0.0;
                              bottomPaddingOfMap = 0.0;
                            });
                          },
                          child: Icon(
                            Icons.close,
                            color: Colors.blueAccent,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Positioned(
            //   bottom: 0,
            //   left: 0,
            //   right: 0,
            //   child: Container(
            //     height:searchLocationContainerHeight,
            //     decoration: BoxDecoration(
            //       color: Colors.white,
            //       borderRadius: BorderRadius.only(
            //         topLeft: Radius.circular(20),
            //         topRight: Radius.circular(20),
            //       ),
            //       boxShadow: [
            //         BoxShadow(
            //           color: Colors.black12,
            //           blurRadius: 10,
            //           spreadRadius: 5,
            //         ),
            //       ],
            //     ),
            //     child: Column(
            //       mainAxisAlignment: MainAxisAlignment.center,
            //       crossAxisAlignment: CrossAxisAlignment.center,
            //       children: [
            //         LinearProgressIndicator(
            //           value: 0.7,
            //           backgroundColor: Colors.grey[300],
            //           color: Colors.blueAccent,
            //         ),
            //         SizedBox(height: 10),
            //         Center(
            //           child: Text(
            //             "Searching for nearby drivers...",
            //             style: TextStyle(
            //               fontSize: 16,
            //               fontWeight: FontWeight.bold,
            //               color: Colors.black87,
            //             ),
            //           ),
            //         ),
            //         SizedBox(height: 10),
            //         GestureDetector(onTap: (){
            //           referenceRideRequest!.remove();
            //           setState(() {
            //             searchingForDriverContainerHeight = 0.0;
            //             bottomPaddingOfMap = 0.0;
            //           });

            //         },
            //         child: Container(
            //           width: 200,
            //           height: 50,
            //           decoration: BoxDecoration(
            //             color: Colors.blueAccent,
            //             borderRadius: BorderRadius.circular(10),
            //           ),
            //           child: Center(
            //             child: Text(
            //               "Cancel",
            //               style: TextStyle(
            //                 fontSize: 18,
            //                 fontWeight: FontWeight.bold,
            //                 color: Colors.white,
            //               ),
            //             ),
            //           ),
            //         ),
            //         ),
            //         SizedBox(height: 10),

            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
