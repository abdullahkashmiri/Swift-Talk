import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swift_talk/Models/user.dart';
import 'package:swift_talk/Screens/Chat/chat.dart';
import 'package:swift_talk/Screens/Loading/loading_Screen.dart';
import 'package:swift_talk/Services/database.dart';

class Contact_Profile_Screen extends StatefulWidget {

  final String uid;
  Contact_Profile_Screen({required this.uid});

  @override
  State<Contact_Profile_Screen> createState() => _Contact_Profile_ScreenState();
}

class _Contact_Profile_ScreenState extends State<Contact_Profile_Screen> {
  bool isPageLoaded = false;
  UserData? userData;
  @override
  Widget build(BuildContext context) {
    final String ProfileUid = widget.uid;
    print('Profile User uid : '+ ProfileUid);
    return StreamBuilder<UserData>(
        stream: DataBase_Service(uid: ProfileUid).userData,
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting) {
            return Loading_Screen();
          }
          if(snapshot.hasData == null) {
            return Loading_Screen();
          }
          if(snapshot.hasError == true) {
            print('snapshot error occurred : ${snapshot.error}');
            Navigator.pop(context);
            return Loading_Screen();
          }
          if(isPageLoaded == false) {
            userData = snapshot.data as UserData;
            isPageLoaded = true;
          }
          return Scaffold(
            backgroundColor: Colors.blue.shade50,
            appBar: AppBar(
              title: Text('User Profile'),
              centerTitle: true,
            ),
            body: Container(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.transparent,
                      backgroundImage: NetworkImage(
                        userData?.profilePic ??
                            'https://firebasestorage.googleapis.com/v0/b/swift-talk-co-ab21a.appspot.com/o/Default%2Fprofile_default.png?alt=media&token=473d6feb-a748-490b-9841-3f56ccee7dcb&_gl=1*1rol94l*_ga*NjEwMDgxNjQzLjE2OTQ1MDY4NzY.*_ga_CW55HF8NVT*MTY5NjgwMjI3NC40Mi4xLjE2OTY4MDIzOTMuMTMuMC4w',
                      ),
                      radius: 70,
                    ),
                    SizedBox(height: 30,),
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.blue,
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        child: Text('User Details',
                        style: TextStyle(fontSize: 25,color: Colors.white,fontWeight: FontWeight.bold),),
                      ),
                    ),
                    SizedBox(height: 20,),
                    Container(
                      width: 250,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                                children: [
                                  TextSpan(text: 'Name : ',style: TextStyle(fontSize: 18, color: Colors.black,fontWeight: FontWeight.bold)),
                                  TextSpan(text: '${userData?.name}',style: TextStyle(fontSize: 18, color: Colors.blue,fontWeight: FontWeight.bold)),
                                ]
                            ),
                          ),
                          SizedBox(height: 15,),
                          RichText(
                            text: TextSpan(
                                children: [
                                  TextSpan(text: 'Email : ',style: TextStyle(fontSize: 18, color: Colors.black,fontWeight: FontWeight.bold)),
                                  TextSpan(text: '${userData?.email}',style: TextStyle(fontSize: 18, color: Colors.blue,fontWeight: FontWeight.bold)),
                                ]
                            ),
                          ),
                          SizedBox(height: 15,),
                          RichText(
                            text: TextSpan(
                                children: [
                                  TextSpan(text: 'Phone : ',style: TextStyle(fontSize: 18, color: Colors.black,fontWeight: FontWeight.bold)),
                                  TextSpan(text: '${userData?.Phone}',style: TextStyle(fontSize: 18, color: Colors.blue,fontWeight: FontWeight.bold)),
                                ]
                            ),
                          ),
                          SizedBox(height: 15,),
                          RichText(
                            text: TextSpan(
                                children: [
                                  TextSpan(text: 'Status : ',style: TextStyle(fontSize: 18, color: Colors.black,fontWeight: FontWeight.bold)),
                                  TextSpan(text: '${userData?.Status}',style: TextStyle(fontSize: 18, color: Colors.blue,fontWeight: FontWeight.bold)),
                                ]
                            ),
                          ),
                          SizedBox(height: 15,),
                          RichText(
                            text: TextSpan(
                                children: [
                                  TextSpan(text: 'About Me : ',style: TextStyle(fontSize: 18, color: Colors.black,fontWeight: FontWeight.bold)),
                                  TextSpan(text: '${userData?.AboutMe}',style: TextStyle(fontSize: 18, color: Colors.blue,fontWeight: FontWeight.bold)),
                                ]
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 70,),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
                          return Chat_Screen(Chat_User: userData!.uid);
                        }));
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        primary: Colors.blue,  // Background color
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                      ),
                      child: Text('Chat now',
                      style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.bold),),
                    ),
                    SizedBox(height: 50,)
                  ],
                ),
              ),
            ),
          );
        });
  }
}