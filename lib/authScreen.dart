import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myloginpage/Home.dart';
import 'package:myloginpage/HomeScreen.dart';
import 'package:myloginpage/login.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(builder: (context,snapshot){
      if(snapshot.hasData){
        return MaterialApp(home:Home());
      }

      return MaterialApp(home: MyLogin());
    },stream: FirebaseAuth.instance.authStateChanges(),);
  }
}
