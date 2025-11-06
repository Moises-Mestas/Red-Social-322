import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_application_3/services/database_service.dart';
import 'package:flutter_application_3/services/shared_pref_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  Future<User?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) return null;

      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) return null;

      // Guardar datos del usuario
      final username = user.email!.replaceAll("@gmail.com", "").toUpperCase();
      final firstletter = username.substring(0, 1);

      await SharedPrefService().saveUserData(
        displayName: user.displayName ?? "",
        email: user.email ?? "",
        userId: user.uid,
        username: username,
        imageUrl: user.photoURL ?? "",
      );

      // Crear/actualizar usuario en base de datos
      await DatabaseService().addUser(user.uid, {
        "Name": user.displayName,
        "Email": user.email,
        "Image": user.photoURL,
        "Id": user.uid,
        "username": username,
        "SearchKey": firstletter.toUpperCase(),
      });

      return user;
    } catch (e) {
      print("Error en signInWithGoogle: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      await SharedPrefService().clearUserData();
    } catch (e) {
      print("Error en signOut: $e");
      rethrow;
    }
  }

  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }
}
