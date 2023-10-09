import 'package:flutter/material.dart';

class Chat_Screen extends StatefulWidget {

  String Chat_User;
  Chat_Screen({required this.Chat_User});
  @override
  State<Chat_Screen> createState() => _Chat_ScreenState();
}

class _Chat_ScreenState extends State<Chat_Screen> {
  late final String chatUserUid;

  //Functions
  void initState() {
    super.initState();
    // Initialize the values in initState
    chatUserUid = widget.Chat_User;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
      ),
    );
  }
}
