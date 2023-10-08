import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:swift_talk/Constants/status_dropdown.dart';
import 'package:swift_talk/Models/user.dart';
import 'package:swift_talk/Services/database.dart';

import '../Loading/loading_Screen.dart';

class Profile_Screen extends StatefulWidget {
  const Profile_Screen({super.key});

  @override
  State<Profile_Screen> createState() => _Profile_ScreenState();
}

class _Profile_ScreenState extends State<Profile_Screen> {

  File ?profilepic = null;
  String currentStatus = 'Away';
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController statusController = TextEditingController();
  TextEditingController aboutMeController = TextEditingController();
  bool _dataFetched = false;
  bool _savingData = false;
  bool initializeDone = false;
  bool profileUpdated = false;
  String error = '';
  //Functions

  Future<bool> saveData(UserData userData, Current_User user) async {
    // Check if the phone number is unique before updating
    bool isPhoneNumberUnique = await isUniquePhoneNumber(phoneController.text, user.uid);

    if (!isPhoneNumberUnique) {
      // Handle the case where the phone number is not unique
      print('Phone number is not unique.');
      setState(() {
        error = 'Phone number already registered.';
      });
      return false;
    }

    if (profilepic == null || profileUpdated == false) {
      print('if without pic');
      await DataBase_Service(uid: user.uid).updateUserDataWithoutPic(
        nameController.text,
        phoneController.text,
        userData!.email,
        userData!.password,
        currentStatus,
        aboutMeController.text,
        userData.profilePic ?? '',
      );
    } else {
      print('else with pic');
      if (userData.profilePic != null && userData.profilePic.isNotEmpty) {
        print('\n\n\n\n\n\n\n');
        try {
          // Assuming userUid is the UID of the user whose profile picture you want to delete
          String userUid = userData.uid; // Replace with the actual user's UID
          await DataBase_Service(uid: userUid).deleteProfilePictures(userUid);
          print('Old profile pictures for user $userUid deleted successfully.');
        } catch (e) {
          print('Error deleting old profile pictures: $e');
          // Add more detailed error handling here, log the error, etc.
        }
      }

      await DataBase_Service(uid: user.uid).updateUserData(
          nameController.text,
          phoneController.text,
          userData!.email,
          userData!.password,
          currentStatus,
          aboutMeController.text,
          profilepic!
      );
    }
    //await Future.delayed(Duration(seconds: 1));
    return true;
  }


// Function to check if the phone number is unique
  Future<bool> isUniquePhoneNumber(String phoneNumber, String currentUserId) async {
    try {
      // Fetch all user accounts
      List<UserData> allUsers = await DataBase_Service(uid: currentUserId).allUserAccounts.first;

      // Check if the phone number already exists
      return !allUsers.any((user) => user.Phone == phoneNumber);
    } catch (e) {
      print('Error checking phone number uniqueness: $e');
      return false; // Return false in case of an error
    }
  }

  Future<void> downloadAndSaveImage(String pic) async {
    final response = await http.get(Uri.parse(pic));

    if (response.statusCode == 200) {
      final Uint8List bytes = response.bodyBytes;

      // Save the image to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_image.png');
      await tempFile.writeAsBytes(bytes);

      setState(() {
        profilepic = tempFile;
      });
    } else {
      // Handle error
      print("Failed to download image. Status code: ${response.statusCode}");
    }
  }

