import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:swift_talk/Screens/Loading/loading_Screen.dart';
import 'package:swift_talk/Services/auth.dart';
import 'package:swift_talk/main.dart';

class SignUp_Screen extends StatefulWidget {
  const SignUp_Screen({super.key});

  @override
  State<SignUp_Screen> createState() => _SignUp_ScreenState();
}

class _SignUp_ScreenState extends State<SignUp_Screen> {
  //Variables
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _cPasswordController = TextEditingController();

  final Auth_Service _auth = Auth_Service();
  String email = '';
  String password = '';
  String cPassword = '';
  String error = '';
  bool isSigningUp = false;
  //Functions
  @override
  Widget build(BuildContext context) {
    if(isSigningUp == false)
    return Scaffold(
      appBar: AppBar(
        title: Text('Swift Talk'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 40),
            child: Form(
              child: Column(
                children: [
                  SizedBox(height: 10.0,),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 70),
                    child: Image.asset('assets/images/logo_only_swift.png'),
                  ),
                  SizedBox(height: 50,),

                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'your_email@gmail.com',
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email, color: Colors.blue),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelStyle: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      hintStyle: TextStyle(color: Colors.blue.withOpacity(0.7), fontWeight: FontWeight.bold),
                    ),
                    validator: (value) {
                      return value!.isEmpty ? 'Enter an email' : null;
                    },
                  ),

                  SizedBox(height: 20,),

                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icon(Icons.lock, color: Colors.blue),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelStyle: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      hintStyle: TextStyle(color: Colors.blue.withOpacity(0.7), fontWeight: FontWeight.bold),
                    ),
                    validator: (value) {
                      return value!.length < 6 ? 'Enter a password at least 6 characters long' : null;
                    },
                    obscureText: true,
                    obscuringCharacter: '*',
                  ),

                  SizedBox(height: 20,),

                  TextFormField(
                    controller: _cPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Confirm your password',
                      prefixIcon: Icon(Icons.lock, color: Colors.blue),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2.0),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelStyle: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      hintStyle: TextStyle(color: Colors.blue.withOpacity(0.7), fontWeight: FontWeight.bold),
                    ),
                    validator: (value) {
                      return value!.length < 6 ? 'Enter a password at least 6 characters long' : null;
                    },
                    obscureText: true,
                    obscuringCharacter: '*',
                  ),

                  SizedBox(height: 20,),
                  Text(error,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16
                  ),),
                  SizedBox(height: 20,),

                  ElevatedButton(
                    onPressed: () async {
                      email = _emailController.text.trim();
                      password = _passwordController.text.trim();
                      cPassword = _cPasswordController.text.trim();

                      if (email == '' || password == '' || cPassword == '') {
                        log('Enter all values');
                        setState(() {
                          error = 'Fill all fields';
                        });
                      } else {
                        if (password != cPassword) {
                          log('Password and Confirm Password Do not match');
                          setState(() {
                            error = 'Passwords do not match';
                          });
                        } else {
                          setState(() {
                            error = '';
                            isSigningUp = true;
                          });

                          dynamic result = await _auth.signUpWithEmailAndPassword(email, password);
                          setState(() {
                            isSigningUp = false;
                          });


                          if (result == null) {
                            setState(() {
                              error = Global_error;
                              Global_error = '';
                            });
                          } else {
                            setState(() {
                              error = '';
                            });

                            _emailController.clear();
                            _passwordController.clear();
                            _cPasswordController.clear();

                            Navigator.pop(context);
                          }
                        }
                      }
                    },
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      primary: Colors.blue, // Background color
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                    ),
                  ),

                  SizedBox(height: 60,),
                  Text('Connect Swiftly, Chat Elegantly!',
                  style: TextStyle(
                    color: Colors.blue.shade500,
                    fontSize: 16
                  ),),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    else
      return Loading_Screen();
  }
}
