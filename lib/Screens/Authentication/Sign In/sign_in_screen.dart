import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:swift_talk/Screens/Authentication/Sign%20Up/sign_up_screen.dart';
import 'package:swift_talk/Screens/Chat%20List/chat_list.dart';
import 'package:swift_talk/Services/auth.dart';
import 'package:swift_talk/main.dart';
import 'package:swift_talk/Screens/Loading/loading_Screen.dart';

class SignIn_Screen extends StatefulWidget {
  const SignIn_Screen({super.key});

  @override
  State<SignIn_Screen> createState() => _SignIn_ScreenState();
}

class _SignIn_ScreenState extends State<SignIn_Screen> {
  //Variables
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  final Auth_Service _auth = Auth_Service();
  String email = '';
  String password = '';
  String error = '';
  bool isSigningIn = false;
  //Functions
  @override
  Widget build(BuildContext context) {
    if(isSigningIn == false) {
      return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 40),
            child: Form(
              child: Column(
                children: [
                  SizedBox(height: 70,),
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
                      if (email == '' || password == '') {
                        log('Enter all values');
                        setState(() {
                          error = 'Fill all fields';
                        });
                      } else {
                        setState(() {
                          isSigningIn = true;
                          error='';
                        });
                        dynamic result = await _auth.signInWithEmailAndPassword(email, password);
                        setState(() {
                          isSigningIn = false;
                        });
                        print('Sign In Result : $result');
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
                          print('Sign In');
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return Chat_List();
                            }),
                          );
                        }
                      }
                    },
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                      primary: Colors.blue, // Background color
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                    ),
                  ),

                  SizedBox(height: 30.0,),
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        isSigningIn = true;
                      });
                      // Introduce a delay of 2 seconds before navigating.
                      await Future.delayed(Duration(seconds: 1));
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return SignUp_Screen();
                      }));
                      setState(() {
                        error = '';
                        isSigningIn = false;
                      });
                    }, child: Text('Create an Account',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      color: Colors.blue.shade500
                    ),),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      elevation: 0.0
                    ),),
                  SizedBox(height: 50,),
                  Text('Welcome to Swift Talk',
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
    } else
      return Loading_Screen();
  }
}
