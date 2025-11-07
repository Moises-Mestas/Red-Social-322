
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String text;
  final String? imageUrl;
  final Timestamp createdAt;
  final String userId;
  final String userName;
  final String userImageUrl;
  final List<String> likes; // Lista de UserIDs que han dado like
  final int commentCount; // <-- AÑADE ESTA LÍNEA

  PostModel({
    required this.id,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    required this.userId,
    required this.userName,
    required this.userImageUrl,
    required this.likes,
    required this.commentCount, // <-- AÑADE ESTA LÍNEA
  });

  // Factory para crear un PostModel desde un DocumentSnapshot de Firestore
  factory PostModel.fromMap(DocumentSnapshot doc) {
    Map<String, dynamic> map = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userImageUrl: map['userImageUrl'] ?? '',
      likes: List<String>.from(map['likes'] ?? []),
      commentCount: map['commentCount'] ?? 0, // <-- AÑADE ESTA LÍNEA
    );
  }

  // Método para convertir el modelo a un Map (para subir a Firestore)
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'userId': userId,
      'userName': userName,
      'userImageUrl': userImageUrl,
      'likes': likes,
    };
  }
}