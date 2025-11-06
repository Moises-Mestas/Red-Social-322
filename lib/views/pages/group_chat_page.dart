import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_application_3/controllers/chat_controller.dart';
import 'package:flutter_application_3/controllers/group_controller.dart';

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

  Stream? _messageStream;
  String? _myUsername;
  File? _selectedImage;
  bool _isUserInGroup = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getMyUsername();
    await _checkIfUserIsInGroup();
    _getMessages();
  }

  Future<void> _getMyUsername() async {
    _myUsername = await _chatController.getMyUsername();
    setState(() {});
  }

  Future<void> _checkIfUserIsInGroup() async {
    _isUserInGroup = await _groupController.isUserInGroup(widget.groupId);
    setState(() {});
  }

  void _getMessages() {
    _messageStream = _chatController.getChatRoomMessages(widget.groupId);
    setState(() {});
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty && _myUsername != null) {
      await _chatController.sendTextMessage(
        chatRoomId: widget.groupId,
        message: _messageController.text,
        myPicture: '',
        isGroup: true,
      );
      _messageController.clear();
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
      myPicture: '',
      isGroup: true,
    );
  }

  Future<void> _joinGroup() async {
    final bool? joinGroupResponse = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Unirte al grupo?'),
        content: const Text('¿Quieres unirte a este grupo?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí'),
          ),
        ],
      ),
    );

    if (joinGroupResponse == true) {
      await _groupController.joinGroup(widget.groupId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Te has unido al grupo')));
        await _checkIfUserIsInGroup();
      }
    }
  }

  Widget _chatMessageTile(String message, bool sendByMe, String data) {
    final type = data.toLowerCase();

    return Row(
      mainAxisAlignment: sendByMe
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                        return const Text(
                          "Error al cargar la imagen",
                          style: TextStyle(color: Colors.white),
                        );
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
            return _chatMessageTile(ds["message"], sendByMe, ds["Data"]);
          },
        );
      },
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

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _getImage,
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
          _buildInputArea(),
        ],
      ),
    );
  }
}
