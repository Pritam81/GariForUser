import 'package:flutter/material.dart';
import 'package:gariforuser/Assistants/request_assistant.dart';
import 'package:gariforuser/global/global.dart';
import 'package:gariforuser/global/map_key.dart';
import 'package:gariforuser/infoHandler/app_info.dart';
import 'package:gariforuser/model/direction.dart';
import 'package:gariforuser/screens/Home/predictedplaces.dart';
import 'package:gariforuser/screens/Home/progressdialogue.dart';
import 'package:provider/provider.dart';

class PlacesPredicionTileDesihgn extends StatefulWidget {
  final PredictedPlaces? predictedPlaces;
  PlacesPredicionTileDesihgn({this.predictedPlaces});

  @override
  State<PlacesPredicionTileDesihgn> createState() =>
      _PlacesPredicionTileDesihgnState();
}

class _PlacesPredicionTileDesihgnState
    extends State<PlacesPredicionTileDesihgn> {
  getplacesdirectiondetails(String placeid, context) async {
    showDialog(
      context: context,
      builder:
          (BuildContext context) =>
              progressDialogue(message: "Getting Place Details..."),
    );

    String placeDirectionDetailsUrl =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeid&key=$mapKey";
    var responseApi = await RequestAssistant.getRequest(
      placeDirectionDetailsUrl,
    );

    Navigator.pop(context); // Close the progress dialog

    if (responseApi == "Error Occured. Failed.  No Response.") {
      return;
    }

    if (responseApi["status"] == "OK") {
      Directions directions = Directions();
      directions.locationName = responseApi["result"]["name"];
      directions.locationId = placeid;
      directions.locationLatitude =
          responseApi["result"]["geometry"]["location"]["lat"];
      directions.locationLongitude =
          responseApi["result"]["geometry"]["location"]["lng"];

      Provider.of<AppInfo>(
        context,
        listen: false,
      ).updateDropOffLocationAddress(directions);

      setState(() {
        userDropOffAddress = directions.locationName!;
      });

      Navigator.pop(context, "obtainDropOff");
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Handle null predictedPlaces
    final prediction = widget.predictedPlaces;
    if (prediction == null ||
        prediction.mainText == null ||
        prediction.placeId == null) {
      return const SizedBox(); // or return a placeholder widget if you prefer
    }

    return ElevatedButton(
      onPressed: () {
        getplacesdirectiondetails(prediction.placeId!, context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        shadowColor: Colors.black,
        elevation: 5,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const Icon(
              Icons.add_location,
              color: Color.fromARGB(255, 78, 76, 175),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prediction.mainText!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    prediction.secondaryText ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
