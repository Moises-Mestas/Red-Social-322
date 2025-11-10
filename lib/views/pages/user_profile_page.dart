// lib/views/pages/user_profile_page.dart
import 'dart:io';
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
// --- AÑADIDO IMPORT (NUEVO) ---
import 'package:flutter_application_3/views/widgets/followers_list_dialog.dart';

// --- Imports añadidos para Publicaciones ---
import 'package:flutter_application_3/controllers/post_controller.dart';
import 'package:flutter_application_3/models/comment_model.dart';
import 'package:flutter_application_3/models/post_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
// ------------------------------------------

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

  // --- AÑADIDO: Controladores y variables para posts ---
  final PostController _postController = PostController();
  final ImagePicker _picker = ImagePicker();
  File? _imageToPost;
  final TextEditingController _textController = TextEditingController();
  // ---------------------------------------------------

  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _userProfileData = {};
  String? _userId; // ID del perfil que se está viendo
  String? _myUserId; // <-- AÑADIDO: ID del usuario logueado
  String? _myUsername; // Mi propio apodo (para la barra de nav)
  int _followersCount = 0;
  int _followingCount = 0;
  int _postsCount = 0;
  bool _isFollowing = false;
  bool _isLoading = true;
  int _selectedTab = 0;
  bool _isSendingMessage = false;

  int _selectedIndex = 1;
  bool _isMyProfile = false;

  @override
  void initState() {
    super.initState();
    _loadAllData(); // <-- Combinado _loadUserProfile y _checkIfThisIsMyProfile
    timeago.setLocaleMessages('es', timeago.EsMessages()); // <-- AÑADIDO
  }

  // --- MODIFICADO: Para cargar todo en una sola función ---
  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });

    // 1. Cargar datos del usuario actual (logueado)
    _myUsername = await _sharedPrefService.getUserName();
    _myUserId = await _sharedPrefService.getUserId();

    // 2. Comprobar si este perfil es mi perfil
    if (widget.username == _myUsername) {
      _isMyProfile = true;
      _selectedIndex = 1;
    } else {
      _isMyProfile = false;
      _selectedIndex = -1;
    }

    // 3. Cargar datos del perfil que estamos visitando
    try {
      final userQuery = await _databaseService.getUserInfo(widget.username);
      if (userQuery.docs.isNotEmpty) {
        final userDoc = userQuery.docs.first;
        _userId = userDoc.id;
        _userData = userDoc.data() as Map<String, dynamic>;

        final profileSnapshot =
            await _databaseService.getDatosCollection(_userId!);
        if (profileSnapshot.exists) {
          _userProfileData = profileSnapshot.data() as Map<String, dynamic>;
        }

        if (_userId != null) {
          // Cargar contadores de posts (¡Asegúrate de que el índice de Firebase esté creado!)
          try {
            final postSnapshot =
                await _postController.getPostsForUserStream(_userId!).first;
            _postsCount = postSnapshot.docs.length;
          } catch (e) {
            print("Error al contar posts (revisa índice de Firebase): $e");
            _postsCount = 0; // Continuar sin posts si falla
          }

          _followersCount = await _followController.getFollowersCount(_userId!);
          _followingCount = await _followController.getFollowingCount(_userId!);

          if (!_isMyProfile && _myUserId != null) {
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  // --- FIN DE LA MODIFICACIÓN ---

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

  void _showFollowList(bool isFollowers) {
    if (_userId == null) return; // No hacer nada si no hay ID

    showDialog(
      context: context,
      builder: (context) {
        return FollowersListDialog(
          userId: _userId!,
          isFollowers: isFollowers,
          followController: _followController,
        );
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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
      // --- APPBAR CORREGIDO (DEL CÓDIGO 2) ---
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
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
        elevation: 0,
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
                Color(0xff9A1C1C), // Un rojo más oscuro
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (_myUsername != widget.username)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showFollowOptions,
            ),
        ],
      ),
      // --- FIN DEL APPBAR ---

      body: RefreshIndicator(
        onRefresh: _loadAllData,
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
                              // --- MODIFICADO: _postsCount ahora tiene valor ---
                              _buildStatItem(_postsCount, 'Publicaciones'),
                              GestureDetector(
                                onTap: () => _showFollowList(true),
                                child:
                                    _buildStatItem(_followersCount, 'Seguidores'),
                              ),
                              GestureDetector(
                                onTap: () => _showFollowList(false),
                                child:
                                    _buildStatItem(_followingCount, 'Siguiendo'),
                              ),
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

                    // BOTONES (Lógica de "Editar Perfil" vs "Seguir")
                    if (_isMyProfile)
                      _buildEditProfileButton()
                    else
                      _buildActionButtons(),
                  ],
                ),
              ),

              // TABS Y CONTENIDO
              _buildProfileTabs(),
              _buildTabContent(), // <-- Este widget ahora mostrará el Grid
            ],
          ),
        ),
      ),

      // --- AÑADIDO: FloatingActionButton ---
      floatingActionButton: _isMyProfile
          ? FloatingActionButton(
              onPressed: _showCreatePostModal,
              backgroundColor: const Color.fromARGB(255, 156, 50, 50), // Color rojo
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null, // No mostrar el botón si no es mi perfil
      // ------------------------------------

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
    );
  }

  Widget _buildEditProfileButton() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(
                    userData: const {},
                    onProfileUpdated: () {
                      _loadAllData();
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
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

  // --- WIDGET REEMPLAZADO (DEL CÓDIGO 2) ---
  Widget _buildTabContent() {
    // Si no es la primera pestaña (Grid), muestra el placeholder
    if (_selectedTab != 0) {
      return Container(
        padding: const EdgeInsets.all(50),
        child: const Column(
          children: [
            Icon(Icons.video_library, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'No hay videos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Videos y Reels aparecerán aquí',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Si es la primera pestaña, muestra el Grid de posts
    return StreamBuilder<QuerySnapshot>(
      stream: _postController.getPostsForUserStream(_userId!), // <-- ¡IMPORTANTE!
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(50),
            child: Column(
              children: [
                const Icon(Icons.photo_library, size: 80, color: Colors.grey),
                const SizedBox(height: 20),
                Text(
                  _isMyProfile
                      ? 'No tienes publicaciones'
                      : 'No hay publicaciones',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  _isMyProfile
                      ? 'Cuando publiques fotos, aparecerán aquí'
                      : 'Este usuario aún no ha publicado fotos',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Tenemos posts, mostramos el Grid
        var posts = snapshot.data!.docs;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Para que no haga scroll
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // 3 fotos por fila
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            PostModel post = PostModel.fromMap(posts[index]);

            // Mostramos la imagen (o icono si es solo texto)
            return GestureDetector(
              onTap: () => _showPostDetailDialog(post),
              child: Container(
                color: Colors.grey[200],
                child: (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                    ? Image.network(
                        post.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) =>
                            const Icon(Icons.error, color: Colors.grey),
                      )
                    : const Center(
                        child: Icon(Icons.article, color: Colors.grey)),
              ),
            );
          },
        );
      },
    );
  }
  // --- FIN DEL WIDGET REEMPLAZADO ---

  // --- WIDGET AÑADIDO (Copiado de principal_page.dart) ---
  /// Muestra el modal para crear un post
  void _showCreatePostModal() {
    _textController.clear();
    setState(() {
      _imageToPost = null;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context); // <-- CORRECCIÓN

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Container(
              margin: const EdgeInsets.fromLTRB(10, 20, 10, 60),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Crear Publicación",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: "¿Qué estás pensando?",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 10),
                    if (_imageToPost != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _imageToPost!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.image),
                          label: const Text("Adjuntar Imagen"),
                          onPressed: () async {
                            final XFile? image = await _picker.pickImage(
                                source: ImageSource.gallery);
                            if (image != null) {
                              modalSetState(() {
                                _imageToPost = File(image.path);
                              });
                            }
                          },
                        ),
                        ElevatedButton(
                          child: const Text("Publicar"),
                          onPressed: () async {
                            if (_textController.text.isEmpty &&
                                _imageToPost == null) {
                              return;
                            }

                            final navigator =
                                Navigator.of(context); // <-- CORRECCIÓN
                            navigator.pop(); // Cierra el modal

                            scaffoldMessenger.showSnackBar(
                                const SnackBar(content: Text("Publicando...")));

                            // Llama al controlador (ya sabe quién es el usuario)
                            await _postController.createPost(
                              _textController.text,
                              _imageToPost,
                            );
                            
                            // scaffoldMessenger.hideCurrentSnackBar(); // No es necesario si recargas
                            _loadAllData(); // <-- Recarga el perfil para ver el post nuevo
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  // --- FIN DEL WIDGET ---

  // --- WIDGET AÑADIDO (Copiado de principal_page.dart) ---
  /// Muestra el post completo en un diálogo
  Future<void> _showPostDetailDialog(PostModel post) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero, // <-- MODIFICADO
          content: _buildPostDetailWidget(post), // <-- MODIFICADO
          actionsAlignment: MainAxisAlignment.center, // <-- AÑADIDO
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child:
                  const Text('Cerrar', style: TextStyle(color: Color.fromARGB(255, 156, 50, 50))),
            )
          ],
        );
      },
    ).then((_) {
      // --- AÑADIDO: Recargar datos después de cerrar el diálogo ---
      // Esto actualiza el contador de likes/comentarios en el grid
      _loadAllData();
      // --- FIN DE LA ADICIÓN ---
    });
  }
  // --- FIN DEL WIDGET ---

/// Construye el widget del Post para el diálogo de detalle
Widget _buildPostDetailWidget(PostModel post) {
  // --- AÑADIDO: StatefulBuilder para que el like se actualice DENTRO del modal ---
  return StatefulBuilder(
    builder: (context, setStateInModal) {
      bool isLiked = post.likes.contains(_myUserId);
      String timeAgo = timeago.format(post.createdAt.toDate(), locale: 'es');

      return Card(
        margin: EdgeInsets.zero, // Sin margen dentro del diálogo
        elevation: 0, // Sin sombra
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Para que se ajuste al contenido
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(post.userImageUrl.isNotEmpty
                        ? post.userImageUrl
                        : 'https://via.placeholder.com/150'),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(timeAgo,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 15),

              if (post.text.isNotEmpty)
                Text(post.text, style: const TextStyle(fontSize: 16)),

              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 10),

                // Contenedor con límites definidos para la imagen
                ConstrainedBox(
                  constraints: BoxConstraints(
                    // Establece una altura máxima (350 píxeles)
                    maxHeight: 350.0,
                    // Ancho máximo para el ancho disponible del diálogo
                    maxWidth: MediaQuery.of(context).size.width * 0.85,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.network(
                      post.imageUrl!,
                      fit: BoxFit.contain, // Usar contain para no recortar
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (c, e, s) =>
                          const Center(child: Text("Error al cargar imagen")),
                    ),
                  ),
                ),
              ], // <-- Cierre del List 'if (post.imageUrl != null) ...'

              const SizedBox(height: 10),
              Divider(),

              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey,
                        ),
                        onPressed: () async { // <-- ¡HACER ASÍNCRONO!
                            // Lógica de Like
                            await _postController.toggleLike(post.id, post.likes); // <-- ¡USAR AWAIT!

                            // Actualiza la UI del modal
                            setStateInModal(() {
                              if (isLiked) {
                                post.likes.remove(_myUserId);
                              } else {
                                post.likes.add(_myUserId!);
                              }
                            });
                          },
                      ),
                      Text("${post.likes.length}"),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.mode_comment_outlined,
                            color: Colors.grey),
                        onPressed: () {
                          Navigator.pop(context); // Cierra el diálogo del post
                          _showCommentsModal(
                              context, post.id); // Abre el de comentarios
                        },
                      ),
                      Text("${post.commentCount}"),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      );
    },
  ); // <-- Cierre del StatefulBuilder
}
  // --- FIN DEL WIDGET ---

  // --- WIDGET AÑADIDO (Copiado de principal_page.dart) ---
  /// Muestra el modal para ver y añadir comentarios
  void _showCommentsModal(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return _CommentsModalContent(
              postId: postId,
              postController: _postController,
              myUserId: _myUserId!,
              scrollController: scrollController,
            );
          },
        );
      },
    ).then((_) {
      // --- AÑADIDO: Recargar datos después de cerrar el modal ---
      _loadAllData();
      // --- FIN DE LA ADICIÓN ---
    });
  }
  // --- FIN DEL WIDGET ---
}

