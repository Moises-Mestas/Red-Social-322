import 'package:flutter/material.dart';
import 'package:flutter_application_3/controllers/auth_controller.dart';
import 'package:flutter_application_3/controllers/profile_controller.dart';
import 'package:flutter_application_3/services/shared_pref_service.dart';
import 'package:flutter_application_3/views/pages/onboarding_page.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileController _profileController = ProfileController();
  final SharedPrefService _sharedPrefService = SharedPrefService();
  final AuthController _authController = AuthController();

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadUserData(Map<String, dynamic> userData) {
    _nameController.text = userData['displayName'] ?? '';
    _usernameController.text = userData['username'] ?? '';
    _emailController.text = userData['email'] ?? '';
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty || _usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Nombre y apodo son obligatorios'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await _sharedPrefService.getUserId();
      if (userId != null) {
        await _profileController.updateUserProfile(
          userId: userId,
          name: _nameController.text,
          username: _usernameController.text,
          email: _emailController.text,
        );

        setState(() {
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Perfil actualizado exitosamente'),
          ),
        );

        // Recargar la página para mostrar los datos actualizados
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error al actualizar: $e'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changeProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userId = await _sharedPrefService.getUserId();
        if (userId != null) {
          final imageUrl = await _profileController.updateProfileImage(
            userId,
            image,
          );

          if (imageUrl != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.green,
                content: Text('Imagen actualizada exitosamente'),
              ),
            );
            setState(() {});
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error al cambiar imagen: $e'),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
        if (!_isEditing && userData != null) {
          _loadUserData(userData);
        }

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
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 79, 191, 219),
      appBar: AppBar(
        title: const Text("Perfil"),
        backgroundColor: const Color.fromARGB(255, 79, 191, 219),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _loadUserData(userData!);
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.only(
                    bottom: 160,
                    left: 20,
                    right: 20,
                  ),
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
                      // Foto de perfil editable
                      GestureDetector(
                        onTap: _isEditing ? _changeProfileImage : null,
                        child: Container(
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
                          child: Stack(
                            children: [
                              ClipRRect(
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
                              if (_isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Campos editables
                      _buildEditableField(
                        'Email:',
                        _emailController,
                        isEditable: false, // El email no se puede editar
                      ),
                      const SizedBox(height: 20),
                      _buildEditableField(
                        'Nombre:',
                        _nameController,
                        isEditable: _isEditing,
                      ),
                      const SizedBox(height: 20),
                      _buildEditableField(
                        'Apodo:',
                        _usernameController,
                        isEditable: _isEditing,
                      ),
                      const SizedBox(height: 30),

                      // Botón de guardar cambios
                      if (_isEditing)
                        GestureDetector(
                          onTap: _updateProfile,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.save, color: Colors.white),
                                SizedBox(width: 10),
                                Text(
                                  'Guardar cambios',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Botón de "Cerrar sesión"
                      GestureDetector(
                        onTap: () {
                          _authController.signOut(context);
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
  }

  // Método para crear campos editables
  Widget _buildEditableField(
    String title,
    TextEditingController controller, {
    required bool isEditable,
  }) {
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
            color: isEditable ? Colors.white : Colors.grey[200],
            borderRadius: BorderRadius.circular(15),
            border: isEditable ? Border.all(color: Colors.blue) : null,
          ),
          child: isEditable
              ? TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                )
              : Text(
                  controller.text.isEmpty ? 'No disponible' : controller.text,
                  style: TextStyle(fontSize: 18, color: Colors.black87),
                ),
        ),
      ],
    );
  }

  // Método para obtener los datos del usuario
  Future<Map<String, dynamic>> _getUserData() async {
    final userData = await _sharedPrefService.getAllUserData();

    return {
      'displayName': userData['displayName'],
      'email': userData['email'],
      'username': userData['username'],
      'imageUrl': userData['imageUrl'],
    };
  }
}
