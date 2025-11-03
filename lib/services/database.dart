import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_3/services/shared_pref.dart';
class DatabaseMethods {
  
  Future addUser(Map<String, dynamic> userInfoMap, String id)async{
    return await FirebaseFirestore.instance.collection("users").doc(id).set(userInfoMap);
  }

Future addMessage(String chatRoomId, String messageId, Map<String, dynamic> messageInfoMap) async {
  return await FirebaseFirestore.instance
      .collection("chatrooms")
      .doc(chatRoomId)
      .collection("chats")
      .doc(messageId)
      .set(messageInfoMap);
}

updateLastMessageSend(
  String chatRoomId, 
  Map<String, dynamic> lastMessageInfoMap) async {
  return FirebaseFirestore.instance
      .collection("chatrooms")
      .doc(chatRoomId)
      .update(lastMessageInfoMap);
}

Future<QuerySnapshot> Search(String username) async {
  return await FirebaseFirestore.instance
      .collection("users")
      .where("SearchKey", isEqualTo: username.substring(0, 1).toUpperCase())
      .get();
}

createChatRoom(String chatRoomId, Map<String, dynamic> chatRoomInfoMap) async {
  final snapshot = await FirebaseFirestore.instance
      .collection("chatrooms") // <--- en minúscula
      .doc(chatRoomId)
      .get();
  if (snapshot.exists) {
    return true;
  } else {
    return FirebaseFirestore.instance
        .collection("chatrooms") // <--- en minúscula
        .doc(chatRoomId)
        .set(chatRoomInfoMap);
  }
}

  Future<Stream<QuerySnapshot>> getChatRoomMessages(chatRoomId)async{
    return await FirebaseFirestore.instance.collection("chatrooms").doc(chatRoomId).collection("chats").orderBy("time", descending: true)
    .snapshots(); 
  }

  Future<QuerySnapshot> getUserInfo(String username)async{
    return await FirebaseFirestore.instance.collection("users").where("username", isEqualTo: username).get();
  }

Future<Stream<QuerySnapshot>> getChatRooms() async {
  String? myUsername = await SharedpreferencesHelper().getUserName();

  // Verifica que 'users' contenga al usuario actual (myUsername)
  return FirebaseFirestore.instance
    .collection("chatrooms")
    .where("users", arrayContains: myUsername!)  // Verifica si el usuario está en la conversación
    .orderBy("lastMessageSendTs", descending: true)  // Ordena por el último mensaje
    .snapshots();
}

}