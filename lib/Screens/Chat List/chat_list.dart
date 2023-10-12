import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swift_talk/Models/user.dart';
import 'package:swift_talk/Screens/Authentication/Sign%20In/sign_in_screen.dart';
import 'package:swift_talk/Screens/Chat/chat.dart';
import 'package:swift_talk/Screens/Contact%20List/contact_list.dart';
import 'package:swift_talk/Screens/Loading/loading_Screen.dart';
import 'package:swift_talk/Screens/Profile/Contacts_known/my_contacts.dart';
import 'package:swift_talk/Screens/Profile/profile.dart';
import 'package:swift_talk/Services/database.dart';
import '../../Services/auth.dart';
import 'package:intl/intl.dart';


class Chat_List extends StatefulWidget {
  const Chat_List({Key? key}) : super(key: key);

  @override
  State<Chat_List> createState() => _Chat_ListState();
}

class _Chat_ListState extends State<Chat_List> {
  final Auth_Service _auth = Auth_Service();
  bool isLoggingOut = false;
  bool isSigningOut = false;
  void signOut() async {
    setState(() {
      isLoggingOut = true;
    });
    await Future.delayed(Duration(seconds: 2));
    await _auth.signOut();
    setState(() {
      isLoggingOut = false;
    });
  }

  String formatDate(DateTime dateTime) {
    // Replace this with your actual date formatting logic
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {

    final user = Provider.of<Current_User>(context);
    if (isLoggingOut == false) {
      return Scaffold(
        backgroundColor: Colors.white70,

        appBar: AppBar(
          title: Text('Swift Talk',style: TextStyle(fontWeight: FontWeight.bold),),
          leading: IgnorePointer(
            ignoring: isSigningOut,
            child: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  icon: Icon(
                    Icons.account_circle,
                    size: 40.0,
                  ),
                );
              },
            ),
          ),
          actions: [
            IgnorePointer(
              ignoring: isSigningOut,
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Phone_Directory_Screen()),
                  );
                },
                icon: Icon(Icons.contacts),
              ),
            ),
            IgnorePointer(
              ignoring: isSigningOut,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    isSigningOut = true;
                  });
                },
                icon: Icon(Icons.logout),
              ),
            ),
          ],
        ),
        drawer: MyDrawer(userId: user.uid,),

        body: Stack(
          children: [
            IgnorePointer(
              ignoring: isSigningOut,
              child: Center(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: DataBase_Service(uid: user.uid).getDirectChats(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Loading_Screen();
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (snapshot.hasData && snapshot.data != null) {
                      var querySnapshot = snapshot.data as QuerySnapshot<Map<String, dynamic>>;

                      var documents = querySnapshot.docs; // List of QueryDocumentSnapshot

                      documents.sort((a, b) {
                        var timeA = UserChatListData.fromMap(a.data(), user.uid).lastMessageSentAt;
                        var timeB = UserChatListData.fromMap(b.data(), user.uid).lastMessageSentAt;
                        return timeB.compareTo(timeA);
                      });

                      if (documents.isNotEmpty) {
                        return ListView.builder(
                          itemCount: documents.length,
                          itemBuilder: (context, index) {
                            var chatUserData = UserChatListData.fromMap(documents[index].data(), user.uid);
                            bool isUnread = chatUserData.isChatRead != 0; // Check if the chat is unread
                            int unReadMessages = chatUserData.isChatRead;

                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.5),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50.0)
                              ),
                              child: ListTile(
                                tileColor: isUnread ? Colors.blue[50] : Colors.white, // Set background color for unread messages
                                leading: CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: NetworkImage(chatUserData.userImage),
                                ),
                                title: Padding(
                                  padding: const EdgeInsets.fromLTRB(0, 8.0, 0, 0),
                                  child: Text(
                                    chatUserData.userName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                                subtitle: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 10,),
                                    Container(
                                      height: 30, // Adjust the height as needed
                                      child: Text(
                                        chatUserData.lastMessageText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if(unReadMessages != 0)
                                      CircleAvatar(
                                        child: Text('$unReadMessages', style: TextStyle(color: Colors.white,),),
                                        radius: 15,
                                        backgroundColor: Colors.blue,
                                      ),
                                    if(unReadMessages == 0)
                                      SizedBox(height: 10,),
                                    SizedBox(height: 2,),
                                    Text(
                                      ' • ${formatTimestamp(chatUserData.lastMessageSentAt)}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  // Handle onTap event
                                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                                    return Chat_Screen(chatId: chatUserData.chatId, chatUserId: chatUserData.userId, thisUserIdd: user.uid,);
                                  }));
                                },
                              ),
                            );


                          },
                        );
                      } else {
                        return Text('No directChats found.');
                      }
                    } else {
                      return Loading_Screen();
                    }
                  },
                ),



              ),
            ),
            // Centered container
            Positioned.fill(
              child: Opacity(
                opacity: isSigningOut ? 1.0 : 0.0,
                child: Center(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 30.0),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.0)
                    ),
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 5.0,),
                        Text(
                          'Are you sure you want to Sign Out',
                          style: TextStyle(fontSize: 16.0),
                        ),
                        SizedBox(height: 20.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(minWidth: 100.0), // Set your desired width
                              child: ElevatedButton(
                                onPressed: () {
                                  print('no');
                                  setState(() {
                                    isSigningOut = false;
                                  });
                                },
                                child: Text('No',
                                ),
                              ),
                            ),
                            SizedBox(width: 20.0),
                            ConstrainedBox(
                              constraints: BoxConstraints(minWidth: 100.0), // Set your desired width
                              child: ElevatedButton(
                                onPressed: () {
                                  print('signing out');
                                  signOut();
                                  Navigator.popUntil(context, (route) => route.isFirst);
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignIn_Screen()));
                                },
                                child: Text('Sign Out',),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red
                                ),
                              ),
                            ),
                          ],
                        )

                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20.0,
              right: 16.0,
              child: IgnorePointer(
                ignoring: isSigningOut,
                child: FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return Contact_List_Screen();
                        }),
                      );
                    },
                    child: Icon(Icons.message_rounded)
                ),
              ),
            ),

          ],
        ),
      );
    } else
      return Loading_Screen();
  }
}
String formatTimestamp(DateTime timestamp) {
  DateTime now = DateTime.now();
  DateTime today = DateTime(now.year, now.month, now.day);

  if (timestamp.isAfter(today)) {
    // Message is from today, display time
    return DateFormat.jm().format(timestamp);
  } else {
    // Message is from a different day, display date
    return DateFormat('yyyy-MM-dd').format(timestamp);
  }
}

