import 'package:flutter/material.dart';
import 'package:flutter_application_3/pages/onboarding.dart';
import 'package:flutter_application_3/services/shared_pref.dart';
import 'package:flutter_application_3/services/auth.dart'; // Importamos el servicio de autenticación

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Color.fromARGB(255, 79, 191, 219), // Fondo con el color que mencionaste
            appBar: AppBar(
              title: const Text("Perfil"),
              backgroundColor: Color.fromARGB(255, 79, 191, 219),
            ),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Color.fromARGB(255, 79, 191, 219), // Fondo con el color que mencionaste
            appBar: AppBar(
              title: const Text("Perfil"),
              backgroundColor: Color.fromARGB(255, 79, 191, 219),
            ),
            body: Center(
              child: Text('Error al cargar los datos del usuario'),
            ),
          );
        }

        var userData = snapshot.data;
        return Scaffold(
          backgroundColor: Color.fromARGB(255, 79, 191, 219), // Fondo con el color que mencionaste
          appBar: AppBar(
            title: const Text("Perfil"),
            backgroundColor: Color.fromARGB(255, 79, 191, 219),
          ),
          body: Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.only(bottom: 160, left: 20, right: 20),
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Contorno bonito alrededor de la foto
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: Color.fromARGB(255, 79, 191, 219),
                          width: 5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(3), // Espacio entre la imagen y el borde
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(80),
                        child: Image.network(
                          userData?['photoURL'],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Textos alineados al centro
                    _buildUserDataField('Email:', userData?['email']),
                    const SizedBox(height: 20),
                    _buildUserDataField('Nombre:', userData?['displayName']),
                    const SizedBox(height: 20),
                    _buildUserDataField('Apodo:', userData?['username']),
                    const SizedBox(height: 30),
                    // Botón de "Cerrar sesión"
                    GestureDetector(
                      onTap: () {
                        AuthMethods().signOut(context); // Cerrar sesión
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => Onboarding()), // Redirigir a Onboarding
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.only(top: 20),
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.exit_to_app, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Cerrar sesión',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Método para obtener los datos del usuario desde SharedPreferences
  Future<Map<String, dynamic>> _getUserData() async {
    SharedpreferencesHelper prefsHelper = SharedpreferencesHelper();

    String? name = await prefsHelper.getUserDisplayName();
    String? email = await prefsHelper.getUserEmail();
    String? username = await prefsHelper.getUserName();
    String? photoURL = await prefsHelper.getUserImage();

    return {
      'displayName': name,
      'email': email,
      'username': username,
      'photoURL': photoURL,
    };
  }

  // Método para crear los campos de datos del usuario (Email, Nombre, Apodo)
  Widget _buildUserDataField(String title, String? data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 79, 191, 219),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            data ?? 'No disponible',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
