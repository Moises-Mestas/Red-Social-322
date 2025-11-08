// lib/views/pages/group_chat_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_application_3/controllers/chat_controller.dart';
import 'package:flutter_application_3/controllers/group_controller.dart';
import 'package:flutter_application_3/services/shared_pref_service.dart'; 
import 'package:flutter_application_3/views/pages/user_profile_page.dart'; 

class GroupChatPage extends StatefulWidget {
  final String groupName, groupImageUrl, groupId;

  const GroupChatPage({
    super.key,
    required this.groupName,
    required this.groupImageUrl,
    required this.groupId,
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final ChatController _chatController = ChatController();
  final GroupController _groupController = GroupController();
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final SharedPrefService _sharedPrefService = SharedPrefService(); 

  Stream? _messageStream;
  String? _myUsername;
  String? _myPicture; // <-- Variable para guardar tu foto
  File? _selectedImage;
  bool _isUserInGroup = false;

  String? _replyToMessageId;
  String? _replyToMessageText;
  String? _replyToMessageSenderApodo;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getMyUsername();
    await _getMyPicture(); // <-- Cargar tu foto al iniciar
    await _checkIfUserIsInGroup();
    _getMessages();
  }

  Future<void> _getMyUsername() async {
    _myUsername = await _chatController.getMyUsername();
    setState(() {});
  }

  // --- MÉTODO PARA OBTENER TU FOTO ---
  Future<void> _getMyPicture() async {
    _myPicture = await _sharedPrefService.getUserImage();
  }

  Future<void> _checkIfUserIsInGroup() async {
    _isUserInGroup = await _groupController.isUserInGroup(widget.groupId);
    setState(() {});
  }

  void _getMessages() {
    _messageStream = _chatController.getChatRoomMessages(widget.groupId);
    setState(() {});
  }

  void _startReply(String messageId, String messageText, String senderApodo) {
    setState(() {
      _replyToMessageId = messageId;
      _replyToMessageText = messageText;
      _replyToMessageSenderApodo = senderApodo;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyToMessageId = null;
      _replyToMessageText = null;
      _replyToMessageSenderApodo = null;
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty && _myUsername != null) {
      await _chatController.sendTextMessage(
        chatRoomId: widget.groupId,
        message: _messageController.text,
        myPicture: _myPicture ?? '', // <-- ¡¡AQUÍ ESTÁ LA CORRECCIÓN!! (antes era '')
        isGroup: true,
        replyToMessageId: _replyToMessageId,
        replyToMessageText: _replyToMessageText,
        replyToMessageSenderApodo: _replyToMessageSenderApodo,
      );
      _messageController.clear();
      _cancelReply(); 
    }
  }

  Future<void> _getImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() {
      _selectedImage = File(image.path);
    });
    await _uploadImage();
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null || _myUsername == null) return;

