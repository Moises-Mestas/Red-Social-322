import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3/services/database.dart';
import 'package:flutter_application_3/services/shared_pref.dart';


import 'package:google_sign_in/google_sign_in.dart';

class AuthMethods{
  final FirebaseAuth auth= FirebaseAuth.instance;
  
  getCurrentUser()async{
    return await auth.currentUser;
  }
  signInWithGoogle(BuildContext context) async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    final GoogleSignIn googleSignIn = GoogleSignIn();

    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();

    final GoogleSignInAuthentication? googleSignInAuthentication =
        await googleSignInAccount?.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleSignInAuthentication?.idToken,
      accessToken: googleSignInAuthentication?.accessToken,
    );

    UserCredential result = await firebaseAuth.signInWithCredential(credential);

    User? userDetails = result.user;
    String username= userDetails!.email!.replaceAll("@gmail.com", ""); 
    String firstletter= username.substring(0,1).toUpperCase();
    await SharedpreferencesHelper().saveUserDisplayName(userDetails!.displayName!);
    await SharedpreferencesHelper().saveUserEmail(userDetails.email!);
    await SharedpreferencesHelper().saveUserId(userDetails.uid!);
    await SharedpreferencesHelper().saveUserName(username!);
    await SharedpreferencesHelper().saveUserImage(userDetails.photoURL!);

    if (result != null) {
      Map<String, dynamic> userInfoMap={
        "Name": userDetails!.displayName,
        "Email": userDetails!.email,
        "Image": userDetails.photoURL,
        "Id": userDetails.uid,
        "username": username.toUpperCase(),
        "SearchKey":  firstletter             

      };
      await DatabaseMethods().addUser(userInfoMap, userDetails!.uid).then((valur){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.green,
          content: Text("Registro Exitoso", style: TextStyle(color: Colors.black, fontSize: 25, fontWeight: FontWeight.bold ))));
      });
    }
  }

}