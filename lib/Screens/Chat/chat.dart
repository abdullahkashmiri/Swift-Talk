import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:swift_talk/Models/user.dart';
import 'package:swift_talk/Screens/Contact_Profile/Contact_Profile.dart';
import 'package:swift_talk/Screens/Loading/loading_Screen.dart';
import 'package:swift_talk/Services/database.dart';


// ignore: must_be_immutable
class Chat_Screen extends StatefulWidget {

  String chatId;
  String chatUserId;
  String thisUserIdd;
  Chat_Screen({required this.chatId, required this.chatUserId, required this.thisUserIdd});
  @override
  State<Chat_Screen> createState() => _Chat_ScreenState();
}
bool isMessageReplying = false; // is this user replying for the message used for when system back button is pressed it checks for either to return or remove replymessage interfacs

class _Chat_ScreenState extends State<Chat_Screen> {
  late final String chatId;
  late String chatUserUid;
  late String thisUserIdd;
  late String currentUserName;
  late String chatUserName;
  bool isLoadingScreen = false;
   //Functions
  @override
  void initState() {
    super.initState();
    // Initialize the values in initState
    chatId = widget.chatId;
    thisUserIdd = widget.thisUserIdd;
    chatUserUid = widget.chatUserId;
  }

  void didChangeDependencies() {
    super.didChangeDependencies();

    // Move the provider-dependent initialization here
    if (thisUserIdd == chatUserUid)
      return;
    DataBase_Service(uid: thisUserIdd).updateChatInfoMessagesReadOnChatOpen(
        chatId, chatUserUid);
  }

  Future<void> closeScreen(String uid) async {
    await DataBase_Service(uid: uid).updateChatInfoMessagesReadOnChatClose(
        chatId, chatUserUid);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<Current_User>(context);

    return WillPopScope(
      onWillPop: () async {
        if (isMessageReplying == true) {
          setState(() {
            isMessageReplying = false;
          });
          return false;
        } else {
          await closeScreen(user.uid);
          return true;
        }
      },
      child: FutureBuilder<DocumentSnapshot<Object?>?>(
        future: DataBase_Service(uid: user.uid).getChatInfo(chatId),
        //Sending Chat Info only of a particular chat id from Chats
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Loading_Screen();
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (snapshot.hasData && snapshot.data != null) {
            if (snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              var candidateId1 = data['candidate1'];
              var candidateId2 = data['candidate2'];

              if (candidateId1 == null || candidateId2 == null) {
                // Handle the case where 'candidate1' or 'candidate2' is null
                return Text('Candidate ID not found');
              }

              String chatUserUid;
              int userType;
              if (candidateId1 == user.uid) {
                currentUserName = data['thisUserName'];
                chatUserName = data['chatUserName'];
                chatUserUid = candidateId2;
                userType = 2; // use chat to fetch data
              } else {
                currentUserName = data['chatUserName'];
                chatUserName = data['thisUserName'];
                chatUserUid = candidateId1;
                userType = 1; // use this to fetch data
              }
              return FutureBuilder(
                  future: DataBase_Service(uid: chatUserUid).userDataFuture,
                  builder: (context, chatUserSnapshot) {
                    if (chatUserSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Loading_Screen();
                    }
                    if (chatUserSnapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    // Check if chatUserSnapshot data is null
                    if (chatUserSnapshot.data == null) {
                      // Handle the case where chat user data is null
                      return Text('Chat user data is null');
                    }
                    if (chatUserSnapshot.hasData &&
                        chatUserSnapshot.data != null) {
                      var chatUserData = chatUserSnapshot.data;
                     if(isLoadingScreen)
                       return Loading_Screen();
                     else {
                       return Scaffold(
                        appBar: AppBar(
                          title: InkWell(
                            onTap: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                    return Contact_Profile_Screen(
                                        uid: chatUserUid, id: 1);
                                  }));
                            },
                            child:  Text(chatUserData!.name),
                          ),
                          leading: InkWell(
                            onTap: () async {
                              await DataBase_Service(uid: user.uid)
                                  .updateChatInfoMessagesReadOnChatClose(
                                  chatId, chatUserUid);
                              Navigator.pop(context);

                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_back, size: 22.0,),
                                CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: NetworkImage(
                                      chatUserData!.profilePic),
                                  radius: 17,
                                ),

                              ],

                            ),
                          ),
                          actions: [
                              PopupMenuButton<String>(
                              onSelected: (value) async {
                                // Handle the selected option
                                if (value == 'viewContact') {
                                  // Do something for Item 1
                                  setState(() {
                                    isLoadingScreen = true;
                                  });
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                        return Contact_Profile_Screen(
                                            uid: chatUserUid, id: 1);
                                      }));
                                  setState(() {
                                    isLoadingScreen = false;
                                  });
                                }
                                else if (value == 'deleteMessages') {
                                  // Do something for Item 1
                                  setState(() {
                                    isLoadingScreen = true;
                                  });
                                  await DataBase_Service(uid: user.uid)
                                      .deleteDirectChatAllMessagesForMe(chatId);
                                  setState(() {
                                    isLoadingScreen = false;
                                  });
                                } else if (value == 'deleteWholeChat') {
                                  Navigator.pop(context);
                                  if (await DataBase_Service(uid: user.uid)
                                      .deleteDirectChat(
                                      user.uid, chatUserUid, chatId) == true) {
                                  }
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'viewContact',
                                  child: Text('View Contact'),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'deleteMessages',
                                  child: Text('Clear Chat Messages'),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'deleteWholeChat',
                                  child: Text('Exit Chat'),
                                ),
                              ],
                            ),
                          ],
                        ),
                         backgroundColor: Colors.blue.shade50,
                        body: Chat_Widget(
                          currentUser: user.uid,
                          chatId: chatId,
                          ChatUserId: chatUserUid,
                          userType: userType,
                          currentUserName: currentUserName,
                          chatUserName: chatUserName,
                        ),
                      );
                     }
                    } else {
                      return Loading_Screen();
                    }
                  });
            } else {
              return Text('Document does not exist');
            }
          } else {
            return Text('No Record Found');
          }
        },
      ),
    );
  }
}


 class Chat_Widget extends StatefulWidget {
  String currentUser;
  String chatId;
  String ChatUserId;
  int userType;
  String currentUserName;
  String chatUserName;

  Chat_Widget(
      {required this.currentUser, required this.chatId, required this.ChatUserId, required this.userType, required this.currentUserName, required this.chatUserName});

  @override
  State<Chat_Widget> createState() => _Chat_WidgetState();
}

