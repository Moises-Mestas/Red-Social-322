import 'package:flutter/material.dart';
import 'package:flutter_application_3/services/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      await _authService.signInWithGoogle();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Inicio de sesión exitoso",
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Error al iniciar sesión: $e"),
        ),
      );
      rethrow;
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await _authService.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            "Sesión cerrada exitosamente",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Error al cerrar sesión: $e"),
        ),
      );
      rethrow;
    }
  }
}
