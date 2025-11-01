import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Método para crear un chat si no existe, o agregar un mensaje si ya existe
  Future<void> sendMessage(String receiverId, String message) async {
    User? user = _auth.currentUser;

    if (user == null) {
      throw Exception("No user is logged in");
    }

    String senderId = user.uid;
    String chatId = _generateChatId(senderId, receiverId);

    // Verifica si ya existe un chat entre los dos usuarios
    DocumentReference chatRef = _firestore.collection('chats').doc(chatId);

    // Agrega un mensaje a la subcolección de mensajes
    await chatRef.collection('messages').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // También podemos actualizar el chat principal si es necesario
    await chatRef.set({
      'senderId': senderId,
      'receiverId': receiverId,
    }, SetOptions(merge: true)); // Si ya existe, actualiza los datos
  }

  // Método para obtener los mensajes de un chat
  Stream<QuerySnapshot> getMessages(String receiverId) {
    User? user = _auth.currentUser;

    if (user == null) {
      throw Exception("No user is logged in");
    }

    String senderId = user.uid;
    String chatId = _generateChatId(senderId, receiverId);

    // Recupera los mensajes de la subcolección 'messages'
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  // Genera un ID único para el chat entre los dos usuarios
  String _generateChatId(String senderId, String receiverId) {
    // La idea es concatenar los IDs de los usuarios en un orden fijo
    if (senderId.compareTo(receiverId) > 0) {
      return '$senderId-$receiverId';
    } else {
      return '$receiverId-$senderId';
    }
  }
}
