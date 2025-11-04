import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    loadGroups();
  }

  loadGroups() async {
    groupsStream = await DatabaseMethods().getGroups();
    setState(() {});
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
          TextField(
            controller: searchController,
            decoration: const InputDecoration(hintText: 'Buscar grupo...'),
            onChanged: (value) {
              // Aquí puedes implementar la búsqueda de grupos
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: createGroup,  // Llamamos a la función de crear grupo
          ),
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

                return ListView.builder(
                  itemCount: snapshot.data.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot ds = snapshot.data.docs[index];
                    return GestureDetector(
                      onTap: () {
                        // Navegar a la página del grupo cuando se hace tap en el grupo
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
                                        ds["imageUrl"], // Aquí cargamos la imagen del grupo
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