// ignore: must_be_immutable
class MyDrawer extends StatefulWidget {
  String userId;
  MyDrawer({super.key, required this.userId});
  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  late String userId;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    userId = widget.userId;
  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: DataBase_Service(uid: userId).userData,
      builder: (context,AsyncSnapshot<UserData> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Loading_Screen();
        }
        if (snapshot.hasError) {
          return Text('Error in fetching data: ${snapshot.error}');
        }
        if (snapshot.data == null) {
          return Text('No Data Found');
        }
        UserData? userData = snapshot.data;

        return Drawer(
          child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(
                          userData?.profilePic ?? 'https://firebasestorage.googleapis.com/v0/b/swift-talk-co-ab21a.appspot.com/o/Default%2Fprofile_default.png?alt=media&token=473d6feb-a748-490b-9841-3f56ccee7dcb&_gl=1*21nz2g*_ga*NjEwMDgxNjQzLjE2OTQ1MDY4NzY.*_ga_CW55HF8NVT*MTY5NzMwOTE2OC42Ni4xLjE2OTczMDkxODIuNDYuMC4w',
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        userData?.name ?? '',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30.0,),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 10.0),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(child: Text('Account Details',
                    style: TextStyle(
                        fontSize: 24.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                    ),)),
                ),
              ),
              SizedBox(height: 10.0,),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.phone,color: Colors.blue,
                        size: 30.0,),
                      title: RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Phone: ',
                              style: TextStyle(color: Colors.black),
                            ),
                            TextSpan(
                              text: '${userData?.Phone}',
                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.email,color: Colors.blue,
                        size: 30.0,),
                      title: RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: <TextSpan>[
                            const TextSpan(
                              text: 'Email: ',
                              style: TextStyle(color: Colors.black),
                            ),
                            TextSpan(
                              text: '${userData?.email}' ,
                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.person,color: Colors.blue,
                        size: 30.0,),
                      title: RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: <TextSpan>[
                            TextSpan(
                              text: 'About Me: ',
                              style: TextStyle(color: Colors.black),
                            ),
                            TextSpan(
                              text: '${userData?.AboutMe}', // Make sure to use the correct property name
                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.info_outline,
                        color: Colors.blue,
                        size: 30.0,),
                      title: RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Status: ',
                              style: TextStyle(color: Colors.black),
                            ),
                            TextSpan(
                              text: '${userData?.Status}' , // Make sure to use the correct property name
                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30.0,),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) {
                              return Profile_Screen();
                            }));
                          },
                          child: Text('Update Account',
                            style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold
                            ),)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}