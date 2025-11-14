// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter_application_3/core/constants/app_constants.dart';
// Has importado 'app_constants.dart' dos veces, eliminamos una.

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==========================
  // 🚀 USER METHODS
  // ==========================

  Future<void> addUser(String id, Map<String, dynamic> userInfoMap) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(id)
        .set(userInfoMap, SetOptions(merge: true));
  } // <-- ¡EL CORCHETE DE CIERRE VA AQUÍ!

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

  /// 🔧 Método agregado: Actualizar datos del usuario
  Future<void> updateUserData(
    String userId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(updatedData);
    } catch (e) {
      print("Error actualizando usuario: $e");
      throw e;
    }
  }

  /// 🔧 Método agregado: Actualizar imagen de perfil
  Future<String?> updateProfileImage(String userId, File imageFile) async {
    try {
      String? imageUrl = await uploadImage(
        imageFile,
        customPath: "profile_images/$userId",
      );

      if (imageUrl != null) {
        await updateUserData(userId, {'Image': imageUrl});
      }

      return imageUrl;
    } catch (e) {
      print("Error actualizando imagen: $e");
      return null;
    }
  }

  /// 🔧 Método agregado: Obtener usuario por ID
  Future<DocumentSnapshot> getUserById(String userId) async {
    return await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
  }

  // ==========================
  // 📸 IMAGE UPLOAD
  // ==========================

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

  // ==========================
  // 💬 CHATROOMS & GROUPS
  // ==========================

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

  Future<String?> createGroup(Map<String, dynamic> groupInfoMap) async {
    try {
      String groupId = 'grupo_${DateTime.now().millisecondsSinceEpoch}';
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

  Future<void> resetUnreadCount(String chatRoomId, String myUsername) async {
    // El campo se llamará 'unreadCount_MIUSERNAME'
    String myUnreadField = "unreadCount_$myUsername";
    
    await _firestore
        .collection(AppConstants.chatroomsCollection)
        .doc(chatRoomId)
        .set({
          myUnreadField: 0, // Resetea el contador
        }, SetOptions(merge: true)); // Usa merge para no borrar otros campos
  }



  
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

  // ==========================
  // 💭 COMMENTS (subcollection)
  // ==========================

  Future<void> addComment(
    String postId,
    Map<String, dynamic> commentData,
  ) async {
    await _firestore
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .collection(AppConstants.commentsSubcollection)
        .add(commentData);
  }

  Future<void> updatePostCommentCount(String postId) async {
    final docRef =
        _firestore.collection(AppConstants.postsCollection).doc(postId);
    await docRef.update({"commentCount": FieldValue.increment(1)});
  }

  Stream<QuerySnapshot> getComments(String postId) {
    return _firestore
        .collection(AppConstants.postsCollection)
        .doc(postId)
        .collection(AppConstants.commentsSubcollection)
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

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
      await docRef.update({
        "likes": FieldValue.arrayRemove([userId]),
      });
    } else {
      await docRef.update({
        "likes": FieldValue.arrayUnion([userId]),
      });
    }
  }

  // ==========================
  // 📰 POSTS
  // ==========================

  Future<void> createPost(Map<String, dynamic> postData) async {
    await _firestore.collection(AppConstants.postsCollection).add(postData);
  }

  Stream<QuerySnapshot> getPosts() {
    return _firestore
        .collection(AppConstants.postsCollection)
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getPostsForUser(String userId) {
    return _firestore
        .collection(AppConstants.postsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> toggleLike(String postId, String userId, bool isLiked) async {
    final docRef =
        _firestore.collection(AppConstants.postsCollection).doc(postId);

    if (isLiked) {
      await docRef.update({
        "likes": FieldValue.arrayRemove([userId]),
      });
    } else {
      await docRef.update({
        "likes": FieldValue.arrayUnion([userId]),
      });
    }
  }
  // ==============datos=======================//

  Future<void> addDatosCollection(
    String datosId,
    Map<String, dynamic> datosData,
  ) async {
    await _firestore
        .collection(AppConstants.datosCollection)
        .doc(datosId)
        .set(datosData);
  }

  Future<DocumentSnapshot> getDatosCollection(String userId) async {
    return await _firestore
        .collection(AppConstants.datosCollection)
        .doc(userId)
        .get();
  }

  Future<void> updateDatosPersonales(
    String userId,
    Map<String, dynamic> updatedData,
  ) async {
    await _firestore
        .collection(AppConstants.datosCollection)
        .doc(userId)
        .update(updatedData);
  }

  Stream<DocumentSnapshot> listenToDatosPersonales(String userId) {
    return _firestore
        .collection(AppConstants.datosCollection)
        .doc(userId)
        .snapshots();
  }

  Future<void> deleteDatosPersonales(String userId) async {
    await _firestore
        .collection(AppConstants.datosCollection)
        .doc(userId)
        .delete();
  }

  Stream<DocumentSnapshot> getGroupDetailsStream(String groupId) {
    return _firestore
        .collection(AppConstants.chatroomsCollection)
        .doc(groupId)
        .snapshots();
  }

  /// Método genérico para actualizar un grupo (usado para foto o nombre)
  Future<void> updateGroupData(
      String groupId, Map<String, dynamic> data) async {
    await _firestore
        .collection(AppConstants.chatroomsCollection)
        .doc(groupId)
        .update(data);
  }

  /// Método para sacar a un usuario de un grupo (para "salir" o "expulsar")
  Future<void> removeUserFromGroup(String groupId, String username) async {
    await _firestore
        .collection(AppConstants.chatroomsCollection)
        .doc(groupId)
        .update({
      'users': FieldValue.arrayRemove([username])
    });
  }

  /// Actualiza el estado de presencia del usuario en Firestore
  Future<void> updateUserPresence(String userId, bool isOnline) async {
    // Usamos .set con merge:true para crear los campos si no existen
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(), // Siempre actualiza la última vez visto
    }, SetOptions(merge: true));
  }

  /// Obtiene un stream de un solo usuario (para ver su estado en vivo)
  Stream<DocumentSnapshot> getUserStream(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots();
  }

  // ==========================
  // 📚 STORIES (Añadidos aquí)
  // ==========================

  /// Sube la imagen de una historia a Storage
  Future<String?> uploadStoryImage(File imageFile, String userId) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      String path = "stories/$userId/$fileName"; // Carpeta de historias por usuario

      Reference storageReference = _storage.ref().child(path);
      UploadTask uploadTask = storageReference.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error subiendo imagen de historia: $e");
      return null;
    }
  }

  /// Crea un nuevo documento de historia
  Future<void> createStory(String userId, Map<String, dynamic> storyData) async {
    // Creamos la historia en una subcolección del usuario
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.storiesCollection)
        .add(storyData);
  }

  /// Obtiene un stream de historias activas (que no hayan expirado)
  Stream<QuerySnapshot> getActiveStoriesStream(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.storiesCollection)
        .where('expiresAt', isGreaterThan: Timestamp.now()) // Filtra expiradas
        .orderBy('expiresAt', descending: true) // Muestra la más nueva primero
        .snapshots();
  }
} // <-- ¡EL CORCHETE DE CIERRE DE LA CLASE DEBE ESTAR AQUÍ!