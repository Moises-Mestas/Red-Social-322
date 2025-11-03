import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3/pages/home.dart';
import 'package:flutter_application_3/services/database.dart';
import 'package:flutter_application_3/services/shared_pref.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:random_string/random_string.dart';


class ChatPage extends StatefulWidget {
  String name, profileurl, username;
  ChatPage(
      {required this.name, required this.profileurl, required this.username});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Stream? messageStream;
  String? myUsername, myName, myEmail, mypicture, chatRoomid, messageId;
  TextEditingController messageController = new TextEditingController();
  File? selectedImage;
  final ImagePicker _picker = ImagePicker();
  // --- VARIABLES PARA LA GRABACIÓN DE VOZ ---

    bool _isRecording = false;
    String? _filePath;

    FlutterSoundRecorder _recorder = FlutterSoundRecorder();

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

    Future<void> _startRecording() async {
      await _recorder.startRecorder(toFile: _filePath);
      setState(() {
        _isRecording = true;
        Navigator.pop(context);
        openRecording();
      });
    }
    Future<void> _stopRecording() async {
      await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
        Navigator.pop(context);
        openRecording();
      });
    }


  getthesahredpref() async {
    myUsername = await SharedpreferencesHelper().getUserName();
    myName = await SharedpreferencesHelper().getUserDisplayName();
    myEmail = await SharedpreferencesHelper().getUserEmail();
    mypicture = await SharedpreferencesHelper().getUserImage();

    chatRoomid = getChatRoomIdbyUsernme(widget.username, myUsername!);
    setState(() {});
  }

  ontheload() async {
    await getthesahredpref();
    await getandSetMessages();
    setState(() {});
  }

@override
void initState() {
  ontheload();
  _initialize(); // <--- añade esto
  super.initState();
}


Future<void> _uploadFile() async {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.redAccent,
      content: Text(
        'Your Audio is Uploading Please Wait...',
        style: TextStyle(fontSize: 20.0),
      ),
    ),
  );

  File file = File(_filePath!);
  try {
    TaskSnapshot snapshot =
        await FirebaseStorage.instance.ref('uploads/audio.aac').putFile(file);

    String downloadURL = await snapshot.ref.getDownloadURL();
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('h:mma').format(now);

    Map<String, dynamic> messageInfoMap = {
      "Data": "Audio",
      "message": downloadURL,
      "sendBy": myUsername,
      "ts": formattedDate,
      "time": FieldValue.serverTimestamp(),
      "imgUrl": mypicture,
    };

    messageId = randomAlphaNumeric(10);

    await DatabaseMethods()
        .addMessage(chatRoomid!, messageId!, messageInfoMap)
        .then((value) async {
      Map<String, dynamic> lastMessageInfoMap = {
        "lastMessage": "[Audio]",
        "lastMessageSendTs": formattedDate,
        "time": FieldValue.serverTimestamp(),
        "lastMessageSendBy": myUsername,
      };
      DatabaseMethods()
          .updateLastMessageSend(chatRoomid!, lastMessageInfoMap);
    });
  } catch (e) {
    print('Error al cargar: $e');
      
    
  }
}


