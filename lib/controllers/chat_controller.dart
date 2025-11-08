// lib/controllers/chat_controller.dart
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

  // --- MODIFICADO: Añadidos campos de 'reply' ---
  Future<void> sendTextMessage({
    required String chatRoomId,
    required String message,
    required String myPicture,
    required bool isGroup,
    String? replyToMessageId,
    String? replyToMessageText,
    String? replyToMessageSenderApodo,
  }) async {
    final myUsername = await _sharedPrefService.getUserName();
    if (myUsername == null) return;

    final now = DateTime.now();
    final formattedDate = DateFormat('h:mma').format(now); // <-- Usaremos este para la hora

    final messageInfoMap = {
      "Data": "Message",
      "message": message,
      "sendBy": myUsername,
      "ts": formattedDate, // <-- Hora formateada
      "time": FieldValue.serverTimestamp(),
      "imgUrl": myPicture,
      // --- NUEVOS CAMPOS ---
      "replyToMessageId": replyToMessageId,
      "replyToMessageText": replyToMessageText,
      "replyToMessageSenderApodo": replyToMessageSenderApodo,
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

  // --- MODIFICADO: Añadidos campos de 'reply' ---
  Future<void> sendImageMessage({
    required String chatRoomId,
    required File imageFile,
    required String myPicture,
    required bool isGroup,
    String? replyToMessageId,
    String? replyToMessageText,
    String? replyToMessageSenderApodo,
  }) async {
    final myUsername = await _sharedPrefService.getUserName();
    if (myUsername == null) return;

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
      // --- NUEVOS CAMPOS ---
      "replyToMessageId": replyToMessageId,
      "replyToMessageText": replyToMessageText,
      "replyToMessageSenderApodo": replyToMessageSenderApodo,
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

  // (sendImageMessageWithUrl omitido por brevedad, asumo que no se usa para respuestas)
  Future<void> sendImageMessageWithUrl(
      {required String chatRoomId,
      required String imageUrl,
      required String myPicture,
      required bool isGroup}) async {
        // ... (tu código) ...
      }


  // --- MODIFICADO: Añadidos campos de 'reply' ---
  Future<void> sendAudioMessage({
    required String chatRoomId,
    required String audioUrl,
    required String myPicture,
    String? replyToMessageId,
    String? replyToMessageText,
    String? replyToMessageSenderApodo,
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
      // --- NUEVOS CAMPOS ---
      "replyToMessageId": replyToMessageId,
      "replyToMessageText": replyToMessageText,
      "replyToMessageSenderApodo": replyToMessageSenderApodo,
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