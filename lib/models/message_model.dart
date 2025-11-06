import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String message;
  final String sendBy;
  final DateTime time;
  final String data; // "Message", "Image", "Audio"
  final String? imgUrl;

  MessageModel({
    required this.id,
    required this.message,
    required this.sendBy,
    required this.time,
    required this.data,
    this.imgUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'sendBy': sendBy,
      'time': time,
      'Data': data,
      'imgUrl': imgUrl,
    };
  }

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    return MessageModel(
      id: id,
      message: map['message'] ?? '',
      sendBy: map['sendBy'] ?? '',
      time: (map['time'] as Timestamp).toDate(),
      data: map['Data'] ?? 'Message',
      imgUrl: map['imgUrl'],
    );
  }
}
