// profile_controller.dart
import 'dart:io';

import 'package:flutter_application_3/services/database_service.dart';
import 'package:flutter_application_3/services/shared_pref_service.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController {
  final DatabaseService _databaseService = DatabaseService();
  final SharedPrefService _sharedPrefService = SharedPrefService();

  // Actualizar datos del usuario
  Future<void> updateUserProfile({
    required String userId,
    required String name,
    required String username,
    required String email,
  }) async {
    try {
      await _databaseService.updateUserData(userId, {
        'Name': name,
        'username': username,
        'Email': email,
        'SearchKey': username.substring(0, 1).toUpperCase(),
      });

      await _sharedPrefService.saveUserData(
        userId: userId,
        displayName: name,
        email: email,
        username: username,
        imageUrl: await _sharedPrefService.getUserImage() ?? '',
      );
    } catch (e) {
      throw e;
    }
  }

  Future<String?> updateProfileImage(String userId, XFile imageFile) async {
    try {
      final imageUrl = await _databaseService.updateProfileImage(
        userId,
        File(imageFile.path),
      );

      if (imageUrl != null) {
        await _sharedPrefService.saveUserImage(imageUrl);
      }

      return imageUrl;
    } catch (e) {
      throw e;
    }
  }

  Future<Map<String, dynamic>> getUpdatedUserData(String userId) async {
    try {
      final userDoc = await _databaseService.getUserById(userId);
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;

        await _sharedPrefService.saveUserData(
          userId: userId,
          displayName: userData['Name'] ?? '',
          email: userData['Email'] ?? '',
          username: userData['username'] ?? '',
          imageUrl: userData['Image'] ?? '',
        );

        return userData;
      }
      return {};
    } catch (e) {
      throw e;
    }
  }
}
