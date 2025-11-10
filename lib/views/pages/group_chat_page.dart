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
import 'package:firebase_storage/firebase_storage.dart'; // <-- Añadido para subir audio
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
  bool _isLoading = false; 

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
    _initializeAudio();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }
  
  // --- MÉTODOS DE AUDIO ---
  Future<void> _initializeAudio() async {
    await _recorder.openRecorder();
    await _requestPermission();
    var tempDir = await getTemporaryDirectory();
    _filePath = '${tempDir.path}/audio.aac';
  }

  Future<void> _requestPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

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

  Future<void> _uploadAudioFile() async {
    if (_filePath == null) return;
    
    try {
      File file = File(_filePath!);
      TaskSnapshot snapshot = await FirebaseStorage.instance
          .ref('uploads/audio_grupo_${DateTime.now().millisecondsSinceEpoch}.aac')
          .putFile(file);
      String downloadURL = await snapshot.ref.getDownloadURL();

      await _chatController.sendAudioMessage(
        chatRoomId: widget.groupId,
        audioUrl: downloadURL,
        myPicture: _myPicture ?? '',
        replyToMessageId: _replyToMessageId,
        replyToMessageText: _replyToMessageText,
        replyToMessageSenderApodo: _replyToMessageSenderApodo,
      );
      _cancelReply();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al subir audio: $e"), backgroundColor: Colors.red),
      );
    }
  }

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
                      _uploadAudioFile(); // <-- Llamar a la función de subida
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
  // --- FIN MÉTODOS DE AUDIO ---

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

  Future<void> _joinGroup() async {
    if (_myUsername == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await _groupController.joinGroup(widget.groupId);
      
      if (mounted) {
        await _checkIfUserIsInGroup(); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Te has unido al grupo!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al unirse: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
         setState(() {
          _isLoading = false;
        });
      }
    }
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
    // --- LÓGICA DE DISEÑO COPIADA DE CHAT_PAGE ---
    const double avatarRadius = 25;
    const double avatarPadding = 8;
    const double avatarTotalSpace = (avatarRadius * 2) + avatarPadding; // 58px

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
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 27, vertical: 4), // <-- MÁRGENES
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
                    color: sendByMe ? const Color.fromARGB(209, 134, 56, 42) : const Color.fromARGB(255, 156, 50, 50)
,
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

  // --- WIDGET _buildInputArea MODIFICADO (Del Código 2) ---
  Widget _buildInputArea() {
    // Verifica si no está en el grupo
    if (!_isUserInGroup) {
      return Container(
        // --- MODIFICACIÓN: Padding/Margin para subir el botón ---
        padding: const EdgeInsets.only(left: 16, right: 16, top: 10),
        margin: const EdgeInsets.only(bottom: 100.0), // <-- Controla la altura desde abajo
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _joinGroup,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 156, 50, 50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Unirse al grupo para enviar mensajes'),
          ),
        ),
      );
    }

    // Código original para enviar mensajes (si está en el grupo)
    return Container(
      // --- MODIFICACIÓN: Padding/Margin para subir la barra de chat ---
      margin: const EdgeInsets.only(bottom: 55.0), // <-- Controla la altura desde abajo
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
                color: const Color.fromARGB(255, 156, 50, 50)
,
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
                      color: Color.fromARGB(255, 156, 50, 50)
,
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
                color: const Color.fromARGB(255, 156, 50, 50)
,
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
      backgroundColor: const Color.fromARGB(255, 156, 50, 50)
,
      appBar: AppBar(
        title: Text(
          widget.groupName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 156, 50, 50)
,
        foregroundColor: Colors.white,
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
        ],
      ),
      body: Container(
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
                _buildInputArea(), // <-- Este widget ahora maneja su propio padding/margin
              ],
            )
          ],
        ),
      ),
    );
  }
}