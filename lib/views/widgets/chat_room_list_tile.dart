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
  String id = "";

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  void _getUserInfo() async {
    username = widget.chatRoomId
        .replaceAll("_", "")
        .replaceAll(widget.myUsername, "");

    final querySnapshot = await _databaseService.getUserInfo(username);

    if (mounted && querySnapshot.docs.isNotEmpty) {
      setState(() {
        name = querySnapshot.docs[0]["Name"];
        profilePicUrl = querySnapshot.docs[0]["Image"];
        id = querySnapshot.docs[0]["Id"];
      });
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
              profileurl: profilePicUrl,
              username: username,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen de perfil
              profilePicUrl.isEmpty
                  ? const CircleAvatar(
                      backgroundColor: Colors.grey,
                      radius: 35,
                      child: Icon(Icons.person, color: Colors.white),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Image.network(
                        profilePicUrl,
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const CircleAvatar(
                            backgroundColor: Colors.grey,
                            radius: 35,
                            child: Icon(Icons.person, color: Colors.white),
                          );
                        },
                      ),
                    ),
              const SizedBox(width: 20.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10.0),
                    Text(
                      name.isNotEmpty ? name : "Cargando...",
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
                _formatTime(widget.time),
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String time) {
    try {
      if (time.length > 10) {
        return time.substring(11, 16); // Formato HH:mm
      }
      return time;
    } catch (e) {
      return time;
    }
  }
}