// --- WIDGET AÑADIDO (Copiado de principal_page.dart) ---
// (Necesario para que _showCommentsModal funcione)
class _CommentsModalContent extends StatefulWidget {
  final String postId;
  final PostController postController;
  final String myUserId;
  final ScrollController scrollController;

  const _CommentsModalContent({
    required this.postId,
    required this.postController,
    required this.myUserId,
    required this.scrollController,
  });

  @override
  State<_CommentsModalContent> createState() => _CommentsModalContentState();
}

class _CommentsModalContentState extends State<_CommentsModalContent> {
  final TextEditingController _commentController = TextEditingController();

  String? _replyingToCommentId;
  String? _replyingToUserName;

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
      _commentController.clear();
    });
  }

  void _sendComment() {
    if (_commentController.text.isEmpty) return;

    widget.postController.addComment(
      postId: widget.postId,
      text: _commentController.text,
      parentCommentId: _replyingToCommentId,
    );

    _cancelReply();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Comentarios",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.postController.getCommentsStream(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No hay comentarios."));
                }

                final allComments = snapshot.data!.docs
                    .map((doc) => CommentModel.fromMap(doc))
                    .toList();

                    
                final topLevelComments = allComments
                            .where((c) => c.parentCommentId == null)
                            .toList();


                final replies = allComments
                    .where((c) => c.parentCommentId != null)
                    .toList();

                final Map<String, List<CommentModel>> repliesMap = {};
                for (var reply in replies) {
                  if (!repliesMap.containsKey(reply.parentCommentId)) {
                    repliesMap[reply.parentCommentId!] = [];
                  }
                  repliesMap[reply.parentCommentId!]!.add(reply);
                }

                return ListView.builder(
                  controller: widget.scrollController,
                  itemCount: topLevelComments.length,
                  itemBuilder: (context, index) {
                    final comment = topLevelComments[index];
                    final commentReplies = repliesMap[comment.id] ?? [];


                    return _buildCommentTile(
                      comment,
                      commentReplies,
                    );
                  },
                );
              },
            ),
          ),
          _buildCommentInputArea(),
        ],
      ),
    );
  }

  Widget _buildCommentTile(CommentModel comment, List<CommentModel> replies) {
    bool isLiked = comment.likes.contains(widget.myUserId);
    String timeAgo = timeago.format(comment.createdAt.toDate(), locale: 'es');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(comment.userImageUrl.isNotEmpty
                    ? comment.userImageUrl
                    : 'https://via.placeholder.com/150'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(comment.text),
                    Row(
                      children: [
                        Text(timeAgo,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _replyingToCommentId = comment.id;
                              _replyingToUserName = comment.userName;
                            });
                          },
                          child: const Text("Responder",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                      size: 16,
                    ),
                    onPressed: () {
                      widget.postController.toggleCommentLike(
                          postId: widget.postId,
                          commentId: comment.id,
                          currentLikes: comment.likes);
                    },
                  ),
                  Text(comment.likes.length.toString(),
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          if (replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40.0, top: 8.0),
              child: Column(
                children:
                    replies.map((reply) => _buildReplyTile(reply)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyTile(CommentModel reply) {
    bool isLiked = reply.likes.contains(widget.myUserId);
    String timeAgo = timeago.format(reply.createdAt.toDate(), locale: 'es');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: NetworkImage(reply.userImageUrl.isNotEmpty
                ? reply.userImageUrl
                : 'https://via.placeholder.com/150'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reply.userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Text(reply.text, style: const TextStyle(fontSize: 13)),
                Text(timeAgo,
                    style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.grey,
                  size: 14,
                ),
                onPressed: () {
                  widget.postController.toggleCommentLike(
                      postId: widget.postId,
                      commentId: reply.id,
                      currentLikes: reply.likes);
                },
              ),
              Text(reply.likes.length.toString(),
                  style: const TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: 8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingToCommentId != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Respondiendo a $_replyingToUserName...",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: _cancelReply,
                )
              ],
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: _replyingToCommentId != null
                        ? "Escribe tu respuesta..."
                        : "Añade un comentario...",
                    border: InputBorder.none,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Color.fromARGB(255, 156, 50, 50)),
                onPressed: _sendComment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
// --- FIN DE LA CLASE ---