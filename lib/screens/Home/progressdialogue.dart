import 'package:flutter/material.dart';
// ignore: camel_case_types
class progressDialogue extends StatelessWidget {
  const progressDialogue({super.key, required String message});

  @override
  Widget build(BuildContext context) {
    return  Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 6,
              
            ),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.green,
              ),

            )
          ],
        )
      ),
     );
  }
}