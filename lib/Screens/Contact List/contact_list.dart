import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swift_talk/Screens/Contact%20List/all_contacts.dart';
import 'package:swift_talk/Screens/Contact_Profile/Contact_Profile.dart';
import 'package:swift_talk/Screens/Loading/loading_Screen.dart';
import 'package:swift_talk/Services/database.dart';
import '../../Models/user.dart';

class Contact_List_Screen extends StatefulWidget {
  const Contact_List_Screen({super.key});

  @override
  State<Contact_List_Screen> createState() => _Contact_List_ScreenState();
}

class _Contact_List_ScreenState extends State<Contact_List_Screen> {
  bool isPageLoaded = false;
  List<UserData>? userDataList;

  //Functions

  @override
  Widget build(BuildContext context) {
    final Cuser = Provider.of<Current_User>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Contacts',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
                  return All_Contact_List_Screen();
                }));
              },
              icon: Icon(Icons.contact_page))
        ],
      ),
      body: StreamBuilder<List<String>>(
        stream: DataBase_Service(uid: Cuser.uid).getPhoneNumbers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Loading_Screen(); // Return a loading indicator while waiting for data
          }
          if (snapshot.hasError) {
            return Loading_Screen(); // Handle error by showing a loading indicator for now
          }

          List<String>? userPhoneNumbers = snapshot.data;

          if (userPhoneNumbers == null || userPhoneNumbers.isEmpty) {
            return Center(child: Text('No Contacts Found!\nAdd Contacts or Browse Directory.',
            style: TextStyle(color: Colors.blue, fontSize: 16.0),
            textAlign: TextAlign.center,));
          }
          return StreamBuilder<List<UserData>>(
            stream: DataBase_Service(uid: Cuser.uid).allUserAccounts,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Loading_Screen(); // Return a loading indicator while waiting for data
              }
              if (snapshot.hasError) {
                return Loading_Screen(); // Handle error by showing a loading indicator for now
              }
              if (snapshot.hasData && snapshot.data != null) {
                if(isPageLoaded == false) {
                  userDataList = List.from(
                      snapshot.data as Iterable);

                  // Excluding current user's account
                  userDataList?.removeWhere((user) => user.uid == Cuser.uid);

                  // Filter user data based on phone numbers
                  userDataList?.retainWhere((user) =>
                  userPhoneNumbers?.contains(user.Phone) ?? false);
                  isPageLoaded = true;
                }
                return ListView.builder(
                  itemBuilder: (context, index) {
                    UserData? userData = userDataList![index];
                    if(userData.Phone != '')
                      return InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) {
                          return Contact_Profile_Screen(uid: userData.uid, id: 0,);// 0 as default to start chat
                        }));
                      },
                      child: Card(
                        elevation: 5,
                        margin: EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        child: ListTile(
                          title: Text(
                            userData.name,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            userData.Status,
                            style: TextStyle(color: Colors.grey),
                          ),
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(
                              userData.profilePic,
                            ),
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      ),
                    );
                    return null;
                  },
                  itemCount: userDataList?.length ?? 0,
                );
              } else {
                return Loading_Screen();
              }
            },
          );
        },
      ),
    );
  }
}
