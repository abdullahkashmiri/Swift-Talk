import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swift_talk/Screens/Contact_Profile/Contact_Profile.dart';
import 'package:swift_talk/Screens/Loading/loading_Screen.dart';
import 'package:swift_talk/Services/database.dart';
import '../../Models/user.dart';

class All_Contact_List_Screen extends StatefulWidget {
  const All_Contact_List_Screen({super.key});

  @override
  State<All_Contact_List_Screen> createState() => _All_Contact_List_ScreenState();
}

class _All_Contact_List_ScreenState extends State<All_Contact_List_Screen> {
  List<UserData>? userDataList;
  @override
  bool isPageLoaded = false;
  Widget build(BuildContext context) {
    final Cuser = Provider.of<Current_User>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Directory',
          style: TextStyle(
              color: Colors.white
          ),),
        centerTitle: true,
      ),
      body: Container(
        child: StreamBuilder(
          stream: DataBase_Service(uid: Cuser.uid).allUserAccounts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Loading_Screen(); // Return a loading indicator while waiting for data
            }
            if (snapshot.hasError) {
              print('Error: ${snapshot.error}');
              return Loading_Screen(); // Handle error by showing a loading indicator for now
            }
            if(snapshot.hasData && snapshot.data != null) {
              if(isPageLoaded == false) {
                userDataList = List.from(
                    snapshot.data as Iterable);
                //Excluding current user's account
                userDataList?.removeWhere((user) => user.uid == Cuser.uid);
                isPageLoaded = true;
              }
              return ListView.builder(
                itemBuilder: (context, index) {
                  UserData? userData = userDataList![index];
                  return InkWell(
                    onTap: () {
                      print('Name : ' + userData.name);
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return Contact_Profile_Screen(uid: userData.uid);
                      }));
                    },
                    child: Card(
                      elevation: 5,
                      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      child: ListTile(
                        title: Text(
                          userData.name ?? 'No Name',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          userData.Status ?? 'No Status',
                          style: TextStyle(color: Colors.grey),
                        ),
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(
                            userData?.profilePic ??
                                'https://firebasestorage.googleapis.com/v0/b/swift-talk-co-ab21a.appspot.com/o/Default%2Fprofile_default.png?alt=media&token=473d6feb-a748-490b-9841-3f56ccee7dcb&_gl=1*1rol94l*_ga*NjEwMDgxNjQzLjE2OTQ1MDY4NzY.*_ga_CW55HF8NVT*MTY5NjgwMjI3NC40Mi4xLjE2OTY4MDIzOTMuMTMuMC4w',
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                  );
                },
                itemCount: userDataList?.length ?? 0,
              );

            }
            else {
              return Loading_Screen();
            }
          },
        ),
      ),
    );
  }
}
