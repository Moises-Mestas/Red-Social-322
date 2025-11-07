// profile_data_controller.dart
import 'dart:io';
import '../services/database_service.dart';
import '../services/shared_pref_service.dart';
import '../core/constants/app_constants.dart';

class ProfileDataController {
  final DatabaseService _databaseService = DatabaseService();
  final SharedPrefService _sharedPrefService = SharedPrefService();

  // CREATE - Guardar todos los datos personales
  Future<void> saveAllProfileData({
    required String ciudad,
    required String descripcion,
    required String fechaNacimiento,
    required String genero,
    required String telefono,
    required String estudios,
    required String ocupacion,
    required String estadoRelacion,
  }) async {
    try {
      // Obtener el userId actual
      final userId = await _sharedPrefService.getUserId();
      if (userId == null) throw Exception("Usuario no autenticado");

      // Preparar los datos con el userId incluido
      Map<String, dynamic> profileData = {
        AppConstants.ciudad: ciudad,
        AppConstants.descripcion: descripcion,
        AppConstants.fecha_nacimiento: fechaNacimiento,
        AppConstants.genero: genero,
        AppConstants.telefono: telefono,
        AppConstants.estudios: estudios,
        AppConstants.ocupacion: ocupacion,
        AppConstants.estado_relacion: estadoRelacion,
        'userId': userId, // ← IMPORTANTE: Relacionar con el usuario
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      // Guardar en Firebase
      await _databaseService.addDatosCollection(userId, profileData);

      // También guardar en SharedPreferences si quieres acceso rápido
      await _saveToSharedPreferences(profileData);
    } catch (e) {
      throw Exception("Error guardando datos: $e");
    }
  }

  // READ - Obtener todos los datos personales
  Future<Map<String, dynamic>> getProfileData() async {
    try {
      final userId = await _sharedPrefService.getUserId();
      if (userId == null) throw Exception("Usuario no autenticado");

      // Intentar obtener de Firebase
      final snapshot = await _databaseService.getDatosCollection(userId);

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        await _saveToSharedPreferences(data); // Actualizar cache local
        return data;
      } else {
        return {}; // No hay datos aún
      }
    } catch (e) {
      // Si hay error con Firebase, intentar obtener de SharedPreferences
      return await _getFromSharedPreferences();
    }
  }

  // UPDATE - Actualizar datos específicos
  Future<void> updateProfileData(Map<String, dynamic> updatedFields) async {
    try {
      final userId = await _sharedPrefService.getUserId();
      if (userId == null) throw Exception("Usuario no autenticado");

      // Agregar fecha de actualización
      updatedFields['updatedAt'] = DateTime.now();

      // Actualizar en Firebase
      await _databaseService.updateDatosPersonales(userId, updatedFields);

      // Actualizar SharedPreferences
      final currentData = await _getFromSharedPreferences();
      currentData.addAll(updatedFields);
      await _saveToSharedPreferences(currentData);
    } catch (e) {
      throw Exception("Error actualizando datos: $e");
    }
  }

  // UPDATE campos individuales (métodos específicos)
  Future<void> updateCiudad(String nuevaCiudad) async {
    await updateProfileData({AppConstants.ciudad: nuevaCiudad});
  }

  Future<void> updateDescripcion(String nuevaDescripcion) async {
    await updateProfileData({AppConstants.descripcion: nuevaDescripcion});
  }

  Future<void> updateTelefono(String nuevoTelefono) async {
    await updateProfileData({AppConstants.telefono: nuevoTelefono});
  }

  Future<void> updateOcupacion(String nuevaOcupacion) async {
    await updateProfileData({AppConstants.ocupacion: nuevaOcupacion});
  }

  // DELETE - Eliminar todos los datos personales
  Future<void> deleteProfileData() async {
    try {
      final userId = await _sharedPrefService.getUserId();
      if (userId == null) throw Exception("Usuario no autenticado");

      await _databaseService.deleteDatosPersonales(userId);
      await _clearSharedPreferences();
    } catch (e) {
      throw Exception("Error eliminando datos: $e");
    }
  }

  // VERIFICAR - Si el usuario ya tiene datos guardados
  Future<bool> hasProfileData() async {
    try {
      final data = await getProfileData();
      return data.isNotEmpty && data.containsKey(AppConstants.ciudad);
    } catch (e) {
      return false;
    }
  }

  // ========== MÉTODOS PRIVADOS PARA SHARED PREFERENCES ==========

  Future<void> _saveToSharedPreferences(Map<String, dynamic> data) async {
    // Guardar cada campo individualmente en SharedPreferences
    if (data[AppConstants.ciudad] != null) {
      await _sharedPrefService.saveCiudad(data[AppConstants.ciudad]);
    }
    if (data[AppConstants.descripcion] != null) {
      await _sharedPrefService.saveDescripcion(data[AppConstants.descripcion]);
    }
    if (data[AppConstants.fecha_nacimiento] != null) {
      await _sharedPrefService.saveFechaNacimiento(
        data[AppConstants.fecha_nacimiento],
      );
    }
    if (data[AppConstants.genero] != null) {
      await _sharedPrefService.saveGenero(data[AppConstants.genero]);
    }
    if (data[AppConstants.telefono] != null) {
      await _sharedPrefService.saveTelefono(data[AppConstants.telefono]);
    }
    if (data[AppConstants.estudios] != null) {
      await _sharedPrefService.saveEstudios(data[AppConstants.estudios]);
    }
    if (data[AppConstants.ocupacion] != null) {
      await _sharedPrefService.saveOcupacion(data[AppConstants.ocupacion]);
    }
    if (data[AppConstants.estado_relacion] != null) {
      await _sharedPrefService.saveEstadoRelacion(
        data[AppConstants.estado_relacion],
      );
    }
  }

  Future<Map<String, dynamic>> _getFromSharedPreferences() async {
    return {
      AppConstants.ciudad: await _sharedPrefService.getCiudad(),
      AppConstants.descripcion: await _sharedPrefService.getDescripcion(),
      AppConstants.fecha_nacimiento: await _sharedPrefService
          .getFechaNacimiento(),
      AppConstants.genero: await _sharedPrefService.getGenero(),
      AppConstants.telefono: await _sharedPrefService.getTelefono(),
      AppConstants.estudios: await _sharedPrefService.getEstudios(),
      AppConstants.ocupacion: await _sharedPrefService.getOcupacion(),
      AppConstants.estado_relacion: await _sharedPrefService
          .getEstadoRelacion(),
    };
  }

  Future<void> _clearSharedPreferences() async {
    await _sharedPrefService.clearProfileData();
  }
}
