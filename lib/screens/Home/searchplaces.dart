import 'package:flutter/material.dart';
import 'package:gariforuser/Assistants/request_assistant.dart';
import 'package:gariforuser/global/map_key.dart';
import 'package:gariforuser/screens/Home/predictedplaces.dart';
import 'package:gariforuser/widgets/predictiontile.dart';



class SearchPlacesScreen extends StatefulWidget {
  const SearchPlacesScreen({super.key});

  @override
  State<SearchPlacesScreen> createState() => _SearchPlacesScreenState();
}

class _SearchPlacesScreenState extends State<SearchPlacesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasSearched = false;

  List<PredictedPlaces> PredictedPlacesList = [];
  findPlaceAutoCompleteSearch(String inputText) async {
    if (inputText.length > 1) {
      String urlAutoCompleteSearch =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$inputText&key=$mapKey&components=country:in";

      var responseAutoCompleteSeacrh = await RequestAssistant.getRequest(
        urlAutoCompleteSearch,
      );

      if (responseAutoCompleteSeacrh ==
          "Error Occured. Failed.  No Response.") {
        return;
      }
      if (responseAutoCompleteSeacrh["status"] == "OK") {
        var placePredictions = responseAutoCompleteSeacrh["predictions"];
        var placespredictionsList =
            (placePredictions as List)
                .map((json) => PredictedPlaces.fromJson(json))
                .toList();

        setState(() {
          PredictedPlacesList = placespredictionsList;
          print(PredictedPlacesList);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(
          context,
        ).unfocus(); // Dismiss the keyboard when tapping outside
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),

          title: const Text(
            'Search Your Destination',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.green,
        ),
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.adjust_sharp),
                        SizedBox(height: 18),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: TextField(
                              onChanged: (value) {
                                findPlaceAutoCompleteSearch(value);
                              },
                              decoration: InputDecoration(
                                hintText: 'Search Places',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            (PredictedPlacesList.length > 0)
                ? Expanded(
                  child: ListView.separated(
                    itemCount: PredictedPlacesList.length,
                    physics: ClampingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return PlacesPredicionTileDesihgn(
                        predictedPlaces: PredictedPlacesList[index],
                      );
                    },

                    separatorBuilder: (BuildContext context, int index) {
                      return Divider(
                        color: Colors.black,
                        height: 10,
                        thickness: 01,
                        indent: 20,
                        endIndent: 20,
                      );
                    },
                  ),
                )
                : Container(),
          ],
        ),
      ),
    );
  }
}
