// lib/models/comment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String text;
  final Timestamp createdAt;
  final String userId;
  final String userName;
  final String userImageUrl;
  final List<String> likes; // Likes para este comentario
  final String? parentCommentId; // null si es un comentario, ID si es una respuesta

  CommentModel({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.userId,
    required this.userName,
    required this.userImageUrl,
    required this.likes,
    this.parentCommentId,
  });

  factory CommentModel.fromMap(DocumentSnapshot doc) {
    Map<String, dynamic> map = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      text: map['text'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userImageUrl: map['userImageUrl'] ?? '',
      likes: List<String>.from(map['likes'] ?? []),
      parentCommentId: map['parentCommentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'createdAt': createdAt,
      'userId': userId,
      'userName': userName,
      'userImageUrl': userImageUrl,
      'likes': likes,
      'parentCommentId': parentCommentId,
    };
  }
}