import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _isOtpSent = false;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to send OTP (Firebase reset email) to user email
  Future<void> _sendOtp() async {
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('OTP sent to email')));
      setState(() {
        _isOtpSent = true;
      });
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? 'An error occurred';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // Function to reset password
  Future<void> _resetPassword() async {
    if (_newPassController.text == _confirmPassController.text) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        await user!.updatePassword(_newPassController.text.trim());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Password reset successful')));
        Navigator.pop(context); // Go back to login screen
      } on FirebaseAuthException catch (e) {
        String message = e.message ?? 'An error occurred';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Passwords do not match')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.05,
          vertical: height * 0.05,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Image.asset(
                  'assets/images/taxilogo.png',
                  height: height * 0.3,
                  width: width * 0.7,
                ),
              ),
              SizedBox(height: height * 0.015),
              Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: height * 0.03,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: height * 0.03),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Enter your registered Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value!.isEmpty) return 'Email required';
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value))
                    return 'Invalid email format';
                  return null;
                },
              ),
              SizedBox(height: height * 0.02),

              // OTP + New Password fields after Email is submitted
              // ignore: dead_code
              if (false) ...[
                // OTP Field
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Enter OTP',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_clock),
                  ),
                  validator: (value) => value!.isEmpty ? 'OTP required' : null,
                ),
                SizedBox(height: height * 0.02),

                // New Password Field
                TextFormField(
                  controller: _newPassController,
                  obscureText: _obscureNewPass,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPass
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPass = !_obscureNewPass;
                        });
                      },
                    ),
                  ),
                  validator:
                      (value) =>
                          value!.length < 6
                              ? 'Password must be at least 6 characters'
                              : null,
                ),
                SizedBox(height: height * 0.02),

                // Confirm Password
                TextFormField(
                  controller: _confirmPassController,
                  obscureText: _obscureConfirmPass,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPass
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPass = !_obscureConfirmPass;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _newPassController.text)
                      return 'Passwords do not match';
                    return null;
                  },
                ),
                SizedBox(height: height * 0.025),
              ],

              // Button: Send OTP or Reset Password
              SizedBox(
                width: double.infinity,
                height: height * 0.065,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (!_isOtpSent) {
                        // Send OTP to email
                        _sendOtp();
                      } else {
                        // Reset Password
                        _resetPassword();
                      }
                    }
                  },
                  child: Text(
                    _isOtpSent ? 'Reset Password' : 'Send Reset link',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
