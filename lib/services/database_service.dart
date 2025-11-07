import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter_application_3/core/constants/app_constants.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // User methods
  Future<void> addUser(String id, Map<String, dynamic> userInfoMap) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(id)
        .set(userInfoMap);
  }

  Future<QuerySnapshot> searchUser(String username) async {
    return await _firestore
        .collection(AppConstants.usersCollection)
        .where("SearchKey", isEqualTo: username.substring(0, 1).toUpperCase())
        .get();
  }

  Future<QuerySnapshot> getUserInfo(String username) async {
    return await _firestore
        .collection(AppConstants.usersCollection)
        .where("username", isEqualTo: username)
        .get();
  }

  // Image upload
  // En services/database_service.dart
  Future<String?> uploadImage(File imageFile, {String? customPath}) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      String path = customPath ?? "${AppConstants.groupImagesPath}/$fileName";

      Reference storageReference = _storage.ref().child(path);
      UploadTask uploadTask = storageReference.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error subiendo imagen: $e");
      return null;
    }
  }

  // Chat rooms methods
  Future<bool> createChatRoom(
    String chatRoomId,
    Map<String, dynamic> chatRoomInfoMap,
  ) async {
    final snapshot = await _firestore
        .collection(AppConstants.chatroomsCollection)
        .doc(chatRoomId)
        .get();

    if (snapshot.exists) {
      return true;
    } else {
      chatRoomInfoMap["isGroup"] = false;
      await _firestore
          .collection(AppConstants.chatroomsCollection)
          .doc(chatRoomId)
          .set(chatRoomInfoMap);
      return false;
    }
  }

  // Group methods
  Future<String?> createGroup(Map<String, dynamic> groupInfoMap) async {
    try {
      String groupId = 'grupo_${DateTime.now().millisecondsSinceEpoch}';

      if (groupInfoMap["imageUrl"] != null && groupInfoMap["imageUrl"] != "") {
        String? imageUrl = await uploadImage(File(groupInfoMap["imageUrl"]));
        groupInfoMap["imageUrl"] = imageUrl ?? "";
      }

      groupInfoMap["isGroup"] = true;
      await _firestore
          .collection(AppConstants.chatroomsCollection)
          .doc(groupId)
          .set(groupInfoMap);
      return groupId;
    } catch (e) {
      print("Error creando grupo: $e");
      return null;
    }
  }

  // Message methods
  Future<void> addMessage(
    String chatRoomId,
    String messageId,
    Map<String, dynamic> messageInfoMap,
  ) async {
    await _firestore
        .collection(AppConstants.chatroomsCollection)
        .doc(chatRoomId)
        .collection(AppConstants.chatsSubcollection)
        .doc(messageId)
        .set(messageInfoMap);
  }

  Future<void> updateLastMessage(
    String chatRoomId,
    Map<String, dynamic> lastMessageInfoMap,
  ) async {
    await _firestore
        .collection(AppConstants.chatroomsCollection)
        .doc(chatRoomId)
        .update(lastMessageInfoMap);
  }

  // Stream methods
  Stream<QuerySnapshot> getChatRoomMessages(String chatRoomId) {
    return _firestore
        .collection(AppConstants.chatroomsCollection)
        .doc(chatRoomId)
        .collection(AppConstants.chatsSubcollection)
        .orderBy("time", descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserChatRooms(String username) {
    return _firestore
        .collection(AppConstants.chatroomsCollection)
        .where("users", arrayContains: username)
        .where("isGroup", isEqualTo: false)
        .orderBy("lastMessageSendTs", descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserGroups(String username) {
    return _firestore
        .collection(AppConstants.chatroomsCollection)
        .where("users", arrayContains: username)
        .where("isGroup", isEqualTo: true)
        .orderBy("lastMessageSendTs", descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getAllGroups() {
    return _firestore
        .collection(AppConstants.chatroomsCollection)
        .where("isGroup", isEqualTo: true)
        .orderBy("lastMessageSendTs", descending: true)
        .snapshots();
  }






// --- Métodos para Comentarios (Subcolección de Posts) ---

  // Añadir un comentario (o respuesta) a un post
  Future<void> addComment(String postId, Map<String, dynamic> commentData) async {
    await _firestore
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .collection(AppConstants.commentsSubcollection) // <-- Subcolección
        .add(commentData);
  }
Future<void> updatePostCommentCount(String postId) async {
    final docRef = _firestore
        .collection(AppConstants.postsCollection)
        .doc(postId);

    // Usa FieldValue.increment(1) para sumar 1 al contador actual
    await docRef.update({
      "commentCount": FieldValue.increment(1)
    });
  }
  // Obtener el stream de comentarios de un post
  Stream<QuerySnapshot> getComments(String postId) {
    return _firestore
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .collection(AppConstants.commentsSubcollection)
        .orderBy("createdAt", descending: true) // <-- Del más reciente al más antiguo
        .snapshots();
  }

  // Dar/quitar like a un comentario específico
  Future<void> toggleLikeOnComment({
    required String postId,
    required String commentId,
    required String userId,
    required bool isLiked,
  }) async {
    final docRef = _firestore
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .collection(AppConstants.commentsSubcollection)
        .doc(commentId);

    if (isLiked) {
      // Si ya tiene like, quítalo
      await docRef.update({
        "likes": FieldValue.arrayRemove([userId])
      });
    } else {
      // Si no tiene like, añádelo
      await docRef.update({
        "likes": FieldValue.arrayUnion([userId])
      });
    }
  }



// --- Métodos para Posts ---
  // Crear una nueva publicación
  Future<void> createPost(Map<String, dynamic> postData) async {
    await _firestore
        .collection(AppConstants.postsCollection)
        .add(postData);
  }

  // Obtener el stream de todas las publicaciones (el feed)
  Stream<QuerySnapshot> getPosts() {
    return _firestore
        .collection(AppConstants.postsCollection)
        .orderBy("createdAt", descending: true) // Las más nuevas primero
        .snapshots();
  }

  // Dar o quitar like (la lógica de 'toggle')
  Future<void> toggleLike(String postId, String userId, bool isLiked) async {
    final docRef = _firestore
        .collection(AppConstants.postsCollection)
        .doc(postId);

    if (isLiked) {
      // Si ya tiene like, quítalo (arrayRemove)
      await docRef.update({
        "likes": FieldValue.arrayRemove([userId])
      });
    } else {
      // Si no tiene like, añádelo (arrayUnion)
      await docRef.update({
        "likes": FieldValue.arrayUnion([userId])
      });
    }
  }

}