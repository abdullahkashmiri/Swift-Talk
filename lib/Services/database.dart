import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../Models/user.dart';

class DataBase_Service {
  final String uid;

  DataBase_Service({required this.uid});
  //collection reference
  final CollectionReference accountsCollection = FirebaseFirestore.instance
      .collection(('accounts'));
  final CollectionReference chatsCollection = FirebaseFirestore.instance
      .collection(('chats'));
  final CollectionReference directChatsDocRef = FirebaseFirestore.instance.
  collection('directChats');
  // update the data of surrent user
  Future<bool> updateUserData(String name, String phone, String email,
      String password, String status, String aboutMe, File profilePic) async {
    try {
      if (!profilePic.existsSync()) {
        log('Error: Profile picture file does not exist.');
        return false;
      }
      UploadTask uploadTask = FirebaseStorage.instance.ref().child(
          'profilePictures').child(uid).child(Uuid().v1()).putFile(profilePic);
      await uploadTask.whenComplete(() async {
        try {
          TaskSnapshot taskSnapshot = await uploadTask;
          String downloadUrl = await taskSnapshot.ref.getDownloadURL();
          await accountsCollection.doc(uid).set({
            'name': name,
            'Phone': phone,
            'email': email,
            'password': password,
            'Status': status,
            'AboutMe': aboutMe,
            'profilePic': downloadUrl,
          });
          await updateChatInfo(name: name, image: downloadUrl);
        } catch (e) {
          log('Error updating Firestore: $e');
          return false; // Return false if there's an error updating Firestore
        }
      }).catchError((e) {
        log('Error during file upload: $e');
        // ignore: invalid_return_type_for_catch_error
        return false; // Return false if there's an error during file upload
      });
      // Return true only if everything is successful
      return true;
    } catch (e) {
      log('Error updating user data: $e');
      return false;
    }
  }

  // get all uids of accounts
  Future<List<String>> getAllUids() async {
    try {
      QuerySnapshot<Object?> querySnapshot =
      await accountsCollection.get();
      List<String> uids = querySnapshot.docs.map((doc) => doc.id).toList();
      return uids;
    } catch (e) {
      print('Error fetching UIDs: $e');
      throw e;
    }
  }

// update chat info means in all docs when you either update name pic etc
  Future<void> updateChatInfo(
      {required String name, required String image,}) async {
    try {
      // Fetch all UIDs
      List<String> allUids = await getAllUids();
      // Loop through all UIDs
      for (String uidall in allUids) {
        // Fetch all documents in the 'directChats' collection for the current UID
        QuerySnapshot<
            Map<String, dynamic>> querySnapshot = await accountsCollection
            .doc(uidall)
            .collection('directChats')
            .get();
        // Update each document where either candidateId1 or candidateId2 is equal to uid
        for (QueryDocumentSnapshot<
            Map<String, dynamic>> docSnapshot in querySnapshot.docs) {
          Map<String, dynamic> chatInfo = docSnapshot.data();
          // Check conditions and update name and image
          bool doUpdate = false;
          if (chatInfo['candidate1'] == uid) {
            chatInfo['thisUserName'] = name;
            chatInfo['thisUserImage'] = image;
            doUpdate = true;
          } else if (chatInfo['candidate2'] == uid) {
            chatInfo['chatUserName'] = name;
            chatInfo['chatUserImage'] = image;
            doUpdate = true;
          }
          if (doUpdate == true) {
            // Update the document
            await docSnapshot.reference.update(chatInfo);
            //For updating data in direct chats too in chats
            String chatId = chatInfo['chatId'];
            CollectionReference chatColRef = chatsCollection.doc('directChats')
                .collection(chatId);
            // Get the document snapshot
            DocumentSnapshot chatDocSnapshot = await chatColRef.doc('chatInfo')
                .get();
            // Check if the document exists
            if (chatDocSnapshot.exists) {
              // Access data from the document
              Map<String, dynamic> chatDocMap = chatDocSnapshot.data() as Map<
                  String,
                  dynamic>;
              // Update fields based on conditions
              if (chatDocMap['candidate1'] == uid) {
                chatDocMap['thisUserName'] = name;
                chatDocMap['thisUserImage'] = image;
              } else if (chatDocMap['candidate2'] == uid) {
                chatDocMap['chatUserName'] = name;
                chatDocMap['chatUserImage'] = image;
              }
              // Update the document in Firestore
              await chatColRef.doc('chatInfo').set(chatDocMap);
            }
          }
        }
      }
    } catch (e) {
      print('Error in updating chat info: $e');
      throw e;
    }
  }

