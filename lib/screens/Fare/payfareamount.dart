import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
class PayFareAmountDialog extends StatefulWidget {
  
  double? fareAmount;
  PayFareAmountDialog({
  
    this.fareAmount,
  });

  @override
  State<PayFareAmountDialog> createState() => _PayFareAmountDialogState();
}

class _PayFareAmountDialogState extends State<PayFareAmountDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        height: 200,
        width: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Fare Amount",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "\$${widget.fareAmount}",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Fluttertoast.showToast(msg: "Payment Successful!");

                Navigator.pop(context);
              },
              child: Text("Pay Now"),
            ),
          ],
        ),
      ),
    );
  }
}