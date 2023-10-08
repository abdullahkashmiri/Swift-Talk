import 'package:flutter/material.dart';
import 'package:swift_talk/Screens/Authentication/Sign%20In/sign_in_screen.dart';
import 'package:swift_talk/Screens/Contact%20List/contact_list.dart';
import 'package:swift_talk/Screens/Contact_Profile/Contact_Profile.dart';
import 'package:swift_talk/Screens/Loading/loading_Screen.dart';
import 'package:swift_talk/Screens/Profile/Contacts_known/my_contacts.dart';
import 'package:swift_talk/Screens/Profile/profile.dart';

import '../../Services/auth.dart';


class Chat_List extends StatefulWidget {
  const Chat_List({super.key});

  @override
  State<Chat_List> createState() => _Chat_ListState();
}

class _Chat_ListState extends State<Chat_List> {
  //Variables
  final Auth_Service _auth = Auth_Service();
  bool isLogingOut = false;
  @override
  //Functions
  void signOut() async {
    setState(() {
      isLogingOut = true;
    });
    await Future.delayed(Duration(seconds: 2));
    await _auth.signOut();
    setState(() {
      isLogingOut = false;
    });
  }
  Widget build(BuildContext context) {
    if(isLogingOut == false)
    return Scaffold(
      appBar: AppBar(
        title: Text('Swift Talk'),
        centerTitle: true,
        leading:
          IconButton(onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => Profile_Screen()));
          }, icon: Icon(Icons.account_circle,
            size: 30.0,)
            ,),
        actions: [
          IconButton(onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => Phone_Directory_Screen()));
          }, icon: Icon(Icons.contacts)
            ,),
          IconButton(onPressed: () {
            signOut();
            Navigator.popUntil(context, (route) => route.isFirst);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignIn_Screen()));
          }, icon: Icon(Icons.logout)
          ,),

        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Chat List'),
                SizedBox(height: 30,),
                ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Contact_Profile_Screen(uid: 'fhcTXMxdreMOEuO7ey7NvrXFz3n1',)));
                    },
                    child: Text('Test Page')
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 20.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return Contact_List_Screen();
                  //return Phone_Directory_Screen();
                }));
              },
              child: Text('+',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold
              ),),
            ),
          ),
        ],
      ),
    );
    else
      return Loading_Screen();
  }
}
