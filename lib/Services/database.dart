import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../Models/user.dart';
class DataBase_Service {
  final String uid;

  DataBase_Service({required this.uid});

  //collection reference
  final CollectionReference accountsCollection = FirebaseFirestore.instance
      .collection(('accounts'));
  final CollectionReference contactsCollection = FirebaseFirestore.instance
      .collection(('contacts'));

  Future<bool> updateUserData(String name, String phone, String email, String password, String status, String aboutMe, File profilePic) async {
    try {
      if (!profilePic.existsSync()) {
        log('Error: Profile picture file does not exist.');
        return false;
      }

      print('Uploading profile picture...');
      UploadTask uploadTask = FirebaseStorage.instance.ref().child(
          'profilePictures').child(uid).child(Uuid().v1()).putFile(profilePic);

      await uploadTask.whenComplete(() async {
        print('Profile picture uploaded successfully.');
        try {
          TaskSnapshot taskSnapshot = await uploadTask;
          String downloadUrl = await taskSnapshot.ref.getDownloadURL();

          print('Updating Firestore...');
          await accountsCollection.doc(uid).set({
            'name': name,
            'Phone': phone,
            'email': email,
            'password': password,
            'Status': status,
            'AboutMe': aboutMe,
            'profilePic': downloadUrl,
          });

          print('Firestore update successful.');
        } catch (e) {
          log('Error updating Firestore: $e');
          return false; // Return false if there's an error updating Firestore
        }
      }).catchError((e) {
        log('Error during file upload: $e');
        return false; // Return false if there's an error during file upload
      });

      // Return true only if everything is successful
      return true;
    } catch (e) {
      log('Error updating user data: $e');
      return false;
    }
  }


  Future<bool> updateUserDataWithoutPic(String name, String phone, String email,
      String password, String status, String aboutMe,
      String downloadUrl) async {
    try {
      print('Updating Firestore...');
      await accountsCollection.doc(uid).set({
        'name': name,
        'Phone': phone,
        'email': email,
        'password': password,
        'Status': status,
        'AboutMe': aboutMe,
        'profilePic': downloadUrl,
      });

      // This return statement is outside the whenComplete block
      return true; // Success flag
    } catch (e) {
      log('Error updating user data: $e');
      return false;
    }
  }

  //Getting user data from snapshot
  UserData _userDataFromSnapshot(DocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
    return UserData(
        uid: data?['uid'] ?? uid,
        name: data?['name'],
        email: data?['email'],
        password: data?['password'],
        AboutMe: data?['AboutMe'],
        Phone: data?['Phone'],
        Status: data?['Status'],
        profilePic: data?['profilePic']
    );
  }

  // function to deelete a profile picture
  Future<void> deleteProfilePictures(String userUid) async {
    try {
      // Creating a reference to the user's profile pictures folder
      Reference folderRef = FirebaseStorage.instance.ref().child('profilePictures').child(userUid);

      // List all items (profile pictures) in the folder
      ListResult result = await folderRef.listAll();

      // Delete each item in the folder
      await Future.forEach(result.items, (Reference itemRef) async {
        await itemRef.delete();
      });

      // After deleting all profile pictures, delete the folder itself
      await folderRef.delete();

      print('Profile pictures for user $userUid deleted successfully.');
    } catch (e) {
      print('Error deleting profile pictures: $e');
      throw e; // Rethrow the exception to handle it at a higher level if needed
    }
  }

// Function to delete user data
  Future<void> deleteUserData() async {
    try {
      await FirebaseStorage.instance.ref().child('profilePictures')
          .child(uid)
          .delete();
      await accountsCollection.doc(uid).delete();
      log('User data deleted successfully.');
    } catch (e) {
      log('Error deleting user data: $e');
      throw e; // Rethrow the exception to handle it at a higher level if needed
    }
  }

  //get user doc stream
  Stream<UserData> get userData {
    return accountsCollection.doc(uid).snapshots().map((snapshot) {
      print('Snapshot data: ${snapshot.data()}');
      return _userDataFromSnapshot(snapshot);
    });
  }

  //get all contacts data

  UserData _userDataFromSnapshotAllAccounts(DocumentSnapshot<Object?> snapshot) {
    Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

    String uid = snapshot.id; // Use this to get the document ID as UID

    return UserData(
      uid: uid,
      name: data?['name'],
      email: data?['email'],
      password: data?['password'],
      AboutMe: data?['AboutMe'],
      Phone: data?['Phone'],
      Status: data?['Status'],
      profilePic: data?['profilePic'],
    );
  }

  Stream<List<UserData>> get allUserAccounts {
    return accountsCollection.snapshots().map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return _userDataFromSnapshotAllAccounts(doc);
      }).toList();
    });
  }

  // adding phone numbers
  Future<void> addPhoneNumber(String phoneNumber) async {
    try {
      await accountsCollection.doc(uid).collection('phoneNumbers').add({
        'phoneNumber': phoneNumber,
      });
    } catch (e) {
      log('Error adding phone number: $e');
      throw e;
    }
  }

  Stream<List<String>> getPhoneNumbers() {
    try {
      return FirebaseFirestore.instance
          .collection('accounts')
          .doc(uid)
          .collection('phoneNumbers')
          .snapshots()
          .map((querySnapshot) {
        return querySnapshot.docs
            .map((doc) => doc['phoneNumber'].toString())
            .toList();
      });
    } catch (e) {
      print('Error getting phone numbers: $e');
      return Stream<List<String>>.empty();
    }
  }

  Future<void> deletePhoneNumber(String phoneNumber) async {
    try {
      await accountsCollection.doc(uid)
          .collection('phoneNumbers')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          doc.reference.delete();
        });
      });
    } catch (e) {
      log('Error deleting phone number: $e');
      throw e;
    }
  }

  //getting phonenumbers of particuler person
  Future<List<String>> getPhoneNumbersOfContact() async {
    try {
      var result = await FirebaseFirestore.instance
          .collection('accounts')
          .doc(uid)
          .collection('phoneNumbers')
          .get();

      List<String> phoneNumbers = [];

      for (var document in result.docs) {
        phoneNumbers.add(document['phoneNumber'].toString());
      }

      return phoneNumbers;
    } catch (e) {
      print('Error getting phone numbers: $e');
      throw e;
    }
  }



}