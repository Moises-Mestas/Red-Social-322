// lib/views/pages/grupos_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3/views/pages/group_chat_page.dart';
import 'package:flutter_application_3/views/pages/home_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_application_3/controllers/group_controller.dart';
import 'package:flutter_application_3/views/pages/grupos_propios_page.dart';

// --- Imports añadidos para la barra de navegación ---
import 'package:flutter_application_3/services/shared_pref_service.dart';
import 'package:flutter_application_3/views/pages/principal_page.dart';
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
  final SharedPrefService _sharedPrefService = SharedPrefService(); 

  Stream? _userGroupsStream;
  File? _imageFile;
  List<DocumentSnapshot> _userGroups = [];
  List<DocumentSnapshot> _filteredGroups = [];

  int _selectedIndex = 3; 
  String? _myUsername;

  @override
  void initState() {
    super.initState();
    _loadUserGroups();
    _loadMyUsername();
  }

  void _loadMyUsername() async {
    _myUsername = await _sharedPrefService.getUserName();
  }
  
  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    if (index == 1 && _myUsername == null) return;

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
      // 1. Poner el color de fondo rojo al Scaffold
      backgroundColor: const Color(0xffD32323),
      
      // 2. El body ahora es un Column
      body: Column(
        children: [
          
          // --- INICIO DEL NUEVO HEADER ---
          Container(
            // 3. Añadir padding superior manual para la barra de estado
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            height: 56 + MediaQuery.of(context).padding.top, // Altura + barra de estado
            color: const Color(0xffD32323), // Color rojo
            child: Row(
              children: [
                _buildHeaderButton(
                  text: 'MIS GRUPOS',
                  isSelected: true, // Esta página es "Mis Grupos"
                  onTap: () {
                    // Ya estamos aquí, no hacer nada
                  },
                ),
                // Línea vertical divisoria
                Container(
                  width: 4,
                  height: 38, // Altura de la línea
                  color: Colors.white.withOpacity(0.5),
                ),
                _buildHeaderButton(
                  text: 'DESCUBRIR',
                  isSelected: false,
                  onTap: () {
                    // Navegar a GruposPropiosPage
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, a, b) => const GruposPropiosPage(),
                        transitionDuration: Duration.zero,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // --- FIN DEL NUEVO HEADER ---
          
          // --- INICIO DEL CONTENIDO ---
          Expanded(
            child: Container(
              // 4. Contenedor blanco para el resto del contenido
              width: MediaQuery.of(context).size.width, // Asegura que ocupe todo el ancho
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    // 5. Padding para la barra de búsqueda
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
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
                        
                        if (_searchController.text.isEmpty) {
                          _userGroups = snapshot.data.docs;
                          _filteredGroups = _userGroups;
                        } else {
                           _userGroups = snapshot.data.docs;
                           _searchGroups(_searchController.text);
                        }


                        return ListView.builder(
                          // Añadimos padding para que la lista no pegue a los lados
                          padding: const EdgeInsets.symmetric(horizontal: 10), 
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
            ),
          ),
          // --- FIN DEL CONTENIDO ---
        ],
      ),

      // --- BARRA DE NAVEGACIÓN (Sin cambios) ---
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
    );
  }

  // --- WIDGET NUEVO PARA LOS BOTONES DEL HEADER ---
  Widget _buildHeaderButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          // El color es sólido (rojo) para ambos
          color: const Color(0xffD32323),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              // El borde inferior resalta la pestaña activa
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3.0, // Grosor del indicador
                  ),
                ),
              ),
              // Padding para el texto
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                text,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                  fontSize: 16, // Mismo tamaño de letra
                ),
              ),
            ),
          ),
        ),
      ),
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