class _Chat_WidgetState extends State<Chat_Widget> {
  TextEditingController messageController = TextEditingController();
  String message = '';
  String currentUserId = '';
  String chatId = '';
  String ChatUserId = '';
  int userType = 0;
  String replyingMessageText = '';
  late Map<String, dynamic> messageDocument; // this is sent back to SEND-MESSAGE function
  Timestamp timestamp = Timestamp.now();
  late Map<String, dynamic> Message;
  late String currentUserName;
  late String chatUserName;
  bool isLongPressed = true;
  bool showSecondDialogsIcons = false;
  bool isDeletingDialog = false;
  File ?uploadPic = null;
  bool isImageSelected = false;
  bool isLoading = false;


  int indexSd = 0;
  int lastMessageIndexSd = 0;
  bool isLastMessageSd = false;
  Timestamp sentAtSd = Timestamp.now();
  String senderIdSd = '';
  String docIdSd = '';
  String lastMessageIdSd = '';
  late Map<String, dynamic> lastMessageDocSd;
  bool isDataOkayForDelete = false;
  bool isImageExistSd = false;
  String imageSd = '';
  @override

  void initState() {
    // TODO: implement initState
    super.initState();
    currentUserId = widget.currentUser;
    chatId = widget.chatId;
    ChatUserId = widget.ChatUserId;
    userType = widget.userType;
    Message = {
      'senderId': '',
      'sentAt': timestamp,
      'text': '',
    };
    messageDocument = Message;
    currentUserName = widget.currentUserName;
    chatUserName = widget.chatUserName;
  }

