// lib/controllers/post_controller.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_3/core/constants/app_constants.dart';
import 'package:flutter_application_3/services/database_service.dart';
import 'package:flutter_application_3/services/shared_pref_service.dart';

class PostController {
  final DatabaseService _databaseService = DatabaseService();
  final SharedPrefService _sharedPrefService = SharedPrefService();

  // Método para obtener el stream de posts
  Stream<QuerySnapshot> getPostsStream() {
    return _databaseService.getPosts();
  }

  Stream<QuerySnapshot> getPostsForUserStream(String userId) {
    return _databaseService.getPostsForUser(userId);
  }


  Future<void> createPost(String text, File? imageFile) async {
    // 1. Obtener los datos del usuario actual
    final userData = await _sharedPrefService.getAllUserData();
     final String? userId = userData['userId'];
    
    // Aquí obtenemos ambas variables correctamente
     final String? displayName = userData['displayName']; // ej: "Juan Perez"
    final String? userName = userData['username']; // ej: "JUANPEREZ"

    final String? userImageUrl = userData['imageUrl'];

     if (userId == null || userName == null) return; 

    // ... (Tu lógica de subir imagen que ya corregimos está perfecta) ...
    String? postImageUrl;
     if (imageFile != null) {
       String fileName = DateTime.now().millisecondsSinceEpoch.toString();
       String uniquePath = "${AppConstants.postImagesPath}/$fileName";
      postImageUrl = await _databaseService.uploadImage(
      imageFile,
      customPath: uniquePath, 
   );
  }

  // 3. Crear el mapa de datos del post
     Map<String, dynamic> postData = {
      "text": text,
       "imageUrl": postImageUrl,
      "createdAt": FieldValue.serverTimestamp(),
      "userId": userId,
      
      // --- ¡ASEGÚRATE DE QUE ESTÉ ASÍ! ---
      "userName": userName,            // <-- El campo "userName" recibe el apodo
      "userDisplayName": displayName ?? "Usuario", // <-- El campo "userDisplayName" recibe el nombre
      // ---------------------------------

    "userImageUrl": userImageUrl ?? "",
    "likes": [], 
     "commentCount": 0,
 };

  await _databaseService.createPost(postData);
   }
  // Método para dar/quitar like
  Future<void> toggleLike(String postId, List<String> currentLikes) async {
    final String? myUserId = await _sharedPrefService.getUserId();
    if (myUserId == null) return;

    // Comprobar si el usuario ya dio like
    bool isLiked = currentLikes.contains(myUserId);

    // Llamar al servicio
    await _databaseService.toggleLike(postId, myUserId, isLiked);
  }


// --- Métodos de Comentarios ---

  Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _databaseService.getComments(postId);
  }

  Future<void> addComment({
    required String postId,
    required String text,
    String? parentCommentId, // Opcional, para respuestas
  }) async {
    // 1. Obtener datos del usuario
    final userData = await _sharedPrefService.getAllUserData();
    final String? userId = userData['userId'];
    final String? userName = userData['displayName'];
    final String? userImageUrl = userData['imageUrl'];

    if (userId == null) return; // No se puede comentar

    // 2. Crear el mapa de datos del comentario
    Map<String, dynamic> commentData = {
      "text": text,
      "createdAt": FieldValue.serverTimestamp(),
      "userId": userId,
      "userName": userName ?? "Usuario",
      "userImageUrl": userImageUrl ?? "",
      "likes": [],
      "parentCommentId": parentCommentId, // Será null (comentario) o un ID (respuesta)
    };

    // 3. Llamar al servicio
    await _databaseService.addComment(postId, commentData);
    await _databaseService.updatePostCommentCount(postId);
  }

  Future<void> toggleCommentLike({
    required String postId,
    required String commentId,
    required List<String> currentLikes,
  }) async {
    final String? myUserId = await _sharedPrefService.getUserId();
    if (myUserId == null) return;

    bool isLiked = currentLikes.contains(myUserId);
    await _databaseService.toggleLikeOnComment(
      postId: postId,
      commentId: commentId,
      userId: myUserId,
      isLiked: isLiked,
    );
  }


}