  Future<void> initializeData(UserData? userData) async {
    print('in function');
    if (userData != null && _dataFetched == false) {
      print('in function if');

      if(initializeDone == false) {
        // Show loading screen
        nameController.text = userData.name ?? '';
        emailController.text = userData.email ?? '';
        phoneController.text = userData.Phone ?? '';
        aboutMeController.text = userData.AboutMe ?? '';
        profilepic = null;

        await downloadAndSaveImage(userData.profilePic);
        print('after download ' + userData.profilePic);
        currentStatus = userData?.Status ?? 'Available';
      }
      initializeDone = true;
      // Introduce a delay of 2 seconds
      await Future.delayed(Duration(seconds: 1));
      // Mark data as fetched, hide loading screen, and show content
      setState(() {
        _dataFetched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<Current_User>(context);
    return StreamBuilder<UserData>(
      stream: DataBase_Service(uid: user.uid).userData,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          UserData? userData = snapshot.data;
          initializeData(userData);
          if (_dataFetched == true && _savingData == false) {
            return Scaffold(
              body: SingleChildScrollView(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 40.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 70.0,),
                        Container(
                          margin: EdgeInsets.all(10.0),
                          child: MaterialButton(
                            onPressed: () async {
                              XFile ? selectedImage = await ImagePicker()
                                  .pickImage(
                                  source: ImageSource.gallery);
                              if (selectedImage != null) {
                                log('Image selected');
                                File convertedFile = File(selectedImage.path);
                                if (convertedFile != null) {
                                  setState(() {
                                    profilepic = convertedFile;
                                  });
                                  profileUpdated = true;
                                  print(
                                      'image updated in profile pic variable');
                                } else {
                                  log('Selected image file does not exist.');
                                }
                              } else {
                                log('No image selected');
                              }
                            },
                            child: CircleAvatar(
                              key: Key(profilepic?.path ?? ''),
                              // Use the file path as the key
                              radius: 70,
                              backgroundImage: (profilepic != null) ? FileImage(
                                  profilepic!) : null,
                              backgroundColor: Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(height: 30,),

                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            hintText: 'Enter your name here',
                            prefixIcon: Icon(Icons.person, color: Colors.blue),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.blue, width: 2.0),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            labelStyle: TextStyle(color: Colors.blue),
                            hintStyle: TextStyle(
                                color: Colors.blue.withOpacity(0.7)),
                          ),
                        ),
                        SizedBox(height: 10.0,),
                        TextField(
                          controller: aboutMeController,
                          decoration: InputDecoration(
                            labelText: 'About me',
                            hintText: 'Enter your details here',
                            prefixIcon: Icon(
                                Icons.details_rounded, color: Colors.blue),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.blue, width: 2.0),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            labelStyle: TextStyle(color: Colors.blue),
                            hintStyle: TextStyle(
                                color: Colors.blue.withOpacity(0.7)),
                          ),
                        ),
                        SizedBox(height: 10.0,),

                        TextField(
                          controller: emailController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email here',
                            prefixIcon: Icon(Icons.email, color: Colors.blue),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.blue, width: 2.0),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            labelStyle: TextStyle(color: Colors.blue),
                            hintStyle: TextStyle(
                                color: Colors.blue.withOpacity(0.7)),
                          ),
                        ),
                        SizedBox(height: 10,),
                        TextField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone',
                            hintText: '03001234567',
                            prefixIcon: Icon(Icons.phone, color: Colors.blue),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.blue, width: 2.0),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            labelStyle: TextStyle(color: Colors.blue),
                            hintStyle: TextStyle(
                                color: Colors.blue.withOpacity(0.7)),
                          ),
                        ),
                        SizedBox(height: 5,),
                        Text(error,
                          style: TextStyle(
                              color: Colors.red
                          ),),
                        SizedBox(height: 5,),
                        StatusDropdown(
                            initialStatus: currentStatus, onStatusChanged: (
                            newStatus) {
                          print('before: $currentStatus');
                          setState(() {
                            currentStatus = newStatus;
                          });
                          print('after: $currentStatus');
                        }),
                        SizedBox(height: 10.0,),
                        ElevatedButton(
                          onPressed: () async {
                            if (userData?.profilePic != null) {
                              setState(() {
                                _savingData = true; // Set loading state to false after saving data
                              });
                              if(await saveData(userData!, user) == true) {
                                Navigator.pop(context);
                              }
                              await Future.delayed(Duration(milliseconds: 500));
                              setState(() {
                                _savingData = false; // Set loading state to false after saving data
                              });
                            } else {
                              // Handle the case where profilepic is null
                              print(
                                  'Profile picture is null. Update not performed.');
                            }
                          },
                          child: Text(
                            'Update',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            primary: Colors.blue,
                            // You can choose a color that fits your theme
                            elevation: 4.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(35),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          } else {
            return Loading_Screen();
          }
        } else {
          return Loading_Screen();
        }
      },
    );
  }
}

