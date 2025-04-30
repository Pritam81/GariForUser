import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:gariforuser/Assistants/request_assistant.dart';
import 'package:gariforuser/global/global.dart';
import 'package:gariforuser/global/map_key.dart';
import 'package:gariforuser/infoHandler/app_info.dart';
import 'package:gariforuser/model/directiondetailsinfo.dart';
import 'package:gariforuser/model/usermodel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gariforuser/model/direction.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class AssistantsMethods {
  static void readCurrentOnlineUserInfo() async {
    currentuser = FirebaseAuth.instance.currentUser;
    DatabaseReference userRef = FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(currentuser!.uid);

    userRef.once().then((userSnapshot) {
      if (userSnapshot.snapshot.value != null) {
        var userModelCurrentInfo = Usermodel.fromSnapshot(
          userSnapshot.snapshot,
        );
      } else {
        print("No data exists for this user.");
      }
    });
  }

  static Future<String> searchAddressForGeographicCoordinates(
    Position position,
    context,
  ) async {
    String apiUrl =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
    String humanReadableAddress = "";
    var requestResponse = await RequestAssistant.getRequest(apiUrl);

    if (requestResponse != "Error Occured. Failed.  No Response.") {
      humanReadableAddress = requestResponse["results"][0]["formatted_address"];
      print("This is your address: " + humanReadableAddress);

      Directions userPickUpAddress = Directions();
      userPickUpAddress.locationLatitude = position.latitude;
      userPickUpAddress.locationLongitude = position.longitude;

      userPickUpAddress.locationName = humanReadableAddress;
      Provider.of<AppInfo>(
        context,
        listen: false,
      ).updatePickUpLocationAddress(userPickUpAddress);
    }
    return humanReadableAddress;
  }

  static double calculateFaresFromOriginToDestination(
    Directiondetailsinfo directionDetailsInfo,
  ) {
    double timeTraveledFareAmountPerMinute =
        (directionDetailsInfo.durationValue! / 60) * 0.1;
    double distanceTraveledFareAmountPerKilometer =
        (directionDetailsInfo.distanceValue! / 1000) * 0.1;

    double totalAmount =
        timeTraveledFareAmountPerMinute +
        distanceTraveledFareAmountPerKilometer;
    double totalLocalAmount = double.parse(totalAmount.toStringAsFixed(2));
    return totalLocalAmount;
  }

  static Future<Directiondetailsinfo?>
  obtainOriginToDestinationDirectionDetails(
    LatLng originPosition,
    LatLng destinationPosition,
  ) async {
    String urlOriginToDestinationDirectionDetails =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${originPosition.latitude},${originPosition.longitude}&destination=${destinationPosition.latitude},${destinationPosition.longitude}&key=$mapKey";

    var responseDirectionApi = await RequestAssistant.getRequest(
      urlOriginToDestinationDirectionDetails,
    );

    if (responseDirectionApi == "Error Occured. Failed.  No Response.") {
      return null;
    }
    Directiondetailsinfo directionDetailsInfo = Directiondetailsinfo();
    directionDetailsInfo.e_points =
        responseDirectionApi["routes"][0]["overview_polyline"]["points"];
    directionDetailsInfo.distanceText =
        responseDirectionApi["routes"][0]["legs"][0]["distance"]["text"];
    directionDetailsInfo.distanceValue =
        responseDirectionApi["routes"][0]["legs"][0]["distance"]["value"];
    directionDetailsInfo.durationText =
        responseDirectionApi["routes"][0]["legs"][0]["duration"]["text"];
    directionDetailsInfo.durationValue =
        responseDirectionApi["routes"][0]["legs"][0]["duration"]["value"];

    return directionDetailsInfo;
  }

  static Future<String> getAccessToken() async {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "gari-b4d14",
      "private_key_id": "ade47e57331aac213e0939f8f258d0fed5b9ee65",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQDQqxZ69sZ3MCrh\nyBTrfH8lIz0PP0a7a6dfUkxZNYqSwuBTZQT2a+8oC7bUInRWSO0a8oJuF//AHXWG\n2wxwFATZyJ8MyUlo9Yojwt+mfRU9ZdnDF1K1AqQUE3pWRQ/5Tej9R34u0elLK5O8\n0Qzu71WFeSokAwRpAVDwIe/vIDPK16ngD7VBg16kA7M2GUp03WzFl4QOfNZVm/Sd\nZJiytPDW/+CfMDNmxWJN3leV6ec2Jf4OR5Pf/kJfzi/Gq31cJ+6x0RSZQ/1KRq8p\niZxZHuNNneErY0ZF4lNUY5EhsAJCdmvOq3cH4zosd5UJ1ESIN4eb9QxKW1+5C+Q2\nkQplAhxLAgMBAAECggEAI1S8lzBedULWF+mRRTgMrSSUy5aaqtQ1ACpGnBo5LtVJ\nN0WU/AZVdZHaMHvu98ccQmJKXEq69nPmeOFw7y8sjRVvfLI+OEPO0nRF+wIVzRII\nN4Sk79oVHwMXRTEnXb5n0y6+Oj43go9L0f4RcwlaESHtVTCfmAntguM0JWht7Iud\n6S88Lvhs+Y7oCtN2X/kFMlPVO59cXd82ubXwJ1evGPYadL7+39skvE/w8l0HiO+Y\nsBuIhyFKXb/JRWSa6gtItH421Ldn65UOMAbFD8wv9LH2wmgu2xQam5RFWIbMtzNA\n0UEsN4a+cQJiHJzkMl4Noy7eQcxzlFvyC9jF72imZQKBgQD+jUiJEKC+AbvHMlAw\nrvX0ewf+C4ZH1GQ2c3LKbpYFZbdaGsTYjgMuoHsShCzPXnQnNwF6K2TYGK/huUPZ\n88R3n2ViFO/rwOLhPLoUz260KcnnvJzvaBySec1ASXgBXVWDSqWcIkfZZkZLtiJw\nkd/l5lpXKOgmYHf/HPmxXZPqlwKBgQDR2vtfT2G5JYH81tgsKV/V4Sy2OseV8Ie/\nnngUBjoQNplpdrGREL/5NOAzhGv94LBn7+V0pRyazisqiAyzEa+FtCVHeN5WYPuT\n8oh4hHrorKAc/6VyTWwb90cm05/ZWjv7HDfWbZ54Xoqikxp3x12Gql5y/uW/ezed\nogKhPxvWbQKBgQCC2O0oR7vY79sukdZWsBkOCxAYrqPf2HWK591h4WaMb7TIRGpb\nRuSr2yJoajj+f3cFkWjY++Vij44ZYbpXFs8vDmh2+nw5m3UEgsrEV7x4L+LxlCq3\nhbTqNmIjYaCmUuvaCU0H7TcxsTkBQiaB5vpImxhlJUnwMDZ+lM5lNc0LEQKBgQC4\n8J9vU2nv3No9lKlV4fCPcK4SuqKBxUQc3u871nD9MODqTKwYCAbm/G5JeH4jcwyD\nzKsOrSQUWXU5OkTW2tMwpZ3k6uQmg7mynJ8gdsBKpTdF1xZbMVgBHV8bHI1W42rQ\n1gFve5OYyNisha9ht9T4hNRPy8t1gIV26fwfVpqV0QKBgQCXo+fMMUB7BWbuYUse\nCPM1SEcaH51e69AFDlziEWhVAj7GOJ17OqYJ6/a1SDElfzxUSGvSVOGj1Jwb9+0P\nIjXy9tITO6A9oBjfygzq0RxlfLh3eS/5vDxA6hcV4PZKc+Pb0ZmIftDbX9cGM1Cf\nQwsGr0QpfOUvUA5+SaopvRsO8g==\n-----END PRIVATE KEY-----\n",
      "client_email": "gariforuser@gari-b4d14.iam.gserviceaccount.com",
      "client_id": "106519126332971758345",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/gariforuser%40gari-b4d14.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com",
    };

    List<String> scopes = [
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/userinfo.messaging',
    ];

    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    auth.AccessCredentials credentials = await auth
        .obtainAccessCredentialsViaServiceAccount(
          auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
          scopes,
          client,
        );

    client.close();
    return credentials.accessToken.data;
  }

  static sendNotificationToDriverNow(
    String deviceRegistrationToken,
    String userRideRequestId,
    context,
  ) async {
    final String cloudMessagingServerToken = await getAccessToken();
    String destinationAddress = userDropOffAddress;
    Map<String, String> headerNotification = {
      "content-type": "application/json",
      "Authorization": cloudMessagingServerToken,
    };
    Map bodyNotification = {
      "body": "Destination Address: \n$destinationAddress",
      "title": "New Trip Request",
    };
    Map dataMap = {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "id": "1",
      "status": "done",
      "ride_request_id": userRideRequestId,
    };

    Map officialNotificationFormat = {
      "to": deviceRegistrationToken,
      "notification": bodyNotification,
      "data": dataMap,
      "priority": "high",
    };

    var responseNotification = http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
      headers: headerNotification,
      body: jsonEncode({
        officialNotificationFormat
      }),
    );
  }
}
