// lib/views/pages/chat_page.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3/controllers/chat_controller.dart';
import 'package:flutter_application_3/services/shared_pref_service.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:image_picker/image_picker.dart';
// --- AÑADIDO: Import para el reproductor ---
import 'package:audioplayers/audioplayers.dart';
// ----------------------------------------
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

  // --- Variables de Audio ---
  bool _isRecording = false;
  String? _filePath;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  // --- AÑADIDO: Reproductor de Audio ---
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingUrl; // Para saber qué audio se está reproduciendo
  PlayerState? _playerState;
  // ----------------------------------

  @override
  void initState() {
    super.initState();
    _initialize();
    _loadUserData(); // <-- Esta función ahora reseteará el contador

    // --- Escuchar cambios de estado del reproductor ---
    _audioPlayer.onPlayerStateChanged.listen((PlayerState s) {
      if (mounted) {
        setState(() {
          _playerState = s;
          // Si el audio termina, reseteamos el estado
          if (s == PlayerState.completed || s == PlayerState.stopped) {
            _currentlyPlayingUrl = null;
          }
        });
      }
    });
    // ----------------------------------------------------
  }

  // --- MODIFICADO: dispose (de Código 2) ---
  @override
  void dispose() {
    _recorder.closeRecorder();
    _audioPlayer.dispose(); // <-- AÑADIDO
    _messageController.dispose();
    super.dispose();
  }
  // --- FIN DE LA MODIFICACIÓN ---

  Future<void> _initialize() async {
    await _recorder.openRecorder();
    await _requestPermission();
    var tempDir = await getTemporaryDirectory();
    _filePath = '${tempDir.path}/audio.aac';
  }

  Future<void> _requestPermission() async {
    // Pedimos permiso de micrófono Y almacenamiento
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  // --- MODIFICADO: _loadUserData (de Código 2) ---
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

      // --- INICIO DE LA MODIFICACIÓN ---
      // Una vez que tenemos el chatRoomId y nuestro username,
      // le decimos a la BD que ya hemos leído este chat.
      if (_chatRoomId != null) {
        await _chatController.resetUnreadCount(_chatRoomId!, _myUsername!);
      }
      // --- FIN DE LA MODIFICACIÓN ---

      _getAndSetMessages();
    }
  }
  // --- FIN DE LA MODIFICACIÓN ---

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

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Subiendo nota de voz...")));

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error al subir audio: $e"),
          backgroundColor: Colors.red));
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Subiendo imagen...")));

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error al subir imagen: $e"),
          backgroundColor: Colors.red));
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

  // --- Lógica para reproducir audio ---
  Future<void> _playAudio(String url) async {
    try {
      if (_playerState == PlayerState.playing) {
        // Si se está reproduciendo algo
        if (_currentlyPlayingUrl == url) {
          // Si es el MISMO audio, pausar
          await _audioPlayer.pause();
        } else {
          // Si es un audio DIFERENTE, detener el anterior y reproducir el nuevo
          await _audioPlayer.stop();
          await _audioPlayer.play(UrlSource(url));
          setState(() {
            _currentlyPlayingUrl = url;
          });
        }
      } else if (_playerState == PlayerState.paused &&
          _currentlyPlayingUrl == url) {
        // Si está pausado y es el mismo audio, reanudar
        await _audioPlayer.resume();
      } else {
        // Si no se está reproduciendo nada, reproducir
        await _audioPlayer.play(UrlSource(url));
        setState(() {
          _currentlyPlayingUrl = url;
        });
      }
    } catch (e) {
      print("Error al reproducir audio: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Error al reproducir audio"),
          backgroundColor: Colors.red));
    }
  }
  // --- FIN DE LA LÓGICA ---

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
      // Determinamos qué icono mostrar
      bool isPlaying =
          _playerState == PlayerState.playing && _currentlyPlayingUrl == message;
      bool isPaused =
          _playerState == PlayerState.paused && _currentlyPlayingUrl == message;

      IconData playIcon = Icons.play_arrow;
      if (isPlaying) {
        playIcon = Icons.pause;
      } else if (isPaused) {
        playIcon = Icons.play_arrow;
      }

      messageContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón de Play/Pause
          IconButton(
            icon: Icon(playIcon, color: Colors.white, size: 30),
            onPressed: () {
              _playAudio(message); // 'message' contiene la URL del audio
            },
          ),
          const Text("Nota de voz",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
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

    // --- Widget de respuesta ---
    Widget replyWidget = const SizedBox.shrink();
    if (replyText != null && replySenderApodo != null) {
      replyWidget = Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(
                color: Colors.white.withOpacity(0.7),
                width: 4,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                replySenderApodo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
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
    // --- Fin del widget de respuesta ---

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

                // --- Estructura del globo ---
                Container(
                  decoration: BoxDecoration(
                    color: sendByMe
                        ? const Color.fromARGB(209, 134, 56, 42)
                        : const Color(0xffD32323),
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
                        // 1. El widget de respuesta
                        replyWidget,

                        // 2. El contenido del mensaje principal
                        Padding(
                          padding:
                              (replyText != null && replySenderApodo != null)
                                  ? const EdgeInsets.fromLTRB(12, 4, 12, 12)
                                  : const EdgeInsets.all(12),
                          child: messageContent,
                        ),
                      ],
                    ),
                  ),
                ),
                // --- FIN DE LA ESTRUCTURA DEL GLOBO ---

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

  // --- INICIO DE LA MODIFICACIÓN: _openRecordingDialog (de Código 2) ---
  Future<void> _openRecordingDialog() {
    // Usamos StatefulBuilder para que el modal pueda actualizar su propio estado
    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return AlertDialog(
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    // Indicador de grabación
                    if (_isRecording)
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Grabando...",
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    const SizedBox(height: 20.0),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Ya no cerramos el modal
                        if (_isRecording) {
                          await _stopRecording();
                        } else {
                          await _startRecording();
                        }
                        // Actualizamos solo el modal
                        modalSetState(() {});
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
                      // Solo habilitamos el botón si no se está grabando
                      onPressed: _isRecording
                          ? null
                          : () async {
                              // Guardamos el Navigator ANTES del await
                              final navigator = Navigator.of(context);

                              await _uploadAudioFile();

                              // Cerramos el modal DESPUÉS de subir
                              navigator.pop();
                            },
                      child: const Text(
                        'Subir Audio',
                        style: TextStyle(
                            fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  // --- FIN DE LA CORRECCIÓN ---

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
          const Icon(Icons.reply, size: 20, color: Color(0xffD32323)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Respondiendo a $_replyToMessageSenderApodo",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xffD32323),
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