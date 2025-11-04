import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Importar Firebase Storage
import 'dart:io';
import 'package:flutter_application_3/services/shared_pref.dart';

class DatabaseMethods {
  
  // Agregar usuario
  Future addUser(Map<String, dynamic> userInfoMap, String id) async {
    return await FirebaseFirestore.instance.collection("users").doc(id).set(userInfoMap);
  }

  // Subir la imagen del grupo a Firebase Storage y obtener la URL
  Future<String?> uploadImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageReference = FirebaseStorage.instance.ref().child("group_images/$fileName");
      UploadTask uploadTask = storageReference.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error subiendo imagen: $e");
      return null;
    }
  }

  // Agregar mensaje a un chat o grupo
  Future addMessage(String chatRoomId, String messageId, Map<String, dynamic> messageInfoMap) async {
    return await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .doc(messageId)
        .set(messageInfoMap);
  }

  // Actualizar el último mensaje enviado en un chat o grupo
  updateLastMessageSend(String chatRoomId, Map<String, dynamic> lastMessageInfoMap) async {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .update(lastMessageInfoMap);
  }

  // Búsqueda de usuario
  Future<QuerySnapshot> Search(String username) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .where("SearchKey", isEqualTo: username.substring(0, 1).toUpperCase())
        .get();
  }

  // Crear un chat (verifica si ya existe)
  createChatRoom(String chatRoomId, Map<String, dynamic> chatRoomInfoMap) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("chatrooms") // <--- en minúscula
        .doc(chatRoomId)
        .get();
    if (snapshot.exists) {
      return true;
    } else {
      chatRoomInfoMap["isGroup"] = false;
      return FirebaseFirestore.instance
          .collection("chatrooms") // <--- en minúscula
          .doc(chatRoomId)
          .set(chatRoomInfoMap);
    }
  }

  // Crear un grupo
  Future createGroup(Map<String, dynamic> groupInfoMap) async {
    try {
      String groupId = 'grupo_${DateTime.now().millisecondsSinceEpoch}';

      if (groupInfoMap["imageUrl"] != "") {
        String? imageUrl = await uploadImage(File(groupInfoMap["imageUrl"])); // Subir imagen
        groupInfoMap["imageUrl"] = imageUrl ?? ""; // Guardar la URL de la imagen
      }

      groupInfoMap["isGroup"] = true;
      await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(groupId)
          .set(groupInfoMap);
      return groupId;
    } catch (e) {
      print("Error creando grupo: $e");
      return null;
    }
  }

  // Recuperar mensajes de un chat
  Future<Stream<QuerySnapshot>> getChatRoomMessages(chatRoomId) async {
    return await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .orderBy("time", descending: true)
        .snapshots();
  }

  // Obtener la información de un usuario por su nombre de usuario
  Future<QuerySnapshot> getUserInfo(String username) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .where("username", isEqualTo: username)
        .get();
  }

  // Obtener los chats de un usuario
  Future<Stream<QuerySnapshot>> getChatRooms() async {
    String? myUsername = await SharedpreferencesHelper().getUserName();
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .where("users", arrayContains: myUsername!) // Verifica si el usuario está en la conversación
        .where("isGroup", isEqualTo: false) // Filtra solo chats privados, no grupos
        .orderBy("lastMessageSendTs", descending: true) // Ordena por el último mensaje
        .snapshots();
  }

  // Obtener todos los grupos en los que está involucrado el usuario
  Future<Stream<QuerySnapshot>> getGroups() async {
    String? myUsername = await SharedpreferencesHelper().getUserName();
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .where("users", arrayContains: myUsername!) // Asegúrate que el usuario esté en el grupo
        .where("isGroup", isEqualTo: true) // Filtra solo grupos
        .orderBy("lastMessageSendTs", descending: true) // Ordenar por el último mensaje
        .snapshots();
  }

  // Crear un nuevo grupo y agregar el usuario a la lista de miembros
  Future createGroupWithMembers(Map<String, dynamic> groupInfoMap) async {
    try {
      String groupId = 'grupo_${DateTime.now().millisecondsSinceEpoch}';
      groupInfoMap["isGroup"] = true;
      groupInfoMap["users"] = [await SharedpreferencesHelper().getUserName()]; // Añadir el usuario actual

      await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(groupId)
          .set(groupInfoMap);
      return groupId;
    } catch (e) {
      print("Error creando grupo con miembros: $e");
      return null;
    }
  }
}