  // dataMembers for popUp of delete Message
  bool storeData(int index, int lastMessageIndex, String lastMessageId, bool isLastMessage, Timestamp sentAt, String senderId, String docId,
      Map<String, dynamic> lastMessageDoc, String messageText, String imageUrl, bool isImageExist) {
    try {
      messageDocument = {
        'senderId': senderId,
        'sentAt': sentAt,
        'text': messageText,
        'image': imageUrl,
        'isImageExist': isImageExist,
      };
      isImageExistSd = isImageExist;
      imageSd = imageUrl;
      print(isImageExistSd);
      indexSd = index;
      lastMessageIndexSd = lastMessageIndex;
      isLastMessageSd = isLastMessage;
      sentAtSd = sentAt;
      senderIdSd = senderId;
      docIdSd = docId;
      lastMessageIdSd = lastMessageId;
      lastMessageDocSd = lastMessageDoc;
      replyingMessageText = messageText;
      print('data updated');
      return true;
    } catch (e) {
      print('Error in storing data for delete: $e');
      return false;
    }
  }

  Future<bool> deleteMessageForMe(bool isDataOkay) async {
    try {
      if(isDataOkay) {
      if (await DataBase_Service(
          uid: currentUserId)
          .deleteDirectChatMessageForMe(
          currentUserId,
          ChatUserId,
          chatId,
          sentAtSd,
          senderIdSd,
          docIdSd,
          lastMessageIdSd,
          lastMessageDocSd,
          isLastMessageSd,
      imageSd) == true) {
        print(
            'Message Deleted For Me: $docIdSd');
      }

    }
      return true;
    } catch (e) {
      print('Error Occurred in deleting messages $e');
      return false;
    }
  }
  Future<bool> deleteMessageForEveryOne(bool isDataOkay) async {
    try {
      if(isDataOkay) {
        //for everyone
        if (await DataBase_Service(
            uid: currentUserId)
            .deleteDirectChatMessageForEveryOne(
            currentUserId,
            ChatUserId,
            chatId,
            sentAtSd,
            senderIdSd,
            docIdSd,
            lastMessageIdSd,
            lastMessageDocSd,
            isLastMessageSd,
        imageSd) == true) {
          print(
              'Message Deleted For EveryOne: $docIdSd');
        }
      }
      return true;
    } catch (e) {
      print('Error Occurred in deleting messages $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if(isImageSelected == false) {
      return StreamBuilder(
          stream: DataBase_Service(uid: currentUserId).getMessages(
              chatId, ChatUserId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            };
            if (snapshot.hasData && snapshot.data != null) {
              var documents = snapshot.data!.docs;

              // Find and store the 'chatInfo' document
              var chatInfoDoc = documents.firstWhere((element) =>
              element.id == 'chatInfo');

              //remove chatInfoDoc
              documents.removeWhere((element) => element.id == 'chatInfo');

              // Sort the documents based on the 'sentAt' field
              documents.sort((a, b) {
                var sentAtA = a['sentAt'];
                var sentAtB = b['sentAt'];
                return sentAtB.compareTo(
                    sentAtA); // descending order, adjust as needed
              });

              // Find and store the 'chatInfo' document

              int unReadMessages = 0;
              var status; //checking if is user online or not
              if (userType == 1) {
                unReadMessages = chatInfoDoc['thisUserIsChatRead'];
                status = chatInfoDoc['thisUserOnline'];
              } else if (userType == 2) {
                unReadMessages = chatInfoDoc['chatUserIsChatRead'];
                status = chatInfoDoc['chatUserOnline'];
              }
              String currentStatus;
              var currentStatusColor = Colors.black;
              if (status == 1) {
                currentStatus = 'Online';
                currentStatusColor = Colors.green.shade600.withOpacity(0.7);
              } else {
                currentStatus = 'Offline';
                currentStatusColor = Colors.red.shade600.withOpacity(0.7);
              }

              bool isMessageReplied = false; // has user replied for message
              int isMessageRepliedBy = 0; // check if the message is replied or not
              String lastMessageId = '';
              bool isLastMessage = false;
              Map<String, dynamic> lastMessageDoc = {
                'senderId': '',
                'sentAt': timestamp,
                'text': '',
                'image': '',
                'isImageExist': false,
              };
              int lastMessageIndex = -2;
              bool isLastMessageFound = false;

              return Stack(
                children: [

                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showSecondDialogsIcons = false;
                      });
                    },
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            key: UniqueKey(),
                            reverse: true,
                            itemCount: documents.length,
                            itemBuilder: (context, index) {
                              var docId = documents[index].id;
                              var senderId = documents[index]['senderId'];
                              var sentAt = documents[index]['sentAt'];
                              var messageText = documents[index]['text'];
                              var imageUrl = documents[index]['image'];
                              var isImageExist = documents[index]['isImageExist'];
                              String isDeletedForMe = documents[index]['isMessageDeletedForMe'];
                              //used for printing
                              var replyMessage = documents[index]['replyMessage']; // use this to extract data
                              var replyMessageSenderId = replyMessage['senderId']; // use this for updation UI of screen only
                              var replyMessageSentAt = replyMessage['sentAt'];
                              var replyMessageText = replyMessage['text'];
                              var replyImageUrl = replyMessage['image'];
                              var replyIsImageExist = replyMessage['isImageExist'];

                              print(messageText);
                              print(imageUrl);
                              isMessageReplied = false; // checking if there is any reply of text or not
                              var replyUserName = '';
                              if (replyMessageText != '') {
                                // there exists a reply in this text then show in chat screen
                                isMessageReplied = true;
                                if (replyMessageSenderId ==
                                    currentUserId) { //message origin was of current user
                                  isMessageRepliedBy = 1;
                                  replyUserName = 'You';
                                } else if (replyMessageSenderId ==
                                    ChatUserId) { //message origin was of chat user
                                  isMessageRepliedBy = 2;
                                  replyUserName = chatUserName;
                                }
                              }

                              bool isDeletedMessage = false;
                              if (isDeletedForMe == currentUserId) {
                                isDeletedMessage = true;
                              }

                              DateTime sentAtDateTime = (sentAt as Timestamp)
                                  .toDate();
                              String formattedTime = DateFormat('hh:mm a')
                                  .format(
                                  sentAtDateTime);
                              bool isCurrentUser = senderId == currentUserId;

                              DateTime replySentAtDateTime = (replyMessageSentAt as Timestamp)
                                  .toDate();
                              String replyFormattedTime = DateFormat('hh:mm a')
                                  .format(
                                  replySentAtDateTime);

                              // Check if the message is unread (based on unReadMessages count)
                              bool isUnread = index < unReadMessages;

                              //checking if message deleted is last message
                              if (!isDeletedMessage) {
                                if (documents.length > 0) {
                                  if (lastMessageIndex == -2) {
                                    lastMessageIndex = index;
                                    isLastMessageFound = true;
                                  } else if (isLastMessageFound) {
                                    lastMessageDoc = {
                                      'senderId': documents[index]['senderId'],
                                      'sentAt': documents[index]['sentAt'],
                                      'text': documents[index]['text'],
                                      'image': documents[index]['image'],
                                      'isImageExist': documents[index]['isImageExist'],
                                    };
                                    print('index updated at $index');
                                    isLastMessageFound = false;
                                  }

                                  return Container(
                                    margin: EdgeInsets.symmetric(vertical: 8.0),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                      isCurrentUser
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        // this is a message text only
                                        Row(
                                          children: [
                                            if(isCurrentUser)
                                              Expanded(
                                                  child: SizedBox.shrink()),
                                            InkWell(
                                              onLongPress: () {
                                                isDataOkayForDelete = false;
                                                isDataOkayForDelete = storeData(
                                                    index,
                                                    lastMessageIndex,
                                                    lastMessageId,
                                                    isLastMessage,
                                                    sentAt,
                                                    senderId,
                                                    docId,
                                                    lastMessageDoc,
                                                    messageText,
                                                imageUrl,
                                                isImageExist);
                                                setState(() {
                                                  showSecondDialogsIcons = true;
                                                });
                                                print('onLongPress');
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(8.0),
                                                decoration: BoxDecoration(
                                                  color: isCurrentUser
                                                      ? Colors.blue
                                                      : Colors.grey[200],
                                                  borderRadius: BorderRadius
                                                      .circular(8.0),
                                                ),
                                                child: ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    maxWidth: 250,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: isCurrentUser
                                                        ? CrossAxisAlignment.end
                                                        : CrossAxisAlignment
                                                        .start,
                                                    children: [
                                                      if (isMessageReplied)
                                                        Container(
                                                          padding: EdgeInsets
                                                              .all(
                                                              8.0),
                                                          decoration: BoxDecoration(
                                                            color: isCurrentUser
                                                                ? (isMessageRepliedBy ==
                                                                1
                                                                ? Colors.blue
                                                                .shade200
                                                                : Colors
                                                                .grey[300])
                                                                : (isMessageRepliedBy ==
                                                                1
                                                                ? Colors.blue
                                                                .shade400
                                                                : (isMessageRepliedBy ==
                                                                2
                                                                ? Colors
                                                                .grey[400]
                                                                : Colors
                                                                .white)),

                                                            borderRadius: BorderRadius
                                                                .circular(8.0),
                                                          ),
                                                          child: Column(
                                                            crossAxisAlignment: isCurrentUser
                                                                ? CrossAxisAlignment
                                                                .end
                                                                : CrossAxisAlignment
                                                                .start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Icon(Icons
                                                                      .reply),
                                                                  SizedBox(
                                                                      width: 8.0),
                                                                  Text(
                                                                    replyUserName,
                                                                    style: TextStyle(
                                                                        color: isCurrentUser
                                                                            ? (isMessageRepliedBy ==
                                                                            1
                                                                            ? Colors
                                                                            .blue
                                                                            .shade800
                                                                            : Colors
                                                                            .grey[700])
                                                                            : (isMessageRepliedBy ==
                                                                            1
                                                                            ? Colors
                                                                            .white
                                                                            : (isMessageRepliedBy ==
                                                                            2
                                                                            ? Colors
                                                                            .grey[800]
                                                                            : Colors
                                                                            .white)),
                                                                        // color: Colors.black,
                                                                        fontSize: 15.0,
                                                                        fontWeight: FontWeight
                                                                            .bold),
                                                                  ),
                                                                  Expanded(
                                                                      child: SizedBox
                                                                          .shrink()),
                                                                  Text(
                                                                    replyFormattedTime,
                                                                    style: TextStyle(
                                                                      fontSize: 10.0,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    width: 10.0,)
                                                                ],
                                                              ),
                                                              SizedBox(
                                                                height: 2.5,
                                                              ),
                                                              if (replyIsImageExist)
                                                                Center(
                                                                  child: Container(
                                                                    margin:EdgeInsets.symmetric(vertical: 5.0),
                                                                    child: Image.network(replyImageUrl),
                                                                    constraints: BoxConstraints(
                                                                        maxWidth: 250.0,
                                                                        maxHeight: 250.0
                                                                    ),
                                                                  ),
                                                                ),
                                                              Padding(
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                    horizontal: 8.0),
                                                                child: Text(
                                                                  replyMessageText,
                                                                  softWrap: true,
                                                                  style: TextStyle(
                                                                    color: isMessageRepliedBy ==
                                                                        1
                                                                        ? Colors
                                                                        .white
                                                                        : (isMessageRepliedBy ==
                                                                        2
                                                                        ? Colors
                                                                        .black
                                                                        : Colors
                                                                        .black),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      if (isMessageReplied) SizedBox(
                                                          height: 5.0),
                                                      if (isImageExist)
                                                        Center(
                                                          child: Container(
                                                            margin:EdgeInsets.symmetric(vertical: 5.0),
                                                            child: Image.network(imageUrl),
                                                            constraints: BoxConstraints(
                                                              maxWidth: 250.0,
                                                              maxHeight: 250.0
                                                            ),
                                                          ),
                                                        ),
                                                      Padding(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                          horizontal: 7.0,
                                                        ),
                                                        child: Text(
                                                          messageText,
                                                          style: TextStyle(
                                                            color: isCurrentUser
                                                                ? Colors.white
                                                                : Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                            ),
                                          ],
                                        ),

                                        SizedBox(height: 4.0),
                                        //this is time displayed here
                                        Row(
                                          mainAxisAlignment: isCurrentUser
                                              ? MainAxisAlignment.end
                                              : MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              formattedTime,
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12.0,
                                              ),
                                            ),
                                            SizedBox(width: 4.0),
                                            if (isCurrentUser)
                                            // Only show CircleAvatar for messages sent by the current user
                                              CircleAvatar(
                                                backgroundColor: isUnread
                                                    ? Colors.red
                                                    : Colors.green,
                                                radius: 4.0,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              } else {
                                return Container();
                              }
                            },
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(30.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 5.0,
                                spreadRadius: 1.0,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),

                          child: Column(
                            children: [
                              // Add a condition to display the reply message
                              if (isMessageReplying == true)
                                Container(
                                  padding: EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Column(
                                    children: [
                                      if(isImageExistSd)
                                        Container(
                                          padding: EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[400],
                                            borderRadius: BorderRadius.circular(8.0),
                                          ),
                                          constraints: BoxConstraints(
                                              maxHeight: 100.0,
                                              maxWidth: 100.0
                                          ),
                                          child: Image.network(imageSd),
                                        ),
                                      if(isImageExistSd && replyingMessageText != '')
                                        SizedBox(height: 10.0,),
                                      if(replyingMessageText != '')
                                        Container(
                                        padding: EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[400],
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.reply),
                                            SizedBox(width: 8.0),
                                            Flexible(
                                              child: Text(replyingMessageText,
                                                // Set overflow property to handle text overflow
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Row(
                                children: [
                                  SizedBox(width: 10.0),
                                  Expanded(
                                    child: TextField(
                                      onTap: () {
                                        setState(() {
                                          showSecondDialogsIcons = false;
                                        });
                                      },
                                      controller: messageController,
                                      decoration: InputDecoration(
                                        hintText: 'Type a message...',
                                        border: InputBorder.none,
                                        contentPadding:
                                        EdgeInsets.symmetric(
                                            horizontal: 16.0, vertical: 16.0),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(left: 8.0),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue,
                                    ),
                                    child: IconButton(
                                        onPressed: () async {
                                          XFile ? selectedImage = await ImagePicker()
                                              .pickImage(
                                              source: ImageSource.gallery);
                                          if (selectedImage != null) {
                                            log('Image selected');
                                            File convertedFile = File(
                                                selectedImage.path);
                                            // ignore: unnecessary_null_comparison
                                            if (convertedFile != null) {
                                              setState(() {
                                                uploadPic = convertedFile;
                                              });
                                            } else {
                                              log(
                                                  'Selected image file does not exist.');
                                            }
                                          } else {
                                            log('No image selected');
                                          }
                                          setState(() {
                                            isImageSelected = true;
                                          });
                                        },
                                        icon: Icon(Icons.drive_folder_upload,
                                          color: Colors.white,
                                        )),
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(left: 8.0),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue,
                                    ),
                                    child: IconButton(
                                      onPressed: () async {
                                        message = messageController.text.trim();
                                        if (message == '') {
                                          return;
                                        }
                                        messageController.clear();

                                        if (isMessageReplying == false) {
                                          messageDocument = {
                                            'senderId': '',
                                            'sentAt': timestamp,
                                            'text': '',
                                          };
                                        }
                                        setState(() {
                                          isMessageReplying = false;
                                        });
                                        if (await DataBase_Service(
                                            uid: currentUserId)
                                            .sendMessage(
                                            message, chatId, ChatUserId,
                                            messageDocument) ==
                                            false) {
                                          messageController.text = message;
                                        }
                                      },
                                      icon: Icon(
                                        Icons.send,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            showSecondDialogsIcons = false;
                          });
                        },
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: currentStatusColor,
                              // Change the background color as needed
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20.0),
                                bottomRight: Radius.circular(20.0),
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 7.0, horizontal: 20.0),
                            // Adjust vertical padding as needed
                            child: Text(
                              currentStatus,
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Colors.white,
                                letterSpacing: 1.0, // Adjust the value as needed
                              ),
                            ),

                          ),
                        ),
                      ),
                      GestureDetector(
                          onTap: () {
                            setState(() {
                              showSecondDialogsIcons = false;
                            });
                          },
                          child: SizedBox(height: 20.0,)),
                      if(showSecondDialogsIcons == true)
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 80.0),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                  onPressed: () {
                                    setState(() {
                                      showSecondDialogsIcons = false;
                                    });
                                  },
                                  icon: Icon(Icons.arrow_back_rounded,
                                    size: 30.0,
                                    color: Colors.white,)),
                              Expanded(child: SizedBox.shrink()),
                              IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isMessageReplying = true;
                                      showSecondDialogsIcons = false;
                                    });
                                  },
                                  icon: Icon(Icons.reply,
                                    size: 30.0,
                                    color: Colors.white,)),
                              IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isDeletingDialog = true;
                                      showSecondDialogsIcons = false;
                                    });
                                  },
                                  icon: Icon(Icons.delete,
                                    color: Colors.white,)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if(isDeletingDialog == true)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          margin: EdgeInsets.fromLTRB(40.0, 0, 40.0, 60.0),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20.0)
                          ),
                          padding: EdgeInsets.all(16.0),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                maxWidth: 300.0,
                                minWidth: 200.0
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [
                                SizedBox(height: 5.0,),
                                Text(
                                  'Delete Message',
                                  style: TextStyle(fontSize: 16.0,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 10.0),
                                if(currentUserId == senderIdSd)
                                  TextButton(
                                    onPressed: () {
                                      deleteMessageForEveryOne(
                                          isDataOkayForDelete);
                                      setState(() {
                                        isDeletingDialog = false;
                                      });
                                    },
                                    child: Text('Delete for everyone',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),),),
                                TextButton(
                                  onPressed: () {
                                    deleteMessageForMe(isDataOkayForDelete);
                                    setState(() {
                                      isDeletingDialog = false;
                                    });
                                  },
                                  child: Text('Delete for me',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold),),),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      isDeletingDialog = false;
                                    });
                                  },
                                  child: Text('cancel',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold),),)
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                ],
              );
            } else {
              return Loading_Screen();
            }
          });
    } else if(isLoading) {
      return Loading_Screen();
    } else {
      return Container(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  child:  uploadPic != null
                      ? Image.file(uploadPic!,
                    fit: BoxFit.cover,
                  ) // Display the uploaded image
                      : Image.asset('assets/images/profile_default.png', // Default image from assets
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            if (isMessageReplying == true)
              Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  children: [
                    if(isImageExistSd)
                      Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        constraints: BoxConstraints(
                            maxHeight: 100.0,
                            maxWidth: 100.0
                        ),
                        child: Image.network(imageSd),
                      ),
                    if(isImageExistSd && replyingMessageText != '')
                      SizedBox(height: 10.0,),
                    if(replyingMessageText != '')
                      Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.reply),
                            SizedBox(width: 8.0),
                            Flexible(
                              child: Text(replyingMessageText,
                                // Set overflow property to handle text overflow
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5.0,
                    spreadRadius: 1.0,
                    offset: Offset(0, 3),
                  ),
                ],
              ),

              child: Row(
                children: [
                  SizedBox(width: 10.0),
                  Expanded(
                    child: TextField(
                      onTap: () {
                        setState(() {
                          showSecondDialogsIcons = false;
                        });
                      },
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding:
                        EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 16.0),
                      ),
                    ),
                  ),

                  Container(
                    margin: EdgeInsets.only(left: 8.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                    child: IconButton(
                      onPressed: () async {
                        setState(() {
                          isLoading = true;
                        });
                        message = '';
                        message = messageController.text.trim();
                        messageController.clear();

                        if (isMessageReplying == false) {
                          messageDocument = {
                            'senderId': '',
                            'sentAt': timestamp,
                            'text': '',
                          };
                        }
                        setState(() {
                          isMessageReplying = false;
                        });
                        if (await DataBase_Service(
                            uid: currentUserId)
                            .sendMessageImage(
                            message, chatId, ChatUserId,
                            messageDocument, uploadPic!) ==
                            false) {
                          messageController.text = message;
                        }
                        setState(() {
                          isImageSelected = false;
                          isLoading = false;
                        });
                      },
                      icon: Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.0,),
          ],
        )
      );
    }
  }
}