Widget chatMessageTile(String message, bool sendByMe, String data) {
  // Normaliza el valor a minúsculas para evitar errores de comparación
  final type = data.toLowerCase();

  return Row(
    mainAxisAlignment:
        sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
    children: [
      Flexible(
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: sendByMe ? Colors.black45 : Colors.blue,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(30),
              bottomRight:
                  sendByMe ? const Radius.circular(0) : const Radius.circular(30),
              topRight: const Radius.circular(30),
              bottomLeft:
                  sendByMe ? const Radius.circular(30) : const Radius.circular(0),
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

  Future<void> _uploadImage() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(
          "Your Image is Uploading Please Wait...",
          style: TextStyle(fontSize: 20.0),
        ),
      ),
    ); // Text // SnackBar

    try {
      String addId = randomAlphaNumeric(10);

      Reference firebaseStorgeRef =
          FirebaseStorage.instance.ref().child("blogImage").child(addId);

      final UploadTask task = firebaseStorgeRef.putFile(selectedImage!);
      var downloadurl1 = await (await task).ref.getDownloadURL();
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('h:mma').format(now);
      Map<String, dynamic> messageInfoMap = {
        "Data": "Image",
        "message": downloadurl1,
        "sendBy": myUsername,
        "ts": formattedDate,
        "time": FieldValue.serverTimestamp(),
        "imgUrl": mypicture,
      };

      messageId = randomAlphaNumeric(10);
      await DatabaseMethods()
          .addMessage(chatRoomid!, messageId!, messageInfoMap)
          .then((value) {
        Map<String, dynamic> lastMessageInfoMap = {
          "lastMessage": "Image",
          "lastMessageSendTs": formattedDate,
          "time": FieldValue.serverTimestamp(),
          "lastMessageSendBy": myUsername,
        };
        DatabaseMethods()
            .updateLastMessageSend(chatRoomid!, lastMessageInfoMap);
      });} catch (e) {
      print('Error uploading to Firebase: $e');
}
  }
  getandSetMessages() async {
    messageStream = await DatabaseMethods().getChatRoomMessages(chatRoomid);
    setState(() {});
  }

  Future<void> getImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85, // opcional, comprime un poco
    );
    if (image == null) return;           // usuario canceló
    setState(() => selectedImage = File(image.path));
    await _uploadImage();
  }

  Widget chatMessage() {
    return StreamBuilder(
        stream: messageStream,
        builder: (context, AsyncSnapshot snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  itemCount: snapshot.data.docs.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    DocumentSnapshot ds = snapshot.data.docs[index];
                    return chatMessageTile(
                        ds["message"], myUsername == ds["sendBy"], ds["Data"]);
                  })
              : Container();
        });
  }

  getChatRoomIdbyUsernme(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  addMessage(bool sendClicked) async {
    // --- CORREGIDO: 'C' mayúscula en messageController ---
    if (messageController.text != "") {
      String message = messageController.text;
      messageController.text = "";

      DateTime now = DateTime.now();
      String formattedDate = DateFormat('h:mma').format(now);
      Map<String, dynamic> messageInfoMap = {
        "Data": "Message",
        "message": message,
        "sendBy": myUsername, 
        "ts": formattedDate,
        "time": FieldValue.serverTimestamp(),
        "imgUrl": mypicture,
      };
      messageId = randomAlphaNumeric(10);
      await DatabaseMethods()
          .addMessage(chatRoomid!, messageId!, messageInfoMap)
          .then((value) {
        Map<String, dynamic> lastMessageInfoMap = {
          "lastMessage": message,
          "lastMessageSendTs": formattedDate,
          "time": FieldValue.serverTimestamp(),
          "lastMessageSendBy": myUsername,
        };
        DatabaseMethods()
            .updateLastMessageSend(chatRoomid!, lastMessageInfoMap);
        if (sendClicked) {
          message = "";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 79, 191, 219),
      body: Container(
        margin: EdgeInsets.only(top: 40.0),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Row(
              children: [
                GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => Home()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                    )),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 5,
                ),
                Text(widget.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26.0,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SizedBox(height: 20.0),
          Expanded(
            child: Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30)),
              ),
              // --- CORREGIDO: Estructura de UI para chat ---
              child: Column(
                children: [
                  // 1. La lista de mensajes ocupa el espacio expandido
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.only(top: 20.0), // Espacio arriba
                      child: chatMessage(),
                    ),
                  ),
                  
                  // 2. La barra de input se queda fija abajo
                  Container(
                    // ======== AÑADE ESTA LÍNEA ========
                    margin: EdgeInsets.only(bottom: 50.0), 
                    // ===================================
                    padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                    child: Row(
                      children: [
                        GestureDetector( // <-- Botón de micrófono
                          onTap: () {
                            openRecording(); // Llama al diálogo
                          },
                          child: Container(
                            padding: EdgeInsets.all(10), // Padding ajustado
                            decoration: BoxDecoration(
                             color: Color.fromARGB(255, 79, 191, 219),

                                borderRadius: BorderRadius.circular(60)),
                            child: Icon(
                              Icons.mic,
                              size: 28.0, // Tamaño ajustado
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.0),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.0), // Padding interno
                            decoration: BoxDecoration(
                                color: Color(0xFFececf8),
                                borderRadius: BorderRadius.circular(30)), // Bordes redondos
                            child: TextField(
                              controller: messageController,
                              style: TextStyle(color: Colors.black), // Color de texto
                              decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Escribir un mensaje...",
                                  hintStyle: TextStyle(color: Colors.black54),
                                  suffixIcon: IconButton(
                                  icon: const Icon(Icons.attach_file, color: Color.fromARGB(255, 79, 191, 219)),
                                  onPressed: getImage, // <-- abre la galería
                                  tooltip: 'Adjuntar imagen',
                                ))),
                            ),
                          ),
                        
                        SizedBox(width: 10.0),
                        GestureDetector( // <-- Botón de enviar
                          onTap: () {
                            addMessage(true);
                          },
                          child: Container(
                            padding: EdgeInsets.all(10), // Padding ajustado
                            decoration: BoxDecoration(
                            color: Color.fromARGB(255, 79, 191, 219),
                              borderRadius: BorderRadius.circular(60),
                            ),
                            child: Icon(
                              Icons.send,
                              size: 28.0, // Tamaño ajustado
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  // --- FIN DE LA CORRECCIÓN DE UI ---
                ],
              ),
            ),
          )
        ]),
      ),
    );
  }

  // ==========================================================
  // CORREGIDO: Esta función AHORA ESTÁ DENTRO de _ChatPageState
  // ==========================================================
  Future openRecording() => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: SingleChildScrollView(
            child: Container(
              child: Column(
                children: [
                  Text(
                    "Add Voice Note",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ), // Text
                  SizedBox(height: 20.0), // SizedBox
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_isRecording) {
                        await _stopRecording();
                        setState(() => _isRecording = false);
                      } else {
                        await _startRecording();
                        setState(() => _isRecording = true);
                      }
                      // Actualiza el diálogo (si es stateful) o ciérralo
                      // Navigator.pop(context); // Puede que necesites esto
                    },
                    icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                    label: Text(
                      _isRecording ? 'Stop Recording' : 'Start Recording',
                      style: TextStyle(
                          fontSize: 20.0, fontWeight: FontWeight.w600),
                    ),
                  ), // ElevatedButton
                  SizedBox(
                    height: 20.0,
                  ), // SizedBox
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (_isRecording) {
                        null; // No hacer nada si está grabando
                      } else {
                        _uploadFile(); // Sube el archivo si no está grabando
                      }
                    },
                    child: Text(
                      'Upload Audio',
                      style:
                          TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold), // <-- Corregido
                    ),
                  ), // ElevatedButton
                ],
              ),
            ),
          ),
        ),
      );
} // <-- FIN DE LA CLASE _ChatPageState