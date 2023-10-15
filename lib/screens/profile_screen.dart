import "dart:developer";
import "dart:io";
//import 'package:firebase_storage/firebase_storage.dart';
import "package:cached_network_image/cached_network_image.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:go_chat/helper/dialogs.dart";
import "package:go_chat/main.dart";
import "package:go_chat/models/chat_user.dart";
import "package:go_chat/screens/auth/login_screen.dart";
//import "package:go_chat/widgets/userCard.dart";
import "package:google_sign_in/google_sign_in.dart";
import "package:image_picker/image_picker.dart";

import "../api/api.dart";

class Profilescreen extends StatefulWidget {
  final Chatuser user;
  const Profilescreen({super.key, required this.user});

  @override
  State<Profilescreen> createState() => _ProfilescreenState();
}

class _ProfilescreenState extends State<Profilescreen> {
  List<Chatuser> list = [];
  final _formkey = GlobalKey<FormState>();
  String? im;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
            appBar: AppBar(
              title: Text('Profile screen'),
            ),
            floatingActionButton: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton.extended(
                backgroundColor: Colors.redAccent,
                label: Text('Logout'),
                onPressed: () async {
                  Dialogs.ShowprogressBar(context);
                  await Api.updateActiveStatus(false);
                  await Api.auth.signOut().then(
                    (value) async {
                      await GoogleSignIn().signOut().then(
                        (value) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                          Api.auth = FirebaseAuth.instance;
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => Loginscreen()));
                        },
                      );
                    },
                  );
                },
                icon: Icon(Icons.logout),
              ),
            ),
            body: Form(
              key: _formkey,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        width: mq.width,
                        height: mq.height * .03,
                      ),
                      Stack(
                        children: [
                          im != null
                              ? ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(mq.height * .1),
                                  child: Image.file(File(im!),
                                      width: mq.height * .2,
                                      height: mq.height * .2,
                                      fit: BoxFit.cover),
                                )
                              : ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(mq.height * .1),
                                  child: CachedNetworkImage(
                                    width: mq.height * .2,
                                    height: mq.height * .2,
                                    fit: BoxFit.fill,
                                    imageUrl: widget.user.image,
                                    //placeholder: (context, url) => CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                        CircleAvatar(
                                            child: Icon(CupertinoIcons
                                                .person)), //Icon(Icons.error),
                                  ),
                                ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: MaterialButton(
                              onPressed: _showBottomSheet,
                              color: Colors.white,
                              shape: CircleBorder(),
                              elevation: 1,
                              child: Icon(
                                Icons.edit,
                                color: Colors.blue,
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: mq.height * .05,
                      ),
                      Text(widget.user.email,
                          style:
                              TextStyle(color: Colors.black54, fontSize: 16)),
                      SizedBox(
                        height: mq.height * .05,
                      ),
                      TextFormField(
                        onSaved: (val) => Api.me.name = val ?? '',
                        validator: (val) => val != null && val.isNotEmpty
                            ? null
                            : 'Required Field',
                        initialValue: widget.user.name,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.person,
                            color: Colors.blue,
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          hintText: 'eg: Your name',
                          label: Text('Name'),
                        ),
                      ),
                      SizedBox(
                        height: mq.height * .05,
                      ),
                      TextFormField(
                        onSaved: (val) => Api.me.about = val ?? '',
                        validator: (val) => val != null && val.isNotEmpty
                            ? null
                            : 'Required Field',
                        initialValue: widget.user.about,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.mood,
                            color: Colors.blue,
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          hintText: 'eg: feeling happy',
                          label: Text('About'),
                        ),
                      ),
                      SizedBox(
                        height: mq.height * .05,
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_formkey.currentState!.validate()) {
                            _formkey.currentState!.save();
                            Api.updateUserInfo().then(
                              (value) {
                                Dialogs.Snackbar(
                                    context, 'Profile updated succesfully!');
                              },
                            );
                            log('inside validator');
                          }
                        },
                        icon: Icon(
                          Icons.login,
                          size: 28,
                        ),
                        label: Text(
                          'UPDATE',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                            shape: StadiumBorder(),
                            minimumSize: Size(mq.width * .4, mq.height * .055)),
                      )
                    ],
                  ),
                ),
              ),
            )),
      ),
    );
  }

  void _showBottomSheet() {
    showModalBottomSheet(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        context: context,
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            padding:
                EdgeInsets.only(top: mq.height * .03, bottom: mq.height * .05),
            children: [
              Text(
                'Pick profile picture',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              SizedBox(
                height: mq.height * .02,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      // Pick an image.
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        log('image path:${image.path}--Mimetype:${image.mimeType}');
                        //Api.updateProfilepicture(File(im!));

                        setState(() {
                          im = image.path;
                        });
                        Api.updateProfilepicture(File(im!));
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: CircleBorder(),
                        fixedSize: Size(mq.width * .3, mq.height * .15)),
                    child: Image.asset('images/gallery.png'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      // Pick an image.
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (image != null) {
                        log('image path:${image.path}--Mimetype:${image.mimeType}');

                        setState(() {
                          im = image.path;
                        });
                        Api.updateProfilepicture(File(im!));
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: CircleBorder(),
                        fixedSize: Size(mq.width * .3, mq.height * .15)),
                    child: Image.asset('images/camera.png'),
                  )
                ],
              )
            ],
          );
        });
  }
}
