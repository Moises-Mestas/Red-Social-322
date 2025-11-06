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
import 'package:random_string/random_string.dart';
import 'package:flutter_application_3/views/pages/home_page.dart';

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
  String? _myUsername, _myName, _myEmail, _myPicture, _chatRoomId, _messageId;
  File? _selectedImage;

  // Variables para grabación de voz
  bool _isRecording = false;
  String? _filePath;
  FlutterSoundRecorder _recorder = FlutterSoundRecorder();

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

  // Métodos para grabación de voz
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
      const SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(
          'Tu audio se está subiendo, por favor espera...',
          style: TextStyle(fontSize: 16.0),
        ),
      ),
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
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error al subir audio: $e'),
          ),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(
          "Tu imagen se está subiendo, por favor espera...",
          style: TextStyle(fontSize: 16.0),
        ),
      ),
    );

    try {
      await _chatController.sendImageMessage(
        chatRoomId: _chatRoomId!,
        imageFile: _selectedImage!,
        myPicture: _myPicture ?? '',
        isGroup: false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error al subir imagen: $e'),
          ),
        );
      }
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
      );
      _messageController.clear();
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
                : type == "audio"
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.mic, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Audio",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
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
            return _chatMessageTile(
              ds["message"],
              _myUsername == ds["sendBy"],
              ds["Data"],
            );
          },
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 79, 191, 219),
      body: Container(
        margin: const EdgeInsets.only(top: 40.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Row(
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
                  SizedBox(width: MediaQuery.of(context).size.width / 5),
                  Text(
                    widget.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26.0,
                      fontWeight: FontWeight.bold,
                    ),
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
