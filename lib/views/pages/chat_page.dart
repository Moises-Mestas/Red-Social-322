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
import 'package:flutter_application_3/views/pages/user_profile_page.dart'; 

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

  String? _replyToMessageId;
  String? _replyToMessageText;
  String? _replyToMessageSenderApodo;

  bool _isRecording = false;
  String? _filePath;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  
  @override
  void dispose() {
    _recorder.closeRecorder();
    _messageController.dispose();
    super.dispose();
  }

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
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Subiendo nota de voz..."))
    );

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
      _cancelReply(); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al subir audio: $e"), backgroundColor: Colors.red)
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Subiendo imagen..."))
    );

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
      _cancelReply();
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al subir imagen: $e"), backgroundColor: Colors.red)
      );
    } finally {
      setState(() {
        _selectedImage = null; // Limpiar imagen seleccionada
      });
    }
  }

  Future<void> _getImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() => _selectedImage = File(image.path));
    await _uploadImage(); // Subir automáticamente al seleccionar
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
      _cancelReply();
    }
  }

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

    // --- INICIO DE LA MODIFICACIÓN: Nuevo diseño de 'replyWidget' ---
    Widget replyWidget = const SizedBox.shrink();
    if (replyText != null && replySenderApodo != null) {
      replyWidget = Padding(
        // 1. Padding para separarlo del borde de la burbuja
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            // 2. Color de fondo semi-transparente
            color: Colors.black.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            // 3. Barra lateral distintiva
            border: Border(
              left: BorderSide(
                color: Colors.white.withOpacity(0.7), // Color de la barra
                width: 4,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 4. Nombre del remitente original (en negrita)
              Text(
                replySenderApodo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              // 5. Texto del mensaje original (con elipsis)
              Text(
                replyText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }
    // --- FIN DE LA MODIFICACIÓN ---

    const double avatarRadius = 25;
    const double avatarPadding = 8;
    const double avatarTotalSpace = (avatarRadius * 2) + avatarPadding;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 27, vertical: 4),
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

                // --- INICIO DE LA MODIFICACIÓN: Estructura del globo ---
                Container(
                  decoration: BoxDecoration(
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
                  // Usamos ClipRRect para que el color de fondo de la respuesta
                  // respete los bordes redondeados de la burbuja
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
                        // 1. El widget de respuesta (se mostrará si no es nulo)
                        replyWidget, 
                        
                        // 2. El contenido del mensaje principal
                        Padding(
                          // Ajustamos el padding si hay respuesta o no
                          padding: (replyText != null && replySenderApodo != null) 
                              ? const EdgeInsets.fromLTRB(12, 4, 12, 12) // Menos padding superior si hay respuesta
                              : const EdgeInsets.all(12), // Padding normal
                          child: messageContent,
                        ),
                      ],
                    ),
                  ),
                ),
                // --- FIN DE LA MODIFICACIÓN ---

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

            return Dismissible(
              key: Key(ds.id), 
              direction: DismissDirection.startToEnd,
              
              confirmDismiss: (direction) async {
                _startReply(ds.id, ds["message"], ds["sendBy"]);
                return false; 
              },
              
              background: Container(
                // Color de fondo al deslizar (ahora usa tu color rojo)
                color: const Color(0xffD32323).withOpacity(0.1),
                padding: const EdgeInsets.only(left: 28),
                alignment: Alignment.centerLeft,
                child: const Icon(Icons.reply, color: Color(0xffD32323)),
              ),
              
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
          },
        );
      },
    );
  }

  Future<void> _openRecordingDialog() {
    return showDialog(
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
                    _uploadAudioFile(); 
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
          const Icon(Icons.reply, size: 20, color: Color(0xffD32323)), // <-- Color cambiado
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Respondiendo a $_replyToMessageSenderApodo",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xffD32323), // <-- Color cambiado
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffD32323), // <-- Color principal
      body: Container(
        margin: const EdgeInsets.only(top: 40.0),
        child: Column(
          children: [
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
                    widget.username,
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
                    Column(
                      children: [
                        _buildReplyBanner(), 
                        Container(
                          // Aplicamos el padding/margin que solicitaste
                          margin: const EdgeInsets.only(bottom: 60.0), 
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
}