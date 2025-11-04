import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_application_3/pages/groupchat_page.dart';
import 'package:image_picker/image_picker.dart'; // Para cargar imágenes
import 'dart:io';
import 'package:flutter_application_3/services/database.dart';
import 'package:flutter_application_3/services/shared_pref.dart';

class GruposPage extends StatefulWidget {
  const GruposPage({super.key});

  @override
  State<GruposPage> createState() => _GruposPageState();
}

class _GruposPageState extends State<GruposPage> {
  TextEditingController searchController = TextEditingController();
  Stream? groupsStream;
  File? _imageFile;
  List<DocumentSnapshot> allGroups = [];  // Todos los grupos
  List<DocumentSnapshot> filteredGroups = [];  // Grupos filtrados para búsqueda

  @override
  void initState() {
    super.initState();
    loadGroups();
  }

  loadGroups() async {
    // Cargar todos los grupos
    groupsStream = await DatabaseMethods().getGroups();
    setState(() {});
  }

  // Función de búsqueda en tiempo real
  searchGroups(String query) async {
    List<DocumentSnapshot> searchResults = [];
    if (query.isEmpty) {
      searchResults = allGroups;
    } else {
      searchResults = allGroups.where((group) {
        String groupName = group['name'].toString().toLowerCase();
        return groupName.contains(query.toLowerCase());
      }).toList();
    }

    setState(() {
      filteredGroups = searchResults;
    });
  }

  // Método para seleccionar una imagen
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path); // Guardamos la imagen seleccionada
      });
    }
  }

  // Función para crear un nuevo grupo
  createGroup() async {
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
              onPressed: _pickImage, // Permite al usuario elegir una imagen
              child: Text(_imageFile == null ? 'Seleccionar Imagen' : 'Imagen Seleccionada'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (groupName != null && groupName!.isNotEmpty) {
                // Recupera el nombre de usuario para añadirlo al grupo
                String? myUsername = await SharedpreferencesHelper().getUserName();

                // Crear el grupo si el nombre es válido y se ha seleccionado una imagen
                Map<String, dynamic> groupInfoMap = {
                  "name": groupName,
                  "imageUrl": _imageFile?.path ?? "", // Usamos la ruta de la imagen si fue seleccionada
                  "users": [myUsername],    // Agregar el usuario actual a la lista de miembros
                  "lastMessage": "",
                  "lastMessageSendTs": DateTime.now(),
                  "isGroup": true, // Especificamos que es un grupo
                };

                String? groupId = await DatabaseMethods().createGroup(groupInfoMap);

                if (groupId != null) {
                  print('Grupo creado con id: $groupId');
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
      appBar: AppBar(title: const Text("Grupos")),
      body: Column(
        children: [
          // Barra de búsqueda con botón de crear grupo separado
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      searchGroups(value); // Llamamos a la función de búsqueda
                    },
                    decoration: const InputDecoration(
                      hintText: 'Buscar grupo...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10), // Espacio entre la barra de búsqueda y el botón
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: createGroup, // Llamamos a la función de crear grupo
                ),
              ],
            ),
          ),
          // Lista de grupos
          Expanded(
            child: StreamBuilder(
              stream: groupsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
                  return const Center(child: Text("No hay grupos disponibles"));
                }

                // Almacenar los grupos cuando se obtienen
                if (allGroups.isEmpty) {
                  allGroups = snapshot.data.docs;
                  filteredGroups = allGroups;
                }

                return ListView.builder(
                  itemCount: filteredGroups.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot ds = filteredGroups[index];
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
                              // Muestra la imagen del grupo en un círculo
                              ds["imageUrl"] != ""
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: Image.network(
                                        ds["imageUrl"],
                                        height: 70,
                                        width: 70,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const CircleAvatar(
                                      backgroundColor: Colors.black,
                                      child: Icon(
                                        Icons.group,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                              const SizedBox(width: 20.0),
                              // Muestra el nombre del grupo y el último mensaje
                              Column(
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
                              const Spacer(),
                              // Muestra la hora del último mensaje
                              Text(
                                ds["lastMessageSendTs"].toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
