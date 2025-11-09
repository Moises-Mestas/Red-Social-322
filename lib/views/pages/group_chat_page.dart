// lib/views/pages/group_chat_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3/views/pages/group_info_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_application_3/controllers/chat_controller.dart';
import 'package:flutter_application_3/controllers/group_controller.dart';
import 'package:flutter_application_3/services/shared_pref_service.dart'; 
import 'package:flutter_application_3/views/pages/user_profile_page.dart'; 

// --- Imports para el grabador de audio (copiado de chat_page) ---
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
// -----------------------------------------------------------

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
  String? _myPicture;
  File? _selectedImage;
  bool _isUserInGroup = false;

  String? _replyToMessageId;
  String? _replyToMessageText;
  String? _replyToMessageSenderApodo;

  // --- Variables de audio (copiadas de chat_page) ---
  bool _isRecording = false;
  String? _filePath;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  // --------------------------------------------------

  @override
  void initState() {
    super.initState();
    _initialize();
    _initializeAudio(); // <-- AÑADIDO
  }
  
  // --- MÉTODO AÑADIDO ---
  Future<void> _initializeAudio() async {
    await _recorder.openRecorder();
    await _requestPermission();
    var tempDir = await getTemporaryDirectory();
    _filePath = '${tempDir.path}/audio.aac';
  }

  // --- MÉTODO AÑADIDO ---
  Future<void> _requestPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  Future<void> _initialize() async {
    await _getMyUsername();
    await _getMyPicture();
    await _checkIfUserIsInGroup();
    _getMessages();
  }

  Future<void> _getMyUsername() async {
    _myUsername = await _chatController.getMyUsername();
    setState(() {});
  }

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
        myPicture: _myPicture ?? '',
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
      myPicture: _myPicture ?? '',
      isGroup: true,
      replyToMessageId: _replyToMessageId,
      replyToMessageText: _replyToMessageText,
      replyToMessageSenderApodo: _replyToMessageSenderApodo,
    );
    _cancelReply(); 
  }

  // --- MÉTODOS DE AUDIO AÑADIDOS (copiados de chat_page) ---
  Future<void> _startRecording() async {
    await _recorder.startRecorder(toFile: _filePath);
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
  }

  
      // ... (manejo de error)
 
  
  Future<void> _openRecordingDialog() => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              "Nota de voz",
              style: TextStyle(
                color: Colors.black,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                if (_isRecording) {
                  await _stopRecording();
                } else {
                  await _startRecording();
                }
              },
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(
                _isRecording ? 'Detener grabación' : 'Iniciar grabación',
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (!_isRecording) {
                }
              },
              child: const Text(
                'Subir Audio',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  // --- FIN DE MÉTODOS DE AUDIO ---

  Future<void> _joinGroup() async {
    // ... (tu código no cambia) ...
  }

  // --- WIDGET DE MENSAJE (Con diseño y márgenes nuevos) ---
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
    
    const double avatarRadius = 25; // <-- Radio más grande
    const double avatarPadding = 8;
    const double avatarTotalSpace = (avatarRadius * 2) + avatarPadding; // <-- 58px

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 27, vertical: 4), // <-- Márgenes
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
                    // --- COLORES DE GLOBO MEMORIZADOS ---
                    color: sendByMe ? const Color.fromARGB(209, 134, 56, 42) : const Color(0xffD32323),
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
                      fontSize: 13,
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
                senderPicture: ds["imgUrl"] ?? "", 
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

  // --- WIDGET REDISEÑADO ---
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

    // Copiado de chat_page.dart
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0), // <-- Padding inferior
      padding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 10.0,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _openRecordingDialog,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xffD32323),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.mic,
                size: 28.0,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFececf8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Escribir un mensaje...",
                  hintStyle: const TextStyle(
                    color: Colors.black54,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.attach_file,
                      color: Color(0xffD32323),
                    ),
                    onPressed: _getImage,
                    tooltip: 'Adjuntar imagen',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10.0),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xffD32323),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.send,
                size: 28.0,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

@override
  Widget build(BuildContext context) {
  return Scaffold(
  // --- DISEÑO DE APPBAR Y FONDO ACTUALIZADO ---
   backgroundColor: const Color.fromARGB(255, 156, 50, 50)
,
  appBar: AppBar(
  title: Text(
  	widget.groupName,
        // --- INICIO DE LA MODIFICACIÓN ---
  	style: const TextStyle(
  		fontWeight: FontWeight.bold, // <-- AÑADIDO
  	),
        // --- FIN DE LA MODIFICACIÓN ---
   ),
      
            centerTitle: true,
            backgroundColor: const Color.fromARGB(255, 156, 50, 50), // Color rojo
            foregroundColor: Colors.white, // Color de texto e iconos blanco
            elevation: 0,
            actions: [
            IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
            Navigator.push(
            context,
            MaterialPageRoute(
            builder: (context) => GroupInfoPage(
            groupId: widget.groupId,
            groupName: widget.groupName,
            ),
            ),
            );
            },
            ),
            if (!_isUserInGroup)
            IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: _joinGroup,
            tooltip: 'Unirse al grupo',
            ),
            ],
            ),
      // --- FIN DE APPBAR ---

      body: Container( // Añadido para que el fondo blanco no cubra el rojo
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            Expanded(child: _buildMessageList()),
            Column(
              children: [
                _buildReplyBanner(),
                _buildInputArea(),
              ],
            )
          ],
        ),
      ),
    );
  }
}