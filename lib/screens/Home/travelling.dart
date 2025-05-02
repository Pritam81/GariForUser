import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gariforuser/screens/Fare/razorpaykey.dart';
import 'package:gariforuser/screens/Home/homescreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class TravellingPage extends StatefulWidget {
  final String driverName;
  final String driverPhone;
  final String carModel;
  final String carNumber;
  final String carColor;
  final String origin;
  final String destination;

  const TravellingPage({
    Key? key,
    required this.driverName,
    required this.driverPhone,
    required this.carModel,
    required this.carNumber,
    required this.carColor,
    required this.origin,
    required this.destination,
  }) : super(key: key);

  @override
  State<TravellingPage> createState() => _TravellingPageState();
}

class _TravellingPageState extends State<TravellingPage> {
  void _triggerSOS(BuildContext context) {
    final message = "🚨 SOS! I need help. Please contact me immediately.";
    Share.share(message);
  }

  final String phoneNumber = "+919749922509"; // Replace with your phone number

  Future<void> _sendSosMessage(BuildContext context) async {
    try {
      // Request location permission if not granted
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied.")),
        );
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String message =
          "🚨 SOS Alert 🚨\nI'm in danger. Please help!\nLocation:\nhttps://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

      // SMS URL with recipient
      final Uri smsUri = Uri.parse(
        "sms:+918101525213?body=${Uri.encodeComponent(message)}",
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch SMS app.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  var _razorpay = Razorpay();
  void initState() {
    // TODO: implement initState
    super.initState();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Fluttertoast.showToast(
      msg: "Payment Successful! Thank you for travelling with us!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    });

    // Do something when payment succeeds
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    // Do something when payment fails
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Do something when an external wallet is selected
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Travelling...")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🛣 You're on your way!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text("From: ${widget.origin.split(',')[1].trim()}"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.flag, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(child: Text("To: ${widget.destination}")),
              ],
            ),
            const Divider(height: 32, thickness: 1.5),
            const Text(
              "👨‍✈️ Driver Information",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Text(widget.driverName),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.green),
                const SizedBox(width: 8),
                Text(widget.driverPhone),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.directions_car, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text("${widget.carModel} - ${widget.carColor}"),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.confirmation_number, color: Colors.orange),
                const SizedBox(width: 8),
                Text("Car No: ${widget.carNumber}"),
              ],
            ),
            const Spacer(),
            const Center(
              child: Text(
                "Enjoy your ride and stay safe!",
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 16),
            Text("Reached Destination?"),

            ElevatedButton(
              onPressed: () {
                var options = {
                  'key': API_Key,
                  'amount': 115 * 100, //in the smallest currency sub-unit.
                  'name': 'Gariforuser',
                  'description': 'Fare Payment',

                  'description': 'DONATION',
                  'timeout': 360, // in seconds
                };

                _razorpay.open(options);

                //razorpay api
              },
              child: Text("Pay Fare"),

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _sendSosMessage(context);
          // Uncomment the line be
          //low to call the driver directly
          // launch("tel:${widget.driverPhone}");
        },
        icon: const Icon(Icons.warning),
        label: const Text("SOS"),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
