import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:go_chat/helper/my_date_uti.dart";
import "package:go_chat/main.dart";
import "package:go_chat/models/chat_user.dart";

import "../api/api.dart";
import "../api/message.dart";
import "../screens/chatscreen.dart";
import "dialogs/profile_dialogs.dart";
//import "package:go_chat/main.dart";

class Usercard extends StatefulWidget {
  final Chatuser user;
  const Usercard({super.key, required this.user});

  @override
  State<Usercard> createState() => _UsercardState();
}

class _UsercardState extends State<Usercard> {
  Message? _message;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => Chatscreen(user: widget.user)));
          },
          child: StreamBuilder(
            stream: Api.getlastmessage(widget.user),
            builder: (context, snapshot) {
              final data = snapshot.data?.docs;
              final list =
                  data?.map((e) => Message.fromJson(e.data())).toList() ?? [];
              if (list.isNotEmpty) _message = list[0];
              return ListTile(
                //user profile picture
                leading: InkWell(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (_) => ProfileDialog(user: widget.user));
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(mq.height * .03),
                    child: CachedNetworkImage(
                      width: mq.height * .055,
                      height: mq.height * .055,
                      imageUrl: widget.user.image,
                      errorWidget: (context, url, error) => const CircleAvatar(
                          child: Icon(CupertinoIcons.person)),
                    ),
                  ),
                ),

                //user name
                title: Text(widget.user.name),

                //last message
                subtitle: Text(
                    _message != null
                        ? _message!.type == Type.image
                            ? 'image'
                            : _message!.msg
                        : widget.user.about,
                    maxLines: 1),

                //last message time
                trailing: _message == null
                    ? null //show nothing when no message is sent
                    : _message!.read.isEmpty && _message!.fromId != Api.user.uid
                        ?
                        //show for unread message
                        Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                                color: Colors.greenAccent.shade400,
                                borderRadius: BorderRadius.circular(10)),
                          )
                        :
                        //message sent time
                        Text(
                            MydateUtil.getLastmessage(
                                context: context, time: _message!.sent),
                            style: const TextStyle(color: Colors.black54),
                          ),
              );
            },
          )),
    );
  }
}
