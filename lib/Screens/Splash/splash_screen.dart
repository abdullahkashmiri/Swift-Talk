import 'dart:async';

import 'package:flutter/material.dart';
import 'package:swift_talk/Screens/Authentication/Sign Up/sign_up_screen.dart';
import 'package:swift_talk/Screens/Authentication/Sign%20In/sign_in_screen.dart';
import 'package:swift_talk/Screens/Wrapper.dart';

class Splash_Screen extends StatefulWidget {
  @override
  State<Splash_Screen> createState() => _Splash_ScreenState();
}

class _Splash_ScreenState extends State<Splash_Screen> {
  //Variables
  var _opacity = 0.0;

  //Functions
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Timer(Duration(seconds: 1), () {
      setState(() {
        _opacity = 1.0;
      });
    });
    Timer(Duration(seconds: 4), (){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
        return Wrapper_Screen();
      }));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedOpacity(
        opacity: _opacity,
        duration: Duration(seconds: 3),
        curve: Curves.easeInOut,
        child: Container(
          child: Center(
              child: Padding(
                padding: const EdgeInsets.all(80.0),
                child: Image.asset('assets/images/swift_logo.png'),
              )),
        ),
      ),
    );
  }
}
