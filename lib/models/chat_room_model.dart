import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final List<String> users;
  final String lastMessage;
  final String lastMessageSendBy;
  final DateTime lastMessageSendTs;
  final bool isGroup;
  final String? name;
  final String? imageUrl;

  ChatRoomModel({
    required this.id,
    required this.users,
    required this.lastMessage,
    required this.lastMessageSendBy,
    required this.lastMessageSendTs,
    required this.isGroup,
    this.name,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'users': users,
      'lastMessage': lastMessage,
      'lastMessageSendBy': lastMessageSendBy,
      'lastMessageSendTs': lastMessageSendTs,
      'isGroup': isGroup,
      'name': name,
      'imageUrl': imageUrl,
    };
  }

  factory ChatRoomModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatRoomModel(
      id: id,
      users: List<String>.from(map['users'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageSendBy: map['lastMessageSendBy'] ?? '',
      lastMessageSendTs: (map['lastMessageSendTs'] as Timestamp).toDate(),
      isGroup: map['isGroup'] ?? false,
      name: map['name'],
      imageUrl: map['imageUrl'],
    );
  }
}
