import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:swift_talk/Constants/constants.dart';
import 'package:swift_talk/Services/database.dart';
import 'package:swift_talk/main.dart';
import 'package:swift_talk/Models/user.dart';
import 'package:path_provider/path_provider.dart';


class Auth_Service {
  //creating and authentication instance for user
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //creating a user object on firebase user
  Current_User? _userFromFirebaseUser(User? user) {
    return user != null ? Current_User(uid: user.uid) : null;
  }
  //auth change user stream
  //Sending user status to stream in main for checking if he/she is either
  //either signed in or not
  Stream<Current_User?> get user {
    return _auth.authStateChanges().map((User? user) => _userFromFirebaseUser(user!));
  }
  //Sign In using EMAIL & PASSWORD
  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return _userFromFirebaseUser(user!);
    } catch (e) {
      log('Error Signing In User $e');
      var errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '');
      Global_error = errorMessage;
      return null;
    }
  }

  // //Sign Up using EMAIL & PASSWORD
  // Future signUpWithEmailAndPassword(String email, String password) async {
  //   try {
  //     UserCredential result = await _auth.createUserWithEmailAndPassword(
  //         email: email, password: password);
  //     User? user = result.user;
  //     //Create a new Record of User in DataBase
  //     File imageFile = await copyAssetToFile('assets/images/add_photo.jpg', 'path_in_local_file_system.jpg');
  //     await DataBase_Service(uid: user!.uid).updateUserData('name', '03001234567',email,  password, 'Available', 'Hey there, Lets talk swiftly', imageFile);
  //     return _userFromFirebaseUser(user!);
  //   } catch (e) {
  //     log('Error Signing Up User $e');
  //     var errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '');
  //     Global_error = errorMessage;
  //     return null;
  //   }
  // }

  //Sign Up using EMAIL & PASSWORD
  Future signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      // Create a new Record of User in DataBase
      File imageFile = await copyAssetToFile('assets/images/profile_default.png', 'path_in_local_file_system.jpg');

      // Attempt to update user data in the database
      bool updateSuccess = await DataBase_Service(uid: user!.uid)
            .updateUserData(
          'name',
          '',
          email,
          password,
          'Available',
          'Hey there, Lets talk swiftly',
          imageFile,
        );

      print('update status $updateSuccess');
      if (updateSuccess) {
        return _userFromFirebaseUser(user);
      } else {
        // If updating user data fails, delete the user
        await _auth.currentUser?.delete();
        var errorMessage = 'Failed to create an Account';
        Global_error = errorMessage;
        return null;
      }
    } catch (e) {
      log('Error Signing Up User $e');
      var errorMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '');
      Global_error = errorMessage;
      return null;
    }
  }



  // Signing Out
  Future signOut() async {
    try {
      return _auth.signOut();
    } catch (e) {
      print('Error signing out : $e');
      return null;
    }
  }

  //Copying Assets path

  Future<File> copyAssetToFile(String assetPath, String targetFileName) async {
    ByteData data = await rootBundle.load(assetPath);
    List<int> bytes = data.buffer.asUint8List();

    // Get the directory for the app's documents
    Directory appDocDir = await getApplicationDocumentsDirectory();

    // Create a new file in the app documents directory
    File file = File('${appDocDir.path}/$targetFileName');

    // Write the bytes to the file
    await file.writeAsBytes(bytes);

    return file;
  }



}