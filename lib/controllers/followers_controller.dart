// lib/controllers/followers_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_3/services/database_service.dart';
import 'package:flutter_application_3/services/shared_pref_service.dart';
import 'package:flutter_application_3/core/constants/app_constants.dart';

class FollowersController {
  final DatabaseService _databaseService = DatabaseService();
  final SharedPrefService _sharedPrefService = SharedPrefService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> followUser(String targetUserId, String targetUsername) async {
    try {
      final currentUserId = await _sharedPrefService.getUserId();
      if (currentUserId == null) throw Exception("Usuario no autenticado");

      // --- INICIO DE LA MODIFICACIÓN ---
      // 1. Obtenemos los datos del USUARIO ACTUAL (quien está siguiendo)
      final currentUsername = await _sharedPrefService.getUserName() ?? 'usuario';
      final currentUserImage = await _sharedPrefService.getUserImage() ?? '';
      // --- FIN DE LA MODIFICACIÓN ---


      // 2. Añadir a la lista de "Siguiendo" (Following) del usuario actual
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .collection(AppConstants.followingCollection)
          .doc(targetUserId)
          .set({
            'userId': targetUserId,
            'username': targetUsername,
            'followedAt': DateTime.now(),
            // Opcional: También podrías guardar la foto del usuario al que sigues
            // 'userImageUrl': targetUserImage (necesitarías obtenerla primero)
          });

      // 3. Añadir a la lista de "Seguidores" (Followers) del usuario objetivo
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(targetUserId)
          .collection(AppConstants.followersCollection)
          .doc(currentUserId)
          .set({
            'userId': currentUserId,
            'username': currentUsername, // <-- Usamos la variable
            'userImageUrl': currentUserImage, // <-- ¡AQUÍ GUARDAMOS LA FOTO!
            'followedAt': DateTime.now(),
          });

      // 4. Crear notificación (optimizada)
      await _createFollowNotification(
        currentUserId,
        targetUserId,
        currentUsername, // <-- Pasamos el nombre que ya obtuvimos
        currentUserImage, // <-- Pasamos la imagen que ya obtuvimos
      );
    } catch (e) {
      throw Exception("Error al seguir usuario: $e");
    }
  }

  Future<void> unfollowUser(String targetUserId) async {
    try {
      final currentUserId = await _sharedPrefService.getUserId();
      if (currentUserId == null) throw Exception("Usuario no autenticado");

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .collection(AppConstants.followingCollection)
          .doc(targetUserId)
          .delete();

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(targetUserId)
          .collection(AppConstants.followersCollection)
          .doc(currentUserId)
          .delete();
    } catch (e) {
      throw Exception("Error al dejar de seguir: $e");
    }
  }

  Future<bool> isFollowing(String targetUserId) async {
    try {
      final currentUserId = await _sharedPrefService.getUserId();
      if (currentUserId == null) return false;

      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .collection(AppConstants.followingCollection)
          .doc(targetUserId)
          .get();

      return snapshot.exists;
    } catch (e) {
      return false;
    }
  }

  Future<int> getFollowersCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.followersCollection)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getFollowingCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.followingCollection)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Stream<QuerySnapshot> getFollowersStream(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.followersCollection)
        .orderBy('followedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getFollowingStream(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.followingCollection)
        .orderBy('followedAt', descending: true)
        .snapshots();
  }

  // --- MODIFICADO: Acepta los parámetros que ya obtuvimos ---
  Future<void> _createFollowNotification(
    String currentUserId,
    String targetUserId,
    String currentUsername, // <-- Parámetro
    String currentUserImage, // <-- Parámetro
  ) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(targetUserId)
          .collection(AppConstants.notificationsCollection)
          .add({
            'type': 'follow',
            'fromUserId': currentUserId,
            'fromUsername': currentUsername,
            'fromUserImage': currentUserImage,
            'message': '$currentUsername empezó a seguirte',
            'isRead': false,
            'createdAt': DateTime.now(),
          });
    } catch (e) {
      print('Error creando notificación: $e');
    }
  }
}