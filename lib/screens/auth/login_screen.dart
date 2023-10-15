import "dart:developer";
import "dart:io";
import "package:flutter/material.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:go_chat/api/api.dart";
import "package:go_chat/helper/dialogs.dart";
import "package:go_chat/main.dart";
import "package:go_chat/screens/home_screen.dart";
import "package:google_sign_in/google_sign_in.dart";

bool _isAnimate = false;

class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Loginscreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _isAnimate = true;
      });
    });
  }

  _handleGooglebuttonclk() {
    _signInWithGoogle().then((user) async {
      Dialogs.ShowprogressBar(context);
      Navigator.pop(context);
      if (user != null) {
        log('\nUser:${user.user}');
        log('\nUserAdditionalinfo:${user.additionalUserInfo}');
        if ((await Api.userExists())) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => Home()));
        } else {
          await Api.Createuser().then((value) => Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => Home())));
        }
      }
    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      await InternetAddress.lookup('google.com');
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      log('\n_signInWithGoogle:$e');
      Dialogs.Snackbar(context, 'Oops! check your internet connection.');
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    //mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to Go Chat'),
      ),
      body: Stack(
        children: [
          AnimatedPositioned(
              top: mq.height * .15,
              right: _isAnimate ? mq.width * .25 : -mq.width * .5,
              width: mq.width * .5,
              duration: Duration(seconds: 1),
              child: Image.asset('images/bubble-chat.png')),
          Positioned(
            bottom: mq.height * .15,
            left: mq.width * .05,
            width: mq.width * .9,
            height: mq.height * .07,
            child: ElevatedButton.icon(
              label: RichText(
                  text: TextSpan(
                      style: TextStyle(color: Colors.black, fontSize: 16),
                      children: [
                    TextSpan(text: 'Sign in with'),
                    TextSpan(
                        text: ' Google',
                        style: TextStyle(fontWeight: FontWeight.w500))
                  ])),
              icon: Image.asset(
                'images/google.png',
                height: mq.height * .3,
              ),
              onPressed: () => {_handleGooglebuttonclk()},
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  elevation: 1,
                  shape: StadiumBorder()),
            ),
          )
        ],
      ),
    );
  }
}
