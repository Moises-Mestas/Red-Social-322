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

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUserId)
          .collection(AppConstants.followingCollection)
          .doc(targetUserId)
          .set({
            'userId': targetUserId,
            'username': targetUsername,
            'followedAt': DateTime.now(),
          });

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(targetUserId)
          .collection(AppConstants.followersCollection)
          .doc(currentUserId)
          .set({
            'userId': currentUserId,
            'username': await _sharedPrefService.getUserName() ?? 'usuario',
            'followedAt': DateTime.now(),
          });

      // 3. Crear notificación
      await _createFollowNotification(
        currentUserId,
        targetUserId,
        targetUsername,
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

  Future<void> _createFollowNotification(
    String currentUserId,
    String targetUserId,
    String targetUsername,
  ) async {
    try {
      final currentUsername = await _sharedPrefService.getUserName();
      final currentUserImage = await _sharedPrefService.getUserImage();

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
