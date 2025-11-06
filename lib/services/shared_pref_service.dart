import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_3/core/constants/app_constants.dart';

class SharedPrefService {
  Future<bool> saveUserData({
    required String displayName,
    required String email,
    required String userId,
    required String username,
    required String imageUrl,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString(AppConstants.userNameKey, displayName);
    await prefs.setString(AppConstants.userEmailKey, email);
    await prefs.setString(AppConstants.userIdKey, userId);
    await prefs.setString(AppConstants.userUserNameKey, username);
    await prefs.setString(AppConstants.userImageKey, imageUrl);

    return true;
  }

  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userIdKey);
  }

  Future<String?> getUserDisplayName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userNameKey);
  }

  Future<String?> getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userUserNameKey);
  }

  Future<String?> getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userEmailKey);
  }

  Future<String?> getUserImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userImageKey);
  }

  Future<Map<String, String?>> getAllUserData() async {
    return {
      'displayName': await getUserDisplayName(),
      'email': await getUserEmail(),
      'userId': await getUserId(),
      'username': await getUserName(),
      'imageUrl': await getUserImage(),
    };
  }

  Future<void> clearUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userNameKey);
    await prefs.remove(AppConstants.userEmailKey);
    await prefs.remove(AppConstants.userImageKey);
    await prefs.remove(AppConstants.userUserNameKey);
  }
}
