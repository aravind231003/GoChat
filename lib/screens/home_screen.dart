import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:go_chat/main.dart";
import "package:go_chat/models/chat_user.dart";
import "package:go_chat/screens/profile_screen.dart";
//import "package:go_chat/widgets/userCard.dart";
//import "package:google_sign_in/google_sign_in.dart";
//import 'dart:convert';

import "../api/api.dart";
import "../helper/dialogs.dart";
import "../widgets/userCard.dart";

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomescreenState();
}

class _HomescreenState extends State<Home> {
  List<Chatuser> list = [];
  final List<Chatuser> _searchlist = [];
  bool _isSearching = false;
  @override
  void initState() {
    super.initState();
    Api.getSelfinfo();
    Api.updateActiveStatus(true);
    SystemChannels.lifecycle.setMessageHandler((message) {
      if (Api.auth.currentUser == null) {
        if (message.toString().contains('resume')) Api.updateActiveStatus(true);
        if (message.toString().contains('pause')) Api.updateActiveStatus(false);
      }

      return Future.value(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () {
          if (_isSearching) {
            setState(() {
              _isSearching = !_isSearching;
            });
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
          appBar: AppBar(
              title: _isSearching
                  ? TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Name,email",
                      ),
                      autofocus: true,
                      style: TextStyle(fontSize: 16, letterSpacing: .5),
                      onChanged: (val) {
                        _searchlist.clear();
                        for (var i in list) {
                          if (i.name
                                  .toLowerCase()
                                  .contains(val.toLowerCase()) ||
                              i.email
                                  .toLowerCase()
                                  .contains(val.toLowerCase())) {
                            _searchlist.add(i);
                          }
                          setState(() {
                            _searchlist;
                          });
                        }
                      },
                    )
                  : Text('Go Chat'),
              leading: Icon(CupertinoIcons.home),
              actions: [
                IconButton(
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                      });
                    },
                    icon: Icon(_isSearching
                        ? CupertinoIcons.clear_circled_solid
                        : Icons.search)),
                IconButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => Profilescreen(
                                    user: Api.me,
                                  )));
                    },
                    icon: Icon(Icons.more_vert))
              ]),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FloatingActionButton(
              onPressed: () {
                _addChatUserDialog();
              },
              child: Icon(Icons.add_comment_rounded),
            ),
          ),
          body: StreamBuilder(
            stream: Api.getMyUserId(),

            //get id of only known users
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                //if data is loading
                case ConnectionState.waiting:
                case ConnectionState.none:
                  return const Center(child: CircularProgressIndicator());

                //if some or all data is loaded then show it
                case ConnectionState.active:
                case ConnectionState.done:
                  return StreamBuilder(
                    stream: Api.getAlluser(
                        snapshot.data?.docs.map((e) => e.id).toList() ?? []),

                    //get only those user, who's ids are provided
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        //if data is loading
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                        // return const Center(
                        //     child: CircularProgressIndicator());

                        //if some or all data is loaded then show it
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;
                          list = data
                                  ?.map((e) => Chatuser.fromJson(e.data()))
                                  .toList() ??
                              [];

                          if (list.isNotEmpty) {
                            return ListView.builder(
                                itemCount: _isSearching
                                    ? _searchlist.length
                                    : list.length,
                                padding: EdgeInsets.only(top: mq.height * .01),
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return Usercard(
                                      user: _isSearching
                                          ? _searchlist[index]
                                          : list[index]);
                                });
                          } else {
                            return const Center(
                              child: Text('No Connections Found!',
                                  style: TextStyle(fontSize: 20)),
                            );
                          }
                      }
                    },
                  );
              }
            },
          ),
        ),
      ),
    );
  }

  void _addChatUserDialog() {
    String email = '';

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              contentPadding: const EdgeInsets.only(
                  left: 24, right: 24, top: 20, bottom: 10),

              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),

              //title
              title: Row(
                children: const [
                  Icon(
                    Icons.person_add,
                    color: Colors.blue,
                    size: 28,
                  ),
                  Text('  Add User')
                ],
              ),

              //content
              content: TextFormField(
                maxLines: null,
                onChanged: (value) => email = value,
                decoration: InputDecoration(
                    hintText: 'Email Id',
                    prefixIcon: const Icon(Icons.email, color: Colors.blue),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15))),
              ),

              //actions
              actions: [
                //cancel button
                MaterialButton(
                    onPressed: () {
                      //hide alert dialog
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.blue, fontSize: 16))),

                //add button
                MaterialButton(
                    onPressed: () async {
                      //hide alert dialog
                      Navigator.pop(context);
                      if (email.isNotEmpty) {
                        await Api.addChatUser(email).then((value) {
                          if (!value) {
                            Dialogs.Snackbar(context, 'User does not Exists!');
                          }
                        });
                      }
                    },
                    child: const Text(
                      'Add',
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ))
              ],
            ));
  }
}
