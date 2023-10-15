//import 'dart:convert';

//import 'dart:convert';
//import 'package:flutter/foundation.dart' as foundation;

import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import "package:flutter/material.dart";
import 'package:go_chat/helper/my_date_uti.dart';
import 'package:go_chat/models/chat_user.dart';
import 'package:go_chat/api/message.dart';
import 'package:go_chat/screens/view_profilescreen.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api.dart';
import '../main.dart';
import '../widgets/messagecard.dart';

class Chatscreen extends StatefulWidget {
  final Chatuser user;
  const Chatscreen({super.key, required this.user});

  @override
  State<Chatscreen> createState() => _ChatscreenState();
}

class _ChatscreenState extends State<Chatscreen> {
  //for storing all messages
  List<Message> _list = [];
  //for handling message text change
  final _texController = TextEditingController();
  //for checking if images are uploading
  //for controlling emojis,
  bool _showemoji = false, _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: WillPopScope(
          onWillPop: () {
            if (_showemoji) {
              setState(() {
                _showemoji = !_showemoji;
              });
              return Future.value(false);
            } else {
              return Future.value(true);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              flexibleSpace: _appbar(),
            ),
            backgroundColor: Color.fromARGB(255, 170, 206, 235),
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                      stream: Api.getAllmessages(widget.user),
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.waiting:
                          case ConnectionState.none:
                            return SizedBox();
                          case ConnectionState.active:
                          case ConnectionState.done:
                            final data = snapshot.data?.docs;
                            //print('Data:${jsonEncode(data![0].data())}');
                            _list = data
                                    ?.map((e) => Message.fromJson(e.data()))
                                    .toList() ??
                                [];

                            if (_list.isNotEmpty) {
                              return ListView.builder(
                                  reverse: true,
                                  physics: BouncingScrollPhysics(),
                                  padding:
                                      EdgeInsets.only(top: mq.height * .0005),
                                  itemCount: _list.length,
                                  itemBuilder: (context, index) {
                                    return MessageCard(
                                      message: _list[index],
                                    );
                                  });
                            } else {
                              return Center(
                                  child: Text(
                                'Say Hi!👋',
                                style: TextStyle(fontSize: 20),
                              ));
                            }
                        }
                      }),
                ),
                if (_isUploading)
                  Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ))),
                _chatInput(),
                if (_showemoji)
                  SizedBox(
                    height: mq.height * .35,
                    child: EmojiPicker(
                      textEditingController:
                          _texController, // pass here the same [TextEditingController] that is connected to your input field, usually a [TextFormField]

                      config: Config(
                        bgColor: Color.fromARGB(255, 170, 206, 235),

                        columns: 8,

                        emojiSizeMax: 32 *
                            (Platform.isIOS
                                ? 1.30
                                : 1.0), // Issue: https://github.com/flutter/flutter/issues/28894
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

//custom app bar
  Widget _appbar() {
    return InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ViewProfileScreen(user: widget.user))),
        child: StreamBuilder(
          stream: Api.getUserinfo(widget.user),
          builder: (context, snapshot) {
            final data = snapshot.data?.docs;
            final list =
                data?.map((e) => Chatuser.fromJson(e.data())).toList() ?? [];

            return Row(
              children: [
                //back button
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.black54,
                    )),
                // profile picture
                ClipRRect(
                  borderRadius: BorderRadius.circular(mq.height * .3),
                  child: CachedNetworkImage(
                    width: mq.height * .055,
                    height: mq.height * .055,
                    imageUrl:
                        list.isNotEmpty ? list[0].image : widget.user.image,
                    //placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => CircleAvatar(
                        child:
                            Icon(CupertinoIcons.person)), //Icon(Icons.error),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      list.isNotEmpty ? list[0].name : widget.user.name,
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                        list.isNotEmpty
                            ? list[0].isOnline
                                ? 'Online'
                                : MydateUtil.getLastActiveTime(
                                    context: context,
                                    lastActive: list[0].lastActive)
                            : MydateUtil.getLastActiveTime(
                                context: context,
                                lastActive: widget.user.lastActive),
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ))
                  ],
                )
              ],
            );
          },
        ));
  }

// chatting text input
  Widget _chatInput() {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: mq.height * .01, horizontal: mq.width * .025),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    IconButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _showemoji = !_showemoji;
                          });
                        },
                        icon: Icon(
                          Icons.emoji_emotions,
                          color: Colors.blueAccent,
                        )),
                    Expanded(
                        child: TextField(
                      controller: _texController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      onTap: () {
                        if (_showemoji)
                          setState(() {
                            _showemoji = !_showemoji;
                          });
                      },
                      decoration: InputDecoration(
                          hintText: 'Type someting...',
                          hintStyle: TextStyle(color: Colors.blueAccent),
                          border: InputBorder.none),
                    )),
                    IconButton(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          // Pick an image.
                          final List<XFile> images =
                              await picker.pickMultiImage(imageQuality: 70);
                          for (var i in images) {
                            log('Image path:${i.path}');
                            setState(() {
                              _isUploading = true;
                            });
                            await Api.SendChatimage(widget.user, File(i.path));
                            setState(() {
                              _isUploading = false;
                            });
                          }
                        },
                        icon: Icon(
                          Icons.image,
                          color: Colors.blueAccent,
                        )),
                    IconButton(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          // Pick an image.
                          final XFile? image = await picker.pickImage(
                              source: ImageSource.camera, imageQuality: 70);
                          if (image != null) {
                            log('image path:${image.path}--Mimetype:${image.mimeType}');
                            setState(() {
                              _isUploading = true;
                            });
                            await Api.SendChatimage(
                                widget.user, File(image.path));
                            setState(() {
                              _isUploading = false;
                            });
                          }
                        },
                        icon: Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.blueAccent,
                        )),
                    SizedBox(
                      width: mq.width * .02,
                    )
                  ],
                ),
              ),
            ),
          ),
          MaterialButton(
            padding: EdgeInsets.only(top: 10, bottom: 10, right: 5, left: 10),
            minWidth: 0,
            onPressed: () {
              if (_texController.text.isNotEmpty) {
                if (_list.isEmpty) {
                  //on first message (add user to my_user collection of chat user)
                  Api.sendFirstMessage(
                      widget.user, _texController.text, Type.text);
                } else {
                  //simply send message
                  Api.Sendmessages(widget.user, _texController.text, Type.text);
                }

                _texController.text = '';
              }
            },
            shape: CircleBorder(),
            color: Colors.green,
            child: Icon(
              Icons.send,
              color: Colors.blueAccent,
              size: 26,
            ),
          )
        ],
      ),
    );
  }
}
