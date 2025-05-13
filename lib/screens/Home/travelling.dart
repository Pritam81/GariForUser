import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gariforuser/model/usermodel.dart';
import 'package:gariforuser/screens/Fare/razorpaykey.dart';
import 'package:gariforuser/screens/Home/homescreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

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
  final _razorpay = Razorpay();
  Usermodel? userModel;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> fetchUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DatabaseReference userRef = FirebaseDatabase.instance
          .ref()
          .child("users")
          .child(currentUser.uid);

      userRef.once().then((DatabaseEvent event) {
        DataSnapshot snapshot = event.snapshot;
        if (snapshot.exists) {
          setState(() {
            userModel = Usermodel.fromSnapshot(snapshot);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Fluttertoast.showToast(
      msg: "Payment Successful! Thank you for travelling with us!",
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    });
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(
      msg: "Payment failed. Please try again.",
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(
      msg: "External Wallet selected: ${response.walletName}",
    );
  }

  Future<void> _sendSosMessage(BuildContext context) async {
    try {
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

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String message =
          "SOS Alert! I'm in danger. Please help!\nLocation: https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

      final Uri smsUri = Uri.parse(
        "sms:+919800687500?body=${Uri.encodeComponent(message)}",
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

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text, {
    Color iconColor = Colors.black87,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  String _formatOrigin(String origin) {
    // Check if it starts with a number and contains a comma
    if (origin.isNotEmpty &&
        RegExp(r'^\d').hasMatch(origin) &&
        origin.contains(',')) {
      return origin.substring(origin.indexOf(',') + 1).trim();
    }
    return origin;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Travelling")),
      body: Padding(
        padding: const EdgeInsets.only(top: 5.0, left: 16, right: 16),
        child:
            userModel == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "You're on your way!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.location_on,
                        "From: ${_formatOrigin(widget.origin)}",
                        iconColor: Colors.green,
                      ),
                      _buildInfoRow(
                        Icons.flag,
                        "To: ${widget.destination}",
                        iconColor: Colors.redAccent,
                      ),
                      const Divider(height: 32, thickness: 1.5),
                      _buildInfoSection(
                        title: "Your Info",
                        children: [
                          _buildInfoRow(
                            Icons.person,
                            userModel!.name ?? "Name",
                          ),
                          _buildInfoRow(
                            Icons.phone,
                            userModel!.phone ?? "Phone",
                          ),
                        ],
                      ),
                      _buildInfoSection(
                        title: "Driver Info",
                        children: [
                          _buildInfoRow(
                            Icons.person,
                            widget.driverName,
                            iconColor: Colors.blue,
                          ),
                          _buildInfoRow(
                            Icons.phone,
                            widget.driverPhone,
                            iconColor: Colors.green,
                          ),
                          _buildInfoRow(
                            Icons.directions_car,
                            "${widget.carModel} - ${widget.carColor}",
                            iconColor: Colors.deepPurple,
                          ),
                          _buildInfoRow(
                            Icons.confirmation_number,
                            "Car No: ${widget.carNumber}",
                            iconColor: Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 0),
                      const Center(
                        child: Text(
                          "Enjoy your ride and stay safe!",
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _sendSosMessage(context),
                            icon: const Icon(Icons.warning),
                            label: const Text("SOS"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text("Reached Destination?"),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _razorpay.open({
                            'key': API_Key,
                            'amount': 50 * 100,
                            'name': 'Gariforuser',
                            'description': 'Fare Payment',
                            'timeout': 360,
                          });
                        },
                        icon: const Icon(Icons.payment),
                        label: const Text("Payment"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
