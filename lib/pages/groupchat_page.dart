import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3/services/database.dart';
import 'package:flutter_application_3/services/shared_pref.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:random_string/random_string.dart';

class GroupChatPage extends StatefulWidget {
  final String groupName, groupImageUrl, groupId;

  GroupChatPage({
    required this.groupName,
    required this.groupImageUrl,
    required this.groupId,
  });

  @override
  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  String? myUsername;
  Stream? messageStream;
  TextEditingController messageController = TextEditingController();
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    getMyUsername();
    getMessages();
  }

  getMyUsername() async {
    myUsername = await SharedpreferencesHelper().getUserName();
    setState(() {});
  }

  getMessages() async {
    messageStream = await DatabaseMethods().getChatRoomMessages(widget.groupId);
    setState(() {});
  }

  sendMessage() async {
    if (messageController.text.isNotEmpty) {
      String message = messageController.text;
      messageController.clear();

      DateTime now = DateTime.now();
      String formattedDate = DateFormat('h:mma').format(now);

      Map<String, dynamic> messageInfoMap = {
        "Data": "Message",
        "message": message,
        "sendBy": myUsername,
        "time": FieldValue.serverTimestamp(),
        "imgUrl": "", // Optional image URL
      };

      String messageId = randomAlphaNumeric(10);
      await DatabaseMethods().addMessage(widget.groupId, messageId, messageInfoMap);
      Map<String, dynamic> lastMessageInfoMap = {
        "lastMessage": message,
        "lastMessageSendTs": formattedDate,
        "lastMessageSendBy": myUsername,
      };
      await DatabaseMethods().updateLastMessageSend(widget.groupId, lastMessageInfoMap);
    }
  }

  // Función para adjuntar imagen
  getImage() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85, // opcional, comprime un poco
    );
    if (image == null) return;
    setState(() {
      selectedImage = File(image.path);
    });
    await _uploadImage();
  }

  // Función para subir la imagen a Firebase
  Future<void> _uploadImage() async {
    if (selectedImage == null) return;

    String addId = randomAlphaNumeric(10);
    Reference firebaseStorageRef =
        FirebaseStorage.instance.ref().child("group_images").child(addId);

    final UploadTask task = firebaseStorageRef.putFile(selectedImage!);
    var downloadUrl = await (await task).ref.getDownloadURL();

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('h:mma').format(now);

    Map<String, dynamic> messageInfoMap = {
      "Data": "Image",
      "message": downloadUrl,
      "sendBy": myUsername,
      "time": FieldValue.serverTimestamp(),
      "imgUrl": "", // Optional image URL
    };

    String messageId = randomAlphaNumeric(10);
    await DatabaseMethods()
        .addMessage(widget.groupId, messageId, messageInfoMap)
        .then((value) {
      Map<String, dynamic> lastMessageInfoMap = {
        "lastMessage": "Image",
        "lastMessageSendTs": formattedDate,
        "lastMessageSendBy": myUsername,
      };
      DatabaseMethods()
          .updateLastMessageSend(widget.groupId, lastMessageInfoMap);
    });
  }

  // Widget para mostrar los mensajes
  Widget chatMessageTile(String message, bool sendByMe, String data) {
    final type = data.toLowerCase();

    return Row(
      mainAxisAlignment: sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: sendByMe ? Colors.black45 : Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(30),
                bottomRight: sendByMe ? const Radius.circular(0) : const Radius.circular(30),
                topRight: const Radius.circular(30),
                bottomLeft: sendByMe ? const Radius.circular(30) : const Radius.circular(0),
              ),
            ),
            child: type == "image"
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      message,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Text("Error al cargar la imagen");
                      },
                    ),
                  )
                : Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              // Logic for leaving the group (if necessary)
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: messageStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
                  return const Center(child: Text("No hay mensajes disponibles"));
                }

                return 
                ListView.builder(
                reverse: true, // Esta propiedad invierte el orden de los mensajes
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];
                  bool sendByMe = myUsername == ds['sendBy'];
                  return chatMessageTile(ds["message"], sendByMe, ds["Data"]);
                },
              )
              ;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: getImage, // Llama a la función para elegir una imagen
                  child: const Icon(Icons.photo, color: Colors.blue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "Escribe un mensaje...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}