import 'package:flutter/material.dart';
import 'package:swift_talk/Screens/Chat List/chat_list.dart';
import 'package:swift_talk/Screens/Authentication/Sign In/sign_in_screen.dart';
import 'package:provider/provider.dart';
import 'package:swift_talk/Models/user.dart';

class Wrapper_Screen extends StatelessWidget {
  const Wrapper_Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<Current_User?>(context);
    if(user == null)
      return SignIn_Screen();
    else
      return Chat_List();
  }
}
