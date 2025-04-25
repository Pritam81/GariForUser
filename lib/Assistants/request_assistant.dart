import 'dart:convert';
import 'package:http/http.dart' as http;

class RequestAssistant {
  static Future<dynamic> getRequest(String url) async {
    http.Response httpResponse = await http.get(Uri.parse(url));
    try {
      if (httpResponse.statusCode == 200) {
        String jsonData = httpResponse.body;
        var decodedData = jsonDecode(jsonData);
        return decodedData;
      } else {
        return "Error Occoured. Failed. No Response.";
      }
    } catch (e) {
      return "Error Occoured. Failed.  No Response.";
    }
  }
}
