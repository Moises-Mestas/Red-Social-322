// lib/views/pages/grupos_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3/views/pages/group_chat_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_application_3/controllers/group_controller.dart';
import 'package:flutter_application_3/views/pages/grupos_propios_page.dart';

// --- Imports añadidos para la barra de navegación ---
import 'package:flutter_application_3/services/shared_pref_service.dart';
import 'package:flutter_application_3/views/pages/principal_page.dart';
import 'package:flutter_application_3/views/pages/home_page.dart';
import 'package:flutter_application_3/views/pages/profile_page.dart';
import 'package:flutter_application_3/views/pages/user_profile_page.dart';
// ----------------------------------------------------

class GruposPage extends StatefulWidget {
  const GruposPage({super.key});

  @override
  State<GruposPage> createState() => _GruposPageState();
}

class _GruposPageState extends State<GruposPage> {
  final TextEditingController _searchController = TextEditingController();
  final GroupController _groupController = GroupController();
  final SharedPrefService _sharedPrefService = SharedPrefService(); // <-- AÑADIDO

  Stream? _userGroupsStream;
  File? _imageFile;
  List<DocumentSnapshot> _userGroups = [];
  List<DocumentSnapshot> _filteredGroups = [];

  // --- AÑADIDO: Estado de la barra de navegación ---
  int _selectedIndex = 3; // Esta es la pestaña 3
  String? _myUsername;

  @override
  void initState() {
    super.initState();
    _loadUserGroups();
    _loadMyUsername(); // <-- AÑADIDO
  }

  // --- AÑADIDO ---
  void _loadMyUsername() async {
    _myUsername = await _sharedPrefService.getUserName();
  }
  
  // --- AÑADIDO: Lógica de navegación ---
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
      case 3: // Grupos (Esta página)
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
  // ------------------------------------

  void _loadUserGroups() async {
    _userGroupsStream = await _groupController.getUserGroups();
    setState(() {});
  }

  void _searchGroups(String query) {
    List<DocumentSnapshot> searchResults = [];
    if (query.isEmpty) {
      searchResults = _userGroups;
    } else {
      searchResults = _userGroups.where((group) {
        String groupName = group['name'].toString().toLowerCase();
        return groupName.contains(query.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredGroups = searchResults;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _createGroup() async {
    String? groupName;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Grupo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(hintText: 'Nombre del Grupo'),
              onChanged: (value) {
                groupName = value;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text(
                _imageFile == null
                    ? 'Seleccionar Imagen'
                    : 'Imagen Seleccionada',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            // CÓDIGO CORREGIDO
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              if (!mounted) return;

              if (groupName != null && groupName!.isNotEmpty) {
                navigator.pop();

                final groupId = await _groupController.createGroup(
                  groupName: groupName!,
                  imageFile: _imageFile,
                );

                if (groupId != null) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Grupo creado con id: $groupId')),
                  );
                  if (mounted) {
                    _loadUserGroups();
                  }
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // --- MODIFICADO: AppBar ---
        automaticallyImplyLeading: false, // <-- No mostrar flecha de atrás
        title: const Text(
          "GRUPOS",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xffD32323), // Color rojo
        elevation: 0,
        // -------------------------
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GruposPropiosPage(),
                ),
              );
            },
            child: const Text(
              "Descubrir",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // Color cambiado a blanco
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchGroups,
                    decoration: const InputDecoration(
                      hintText: 'Buscar en mis grupos...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _createGroup,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _userGroupsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
                  return const Center(child: Text("No estás en ningún grupo"));
                }
                
                // Actualizamos la lista base solo si la búsqueda está vacía
                if (_searchController.text.isEmpty) {
                  _userGroups = snapshot.data.docs;
                  _filteredGroups = _userGroups;
                } else {
                  // Si estamos buscando, actualizamos la base y refiltramos
                   _userGroups = snapshot.data.docs;
                   _searchGroups(_searchController.text);
                }


                return ListView.builder(
                  itemCount: _filteredGroups.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot ds = _filteredGroups[index];
                    return _buildGroupTile(ds);
                  },
                );
              },
            ),
          ),
        ],
      ),

      // --- BARRA DE NAVEGACIÓN AÑADIDA ---
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xffD32323),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.5),
        currentIndex: _selectedIndex, // <-- 3
        onTap: _onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Muro',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Grupos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
      // --- FIN DE LA BARRA ---
    );
  }

  Widget _buildGroupTile(DocumentSnapshot ds) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupChatPage(
              groupName: ds["name"],
              groupImageUrl: ds["imageUrl"],
              groupId: ds.id,
            ),
          ),
        );
      },
      child: Material(
        elevation: 3.0,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          width: MediaQuery.of(context).size.width,
          child: Row(
            children: [
              _buildGroupImage(ds["imageUrl"]),
              const SizedBox(width: 20.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ds["name"],
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      ds["lastMessage"] ?? "No hay mensajes",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 15.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatTime(ds["lastMessageSendTs"]?.toString() ?? ""),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: Image.network(
          imageUrl,
          height: 70,
          width: 70,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultGroupAvatar();
          },
        ),
      );
    } else {
      return _buildDefaultGroupAvatar();
    }
  }

  Widget _buildDefaultGroupAvatar() {
    return const CircleAvatar(
      backgroundColor: Colors.black,
      radius: 35,
      child: Icon(Icons.group, size: 40, color: Colors.white),
    );
  }

  String _formatTime(String time) {
    try {
      if (time.length > 10) {
        return time.substring(11, 16);
      }
      return time;
    } catch (e) {
      return time;
    }
  }
}