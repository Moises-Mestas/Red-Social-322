// user_profile_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_3/controllers/followers_controller.dart';
import 'package:flutter_application_3/controllers/chat_controller.dart';
import 'package:flutter_application_3/services/database_service.dart';
import 'package:flutter_application_3/services/shared_pref_service.dart';
import 'package:flutter_application_3/core/constants/app_constants.dart';
import 'package:flutter_application_3/views/pages/chat_page.dart';

// --- Imports añadidos para la barra de navegación ---
import 'package:flutter_application_3/views/pages/principal_page.dart';
import 'package:flutter_application_3/views/pages/home_page.dart';
import 'package:flutter_application_3/views/pages/grupos_page.dart';
import 'package:flutter_application_3/views/pages/profile_page.dart';
// --- Import AÑADIDO para la edición ---
import 'package:flutter_application_3/views/pages/edit_profile_page.dart';
// ----------------------------------------------------

class UserProfilePage extends StatefulWidget {
  final String username;

  const UserProfilePage({super.key, required this.username});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FollowersController _followController = FollowersController();
  final ChatController _chatController = ChatController();
  final DatabaseService _databaseService = DatabaseService();
  final SharedPrefService _sharedPrefService = SharedPrefService();

  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _userProfileData = {};
  String? _userId; // ID del perfil que se está viendo
  String? _myUsername; // Mi propio apodo (para la barra de nav)
  int _followersCount = 0;
  int _followingCount = 0;
  int _postsCount = 0;
  bool _isFollowing = false;
  bool _isLoading = true;
  int _selectedTab = 0;
  bool _isSendingMessage = false;

