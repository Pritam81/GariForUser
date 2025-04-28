import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gariforuser/Assistants/assistants_methods.dart';
import 'package:gariforuser/global/map_key.dart';
import 'package:gariforuser/infoHandler/app_info.dart';
import 'package:gariforuser/model/direction.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:provider/provider.dart';

class PrecisePickUpScreen extends StatefulWidget {
  const PrecisePickUpScreen({super.key});

  @override
  State<PrecisePickUpScreen> createState() => _PrecisePickUpScreenState();
}

class _PrecisePickUpScreenState extends State<PrecisePickUpScreen> {
  LatLng? pickupLocation;
  loc.Location? currentLocation;
  String? _address;

  final Completer<GoogleMapController> _controllerGoogleMap =
      Completer<GoogleMapController>();

  GoogleMapController? newGoogleMapController;
  Position? userCurrentPosition;
  double bottomPaddingOfMap = 0.0;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
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
    // Access the name property through the instance
  }

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

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            myLocationEnabled: true,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,

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
          
        ],
      ),
    );
  }
}
