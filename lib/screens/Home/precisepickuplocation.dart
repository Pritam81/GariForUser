import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gariforuser/infoHandler/app_info.dart';
import 'package:gariforuser/model/direction.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:gariforuser/global/map_key.dart';
import 'package:provider/provider.dart';

class PrecisePickUpScreen extends StatefulWidget {
  const PrecisePickUpScreen({super.key});

  @override
  State<PrecisePickUpScreen> createState() => _PrecisePickUpScreenState();
}

class _PrecisePickUpScreenState extends State<PrecisePickUpScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? newGoogleMapController;

  List<dynamic> _placePredictions = [];
  LatLng _initialPosition = const LatLng(37.42796133580664, -122.085749655962);

  void _onSearchChanged(String value) async {
    if (value.length > 2) {
      String url =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$value&key=$mapKey&components=country:in";
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _placePredictions = data['predictions'];
        });
      }
    } else {
      setState(() {
        _placePredictions = [];
      });
    }
    // Close the keyboard
  }

  Future<void> _goToPlace(String placeId) async {
    final String url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final placeDetail = json.decode(response.body);
      final lat = placeDetail['result']['geometry']['location']['lat'];
      final lng = placeDetail['result']['geometry']['location']['lng'];
      final description = placeDetail['result']['formatted_address'];

      LatLng position = LatLng(lat, lng);
      _moveCamera(position);

      // Save to Provider
      Directions userPickUpAddress = Directions();
      userPickUpAddress.locationLatitude = lat;
      userPickUpAddress.locationLongitude = lng;
      userPickUpAddress.locationName = description;

      Provider.of<AppInfo>(
        context,
        listen: false,
      ).updatePickUpLocationAddress(userPickUpAddress);

      // Optional: hide predictions
      setState(() {
        _placePredictions = [];
      });

      // Close this screen
      Navigator.pop(context); // ✅ This will close the screen
    }
  }

  Future<void> _moveCamera(LatLng position) async {
    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLng(position));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Pickup Location")),
      body: Stack(
        children: [
          Positioned(
            top: 15,
            left: 15,
            right: 15,
            child: Column(
              children: [
                Material(
                  elevation: 5,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "Enter pickup location",
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _placePredictions.length,
                  itemBuilder: (context, index) {
                    final place = _placePredictions[index];
                    return ListTile(
                      title: Text(place['description']),
                      onTap: () {
                        _goToPlace(place['place_id']);
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _placePredictions = [];
                          _searchController.text = place['description'];
                          print("Selected place: ${place['description']}");
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
