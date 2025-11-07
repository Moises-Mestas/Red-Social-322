import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3/views/pages/group_chat_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_application_3/controllers/group_controller.dart';
import 'package:flutter_application_3/views/pages/grupos_page.dart';

class GruposPropiosPage extends StatefulWidget {
  const GruposPropiosPage({super.key});

  @override
  State<GruposPropiosPage> createState() => _GruposPropiosPageState();
}

class _GruposPropiosPageState extends State<GruposPropiosPage> {
  final TextEditingController _searchController = TextEditingController();
  final GroupController _groupController = GroupController();

  Stream? _groupsStream;
  File? _imageFile;
  List<DocumentSnapshot> _allGroups = [];
  List<DocumentSnapshot> _filteredGroups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() async {
    _groupsStream = _groupController.getAllGroups();
    setState(() {});
  }

  void _searchGroups(String query) {
    List<DocumentSnapshot> searchResults = [];
    if (query.isEmpty) {
      searchResults = _allGroups;
    } else {
      searchResults = _allGroups.where((group) {
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
            // 1. Guardamos los objetos de contexto ANTES del 'await'
            final navigator = Navigator.of(context);
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            // 2. Comprobamos si el widget sigue "montado" (vivo)
            if (!mounted) return; 

            if (groupName != null && groupName!.isNotEmpty) {

              // 3. Cerramos el diálogo
              navigator.pop();

              // 4. Hacemos la llamada asíncrona
              final groupId = await _groupController.createGroup(
                groupName: groupName!,
                imageFile: _imageFile,
              );

              if (groupId != null) {
                // 5. Usamos el 'scaffoldMessenger' guardado (¡seguro!)
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Grupo creado con id: $groupId')),
                );

                // 6. Volvemos a comprobar si el widget sigue vivo antes de recargar
                if (mounted) {
                  _loadGroups(); // <-- La única línea diferente
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
        title: TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const GruposPage()),
            );
          },
          child: const Text(
            "Grupos",
            style: TextStyle(color: Colors.black, fontSize: 20),
          ),
        ),
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
            child: const Text("Descubrir", style: TextStyle(color: Colors.red)),
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
                      hintText: 'Buscar grupo...',
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
              stream: _groupsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
                  return const Center(child: Text("No hay grupos disponibles"));
                }

                if (_allGroups.isEmpty) {
                  _allGroups = snapshot.data.docs;
                  _filteredGroups = _allGroups;
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
