import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

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

  // Agrega este método para guardar solo la imagen
  Future<bool> saveUserImage(String imageUrl) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
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

  Future<void> saveCiudad(String ciudad) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('ciudad', ciudad);
  }

  Future<void> saveDescripcion(String descripcion) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('descripcion', descripcion);
  }

  Future<void> saveFechaNacimiento(String fecha) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('fecha_nacimiento', fecha);
  }

  Future<void> saveGenero(String genero) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('genero', genero);
  }

  Future<void> saveTelefono(String telefono) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('telefono', telefono);
  }

  Future<void> saveEstudios(String estudios) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('estudios', estudios);
  }

  Future<void> saveOcupacion(String ocupacion) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('ocupacion', ocupacion);
  }

  Future<void> saveEstadoRelacion(String estado) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('estado_relacion', estado);
  }

  // Métodos para obtener datos del perfil
  Future<String?> getCiudad() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('ciudad');
  }

  Future<String?> getDescripcion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('descripcion');
  }

  Future<String?> getFechaNacimiento() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('fecha_nacimiento');
  }

  Future<String?> getGenero() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('genero');
  }

  Future<String?> getTelefono() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('telefono');
  }

  Future<String?> getEstudios() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('estudios');
  }

  Future<String?> getOcupacion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('ocupacion');
  }

  Future<String?> getEstadoRelacion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('estado_relacion');
  }

  // Limpiar todos los datos del perfil
  Future<void> clearProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('ciudad');
    await prefs.remove('descripcion');
    await prefs.remove('fecha_nacimiento');
    await prefs.remove('genero');
    await prefs.remove('telefono');
    await prefs.remove('estudios');
    await prefs.remove('ocupacion');
    await prefs.remove('estado_relacion');
  }

  // ======datos=================//
}
