import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gariforuser/global/global.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  void clearcontroller() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await firebaseauth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          )
          .then((auth) async {
            currentuser = auth.user;
            if (currentuser != null) {
              Map userMap = {
                "id": currentuser!.uid,
                "name": _nameController.text.trim(),
                "email": _emailController.text.trim(),
                "phone": _phoneController.text.trim(),
              };

              DatabaseReference userRef = FirebaseDatabase.instance.ref().child(
                "users",
              );
              userRef.child(currentuser!.uid).set(userMap);
            }

            await Fluttertoast.showToast(
              msg: "Account has been created",
              backgroundColor: Colors.yellow,
              textColor: Colors.black,
              fontSize: 16.0,
            );

            var prefs = await SharedPreferences.getInstance();
            prefs.setBool("islogin", true);
            clearcontroller();

            setState(() {
              _isLoading = false;
            });

            Navigator.pushReplacementNamed(context, '/homescreen');
          })
          .catchError((error) {
            setState(() {
              _isLoading = false;
            });

            Fluttertoast.showToast(
              msg: error.toString(),
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.04,
          vertical: height * 0.02,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(height: height * 0.05),
              Center(
                child: Image.asset(
                  'assets/images/taxilogo.png',
                  height: height * 0.2,
                  width: width * 0.7,
                ),
              ),
              SizedBox(height: height * 0.015),
              Text(
                'Create an account',
                style: TextStyle(
                  fontSize: height * 0.03,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: height * 0.02),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator:
                    (value) => value!.isEmpty ? 'Please enter your name' : null,
              ),
              SizedBox(height: height * 0.015),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your phone number';
                  if (!RegExp(r'^\d{10}$').hasMatch(value))
                    return 'Enter a valid 10-digit number';
                  return null;
                },
              ),
              SizedBox(height: height * 0.015),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter your email';
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value))
                    return 'Enter a valid email';
                  return null;
                },
              ),
              SizedBox(height: height * 0.015),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator:
                    (value) =>
                        value!.length < 6
                            ? 'Password must be at least 6 characters'
                            : null,
              ),
              SizedBox(height: height * 0.015),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                  ),
                ),
                validator:
                    (value) =>
                        value != _passwordController.text
                            ? 'Passwords do not match'
                            : null,
              ),
              SizedBox(height: height * 0.03),

              // Register Button or Loading
              SizedBox(
                width: double.infinity,
                height: height * 0.065,
                child:
                    _isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            color: Colors.yellow,
                          ),
                        )
                        : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _submit,
                          child: Text(
                            'Register',
                            style: TextStyle(
                              fontSize: height * 0.022,
                              color: Colors.black,
                            ),
                          ),
                        ),
              ),
              SizedBox(height: height * 0.02),

              Text(
                "Have an account?",
                style: TextStyle(
                  fontSize: height * 0.018,
                  color: Colors.black54,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/loginscreen');
                },
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
