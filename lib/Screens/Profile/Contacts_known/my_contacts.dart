import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swift_talk/Screens/Loading/loading_Screen.dart';
import 'package:swift_talk/Services/database.dart';
import '../../../Models/user.dart';
class Phone_Directory_Screen extends StatefulWidget {
  const Phone_Directory_Screen({Key? key}) : super(key: key);

  @override
  _Phone_Directory_ScreenState createState() => _Phone_Directory_ScreenState();
}

class _Phone_Directory_ScreenState extends State<Phone_Directory_Screen> {
  TextEditingController phoneNumberController = TextEditingController();
  String error = '';
  bool isUploading = false;

  //Functions

  Future<bool> isUniquePhoneNumber(String phoneNumber, String currentUserId) async {
    try {
      // Fetch all user phone numbers
      List<String> allPhoneNumbers = await DataBase_Service(uid: currentUserId).getPhoneNumbersOfContact();

      // Check if the phone number already exists
      return !allPhoneNumbers.contains(phoneNumber);
    } catch (e) {
      return false; // Return false in case of an error
    }
  }


  Future<bool> isNumberAlreadyExists(Current_User user) async {
    bool isPhoneNumberUnique = await isUniquePhoneNumber(phoneNumberController.text, user.uid);
    if (!isPhoneNumberUnique) {
      // Handle the case where the phone number is not unique
      setState(() {
        error = 'Phone number already registered.';
      });
      return false;
    }
    setState(() {
      error = '';
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<Current_User?>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Contacts'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<String>>(
        stream: DataBase_Service(uid: user!.uid).getPhoneNumbers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Loading_Screen();
          }

          List<String> phoneNumbers = snapshot.data ?? [];

          if(isUploading == true) {
            return Loading_Screen();
          } else {
            return SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 30,),
                    Center(
                      child: Text(
                        'Add Phone Numbers',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 10,),
                    Card(
                      child: Container(
                        height: 400,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: phoneNumbers.length,
                          itemBuilder: (context, index) {
                            String phoneNumber = phoneNumbers[index];
                            return ListTile(
                              title: Text(phoneNumber),
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () async {
                                  setState(() {
                                    isUploading = true;
                                  });
                                  // Delete the phone number
                                  await DataBase_Service(uid: user.uid)
                                      .deletePhoneNumber(phoneNumber);
                                  setState(() {
                                    isUploading = false;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Card(
                      child: Column(
                        children: [
                          Text(error, style: TextStyle(
                              color: Colors.red
                          ),),
                          TextField(
                            controller: phoneNumberController,
                            decoration: InputDecoration(
                              labelText: 'Add Phone Number',
                              hintText: '03001234567',
                              prefixIcon: Icon(Icons.phone, color: Colors.blue),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () async {
                                  setState(() {
                                    isUploading = true;
                                  });
                                  // Add the phone number
                                  if (phoneNumberController.text.isNotEmpty) {
                                    if (await isNumberAlreadyExists(user) == true) {
                                      await DataBase_Service(uid: user.uid)
                                          .addPhoneNumber(phoneNumberController.text);
                                      phoneNumberController.clear();
                                    }
                                  }
                                  setState(() {
                                    isUploading = false;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
