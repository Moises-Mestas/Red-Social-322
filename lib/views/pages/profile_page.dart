import 'package:flutter/material.dart';
import 'package:flutter_application_3/controllers/auth_controller.dart';
import 'package:flutter_application_3/services/shared_pref_service.dart';
import 'package:flutter_application_3/views/pages/onboarding_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScaffold();
        }

        if (snapshot.hasError) {
          return _buildErrorScaffold();
        }

        var userData = snapshot.data;
        return _buildProfileScaffold(context, userData);
      },
    );
  }

  Scaffold _buildLoadingScaffold() {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 79, 191, 219),
      appBar: AppBar(
        title: const Text("Perfil"),
        backgroundColor: const Color.fromARGB(255, 79, 191, 219),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Scaffold _buildErrorScaffold() {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 79, 191, 219),
      appBar: AppBar(
        title: const Text("Perfil"),
        backgroundColor: const Color.fromARGB(255, 79, 191, 219),
      ),
      body: const Center(child: Text('Error al cargar los datos del usuario')),
    );
  }

  Scaffold _buildProfileScaffold(
    BuildContext context,
    Map<String, dynamic>? userData,
  ) {
    final AuthController authController = AuthController();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 79, 191, 219),
      appBar: AppBar(
        title: const Text("Perfil"),
        backgroundColor: const Color.fromARGB(255, 79, 191, 219),
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
                  offset: const Offset(0, 5),
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
                      color: const Color.fromARGB(255, 79, 191, 219),
                      width: 5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(80),
                    child: Image.network(
                      userData?['imageUrl'] ?? '',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          ),
                        );
                      },
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
                    authController.signOut(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OnboardingPage(),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.exit_to_app, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Cerrar sesión',
                          style: TextStyle(color: Colors.white, fontSize: 18),
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
  }

  // Método para obtener los datos del usuario desde SharedPreferences
  Future<Map<String, dynamic>> _getUserData() async {
    final SharedPrefService prefsHelper = SharedPrefService();
    final userData = await prefsHelper.getAllUserData();

    return {
      'displayName': userData['displayName'],
      'email': userData['email'],
      'username': userData['username'],
      'imageUrl': userData['imageUrl'],
    };
  }

  // Método para crear los campos de datos del usuario (Email, Nombre, Apodo)
  Widget _buildUserDataField(String title, String? data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 79, 191, 219),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            data ?? 'No disponible',
            style: const TextStyle(fontSize: 18, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
