import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_3/core/constants/app_constants.dart';
import 'package:flutter_application_3/services/database_service.dart';
import 'package:flutter_application_3/services/shared_pref_service.dart';

class GroupController {
  final DatabaseService _databaseService = DatabaseService();
  final SharedPrefService _sharedPrefService = SharedPrefService();

  Future<String?> createGroup({
    required String groupName,
    required File? imageFile,
  }) async {
    final myUsername = await _sharedPrefService.getUserName();
    if (myUsername == null) return null;

    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _databaseService.uploadImage(imageFile);
    }

    final groupInfoMap = {
      "name": groupName,
      "imageUrl": imageUrl ?? "",
      "users": [myUsername],
      "lastMessage": "",
      "lastMessageSendTs": DateTime.now(),
      "isGroup": true,
    };

    return await _databaseService.createGroup(groupInfoMap);
  }

  Future<void> joinGroup(String groupId) async {
    final myUsername = await _sharedPrefService.getUserName();
    if (myUsername == null) return;

    final groupDoc = await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(groupId)
        .get();

    if (groupDoc.exists) {
      List<dynamic> users = List.from(groupDoc['users']);
      if (!users.contains(myUsername)) {
        users.add(myUsername);
        await FirebaseFirestore.instance
            .collection("chatrooms")
            .doc(groupId)
            .update({'users': users});
      }
    }
  }

  Future<Stream<QuerySnapshot>> getUserGroups() async {
    final myUsername = await _sharedPrefService.getUserName();
    if (myUsername == null) {
      return const Stream.empty();
    }
    return _databaseService.getUserGroups(myUsername);
  }

  Stream<QuerySnapshot> getAllGroups() {
    return _databaseService.getAllGroups();
  }

  Future<bool> isUserInGroup(String groupId) async {
    final myUsername = await _sharedPrefService.getUserName();
    if (myUsername == null) return false;

    final groupDoc = await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(groupId)
        .get();

    if (groupDoc.exists) {
      List<dynamic> users = groupDoc['users'];
      return users.contains(myUsername);
    }
    return false;
  }


  /// Obtiene el stream de detalles del grupo
  Stream<DocumentSnapshot> getGroupDetailsStream(String groupId) {
    return _databaseService.getGroupDetailsStream(groupId);
  }

  /// Lógica para salir o expulsar a un usuario
  Future<void> removeUserFromGroup(String groupId, String username) async {
    await _databaseService.removeUserFromGroup(groupId, username);
  }

  /// Lógica para actualizar la foto del grupo
  Future<void> updateGroupPhoto(String groupId, File newImageFile) async {
    // 1. Subir la nueva imagen
    String? newImageUrl = await _databaseService.uploadImage(
      newImageFile,
      customPath: AppConstants.groupImagesPath, // Usará un nombre único
    );

    if (newImageUrl != null) {
      // 2. Actualizar el documento del grupo
      await _databaseService.updateGroupData(groupId, {
        'imageUrl': newImageUrl,
      });
    } else {
      throw Exception("No se pudo subir la nueva imagen.");
    }
  }




  // --- AÑADE ESTE NUEVO MÉTODO ---
  /// Lógica para actualizar el nombre del grupo
  Future<void> updateGroupName(String groupId, String newName) async {
    if (newName.isEmpty) {
      throw Exception("El nombre no puede estar vacío");
    }
    // Llama al servicio genérico que ya teníamos
    await _databaseService.updateGroupData(groupId, {
      'name': newName,
    });
  }
}
