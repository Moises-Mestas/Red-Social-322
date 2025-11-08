// lib/views/pages/chat_page.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3/controllers/chat_controller.dart';
import 'package:flutter_application_3/services/shared_pref_service.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_application_3/views/pages/home_page.dart';
import 'package:flutter_application_3/views/pages/user_profile_page.dart'; // <-- IMPORTANTE AÑADIR ESTE

class ChatPage extends StatefulWidget {
  final String name, profileurl, username;

  const ChatPage({
    super.key,
    required this.name,
    required this.profileurl,
    required this.username,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatController _chatController = ChatController();
  final SharedPrefService _sharedPrefService = SharedPrefService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _messageController = TextEditingController();

  Stream? _messageStream;
  String? _myUsername, _myName, _myEmail, _myPicture, _chatRoomId;
  File? _selectedImage;

  // --- Variables de estado para respuesta ---
  String? _replyToMessageId;
  String? _replyToMessageText;
  String? _replyToMessageSenderApodo;

  // Variables para grabación de voz
  bool _isRecording = false;
  String? _filePath;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  @override
  void initState() {
    super.initState();
    _initialize();
    _loadUserData();
  }

  Future<void> _initialize() async {
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

  Future<void> _loadUserData() async {
    final userData = await _sharedPrefService.getAllUserData();
    setState(() {
      _myUsername = userData['username'];
      _myName = userData['displayName'];
      _myEmail = userData['email'];
      _myPicture = userData['imageUrl'];
    });

    if (_myUsername != null) {
      _chatRoomId = await _chatController.getOrCreateChatRoom(widget.username);
      _getAndSetMessages();
    }
  }

  Future<void> _getAndSetMessages() async {
    if (_chatRoomId != null) {
      _messageStream = _chatController.getChatRoomMessages(_chatRoomId!);
      setState(() {});
    }
  }

  // --- Métodos para manejar respuestas ---
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
  // ---------------------------------------------

  // Métodos para grabación de voz
  Future<void> _startRecording() async {
    // ... (código sin cambios) ...
  }

  Future<void> _stopRecording() async {
    // ... (código sin cambios) ...
  }

  Future<void> _uploadAudioFile() async {
    if (_filePath == null) return;
    // ... (SnackBar) ...
    try {
      File file = File(_filePath!);
      TaskSnapshot snapshot = await FirebaseStorage.instance
          .ref('uploads/audio_${DateTime.now().millisecondsSinceEpoch}.aac')
          .putFile(file);
      String downloadURL = await snapshot.ref.getDownloadURL();

      await _chatController.sendAudioMessage(
        chatRoomId: _chatRoomId!,
        audioUrl: downloadURL,
        myPicture: _myPicture ?? '',
        replyToMessageId: _replyToMessageId,
        replyToMessageText: _replyToMessageText,
        replyToMessageSenderApodo: _replyToMessageSenderApodo,
      );
      _cancelReply(); // Limpiar respuesta
    } catch (e) {
      // ... (manejo de error) ...
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;
    // ... (SnackBar) ...
    try {
      await _chatController.sendImageMessage(
        chatRoomId: _chatRoomId!,
        imageFile: _selectedImage!,
        myPicture: _myPicture ?? '',
        isGroup: false,
        replyToMessageId: _replyToMessageId,
        replyToMessageText: _replyToMessageText,
        replyToMessageSenderApodo: _replyToMessageSenderApodo,
      );
      _cancelReply(); // Limpiar respuesta
    } catch (e) {
      // ... (manejo de error) ...
    }
  }

  Future<void> _getImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() => _selectedImage = File(image.path));
    await _uploadImage();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isNotEmpty && _chatRoomId != null) {
      await _chatController.sendTextMessage(
        chatRoomId: _chatRoomId!,
        message: _messageController.text,
        myPicture: _myPicture ?? '',
        isGroup: false,
        replyToMessageId: _replyToMessageId,
        replyToMessageText: _replyToMessageText,
        replyToMessageSenderApodo: _replyToMessageSenderApodo,
      );
      _messageController.clear();
      _cancelReply(); // Limpiar respuesta
    }
  }

  // --- WIDGET REDISEÑADO ---
  Widget _chatMessageTile({
    required String message,
    required bool sendByMe,
    required String dataType,
    required String timestamp,
    required String senderApodo,
    required String senderPicture,
    String? replyText,
    String? replySenderApodo,
    // (ya no se necesita onLongPress)
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
            return const Text("Error al cargar la imagen", style: TextStyle(color: Colors.white));
          },
        ),
      );
    } else if (type == "audio") {
      messageContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.mic, color: Colors.white),
          SizedBox(width: 8),
          Text("Audio", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      );
    } else {
      messageContent = Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. FOTO DE PERFIL (Clickable)
          if (!sendByMe)
            // --- INICIO DE LA MODIFICACIÓN (Foto Clickable) ---
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfilePage(
                      username: senderApodo, // <-- Navega al perfil
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CircleAvatar(
                  radius: 22,
                  backgroundImage: senderPicture.isNotEmpty
                      ? NetworkImage(senderPicture)
                      : null,
                  child: senderPicture.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
              ),
            ),
            // --- FIN DE LA MODIFICACIÓN ---

          // 2. COLUMNA DEL MENSAJE
          Flexible(
            child: Column(
              crossAxisAlignment: sendByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                      bottomRight: sendByMe ? const Radius.circular(0) : const Radius.circular(30),
                      topRight: const Radius.circular(30),
                      bottomLeft: sendByMe ? const Radius.circular(30) : const Radius.circular(0),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(30),
                      bottomRight: sendByMe ? const Radius.circular(0) : const Radius.circular(30),
                      topRight: const Radius.circular(30),
                      bottomLeft: sendByMe ? const Radius.circular(30) : const Radius.circular(0),
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
                  padding: const EdgeInsets.only(top: 4, left: 10, right: 10),
                  child: Text(
                    timestamp,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (sendByMe)
            const SizedBox(width: 52), 
        ],
      ),
    );
  }


  Widget _chatMessageList() {
    return StreamBuilder(
      stream: _messageStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: snapshot.data.docs.length,
          reverse: true,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data.docs[index];
            
            bool isMe = _myUsername == ds["sendBy"];
            
            String? replyText;
            String? replySender;
            try {
              replyText = ds["replyToMessageText"];
              replySender = ds["replyToMessageSenderApodo"];
            } catch (e) {
              replyText = null;
              replySender = null;
            }

            // --- INICIO DE LA MODIFICACIÓN (Swipe to Reply) ---
            return Dismissible(
              key: Key(ds.id), // Clave única para el widget
              direction: DismissDirection.startToEnd, // Solo deslizar de izq a der
              
              // Esta es la función que se llama al deslizar
              confirmDismiss: (direction) async {
                _startReply(ds.id, ds["message"], ds["sendBy"]);
                return false; // Retorna falso para NO eliminar el mensaje
              },
              
              // Fondo que aparece al deslizar
              background: Container(
                color: Colors.blue.withOpacity(0.1),
                padding: const EdgeInsets.only(left: 28),
                alignment: Alignment.centerLeft,
                child: const Icon(Icons.reply, color: Colors.blue),
              ),
              
              // Tu widget de mensaje normal
              child: _chatMessageTile(
                message: ds["message"],
                sendByMe: isMe,
                dataType: ds["Data"],
                timestamp: ds["ts"] ?? "",
                senderApodo: ds["sendBy"],
                senderPicture: ds["imgUrl"] ?? "",
                replyText: replyText,
                replySenderApodo: replySender,
              ),
            );
            // --- FIN DE LA MODIFICACIÓN ---
          },
        );
      },
    );
  }

  Future<void> _openRecordingDialog() {
    // ... (tu código no cambia) ...
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            children: [
              // ...
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
                    _uploadAudioFile(); // Llama a la versión actualizada
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
  }

  // --- WIDGET: Banner de respuesta ---
  Widget _buildReplyBanner() {
    if (_replyToMessageId == null) {
      return const SizedBox.shrink(); // No muestra nada si no hay respuesta
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
  // ------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 79, 191, 219),
      body: Container(
        margin: const EdgeInsets.only(top: 40.0),
        child: Column(
          children: [
            // Header centrado con el Apodo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.username, // Apodo
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Opacity(
                    opacity: 0.0,
                    child: Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: _chatMessageList(),
                      ),
                    ),
                    
                    // --- MODIFICADO: Añadido banner y área de input ---
                    Column(
                      children: [
                        _buildReplyBanner(), // <-- BANNER DE RESPUESTA
                        Container(
                          margin: const EdgeInsets.only(bottom: 50.0),
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
                                    color: const Color.fromARGB(255, 79, 191, 219),
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
                                          color: Color.fromARGB(255, 79, 191, 219),
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
                                    color: const Color.fromARGB(255, 79, 191, 219),
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }
}