import 'dart:io';

class Current_User {
  //Variables
  final String uid;
  //Functions
Current_User({required this.uid});
}

class UserData {
  //Variables
  final String uid;
  String name;
  final String email;
  final String password;
  String Phone;
  String Status;
  String AboutMe;
  String profilePic;
  //Functions
  UserData({required this.uid, required this.name, required this.email, required this.password, required this.AboutMe, required this.Phone, required this.Status, required this.profilePic});
}