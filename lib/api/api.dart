import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_chat/api/message.dart';
import 'package:go_chat/models/chat_user.dart';
import 'package:http/http.dart';

class Api {
  static late Chatuser me;
  //to return current user
  static User get user => auth.currentUser!;
  //for authentication
  static FirebaseAuth auth = FirebaseAuth.instance;
  //for using firebase storage
  static FirebaseStorage storage = FirebaseStorage.instance;
// for firbase messaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  //for accessing cloud firestore data
  static FirebaseFirestore fire = FirebaseFirestore.instance;
  //for checking if user exist

  static Future<bool> userExists() async {
    return (await fire.collection('users').doc(auth.currentUser!.uid).get())
        .exists;
  }

  static Future<bool> addChatUser(String email) async {
    final data =
        await fire.collection('users').where('email', isEqualTo: email).get();
    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      //user exists
      fire
          .collection('users')
          .doc(user.uid)
          .collection('my_users')
          .doc(data.docs.first.id)
          .set({});
      return true;
    } else {
      return false;
    }
  }

  static Future<void> getSelfinfo() async {
    await fire.collection('users').doc(user.uid).get().then(
      (user) async {
        if (user.exists) {
          me = Chatuser.fromJson(user.data()!);
          await getFirebaseMessagingToken();
          Api.updateActiveStatus(true);
        } else {
          await Createuser().then(
            (value) => getSelfinfo(),
          );
        }
      },
    );
  }

  //for creating a new user
  static Future<void> Createuser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final chatuser = Chatuser(
        image: user.photoURL.toString(),
        name: user.displayName.toString(),
        about: 'Hey i am using Go chat',
        createdAt: time,
        isOnline: false,
        lastActive: time,
        id: user.uid,
        pushToken: '',
        email: user.email.toString());

    return await fire.collection('users').doc(user.uid).set(chatuser.toJson());
  }

// for getting all users from firebase firestore
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAlluser(
      List<String> UserIds) {
    return fire
        .collection('users')
        .where('id', whereIn: UserIds.isEmpty ? [''] : UserIds)
        //.where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUserId() {
    return fire
        .collection('users')
        .doc(user.uid)
        .collection('my_users')
        .snapshots();
  }

  static Future<void> sendFirstMessage(
      Chatuser chatUser, String msg, Type type) async {
    await fire
        .collection('users')
        .doc(chatUser.id)
        .collection('my_users')
        .doc(user.uid)
        .set({}).then((value) => Sendmessages(chatUser, msg, type));
  }

// to update user info
  static Future<void> updateUserInfo() async {
    await fire.collection('users').doc(auth.currentUser!.uid).update({
      'name': me.name,
      'about': me.about,
    });
  }

//to update profile picture
  static Future<void> updateProfilepicture(File file) async {
    final ext = file.path.split('.').last;
    log('Extension:$ext');
    final ref = storage.ref().child('profile_pictures/${user.uid}.$ext');
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data transferred:${p0.bytesTransferred / 1000}kb');
    });
    me.image = await ref.getDownloadURL();
    await fire.collection('users').doc(user.uid).update({
      'image': me.image,
    });
  }
//chats(collection)-->conversation_id(doc)-->messages(collection)-->message(doc)

//useful for getting conversation id
  static String getConversationid(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : "${id}_${user.uid}";
//for getting all messages of a specific conversation from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllmessages(
      Chatuser user) {
    return fire
        .collection('chats/${getConversationid(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .snapshots();
  }

//for sending message
  static Future<void> Sendmessages(
      Chatuser chatuser, String msg, Type type) async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final Message message = Message(
        msg: msg,
        toId: chatuser.id,
        read: '',
        type: type,
        sent: time,
        fromId: user.uid);
    final ref =
        fire.collection('chats/${getConversationid(chatuser.id)}/messages/');
    await ref.doc(time).set(message.toJson()).then((value) =>
        sendPushNotification(chatuser, type == Type.text ? msg : 'image'));
  }

//to update status of a message (blue tick)
  static Future<void> Updatemessagereadstatus(Message message) async {
    fire
        .collection('chats/${getConversationid(message.fromId)}/messages/')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

//getting only last message of a specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getlastmessage(
      Chatuser user) {
    return fire
        .collection('chats/${getConversationid(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  //send chat image
  static Future<void> SendChatimage(Chatuser ch, File file) async {
    final ext = file.path.split('.').last;
    log('Extension:$ext');
    final ref = storage.ref().child(
        'images/${getConversationid(ch.id)}/${DateTime.now().millisecondsSinceEpoch}$ext');
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data transferred:${p0.bytesTransferred / 1000}kb');
    });
    final imageUrl = await ref.getDownloadURL();
    await Sendmessages(ch, imageUrl, Type.image);
  }

//to get user info
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserinfo(
      Chatuser chatu) {
    return fire
        .collection('users')
        .where('id', isEqualTo: chatu.id)
        .snapshots();
  }

// to update status of user(online or not)
  static Future<void> updateActiveStatus(bool isOnline) async {
    fire.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken
    });
  }

  //for getting firebase messaging token
  static Future<void> getFirebaseMessagingToken() async {
    FirebaseMessaging fmessaging = FirebaseMessaging.instance;

    await fmessaging.requestPermission();
    await fmessaging.getToken().then((t) {
      if (t != null) {
        me.pushToken = t;
        print('Push Token: $t');
      }
    });
    // for handling foreground messages
    //FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // print('Got a message whilst in the foreground!');
    //print('Message data: ${message.data}');

    //if (message.notification != null) {
    //  print('Message also contained a notification: ${message.notification}');
  }
  //});
//}

  static Future<void> sendPushNotification(
      Chatuser chatUser, String msg) async {
    try {
      final body = {
        "to": chatUser.pushToken,
        "notification": {
          "title": me.name, //our name should be send
          "body": msg,
          "android_channel_id": "chats"
        },
        "data": {
          "some_data": "User ID: ${me.id}",
        },
      };

      var res = await post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader:
                'key=AAAAzcV-UKg:APA91bFCqIOEZp07e3CShqcih-es9m9mwWflZTuh_TOXV8HoBKSjV8SNQqz9P4JRdjEW5jx4B9I05RcFqT0d1M_8LmKZtY4tOJk7xO_otcJHm3sc9GpJ1KFmTxxL_YOmU0v5vs6XMS7M'
          },
          body: jsonEncode(body));
      print('Response status: ${res.statusCode}');
      print('Response body: ${res.body}');
    } catch (e) {
      print('\nsendPushNotificationE: $e');
    }
  }

  static Future<void> deleteMessage(Message message) async {
    await fire
        .collection('chats/${getConversationid(message.toId)}/messages/')
        .doc(message.sent)
        .delete();
    if (message.type == Type.image) {
      await storage.refFromURL(message.msg);
    }
  }

  static Future<void> updateMessage(Message message, String updatmsg) async {
    await fire
        .collection('chats/${getConversationid(message.toId)}/messages/')
        .doc(message.sent)
        .update({'msg': updatmsg});
  }
}
