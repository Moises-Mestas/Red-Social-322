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

  // --- FUNCIÓN AUXILIAR PRIVADA (de Código 2) ---
  String _getRecipientUsername(String chatRoomId, String myUsername) {
    List<String> users = chatRoomId.split('_');
    return users.firstWhere((u) => u != myUsername);
  }
  // --- FIN DE FUNCIÓN AUXILIAR ---

  // --- MODIFICADO: Añadida lógica de 'no leídos' ---
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
    final formattedDate = DateFormat('h:mma').format(now);

    final messageInfoMap = {
      "Data": "Message",
      "message": message,
      "sendBy": myUsername,
      "ts": formattedDate,
      "time": FieldValue.serverTimestamp(),
      "imgUrl": myPicture,
      "replyToMessageId": replyToMessageId,
      "replyToMessageText": replyToMessageText,
      "replyToMessageSenderApodo": replyToMessageSenderApodo,
    };

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();

    await _databaseService.addMessage(chatRoomId, messageId, messageInfoMap);

    // --- LÓGICA DE NO LEÍDOS (de Código 2) ---
    Map<String, dynamic> lastMessageInfoMap = {
      "lastMessage": message,
      "lastMessageSendTs": formattedDate,
      "lastMessageSendBy": myUsername,
    };

    if (!isGroup) {
      // 1. Obtener el nombre del destinatario
      String recipientUsername = _getRecipientUsername(chatRoomId, myUsername);
      // 2. Crear el nombre del campo a incrementar
      String recipientUnreadField = "unreadCount_$recipientUsername";
      // 3. Añadir el incremento al mapa
      lastMessageInfoMap[recipientUnreadField] = FieldValue.increment(1);
    }
    // --- LÓGICA DE NO LEÍDOS (FIN) ---

    await _databaseService.updateLastMessage(chatRoomId, lastMessageInfoMap);
  }

  // --- MODIFICADO: Añadida lógica de 'no leídos' ---
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
      "replyToMessageId": replyToMessageId,
      "replyToMessageText": replyToMessageText,
      "replyToMessageSenderApodo": replyToMessageSenderApodo,
    };

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();

    await _databaseService.addMessage(chatRoomId, messageId, messageInfoMap);

    // --- LÓGICA DE NO LEÍDOS (de Código 2) ---
    Map<String, dynamic> lastMessageInfoMap = {
      "lastMessage": "Image",
      "lastMessageSendTs": formattedDate,
      "lastMessageSendBy": myUsername,
    };

    if (!isGroup) {
      String recipientUsername = _getRecipientUsername(chatRoomId, myUsername);
      String recipientUnreadField = "unreadCount_$recipientUsername";
      lastMessageInfoMap[recipientUnreadField] = FieldValue.increment(1);
    }
    // --- LÓGICA DE NO LEÍDOS (FIN) ---

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

  // --- MODIFICADO: Añadida lógica de 'no leídos' ---
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
      "replyToMessageId": replyToMessageId,
      "replyToMessageText": replyToMessageText,
      "replyToMessageSenderApodo": replyToMessageSenderApodo,
    };

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();

    await _databaseService.addMessage(chatRoomId, messageId, messageInfoMap);

    // --- LÓGICA DE NO LEÍDOS (de Código 2) ---
    Map<String, dynamic> lastMessageInfoMap = {
      "lastMessage": "[Audio]",
      "lastMessageSendTs": formattedDate,
      "lastMessageSendBy": myUsername,
    };

    // Asumimos que los audios solo son en 1 a 1 por ahora (como en Código 2)
    String recipientUsername = _getRecipientUsername(chatRoomId, myUsername);
    String recipientUnreadField = "unreadCount_$recipientUsername";
    lastMessageInfoMap[recipientUnreadField] = FieldValue.increment(1);
    // --- LÓGICA DE NO LEÍDOS (FIN) ---

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

  // --- AÑADE ESTE MÉTODO NUEVO (de Código 2) ---
  Future<void> resetUnreadCount(String chatRoomId, String myUsername) async {
    // Si la lógica de 'isGroup' se añade, habría que verificarla aquí
    try {
      // Este método 'resetUnreadCount' debe existir en tu DatabaseService
      await _databaseService.resetUnreadCount(chatRoomId, myUsername);
    } catch (e) {
      print("Error reseteando contador: $e");
    }
  }
}