import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
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
}
