import "dart:developer";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:go_chat/api/api.dart";
import "package:go_chat/main.dart";
import "package:go_chat/screens/auth/login_screen.dart";
import "package:go_chat/screens/home_screen.dart";

class Splashscreeen extends StatefulWidget {
  const Splashscreeen({super.key});

  @override
  State<Splashscreeen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreeen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(systemNavigationBarColor: Colors.black));
      if (Api.auth.currentUser != null) {
        log('\nUser:${Api.auth.currentUser}');
        log('\nUserAdditionalinfo:${Api.auth.currentUser}');
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => Home()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => Loginscreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to Go Chat'),
      ),
      body: Stack(
        children: [
          Positioned(
              top: mq.height * .15,
              width: mq.width * .5,
              right: mq.width * .25,
              child: Image.asset('images/bubble-chat.png')),
          Positioned(
              bottom: mq.height * .15,
              width: mq.width,
              child: Text(
                'Chatting is fun!  😍',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 5),
              )),
        ],
      ),
    );
  }
}
