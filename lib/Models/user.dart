import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: camel_case_types
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

class UserChatListData {
  final String uid;
  final String chatId;
  final String candidate1;
  final String candidate2;
  var createdAt;
  final String chatUserImage;
  final String thisUserImage;
  final String chatUserName1;
  final String chatUserName2;
  int isChatReadUser1;
  int isChatReadUser2;
  final String lastMessageSenderId;
  var lastMessageSentAt;
  final String lastMessageText;
  late final String userName;
  late final String userImage;
  late final String userId;
  late final int isChatRead;

  UserChatListData({
    required this.uid,
    required this.chatId,
    required this.candidate1,
    required this.candidate2,
    required this.createdAt,
    required this.chatUserImage,
    required this.thisUserImage,
    required this.chatUserName1,
    required this.chatUserName2,
    required this.isChatReadUser1,
    required this.isChatReadUser2,
    required this.lastMessageSenderId,
    required this.lastMessageSentAt,
    required this.lastMessageText,
    String? userName,
    String? userImage,
    String? userId,
    int? isChatRead,
  }) : userName = userName ?? '',
        userImage = userImage ?? '',
        userId = userId ?? '',
        isChatRead = isChatRead ?? 0;

  factory UserChatListData.fromMap(Map<String, dynamic>? data, String uid) {
    if (data == null) {
      throw ArgumentError("Data cannot be null");
    }

    Map<String, dynamic>? lastMessage = data['lastMessage'] as Map<String, dynamic>?;

    bool isCandidate1 = data['candidate1'] == uid;
    bool isCandidate2 = data['candidate2'] == uid;

    // Set user-specific properties based on uid
    String userName;
    String userImage;
    String userId;

    if (isCandidate1) {
      userName = data['chatUserName'] ?? ''; // Swap candidate1 and candidate2
      userImage = data['chatUserImage'] ?? ''; // Swap candidate1 and candidate2
      userId = data['candidate2'] ?? '';       // Swap candidate1 and candidate2
    } else if (isCandidate2) {
      userName = data['thisUserName'] ?? ''; // Swap candidate1 and candidate2
      userImage = data['thisUserImage'] ?? ''; // Swap candidate1 and candidate2
      userId = data['candidate1'] ?? '';       // Swap candidate1 and candidate2
    } else {
      // Handle the case where uid doesn't match candidate1 or candidate2
      // You might want to throw an error or set default values
      userName = '';
      userImage = '';
      userId = '';
    }

    return UserChatListData(
      chatId: data['chatId'] ?? '',
      candidate1: data['candidate1'] ?? '',
      candidate2: data['candidate2'] ?? '',
      uid: uid,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] as DateTime))
          : DateTime.now(),
      chatUserImage: data['chatUserImage'] ?? '',
      thisUserImage: data['thisUserImage'] ?? '',
      chatUserName1: data['thisUserName'] ?? '',
      chatUserName2: data['chatUserName'] ?? '',
      isChatReadUser1: data['thisUserIsChatRead'] as int? ?? 0,
      isChatReadUser2: data['chatUserIsChatRead'] as int? ?? 0,
      lastMessageSenderId: lastMessage?['senderId'] ?? '',
      lastMessageSentAt: lastMessage?['sentAt'] != null
          ? (lastMessage?['sentAt'] is Timestamp
          ? (lastMessage?['sentAt'] as Timestamp).toDate()
          : (lastMessage?['sentAt'] as DateTime))
          : DateTime.now(),
      lastMessageText: lastMessage?['text'] ?? '',
      userName: userName,
      userImage: userImage,
      userId: userId,
      isChatRead: data['thisUserIsChatRead'],
    );
  }


}

