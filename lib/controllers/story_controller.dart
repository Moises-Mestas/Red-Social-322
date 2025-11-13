// lib/controllers/story_controller.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3/services/database_service.dart';
import 'package:flutter_application_3/services/shared_pref_service.dart';

class StoryController {
  final DatabaseService _databaseService = DatabaseService();
  final SharedPrefService _sharedPrefService = SharedPrefService();

  /// Sube una nueva historia (imagen o texto)
  Future<void> createStory(String text, File? imageFile) async {
    try {
      final myUserId = await _sharedPrefService.getUserId();
      final myUsername = await _sharedPrefService.getUserName();
      final myPicture = await _sharedPrefService.getUserImage();

      if (myUserId == null || myUsername == null) {
        throw Exception("Usuario no autenticado");
      }
      
      String? mediaUrl;
      String storyType = "text"; // Tipo por defecto

      // 1. Si hay imagen, subirla
      if (imageFile != null) {
        mediaUrl = await _databaseService.uploadStoryImage(imageFile, myUserId);
        storyType = "image";
      }

      // 2. Definir tiempos
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      // 3. Crear el mapa de datos
      final Map<String, dynamic> storyData = {
        'userId': myUserId,
        'username': myUsername,
        'userImageUrl': myPicture ?? '',
        'mediaUrl': mediaUrl, // Será null si es solo texto
        'text': text,
        'type': storyType,
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'viewedBy': [], // Lista de IDs de quienes la vieron (para el futuro)
      };

      // 4. Guardar en la base de datos
      await _databaseService.createStory(myUserId, storyData);

    } catch (e) {
      print("Error creando historia: $e");
      rethrow;
    }
  }

  /// Obtiene el stream de historias activas para un usuario
  Stream<QuerySnapshot> getActiveStoriesStream(String userId) {
    return _databaseService.getActiveStoriesStream(userId);
  }
}