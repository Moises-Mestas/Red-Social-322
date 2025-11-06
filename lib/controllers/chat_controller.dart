import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_3/services/database_service.dart';
import 'package:flutter_application_3/services/shared_pref_service.dart';
import 'package:flutter_application_3/core/utils/chat_utils.dart';
import 'package:intl/intl.dart';

class ChatController {
  final DatabaseService _databaseService = DatabaseService();
  final SharedPrefService _sharedPrefService = SharedPrefService();

  // Método para obtener el username del usuario actual
  Future<String?> getMyUsername() async {
    return await _sharedPrefService.getUserName();
  }

  // Método para obtener los mensajes de un chat room
  Stream<QuerySnapshot> getChatRoomMessages(String chatRoomId) {
    return _databaseService.getChatRoomMessages(chatRoomId);
  }

  // Método para enviar mensaje de texto
  Future<void> sendTextMessage({
    required String chatRoomId,
    required String message,
    required String myPicture,
    required bool isGroup,
  }) async {
    final myUsername = await _sharedPrefService.getUserName();
    if (myUsername == null) return;

    final now = DateTime.now();
    final formattedDate = DateFormat('h:mma').format(now);

    final messageInfoMap = {
      "Data": "Message",
      "message": message,
      "sendBy": myUsername,
      "ts": formattedDate,
      "time": FieldValue.serverTimestamp(),
      "imgUrl": myPicture,
    };

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();

    await _databaseService.addMessage(chatRoomId, messageId, messageInfoMap);

    final lastMessageInfoMap = {
      "lastMessage": message,
      "lastMessageSendTs": formattedDate,
      "lastMessageSendBy": myUsername,
    };

    await _databaseService.updateLastMessage(chatRoomId, lastMessageInfoMap);
  }

  Future<void> sendImageMessage({
    required String chatRoomId,
    required File imageFile, // ✅ Recibe File, no String
    required String myPicture,
    required bool isGroup, // ✅ Este parámetro es requerido
  }) async {
    final myUsername = await _sharedPrefService.getUserName();
    if (myUsername == null) return;

    // Subir imagen primero
    final String? imageUrl = await _databaseService.uploadImage(imageFile);
    if (imageUrl == null) return;

    final now = DateTime.now();
    final formattedDate = DateFormat('h:mma').format(now);

    final messageInfoMap = {
      "Data": "Image",
      "message": imageUrl,
      "sendBy": myUsername,
      "ts": formattedDate,
      "time": FieldValue.serverTimestamp(),
      "imgUrl": myPicture,
    };

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();

    await _databaseService.addMessage(chatRoomId, messageId, messageInfoMap);

    final lastMessageInfoMap = {
      "lastMessage": "Image",
      "lastMessageSendTs": formattedDate,
      "lastMessageSendBy": myUsername,
    };

    await _databaseService.updateLastMessage(chatRoomId, lastMessageInfoMap);
  }

  // Método para enviar mensaje con imagen (con URL)
  Future<void> sendImageMessageWithUrl({
    required String chatRoomId,
    required String imageUrl,
    required String myPicture,
    required bool isGroup,
  }) async {
    final myUsername = await _sharedPrefService.getUserName();
    if (myUsername == null) return;

    final now = DateTime.now();
    final formattedDate = DateFormat('h:mma').format(now);

    final messageInfoMap = {
      "Data": "Image",
      "message": imageUrl,
      "sendBy": myUsername,
      "ts": formattedDate,
      "time": FieldValue.serverTimestamp(),
      "imgUrl": myPicture,
    };

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();

    await _databaseService.addMessage(chatRoomId, messageId, messageInfoMap);

    final lastMessageInfoMap = {
      "lastMessage": "Image",
      "lastMessageSendTs": formattedDate,
      "lastMessageSendBy": myUsername,
    };

    await _databaseService.updateLastMessage(chatRoomId, lastMessageInfoMap);
  }

  // Método para enviar mensaje de audio
  Future<void> sendAudioMessage({
    required String chatRoomId,
    required String audioUrl,
    required String myPicture,
  }) async {
    final myUsername = await _sharedPrefService.getUserName();
    if (myUsername == null) return;

    final now = DateTime.now();
    final formattedDate = DateFormat('h:mma').format(now);

    final messageInfoMap = {
      "Data": "Audio",
      "message": audioUrl,
      "sendBy": myUsername,
      "ts": formattedDate,
      "time": FieldValue.serverTimestamp(),
      "imgUrl": myPicture,
    };

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();

    await _databaseService.addMessage(chatRoomId, messageId, messageInfoMap);

    final lastMessageInfoMap = {
      "lastMessage": "[Audio]",
      "lastMessageSendTs": formattedDate,
      "lastMessageSendBy": myUsername,
    };

    await _databaseService.updateLastMessage(chatRoomId, lastMessageInfoMap);
  }

  Future<String> getOrCreateChatRoom(String otherUsername) async {
    final myUsername = await _sharedPrefService.getUserName();
    if (myUsername == null) throw Exception("Usuario no autenticado");

    final chatRoomId = ChatUtils.getChatRoomIdByUsername(
      myUsername,
      otherUsername,
    );

    // CORRECCIÓN AQUÍ: Agrega <String, dynamic> antes de las llaves
    final chatInfoMap = <String, dynamic>{
      "users": [myUsername, otherUsername],
    };

    await _databaseService.createChatRoom(chatRoomId, chatInfoMap);

    return chatRoomId;
  }

  Stream<QuerySnapshot> getUserChatRooms() async* {
    final myUsername = await _sharedPrefService.getUserName();
    if (myUsername == null) {
      yield* const Stream.empty();
    } else {
      yield* _databaseService.getUserChatRooms(myUsername);
    }
  }
}
