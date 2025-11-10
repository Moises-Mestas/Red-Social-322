import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3/services/database_service.dart';
import 'package:flutter_application_3/views/pages/chat_page.dart';

class ChatRoomListTile extends StatefulWidget {
  final String chatRoomId;
  final String lastMessage;
  final String myUsername;
  final String time;

  const ChatRoomListTile({
    super.key,
    required this.chatRoomId,
    required this.lastMessage,
    required this.myUsername,
    required this.time,
  });

  @override
  State<ChatRoomListTile> createState() => _ChatRoomListTileState();
}

class _ChatRoomListTileState extends State<ChatRoomListTile> {
  final DatabaseService _databaseService = DatabaseService();

  String profilePicUrl = "";
  String name = "";
  String username = "";
  String? otherUserId; // <-- Cambiado a 'otherUserId' para más claridad
  Stream<DocumentSnapshot>? _userStream; // <-- Añadido de nuevo

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  // --- CORRECCIÓN: El método debe ser Future<void> por ser async ---
  Future<void> _getUserInfo() async {
    username = widget.chatRoomId
        .replaceAll("_", "")
        .replaceAll(widget.myUsername, "");

    final querySnapshot = await _databaseService.getUserInfo(username);

    if (mounted && querySnapshot.docs.isNotEmpty) {
      // Obtenemos el ID del documento del usuario
      otherUserId = querySnapshot.docs[0].id; 
      
      setState(() {
        name = querySnapshot.docs[0]["Name"];
        profilePicUrl = querySnapshot.docs[0]["Image"];
      });
      
      // Si obtuvimos el ID, nos suscribimos a su stream
      if (otherUserId != null) {
        _userStream = _databaseService.getUserStream(otherUserId!);
        setState(() {}); // Actualiza para que el StreamBuilder escuche
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              name: name,
              profileurl: profilePicUrl, // Asegúrate que chat_page reciba 'profileurl'
              username: username,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15.0),
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
              crossAxisAlignment: CrossAxisAlignment.center, // <-- Centrado verticalmente
              children: [
                
                // --- INICIO DE LA CORRECCIÓN (StreamBuilder para foto y estado online) ---
                SizedBox(
                  width: 70, // Ancho fijo
                  height: 70, // Alto fijo
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: _userStream, // Escucha el estado del usuario
                    builder: (context, snapshot) {
                      bool isOnline = false;
                      String? imageFromStream = profilePicUrl; // Foto por defecto

                      if (snapshot.hasData && snapshot.data!.exists) {
                        var data = snapshot.data!.data() as Map<String, dynamic>;
                        isOnline = data.containsKey('isOnline') ? data['isOnline'] : false;
                        imageFromStream = data.containsKey('Image') ? data['Image'] : profilePicUrl;
                      }

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 35, // 70 / 2
                            backgroundColor: Colors.grey[200],
                            backgroundImage: (imageFromStream != null && imageFromStream!.isNotEmpty)
                                ? NetworkImage(imageFromStream!)
                                : null,
                            child: (imageFromStream == null || imageFromStream!.isEmpty)
                                ? const Icon(Icons.person, color: Colors.grey, size: 35)
                                : null,
                          ),
                          if (isOnline)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                // --- FIN DE LA CORRECCIÓN ---

                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // const SizedBox(height: 10.0), // Ya no es necesario con crossAxisAlignment.center
                      Text(
                        name.isNotEmpty ? name : "...",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5.0),
                      Text(
                        widget.lastMessage,
                        style: const TextStyle(
                          color: Color.fromARGB(151, 0, 0, 0),
                          fontSize: 16.0,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10.0),
                Text(
                  widget.time,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}