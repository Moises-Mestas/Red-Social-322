import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3/services/database.dart';
import 'package:flutter_application_3/services/shared_pref.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_application_3/pages/home.dart'; // Asegúrate de importar la página de Home
import 'package:flutter_application_3/pages/onboarding.dart'; // Asegúrate de importar la página de Onboarding

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;

  // Obtener el usuario actual
  getCurrentUser() async {
    return await auth.currentUser;
  }

  // Método para iniciar sesión con Google
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        // Usuario canceló el flujo de inicio de sesión
        return;
      }

      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final result = await auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) return;

      // Guardar datos del usuario en SharedPreferences
      final username = user.email!.replaceAll("@gmail.com", "").toUpperCase();
      final firstletter = username.substring(0, 1);

      await SharedpreferencesHelper().saveUserDisplayName(user.displayName ?? "");
      await SharedpreferencesHelper().saveUserEmail(user.email ?? "");
      await SharedpreferencesHelper().saveUserId(user.uid);
      await SharedpreferencesHelper().saveUserName(username);
      await SharedpreferencesHelper().saveUserImage(user.photoURL ?? "");

      // Crea/actualiza el documento del usuario en la base de datos
      await DatabaseMethods().addUser({
        "Name": user.displayName,
        "Email": user.email,
        "Image": user.photoURL,
        "Id": user.uid,
        "username": username,
        "SearchKey": firstletter.toUpperCase(),
      }, user.uid);

      // Mostrar SnackBar de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Inicio de sesión exitoso",
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );

      // Redirigir al Home después de iniciar sesión correctamente
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Home()), // Navegar a la página principal
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Error al iniciar sesión: $e"),
        ),
      );
    }
  }

  // Método para cerrar sesión
  Future<void> signOut(BuildContext context) async {
    try {
      // Cerrar sesión de Firebase
      await auth.signOut();

      // Cerrar sesión de Google si el usuario está conectado
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      // Limpiar los datos guardados en SharedPreferences
      await SharedpreferencesHelper().clearUserData();

      // Mostrar SnackBar de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            "Sesión cerrada exitosamente",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );

      // Redirigir al Onboarding después de cerrar sesión
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Onboarding()), // Redirige al onboarding
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Error al cerrar sesión: $e"),
        ),
      );
    }
  }
}
