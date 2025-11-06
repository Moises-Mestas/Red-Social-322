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
}