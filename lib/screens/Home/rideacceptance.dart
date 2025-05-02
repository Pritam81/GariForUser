import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:gariforuser/screens/Home/travelling.dart';

class RideRequestsWithDriverInfo extends StatefulWidget {
  @override
  _RideRequestsWithDriverInfoState createState() =>
      _RideRequestsWithDriverInfoState();
}

class _RideRequestsWithDriverInfoState
    extends State<RideRequestsWithDriverInfo> {
  final DatabaseReference rideRequestsRef = FirebaseDatabase.instance
      .ref()
      .child("All Ride Requests");

  List<Map<String, dynamic>> rideDetails = [];

  @override
  void initState() {
    super.initState();
    fetchRideRequests();
  }

  Future<void> fetchRideRequests() async {
    rideDetails.clear();
    final snapshot = await rideRequestsRef.get();
    final data = snapshot.value as Map?;

    if (data != null) {
      for (var entry in data.entries) {
        final rideId = entry.key;
        final ride = entry.value as Map?;

        if (ride != null) {
          final driverId = ride["driverId"];
          Map<String, dynamic> detail = {
            "rideId": rideId,
            "origin": ride["originAddress"] ?? "Unknown",
            "destination": ride["destinationAddress"] ?? "Unknown",
            "userName": ride["userName"] ?? "Unknown",
          };

          if (driverId == "waiting") {
            detail["status"] = "Waiting for driver";
          } else {
            // Get driver info from Drivers node
            final driverSnapshot =
                await FirebaseDatabase.instance
                    .ref()
                    .child("Drivers")
                    .child(driverId)
                    .get();
            final driverData = driverSnapshot.value as Map?;

            if (driverData != null) {
              detail["status"] = "Driver Assigned";
              detail["driverName"] = driverData["name"] ?? "N/A";
              detail["driverPhone"] = driverData["phone"] ?? "N/A";
              detail["carModel"] = driverData["car_model"] ?? "N/A";
              detail["carNumber"] = driverData["car_number"] ?? "N/A";
              detail["carColor"] = driverData["car_color"] ?? "N/A";
            }
          }

          rideDetails.add(detail);
        }
      }

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ride Requests"),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: fetchRideRequests),
        ],
      ),
      body:
          rideDetails.isEmpty
              ? Center(child: Text("waiting for driver, please wait.."))
              : ListView.builder(
                itemCount: 1,
                itemBuilder: (context, index) {
                  final ride = rideDetails[index];
                  return Card(
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      title: Text("Ride ID: ${ride['rideId']}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("From: ${ride['origin']}"),
                          Text("To: ${ride['destination']}"),
                          Text("User: ${ride['userName']}"),
                          SizedBox(height: 8),
                          ride["status"] == "Waiting for driver"
                              ? Text("🚕 Status: Waiting for driver")
                              : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("🚕 Driver: ${ride['driverName']}"),
                                  Text("📞 Phone: ${ride['driverPhone']}"),
                                  Text(
                                    "🚗 Car: ${ride['carModel']} (${ride['carColor']})",
                                  ),
                                  Text("🪪 Number: ${ride['carNumber']}"),
                                ],
                              ),

                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => TravellingPage(
                                          driverName:
                                              ride['driverName'] ?? "Unknown",
                                          driverPhone:
                                              ride['driverPhone'] ?? "Unknown",
                                          carModel:
                                              ride['carModel'] ?? "Unknown",
                                          carNumber:
                                              ride['carNumber'] ?? "Unknown",
                                          carColor:
                                              ride['carColor'] ?? "Unknown",
                                          origin: ride['origin'] ?? "Unknown",
                                          destination:
                                              ride['destination'] ?? "Unknown",
                                        ),
                                  ),
                                );

                                // Handle ride acceptance logic here
                              },
                              child: Text("Caught Driver!"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