    await _chatController.sendImageMessage(
      chatRoomId: widget.groupId,
      imageFile: _selectedImage!,
      myPicture: _myPicture ?? '', // <-- ¡¡AQUÍ ESTÁ LA CORRECCIÓN!! (antes era '')
      isGroup: true,
      replyToMessageId: _replyToMessageId,
      replyToMessageText: _replyToMessageText,
      replyToMessageSenderApodo: _replyToMessageSenderApodo,
    );
    _cancelReply(); 
  }

  Future<void> _joinGroup() async {
    // ... (tu código no cambia) ...
  }

  // --- WIDGET DE MENSAJE (Con márgenes simétricos) ---
  Widget _chatMessageTile({
    required String message,
    required bool sendByMe,
    required String dataType,
    required String timestamp,
    required String senderApodo,
    required String senderPicture,
    String? replyText,
    String? replySenderApodo,
  }) {
    final type = dataType.toLowerCase();

    // Widget para el contenido principal del mensaje
    Widget messageContent;
    if (type == "image") {
      messageContent = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          message,
          height: 200,
          width: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return const Text("Error al cargar la imagen",
                style: TextStyle(color: Colors.white));
          },
        ),
      );
    } else if (type == "audio") {
      messageContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.mic, color: Colors.white),
          SizedBox(width: 8),
          Text("Audio",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ],
      );
    } else {
      messageContent = Text(
        message,
        style: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
      );
    }

    // Widget para el mensaje respondido (si existe)
    Widget replyWidget = const SizedBox.shrink();
    if (replyText != null && replySenderApodo != null) {
      replyWidget = Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Respondiendo a $replySenderApodo",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              replyText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    
    const double avatarRadius = 22;
    const double avatarPadding = 8;
    const double avatarTotalSpace = (avatarRadius * 2) + avatarPadding;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // FOTO o SPACER (Lado Izquierdo)
          if (!sendByMe)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfilePage(
                      username: senderApodo,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(right: avatarPadding),
                child: CircleAvatar(
                  radius: avatarRadius, 
                  backgroundImage: senderPicture.isNotEmpty
                      ? NetworkImage(senderPicture)
                      : null,
                  child:
                      senderPicture.isEmpty ? const Icon(Icons.person) : null,
                ),
              ),
            )
          else
            const SizedBox(width: avatarTotalSpace), 

          // COLUMNA DEL MENSAJE (Flexible)
          Flexible(
            child: Column(
              crossAxisAlignment:
                  sendByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // APODO
                if (!sendByMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0, bottom: 2.0),
                    child: Text(
                      senderApodo,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // GLOBO DEL MENSAJE
                Container(
                  decoration: BoxDecoration(
                    color: sendByMe ? Colors.black45 : Colors.blue,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(30),
                      bottomRight: sendByMe
                          ? const Radius.circular(0)
                          : const Radius.circular(30),
                      topRight: const Radius.circular(30),
                      bottomLeft: sendByMe
                          ? const Radius.circular(30)
                          : const Radius.circular(0),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(30),
                      bottomRight: sendByMe
                          ? const Radius.circular(0)
                          : const Radius.circular(30),
                      topRight: const Radius.circular(30),
                      bottomLeft: sendByMe
                          ? const Radius.circular(30)
                          : const Radius.circular(0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        replyWidget,
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: messageContent,
                        ),
                      ],
                    ),
                  ),
                ),

                // HORA
                Padding(
                  padding:
                      const EdgeInsets.only(top: 4, left: 10, right: 10),
                  child: Text(
                    timestamp,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // SPACER (Lado Derecho)
          if (sendByMe)
            const SizedBox.shrink() 
          else
            const SizedBox(width: avatarTotalSpace),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _messageStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
          return const Center(child: Text("No hay mensajes disponibles"));
        }

        return ListView.builder(
          reverse: true,
          itemCount: snapshot.data.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data.docs[index];
            bool sendByMe = _myUsername == ds['sendBy'];
            
            String? replyText;
            String? replySender;
            try {
              replyText = ds["replyToMessageText"];
              replySender = ds["replyToMessageSenderApodo"];
            } catch (e) {
              replyText = null;
              replySender = null;
            }

            return Dismissible(
              key: Key(ds.id),
              direction: DismissDirection.startToEnd,
              confirmDismiss: (direction) async {
                _startReply(ds.id, ds["message"], ds["sendBy"]);
                return false; 
              },
              background: Container(
                color: Colors.blue.withOpacity(0.1),
                padding: const EdgeInsets.only(left: 28),
                alignment: Alignment.centerLeft,
                child: const Icon(Icons.reply, color: Colors.blue),
              ),
              child: _chatMessageTile(
                message: ds["message"],
                sendByMe: sendByMe,
                dataType: ds["Data"],
                timestamp: ds["ts"] ?? "",
                senderApodo: ds["sendBy"],
                senderPicture: ds["imgUrl"] ?? "", // <-- ¡¡AQUÍ ESTÁ LA CORRECCIÓN!! (se lee ds["imgUrl"])
                replyText: replyText,
                replySenderApodo: replySender,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReplyBanner() {
    if (_replyToMessageId == null) {
      return const SizedBox.shrink(); 
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
      ),
      child: Row(
        children: [
          const Icon(Icons.reply, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Respondiendo a $_replyToMessageSenderApodo",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  _replyToMessageText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: _cancelReply,
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    if (!_isUserInGroup) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _joinGroup,
          child: const Text('Unirse al grupo para enviar mensajes'),
        ),
      );
    }

    // El input de texto ahora está dentro del Column
    // que también contiene el _buildReplyBanner
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _getImage, // Debes implementar _getImage para chat grupal
            child: const Icon(Icons.photo, color: Colors.blue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Escribe un mensaje...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        centerTitle: true, // <-- TÍTULO CENTRADO
        actions: [
          if (!_isUserInGroup)
            IconButton(
              icon: const Icon(Icons.group_add),
              onPressed: _joinGroup,
              tooltip: 'Unirse al grupo',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          // --- MODIFICADO: Contenedor para el banner y el input ---
          Column(
            children: [
              _buildReplyBanner(),
              _buildInputArea(),
            ],
          )
        ],
      ),
    );
  }
}