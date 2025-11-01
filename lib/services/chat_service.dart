import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Crear un nuevo chat si no existe
  Future<void> createChat(String userId) async {
    String currentUserId = _auth.currentUser!.uid;

    // Verificar si ya existe un chat entre estos dos usuarios
    QuerySnapshot snapshot = await _firestore.collection('chats')
        .where('user1Id', isEqualTo: currentUserId)
        .where('user2Id', isEqualTo: userId)
        .get();

    if (snapshot.docs.isEmpty) {
      // Si no existe, creamos un nuevo chat
      String chatId = currentUserId + userId;  // Generamos un chatId único (puedes mejorar esto si lo prefieres)
      
      await _firestore.collection('chats').doc(chatId).set({
        'user1Id': currentUserId,
        'user2Id': userId,
      });

      // Crear también una subcolección de 'messages' dentro del chat
      await _firestore.collection('chats').doc(chatId).collection('messages').add({
        'senderId': currentUserId,
        'message': '¡Hola! Has iniciado un chat.',
        'messageType': 'text',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  // Enviar un mensaje al chat
  Future<void> sendMessage(String userId, String message, String messageType) async {
    String currentUserId = _auth.currentUser!.uid;

    // Obtener el chatId basado en los dos usuarios
    String chatId = currentUserId + userId;

    // Añadir el mensaje a la subcolección 'messages'
    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': currentUserId,
      'message': message,
      'messageType': messageType, // Puede ser 'text', 'image', 'audio'
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Obtener los mensajes de un chat
  Stream<QuerySnapshot> getMessages(String userId) {
    String currentUserId = _auth.currentUser!.uid;

    // Obtener el chatId basado en los dos usuarios
    String chatId = currentUserId + userId;

    // Escuchar los mensajes en tiempo real
    return _firestore.collection('chats').doc(chatId).collection('messages')
      .orderBy('timestamp', descending: false) // Ordenar por timestamp
      .snapshots();
  }
}