  int _selectedIndex = 1;
  bool _isMyProfile = false; // <-- AÑADIDO: Para saber si es mi perfil

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkIfThisIsMyProfile();
  }

  // --- MODIFICADO: Comprobar si el perfil que se visita es el mío ---
  Future<void> _checkIfThisIsMyProfile() async {
    _myUsername = await _sharedPrefService.getUserName();
    if (widget.username == _myUsername) {
      setState(() {
        _selectedIndex = 1; // Si es mi perfil, el ícono 1 está activo
        _isMyProfile = true; // <-- AÑADIDO
      });
    } else {
      setState(() {
        _selectedIndex = -1; // No es mi perfil, ningún ícono está activo
        _isMyProfile = false; // <-- AÑADIDO
      });
    }
  }
  // -----------------------------------------------------------

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    if (index == 1 && _myUsername == null) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Muro Principal
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, a, b) => const PrincipalPage(),
            transitionDuration: Duration.zero,
          ),
        );
        break;
      case 1: // Mi Perfil (UserProfilePage)
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            // Navega a MI PROPIO perfil
            pageBuilder: (context, a, b) =>
                UserProfilePage(username: _myUsername!),
            transitionDuration: Duration.zero,
          ),
        );
        break;
      case 2: // Chats (HomePage)
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, a, b) => const HomePage(),
            transitionDuration: Duration.zero,
          ),
        );
        break;
      case 3: // Grupos
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, a, b) => const GruposPage(),
            transitionDuration: Duration.zero,
          ),
        );
        break;
      case 4: // Ajustes (ProfilePage)
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, a, b) => const ProfilePage(),
            transitionDuration: Duration.zero,
          ),
        );
        break;
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final userQuery = await _databaseService.getUserInfo(widget.username);
      if (userQuery.docs.isNotEmpty) {
        final userDoc = userQuery.docs.first;
        _userId = userDoc.id;
        _userData = userDoc.data() as Map<String, dynamic>;

        final profileSnapshot = await _databaseService.getDatosCollection(
          _userId!,
        );
        if (profileSnapshot.exists) {
          _userProfileData = profileSnapshot.data() as Map<String, dynamic>;
        }

        if (_userId != null) {
          _followersCount = await _followController.getFollowersCount(_userId!);
          _followingCount = await _followController.getFollowingCount(_userId!);

          final currentUserId = await _sharedPrefService.getUserId();
          if (currentUserId != null && currentUserId != _userId) {
            _isFollowing = await _followController.isFollowing(_userId!);
          }
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception("Usuario no encontrado");
      }
    } catch (e) {
      print('Error cargando perfil: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleFollow() async {
    try {
      if (_userId == null) return;

      setState(() {
        _isLoading = true;
      });

      if (_isFollowing) {
        await _followController.unfollowUser(_userId!);
        setState(() {
          _isFollowing = false;
          _followersCount--;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dejaste de seguir a este usuario'),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        await _followController.followUser(_userId!, widget.username);
        setState(() {
          _isFollowing = true;
          _followersCount++;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ahora sigues a este usuario'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startChat() async {
    if (_userId == null) return;

    setState(() {
      _isSendingMessage = true;
    });

    try {
      // Crear o obtener el chat room
      final chatRoomId = await _chatController.getOrCreateChatRoom(
        widget.username,
      );

      // Navegar al chat
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              name: _userData['Name'] ?? widget.username,
              profileurl: _userData['Image'] ?? '',
              username: widget.username,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
      }
    }
  }

  Future<void> _showFollowOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_remove, color: Colors.red),
                title: const Text('Dejar de seguir'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleFollow();
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.grey),
                title: const Text('Bloquear usuario'),
                onTap: () {
                  Navigator.pop(context);
                  _blockUser();
                },
              ),
              ListTile(
                leading: const Icon(Icons.report, color: Colors.orange),
                title: const Text('Reportar usuario'),
                onTap: () {
                  Navigator.pop(context);
                  _reportUser();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _blockUser() {
    // Implementar lógica de bloqueo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de bloqueo en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _reportUser() {
    // Implementar lógica de reporte
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de reporte en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // --- REEMPLAZADO: _buildBio con la versión del Código 2 ---
  String _buildBio() {
    String bio = '';

    if (_userProfileData[AppConstants.ciudad] != null &&
        _userProfileData[AppConstants.ciudad].isNotEmpty) {
      bio += '📍 ${_userProfileData[AppConstants.ciudad]}\n';
    }
    if (_userProfileData[AppConstants.ocupacion] != null &&
        _userProfileData[AppConstants.ocupacion].isNotEmpty) {
      bio += '💼 ${_userProfileData[AppConstants.ocupacion]}\n';
    }
    if (_userProfileData[AppConstants.telefono] != null &&
        _userProfileData[AppConstants.telefono].isNotEmpty) {
      bio += '📞 ${_userProfileData[AppConstants.telefono]}\n';
    }
    if (_userProfileData[AppConstants.fecha_nacimiento] != null &&
        _userProfileData[AppConstants.fecha_nacimiento].isNotEmpty) {
      bio += '🍰 ${_userProfileData[AppConstants.fecha_nacimiento]}\n';
    }
    if (_userProfileData[AppConstants.descripcion] != null &&
        _userProfileData[AppConstants.descripcion].isNotEmpty) {
      bio += '${_userProfileData[AppConstants.descripcion]}\n';
    }

    return bio.isEmpty ? 'Usuario de AquiNomas' : bio.trim();
  }

  Widget _buildAdditionalInfo() {
    final additionalInfo = <Widget>[];

    // Género
    if (_userProfileData[AppConstants.genero] != null &&
        _userProfileData[AppConstants.genero].toString().isNotEmpty) {
      additionalInfo.add(
        Chip(
          label: Text(_userProfileData[AppConstants.genero]),
          backgroundColor: Colors.blue[50],
        ),
      );
    }

    // Estudios
    if (_userProfileData[AppConstants.estudios] != null &&
        _userProfileData[AppConstants.estudios].toString().isNotEmpty) {
      additionalInfo.add(
        Chip(
          label: Text(_userProfileData[AppConstants.estudios]),
          backgroundColor: Colors.green[50],
        ),
      );
    }

    // Estado de relación
    if (_userProfileData[AppConstants.estado_relacion] != null &&
        _userProfileData[AppConstants.estado_relacion].toString().isNotEmpty) {
      additionalInfo.add(
        Chip(
          label: Text(_userProfileData[AppConstants.estado_relacion]),
          backgroundColor: Colors.purple[50],
        ),
      );
    }

    if (additionalInfo.isEmpty) {
      return const SizedBox();
    }

    return Wrap(spacing: 8, runSpacing: 8, children: additionalInfo);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando perfil...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      // --- TU APPBAR MEJORADO (DEL CÓDIGO 1) ---
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Navega (reemplazando) de vuelta a HomePage (pestaña 2)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const HomePage(initialIndex: 2)),
            );
          },
        ),
        title: Text(widget.username),
        centerTitle: true,
        backgroundColor:
            Colors.transparent, // Color base transparente para el gradiente
        elevation: 0, // Se ajustó a 0 en el Código 2, mantenemos eso
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 156, 50, 50), // Tu color rojo
                Color.fromARGB(255, 156, 50, 50), // Un rojo más oscuro
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          // No mostrar "más opciones" si estoy viendo mi propio perfil
          if (_myUsername != widget.username)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showFollowOptions,
            ),
        ],
      ),
      // --- FIN DEL APPBAR ---

      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // HEADER DEL PERFIL
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // FOTO DE PERFIL
                        CircleAvatar(
                          radius: 45,
                          backgroundImage: NetworkImage(
                            _userData['Image'] ??
                                'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                          ),
                        ),
                        const SizedBox(width: 20),

                        // ESTADÍSTICAS
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(_postsCount, 'Publicaciones'),
                              _buildStatItem(_followersCount, 'Seguidores'),
                              _buildStatItem(_followingCount, 'Siguiendo'),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // BIO
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userData['Name'] ?? 'Usuario',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _buildBio(),
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          _buildAdditionalInfo(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- INICIO DE LA MODIFICACIÓN (Lógica del Código 2) ---
                    // Si es mi perfil, muestro "Editar", si no, muestro "Seguir/Mensaje"
                    if (_isMyProfile)
                      _buildEditProfileButton() // <-- Nuevo widget
                    else
                      _buildActionButtons(), // <-- Tu widget antiguo
                    // --- FIN DE LA MODIFICACIÓN ---
                  ],
                ),
              ),

              // TABS Y CONTENIDO
              _buildProfileTabs(),
              _buildTabContent(),
            ],
          ),
        ),
      ),

      // --- TU BARRA DE NAVEGACIÓN (DEL CÓDIGO 1) ---
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 156, 50, 50), // Color rojo
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.5),
        currentIndex:
            _selectedIndex < 0 ? 0 : _selectedIndex, // Evita error con -1
        onTap: _onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home,
                color: _selectedIndex == 0
                    ? Colors.white
                    : Colors.white.withOpacity(0.5)),
            label: 'Muro',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person,
                color: _selectedIndex == 1
                    ? Colors.white
                    : Colors.white.withOpacity(0.5)),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble,
                color: _selectedIndex == 2
                    ? Colors.white
                    : Colors.white.withOpacity(0.5)),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group,
                color: _selectedIndex == 3
                    ? Colors.white
                    : Colors.white.withOpacity(0.5)),
            label: 'Grupos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings,
                color: _selectedIndex == 4
                    ? Colors.white
                    : Colors.white.withOpacity(0.5)),
            label: 'Ajustes',
          ),
        ],
      ),
      // --- FIN DE LA BARRA ---
    );
  }

  // --- WIDGET NUEVO AÑADIDO (DEL CÓDIGO 2) ---
  Widget _buildEditProfileButton() {
    // Este widget reemplaza _buildActionButtons cuando es mi perfil
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(
                    // Pasamos un mapa vacío. EditProfilePage se encarga
                    // de cargar sus propios datos en su initState.
                    userData: const {},
                    onProfileUpdated: () {
                      _loadUserProfile(); // Esto refresca esta página cuando volvemos
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200], // Color gris claro
              foregroundColor: Colors.black, // Texto negro
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0, // Sin sombra
            ),
            child: const Text(
              'Editar Perfil',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
  // --- FIN DEL WIDGET NUEVO ---

  Widget _buildActionButtons() {
    return Row(
      children: [
        // BOTÓN SEGUIR/DEJAR DE SEGUIR
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _toggleFollow,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isFollowing ? Colors.grey : const Color(0xff703eff),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(_isFollowing ? 'Siguiendo' : 'Seguir'),
          ),
        ),
        const SizedBox(width: 8),

        // BOTÓN MENSAJE
        if (_isFollowing)
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSendingMessage ? null : _startChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: const Color(0xff703eff),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xff703eff)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isSendingMessage
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xff703eff),
                        ),
                      ),
                    )
                  : const Text('Mensaje'),
            ),
          ),
        if (_isFollowing) const SizedBox(width: 8),

        // BOTÓN AGREGAR
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            border: Border.all(
              color: _isFollowing
                  ? const Color(0xff703eff)
                  : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.person_add,
            size: 20,
            color: _isFollowing ? const Color(0xff703eff) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(int count, String label) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildProfileTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
          _buildTabItem(0, Icons.grid_on),
          _buildTabItem(1, Icons.video_library),
          _buildTabItem(2, Icons.assignment_ind),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.black : Colors.grey,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return Container(
      padding: const EdgeInsets.all(50),
      child: const Column(
        children: [
          Icon(Icons.photo_library, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'No hay publicaciones',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Cuando el usuario publique fotos, aparecerán aquí',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}