  Future<bool> updateUserDataWithoutPic(String name, String phone, String email,
      String password, String status, String aboutMe,
      String downloadUrl) async {
    try {
      await accountsCollection.doc(uid).set({
        'name': name,
        'Phone': phone,
        'email': email,
        'password': password,
        'Status': status,
        'AboutMe': aboutMe,
        'profilePic': downloadUrl,
      });
      await updateChatInfo(name: name, image: downloadUrl);
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

  // function to delete a profile picture
  Future<void> deleteProfilePictures(String userUid) async {
    try {
      // Creating a reference to the user's profile pictures folder
      Reference folderRef = FirebaseStorage.instance.ref().child(
          'profilePictures').child(userUid);
      // List all items (profile pictures) in the folder
      ListResult result = await folderRef.listAll();

      // Delete each item in the folder
      await Future.forEach(result.items, (Reference itemRef) async {
        await itemRef.delete();
      });
      // After deleting all profile pictures, delete the folder itself
      await folderRef.delete();
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
      return _userDataFromSnapshot(snapshot);
    });
  }

  //get user doc future
  Future<UserData?> get userDataFuture async {
    try {
      DocumentSnapshot snapshot = await accountsCollection.doc(uid).get();
      return _userDataFromSnapshot(snapshot);
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  //get all contacts data
  UserData _userDataFromSnapshotAllAccounts(
      DocumentSnapshot<Object?> snapshot) {
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

  // getting all accounts continusely
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

  //getting all phone numbers of a contact
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

  //deleting  a phone number in contacts of a person
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

  //function to check if there is any correspondence between these users
  Future<bool> doesCollectionExist(String collectionPath) async {
    try {
      QuerySnapshot<
          Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
          .collection(collectionPath)
          .limit(1)
          .get();
      // If the querySnapshot is empty, the collection does not exist
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      // Handle exceptions with more context
      print('Error checking collection existence for $collectionPath: $e');
      return false;
    }
  }

  Future<List<QueryDocumentSnapshot<
      Map<String, dynamic>>>> getDirectChatsFuture() async {
    try {
      CollectionReference<Map<String, dynamic>> chatColRef = accountsCollection
          .doc(uid)
          .collection('directChats');
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await chatColRef
          .get();
      // Return the list of documents
      return querySnapshot.docs;
    } catch (e) {
      print('Error in fetching data: $e');
      throw e;
    }
  }

  Future<String?> createOrGetDirectChat(String candidateId1,
      String candidateId2, String chatUserName, String chatUserPicUrl,
      String thisUserName, String thisUserPicUrl) async {
    try {
      //checking is chats exist or not
      List<QueryDocumentSnapshot<
          Map<String, dynamic>>> docs = await getDirectChatsFuture();
      for (QueryDocumentSnapshot<Map<String, dynamic>> doc in docs) {
        var chatUserData = UserChatListData.fromMap(doc.data(), uid);
        // Check if the candidates match in any order
        if ((chatUserData.candidate1 == candidateId1 &&
            chatUserData.candidate2 == candidateId2) ||
            (chatUserData.candidate1 == candidateId2 &&
                chatUserData.candidate2 == candidateId1)) {
          return chatUserData.chatId;
        }
      }
      String chatId = Uuid().v4();
      Timestamp timestamp = Timestamp.now();
      String text = '';
      Map<String, dynamic> replyMessage = {
        'senderId': '',
        'sentAt': timestamp,
        'text': '',
        'image': '',
        'isImageExist': false
      };
      //last message sent
      Map<String, dynamic> lastMessage = {
        'senderId': '',
        'sentAt': timestamp,
        'text': '',
        'replyMessage': replyMessage,
        'isMessageDeletedForMe': text,
        // place user id who has deleted the message
        'isMessageDeletedForEveryOne': false,
        // only this user messages will be deleted by him
        'image': '',
        'isImageExist': false
      };
      const int value = 0;
      // Create chat info
      Map<String, dynamic> chatInfo = {
        'chatId': chatId,
        'candidate1': candidateId1, //c1
        'candidate2': candidateId2, //c2
        'createdAt': timestamp,
        'lastMessage': lastMessage,
        'chatUserImage': chatUserPicUrl, //c2
        'thisUserImage': thisUserPicUrl, //c1
        'thisUserName': thisUserName, //c1
        'chatUserName': chatUserName, //c2
        'thisUserIsChatRead': value, //c1
        'chatUserIsChatRead': value, //c2
        'thisUserOnline': value, //c1
        'chatUserOnline': value, //c2
      };
      //set chat info in chats make a reference
      CollectionReference chatColRef = await chatsCollection.doc('directChats')
          .collection(chatId);
      // Set chat info
      DocumentReference chatDocRef = await chatColRef.doc('chatInfo');
      await chatDocRef.set(chatInfo);
      String chatInfoName = 'directChats';
      // User no 1
      DocumentReference candidate1DirectChat = await accountsCollection.doc(
          candidateId1).collection(chatInfoName).doc(chatId);
      // Update user1's direct chats
      await candidate1DirectChat.set(chatInfo);
      // all are reversed over here because candidateId1 is getting all this values
      Map<String, dynamic> chatInfoAgain = {
        'chatId': chatId,
        'candidate1': candidateId2,
        'candidate2': candidateId1,
        'createdAt': timestamp,
        'lastMessage': lastMessage,
        'chatUserImage': thisUserPicUrl,
        'thisUserImage': chatUserPicUrl,
        'thisUserName': chatUserName,
        'chatUserName': thisUserName,
        'chatUserIsChatRead': value, //c1
        'thisUserIsChatRead': value, //c2
        'thisUserOnline': value, //c2
        'chatUserOnline': value, //c1
      };
      // Update user2's direct chats
      DocumentReference candidate2DirectChat = await accountsCollection.doc(
          candidateId2).collection(chatInfoName).doc(chatId);
      await candidate2DirectChat.set(chatInfoAgain);
      return chatId;
    } catch (e, stackTrace) {
      print('Error creating a Direct Chat: $e');
      print('StackTrace: $stackTrace');
      return null; // or throw e; depending on how you want to handle it
    }
  }

  //OK
  //Sending Chat Info only of a particular chat id
  Future<DocumentSnapshot<Object?>?> getChatInfo(String chatId) async {
    try {
      DocumentReference chatDocRef = await chatsCollection.doc('directChats')
          .collection(chatId)
          .doc('chatInfo');
      DocumentSnapshot snapshot = await chatDocRef.get();
      return snapshot;
    } catch (e) {
      print('Error Occurred in Fetching ChatInfo: $e');
      return null;
    }
  }

  //OK
  //sending the unread messages count for the chat id of other person we are chatting with sending this of Otherperson
  //how many messages are unread by him
  Future<int> updateChatInfoMessages(String chatId, String chatUserUid) async {
    try {
      DocumentSnapshot<
          Map<String, dynamic>> chatDocument = await accountsCollection
          .doc(chatUserUid)
          .collection('directChats')
          .doc(chatId)
          .get();
      if (chatDocument.exists) {
        Map<String, dynamic> chatInfo = chatDocument.data() ?? {};
        int value = chatInfo['thisUserIsChatRead'];
        return value;
      }
      return 0;
    } catch (e) {
      print('Error in updating chat info: $e');
      throw e;
    }
  }

  //OK
  //Sending message to database and update chat info in directChat as well as both participants
  Future<bool> sendMessage(String message, String chatId,
      String chatUserId, Map<String, dynamic> replyMessage) async {
    try {
      DateTime now = DateTime.now();
      Timestamp timestamp = Timestamp.now();
      int isRead = await updateChatInfoMessages(chatId,
          chatUserId) as int; // return the unread message count of the user with whom we are chatting
      //making a chatColRef
      CollectionReference chatColRef = await chatsCollection.doc('directChats')
          .collection(chatId);
      String todaysDateAgain = DateFormat('HH:mm:ss:SSS').format(now);
      // Create message
      Map<String, dynamic> Message = {
        'senderId': uid,
        'sentAt': timestamp,
        'text': message,
        'replyMessage': replyMessage,
        'isMessageDeletedForMe': '',
        // place user id who has deleted the message
        'isMessageDeletedForEveryOne': false,
        // only this user messages will be deleted by him
        'image': '',
        'isImageExist': false
      };
      //last message sent
      Map<String, dynamic> lastMessage = {
        'senderId': uid,
        'sentAt': timestamp,
        'text': message,
        'replyMessage': replyMessage,
        'image': '',
        'isImageExist': false
      };
      // add message to database of Chats
      DocumentReference chatDocRef = await chatColRef.doc(todaysDateAgain);
      await chatDocRef.set(Message);
      //fetching candidates ids from that chat
      CollectionReference chatColRefCandidatesIds = await chatsCollection.doc(
          'directChats')
          .collection(chatId);
      var data = await chatColRefCandidatesIds.get();
      var chatInfoDoc = data.docs.firstWhere((element) =>
      element.id == 'chatInfo');
      String c1 = chatInfoDoc['candidate1'];
      String c2 = chatInfoDoc['candidate2'];
      int onlineStatusThisUser = chatInfoDoc['thisUserOnline'];
      int onlineStatusChatUser = chatInfoDoc['chatUserOnline'];
      // these candidate ids are from chats and to be used to update the chat info in Chats
      if (chatUserId == c1) {
        if (onlineStatusThisUser == 0) {
          isRead++;
        }
      } else if (chatUserId == c2) {
        if (onlineStatusChatUser == 0) {
          isRead++;
        }
      }
      Map<String, dynamic> chatInfo1 = {
        'chatId': chatId,
        'lastMessage': lastMessage,
        'thisUserIsChatRead': isRead,
      };
      Map<String, dynamic> chatInfo2 = {
        'chatId': chatId,
        'lastMessage': lastMessage,
        'chatUserIsChatRead': isRead,
      };
      //candidate 1 is thisUser and candidate2 is chatUser
      if (chatUserId == c1) {
        DocumentReference chatDocReflast = await chatColRef.doc('chatInfo');
        await chatDocReflast.update(chatInfo1);
      } else if (chatUserId == c2) {
        DocumentReference chatDocReflast = await chatColRef.doc('chatInfo');
        await chatDocReflast.update(chatInfo2);
      }
      //Now Updating ChatInfo in Both Candidates
      Map<String, dynamic> chatInfo = {
        'chatId': chatId,
        'lastMessage': lastMessage,
        'chatUserIsChatRead': isRead,
      };
      String chatTypeName = 'directChats';
      DocumentReference candidate1DirectChat = await accountsCollection.doc(
          uid).collection(chatTypeName).doc(chatId);
      // Update user1's direct chats
      await candidate1DirectChat.update(chatInfo);
      Map<String, dynamic> chatInfoAgain = {
        'chatId': chatId,
        'lastMessage': lastMessage,
        'thisUserIsChatRead': isRead,
      };
      // Update user2's direct chats
      DocumentReference candidate2DirectChat = await accountsCollection.doc(
          chatUserId).collection(chatTypeName).doc(chatId);
      await candidate2DirectChat.update(chatInfoAgain);
      return true;
    } catch (e) {
      print('Error in Sending Message: $e');
      return false;
    }
  }

  //Sending message to database and update chat info in directChat as well as both participants
  Future<bool> sendMessageImage(String message, String chatId,
      String chatUserId, Map<String, dynamic> replyMessage, File pic) async {
    try {
      UploadTask uploadTask = FirebaseStorage.instance.ref().child(
          'storage').child(chatId).child(Uuid().v1()).putFile(pic);
        await uploadTask.whenComplete(() async {
        TaskSnapshot taskSnapshot = await uploadTask;
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        print(downloadUrl);
        DateTime now = DateTime.now();
        Timestamp timestamp = Timestamp.now();
        int isRead = await updateChatInfoMessages(chatId,
            chatUserId) as int; // return the unread message count of the user with whom we are chatting
        //making a chatColRef
        CollectionReference chatColRef = await chatsCollection.doc(
            'directChats')
            .collection(chatId);
        String todaysDateAgain = DateFormat('HH:mm:ss:SSS').format(now);
        // Create message
        Map<String, dynamic> Message = {
          'senderId': uid,
          'sentAt': timestamp,
          'text': message,
          'replyMessage': replyMessage,
          'isMessageDeletedForMe': '',
          // place user id who has deleted the message
          'isMessageDeletedForEveryOne': false,
          // only this user messages will be deleted by him
          'image': downloadUrl,
          'isImageExist': true
        };
        //last message sent
        Map<String, dynamic> lastMessage = {
          'senderId': uid,
          'sentAt': timestamp,
          'text': message,
          'replyMessage': replyMessage,
          'image': downloadUrl,
          'isImageExist': true
        };
        // add message to database of Chats
        DocumentReference chatDocRef = await chatColRef.doc(todaysDateAgain);
        await chatDocRef.set(Message);
        //fetching candidates ids from that chat
        CollectionReference chatColRefCandidatesIds = await chatsCollection.doc(
            'directChats')
            .collection(chatId);
        var data = await chatColRefCandidatesIds.get();
        var chatInfoDoc = data.docs.firstWhere((element) =>
        element.id == 'chatInfo');
        String c1 = chatInfoDoc['candidate1'];
        String c2 = chatInfoDoc['candidate2'];
        int onlineStatusThisUser = chatInfoDoc['thisUserOnline'];
        int onlineStatusChatUser = chatInfoDoc['chatUserOnline'];
        // these candidate ids are from chats and to be used to update the chat info in Chats
        if (chatUserId == c1) {
          if (onlineStatusThisUser == 0) {
            isRead++;
          }
        } else if (chatUserId == c2) {
          if (onlineStatusChatUser == 0) {
            isRead++;
          }
        }
        Map<String, dynamic> chatInfo1 = {
          'chatId': chatId,
          'lastMessage': lastMessage,
          'thisUserIsChatRead': isRead,
        };
        Map<String, dynamic> chatInfo2 = {
          'chatId': chatId,
          'lastMessage': lastMessage,
          'chatUserIsChatRead': isRead,
        };
        //candidate 1 is thisUser and candidate2 is chatUser
        if (chatUserId == c1) {
          DocumentReference chatDocReflast = await chatColRef.doc('chatInfo');
          await chatDocReflast.update(chatInfo1);
        } else if (chatUserId == c2) {
          DocumentReference chatDocReflast = await chatColRef.doc('chatInfo');
          await chatDocReflast.update(chatInfo2);
        }
        //Now Updating ChatInfo in Both Candidates
        Map<String, dynamic> chatInfo = {
          'chatId': chatId,
          'lastMessage': lastMessage,
          'chatUserIsChatRead': isRead,
        };
        String chatTypeName = 'directChats';
        DocumentReference candidate1DirectChat = await accountsCollection.doc(
            uid).collection(chatTypeName).doc(chatId);
        // Update user1's direct chats
        await candidate1DirectChat.update(chatInfo);
        Map<String, dynamic> chatInfoAgain = {
          'chatId': chatId,
          'lastMessage': lastMessage,
          'thisUserIsChatRead': isRead,
        };
        // Update user2's direct chats
        DocumentReference candidate2DirectChat = await accountsCollection.doc(
            chatUserId).collection(chatTypeName).doc(chatId);
        await candidate2DirectChat.update(chatInfoAgain);
      });
      return true;
    } catch (e) {
      print('Error in Sending Message: $e');
      return false;
    }
  }

  Future<void> updateChatInfoMessagesReadOnChatOpen(String chatId,
      String chatUserId) async {
    try {
      //Updating the chat info in Chats
      CollectionReference chatColRef = await chatsCollection.doc('directChats')
          .collection(chatId);
      var data = await chatColRef.get();
      var chatInfoDoc = data.docs.firstWhere((element) =>
      element.id == 'chatInfo');
      String c1 = chatInfoDoc['candidate1'];
      String c2 = chatInfoDoc['candidate2'];
      Map<String, dynamic> chatInfoDirect1 = {
        'chatUserIsChatRead': 0,
        'chatUserOnline': 1, //online
      };
      Map<String, dynamic> chatInfoDirect2 = {
        'thisUserIsChatRead': 0,
        'thisUserOnline': 1, //online
      };
      if (c1 == chatUserId) {
        DocumentReference chatDocReflast = await chatColRef.doc('chatInfo');
        await chatDocReflast.update(chatInfoDirect1);
      } else if (c2 == chatUserId) {
        DocumentReference chatDocReflast = await chatColRef.doc('chatInfo');
        await chatDocReflast.update(chatInfoDirect2);
      }
      // Till here I have updated the chats chat info of this chat ID
      //make all read for this user
      int value = 0;
      Map<String, dynamic> chatInfo1 = {
        'thisUserIsChatRead': value,
        'thisUserOnline': 1, //c1
      };
      // Update user1's direct chats its the account who is opening the chat
      DocumentReference thisCandidateDirectChat = await accountsCollection.doc(
          uid).collection('directChats').doc(chatId);
      await thisCandidateDirectChat.update(chatInfo1);
      //make all read for other user
      Map<String, dynamic> chatInfo2 = {
        'chatUserIsChatRead': value,
        'chatUserOnline': 1,
      };
      // Update user2's direct chats tell him i have read messages
      DocumentReference chatCandidateDirectChat = await accountsCollection.doc(
          chatUserId).collection('directChats').doc(chatId);
      await chatCandidateDirectChat.update(chatInfo2);
    } catch (e) {
      print('Error in updating chat info: $e');
      throw e;
    }
  }

  Future<void> updateChatInfoMessagesReadOnChatClose(String chatId,
      String chatUserId) async {
    try {
      //Updating the chat info in Chats
      CollectionReference chatColRef = await chatsCollection.doc('directChats')
          .collection(chatId);
      var data = await chatColRef.get();
      var chatInfoDoc = data.docs.firstWhere((element) =>
      element.id == 'chatInfo');
      String c1 = chatInfoDoc['candidate1'];
      String c2 = chatInfoDoc['candidate2'];
      Map<String, dynamic> chatInfoDirect1 = {
        'chatUserIsChatRead': 0,
        'chatUserOnline': 0, // offline
      };
      Map<String, dynamic> chatInfoDirect2 = {
        'thisUserIsChatRead': 0,
        'thisUserOnline': 0, //offline
      };
      if (c1 == chatUserId) {
        DocumentReference chatDocReflast = await chatColRef.doc('chatInfo');
        await chatDocReflast.update(chatInfoDirect1);
      } else if (c2 == chatUserId) {
        DocumentReference chatDocReflast = await chatColRef.doc('chatInfo');
        await chatDocReflast.update(chatInfoDirect2);
      }
      // Till here I have updated the chats chat info of this chat ID
      //make all read for this user
      int value = 0;
      Map<String, dynamic> chatInfo1 = {
        'thisUserIsChatRead': value,
        'thisUserOnline': 0, //c1
      };
      // Update user1's direct chats its the account who is opening the chat
      DocumentReference thisCandidateDirectChat = await accountsCollection.doc(
          uid).collection('directChats').doc(chatId);
      await thisCandidateDirectChat.update(chatInfo1);
      //make all read for other user
      Map<String, dynamic> chatInfo2 = {
        'chatUserIsChatRead': value,
        'chatUserOnline': 0,
      };
      // Update user2's direct chats tell him i have read messages
      DocumentReference chatCandidateDirectChat = await accountsCollection.doc(
          chatUserId).collection('directChats').doc(chatId);
      await chatCandidateDirectChat.update(chatInfo2);
    } catch (e) {
      print('Error in updating chat info: $e');
      throw e;
    }
  }

  //OK
  //Stream used to get-all messages
  Stream<QuerySnapshot<Map<String, dynamic>>>? getMessages(String chatId,
      String chatUserId) {
    try {
      //updateChatInfoMessages(chatId, chatUserId);
      CollectionReference<Map<String, dynamic>> chatColRef = chatsCollection
          .doc('directChats')
          .collection(chatId);
      return chatColRef.snapshots();
    } catch (e) {
      print('Error in fetching data: $e');
      return null;
    }
  }

  //Stream used to show all chats in chatList
  Stream<QuerySnapshot<Map<String, dynamic>>> getDirectChats() {
    try {
      CollectionReference<Map<String, dynamic>> chatColRef = accountsCollection
          .doc(uid)
          .collection('directChats');
      // print('Fetching directChats for UID: $uid');
      return chatColRef.snapshots();
    } catch (e) {
      print('Error in fetching data: $e');
      throw e;
    }
  }

  Future<void> deleteChatFolder(String chatId) async {
    try {
      Reference chatFolder = FirebaseStorage.instance.ref().child('storage').child(chatId);
      // List all items (files) in the chat folder
      ListResult result = await chatFolder.listAll();
      // Delete each file in the folder
      await Future.forEach(result.items, (Reference item) async {
        await item.delete();
        print('File ${item.fullPath} deleted successfully');
      });
      print('Chat folder $chatId deleted successfully');
    } catch (error) {
      print('Error deleting chat folder: $error');
      // Handle the error as needed
    }
  }
//Function to delete a Direct Chat completely update this to delete chat of one side only
  Future<bool> deleteDirectChat(String candidateId1, String candidateId2,
      String chatId) async {
    try {
      await deleteChatFolder(chatId);
      // deleting chat from Chats
      CollectionReference chatColRef = chatsCollection.doc('directChats')
          .collection(chatId);
      // Get all documents in the collection
      QuerySnapshot querySnapshot = await chatColRef.get();
      // Delete each document
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
      DocumentReference candidate1DirectChat = await accountsCollection.doc(
          candidateId1).collection('directChats').doc(chatId);
      await candidate1DirectChat.delete();
      DocumentReference candidate2DirectChat = await accountsCollection.doc(
          candidateId2).collection('directChats').doc(chatId);
      await candidate2DirectChat.delete();
      return true;
    } catch (e) {
      print('Error in deleting chat $e');
      return false;
    }
  }

  //Function to delete a Direct Chat messages
  Future<bool> deleteDirectChatAllMessagesForMe(String chatId) async {
    try {
      // deleting chat from Chats
      CollectionReference chatColRef = chatsCollection.doc('directChats')
          .collection(chatId);
      // Get all documents in the collection
      QuerySnapshot querySnapshot = await chatColRef.get();
      // Delete each document
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        if (doc.id != 'chatInfo') {
          Map<String, dynamic>? message = doc.data() as Map<String, dynamic>?;
          String isMessageDeleted = message?['isMessageDeletedForMe'];
          if (message != null) {
            if (isMessageDeleted == '') {
              isMessageDeleted = uid;
              message['isMessageDeletedForMe'] = isMessageDeleted;
              doc.reference.update(message);
            } else if (isMessageDeleted != uid) {
              // Delete the document
              await doc.reference.delete();
            }
          }
        }
      }
      // dont delete chat info doc
      Timestamp timestamp = Timestamp.now();
      Map<String, dynamic> lastMessage = {
        'senderId': '',
        'sentAt': timestamp,
        'text': ''
      };
      Map<String, dynamic> chatInfo = {
        'lastMessage': lastMessage,
        'thisUserIsChatRead': 0, //c1
        'chatUserIsChatRead': 0, //c2
      };
      DocumentReference candidate1DirectChat = await accountsCollection.doc(
          uid).collection('directChats').doc(chatId);
      await candidate1DirectChat.update(chatInfo);
      return true;
    } catch (e) {
      print('Error in deleting chat messages $e');
      return false;
    }
  }

  Future<void> deletePictureFromStorage(String chatId, String downloadUrl) async {
    try {
      // Delete the file
      Uri uri = Uri.parse(downloadUrl);
      String filePath = Uri.decodeComponent(uri.pathSegments.last);
      await FirebaseStorage.instance.ref().child(filePath).delete();
      print('File deleted successfully');
    } catch (error) {
      print('Error deleting file: $error');
      // Handle the error as needed
    }
  }





  //Function to delete a Direct Chat message for me
  Future<bool> deleteDirectChatMessageForMe(String candidateId1,
      String candidateId2,
      String chatId, Timestamp messageTime, String senderId, String docId,
      String isLastMessageDocId, Map<String, dynamic> lastMessageDoc,
      bool isLastMessage, String downloadUrl) async {
    try {
      // deleting chat from Chats
      CollectionReference chatColRef = chatsCollection.doc('directChats')
          .collection(chatId);
      // Get all documents in the collection
      DocumentReference docRef = chatColRef.doc(docId);
      DocumentSnapshot docSnap = await docRef.get();
      Map<String, dynamic>? message = docSnap.data() as Map<String, dynamic>?;
      String isMessageDeleted = message?['isMessageDeletedForMe'];
      if (message != null) {
        if (isMessageDeleted == '') {
          isMessageDeleted = uid;
          message['isMessageDeletedForMe'] = isMessageDeleted;
          docRef.update(message);
        } else if (isMessageDeleted != uid) {
          await deletePictureFromStorage(chatId, downloadUrl);
          // Delete the document
          await docRef.delete();
        }
      }
      if (isLastMessage) {
        // dont delete chat info doc
         Map<String, dynamic> lastMessage = {
          'senderId': lastMessageDoc['senderId'],
          'sentAt': lastMessageDoc['sentAt'],
          'text': lastMessageDoc['text'],
        };
        Map<String, dynamic> chatInfo = {
          'lastMessage': lastMessage,
          'thisUserIsChatRead': 0, //c1
          'chatUserIsChatRead': 0, //c2
        };
        // c1 = currentuser , c2 = chatuser
        DocumentReference candidate1DirectChat = await accountsCollection.doc(
            candidateId1).collection('directChats').doc(chatId);
        await candidate1DirectChat.update(chatInfo);
      }
      return true;
    } catch (e) {
      print('Error in deleting chat messages $e');
      return false;
    }
  }

  //Function to delete a Direct Chat message for me
  Future<bool> deleteDirectChatMessageForEveryOne(String candidateId1,
      String candidateId2,
      String chatId, Timestamp messageTime, String senderId, String docId,
      String isLastMessageDocId, Map<String, dynamic> lastMessageDoc,
      bool isLastMessage, String downloadUrl) async {
    try {
      if (senderId == candidateId1) {
        // deleting chat from Chats
        CollectionReference chatColRef = chatsCollection.doc('directChats')
            .collection(chatId);
        // Get all documents in the collection
        await chatColRef.doc(docId).delete();
        await deletePictureFromStorage(chatId, downloadUrl);
        QuerySnapshot querySnapshot = await chatColRef.get();
        // Delete each document
        String highestDocId = '';
        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          if (doc.id != 'chatInfo') {
            if (highestDocId == '' || (doc.id.compareTo(highestDocId) > 0)) {
              Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
              if (data != null && data['isMessageDeletedForMe'] != candidateId2) {
                highestDocId = doc.id;
              }
            }
          }
        }
        //delete for candidate1
        if (isLastMessage) {
          // dont delete chat info doc
          Map<String, dynamic> lastMessage = {
            'senderId': lastMessageDoc['senderId'],
            'sentAt': lastMessageDoc['sentAt'],
            'text': lastMessageDoc['text'],
          };
          Map<String, dynamic> chatInfo = {
            'lastMessage': lastMessage,
            'thisUserIsChatRead': 0, //c1
            'chatUserIsChatRead': 0, //c2
          };
          // c1 = currentuser , c2 = chatuser
          DocumentReference candidate1DirectChat = await accountsCollection.doc(
              candidateId1).collection('directChats').doc(chatId);
          await candidate1DirectChat.update(chatInfo);
        }
        //delete for candidate2
        print(highestDocId);
        if (highestDocId != '') {
          DocumentSnapshot documentSnapshot = await chatColRef.doc(highestDocId).get();
          Map<String, dynamic>? updateData = documentSnapshot.data() as Map<String, dynamic>?;
// Check if the document exists and the data is not null
          if (updateData != null) {
            Map<String, dynamic> lastMessage = {
              'senderId': updateData['senderId'],
              'sentAt': updateData['sentAt'],
              'text': updateData['text'],
            };
            Map<String, dynamic> chatInfo = {
              'lastMessage': lastMessage,
              'thisUserIsChatRead': 0, //c1
              'chatUserIsChatRead': 0, //c2
            };
            // c1 = currentuser , c2 = chatuser
            DocumentReference candidate2DirectChat = await accountsCollection
                .doc(
                candidateId2).collection('directChats').doc(chatId);
            await candidate2DirectChat.update(chatInfo);
          } else {
            Timestamp timestamp = Timestamp.now();
            Map<String, dynamic> lastMessage = {
              'senderId': '',
              'sentAt': timestamp,
              'text': '',
            };
            Map<String, dynamic> chatInfo = {
              'lastMessage': lastMessage,
              'thisUserIsChatRead': 0, //c1
              'chatUserIsChatRead': 0, //c2
            };
            // c1 = currentuser , c2 = chatuser
            DocumentReference candidate2DirectChat = await accountsCollection.doc(
                candidateId2).collection('directChats').doc(chatId);
            await candidate2DirectChat.update(chatInfo);
          }
        } else {
          Timestamp timestamp = Timestamp.now();
          Map<String, dynamic> lastMessage = {
            'senderId': '',
            'sentAt': timestamp,
            'text': '',
          };
          Map<String, dynamic> chatInfo = {
            'lastMessage': lastMessage,
            'thisUserIsChatRead': 0, //c1
            'chatUserIsChatRead': 0, //c2
          };
          // c1 = currentuser , c2 = chatuser
          DocumentReference candidate2DirectChat = await accountsCollection.doc(
              candidateId2).collection('directChats').doc(chatId);
          await candidate2DirectChat.update(chatInfo);
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error in deleting chat messages $e');
      return false;
    }
  }
}