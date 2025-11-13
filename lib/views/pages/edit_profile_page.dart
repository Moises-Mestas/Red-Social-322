// edit_profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_3/services/database_service.dart';
import 'package:flutter_application_3/services/shared_pref_service.dart';
import 'package:flutter_application_3/core/constants/app_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_3/controllers/profile_controller.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onProfileUpdated;

  const EditProfilePage({
    super.key,
    required this.userData,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final DatabaseService _databaseService = DatabaseService();
  final SharedPrefService _sharedPrefService = SharedPrefService();
  final ProfileController _profileController = ProfileController();

  // Controladores para datos básicos
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Controladores para datos personales
  final TextEditingController _ciudadController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _ocupacionController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _fechaNacimientoController =
      TextEditingController();

  // Valores para dropdowns
  String? _generoSeleccionado;
  String? _estudiosSeleccionado;
  String? _estadoRelacionSeleccionado;

  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _currentImageUrl;

  // Listas para dropdowns
  final List<String> _generos = [
    'Masculino',
    'Femenino',
    'Otro',
    'Prefiero no decir',
  ];

  final List<String> _nivelesEstudios = [
    'Primaria',
    'Secundaria',
    'Preparatoria',
    'Universidad',
    'Posgrado',
    'Otro',
  ];

  final List<String> _estadosRelacion = [
    'Soltero/a',
    'Casado/a',
    'En relación',
    'Divorciado/a',
    'Viudo/a',
    'Prefiero no decir',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    try {
      // 1. CARGAR DATOS BÁSICOS DESDE SHAREDPREFERENCES (como en TableroPage)
      final userData = await _sharedPrefService.getAllUserData();

      // 2. CARGAR DATOS PERSONALES DESDE FIREBASE (como en TableroPage)
      final userId = await _sharedPrefService.getUserId();
      Map<String, dynamic> datosPersonales = {};

      if (userId != null) {
        final datosSnapshot = await _databaseService.getDatosCollection(userId);
        if (datosSnapshot.exists) {
          datosPersonales = datosSnapshot.data() as Map<String, dynamic>;
        }
      }

      // 3. CARGAR DATOS BÁSICOS - DESDE SHAREDPREFERENCES
      _nameController.text = userData['displayName'] ?? userData['Name'] ?? '';
      _usernameController.text = userData['username'] ?? '';
      _emailController.text = userData['email'] ?? userData['Email'] ?? '';
      _currentImageUrl = userData['imageUrl'] ?? userData['Image'] ?? '';

      // 4. CARGAR DATOS PERSONALES - DESDE FIREBASE
      _ciudadController.text = datosPersonales[AppConstants.ciudad] ?? '';
      _descripcionController.text =
          datosPersonales[AppConstants.descripcion] ?? '';
      _ocupacionController.text = datosPersonales[AppConstants.ocupacion] ?? '';
      _telefonoController.text = datosPersonales[AppConstants.telefono] ?? '';
      _fechaNacimientoController.text =
          datosPersonales[AppConstants.fecha_nacimiento] ?? '';

      // 5. CARGAR DROPDOWNS
      final generoFromData = datosPersonales[AppConstants.genero];
      final estudiosFromData = datosPersonales[AppConstants.estudios];
      final estadoRelacionFromData =
          datosPersonales[AppConstants.estado_relacion];

      _generoSeleccionado = _generos.contains(generoFromData)
          ? generoFromData
          : 'Prefiero no decir';

      _estudiosSeleccionado = _nivelesEstudios.contains(estudiosFromData)
          ? estudiosFromData
          : 'Otro';

      _estadoRelacionSeleccionado =
          _estadosRelacion.contains(estadoRelacionFromData)
          ? estadoRelacionFromData
          : 'Prefiero no decir';

      print('=== DATOS CARGADOS EN EditProfilePage ===');
      print('Datos SharedPreferences:');
      print('displayName: ${userData['displayName']}');
      print('username: ${userData['username']}');
      print('email: ${userData['email']}');
      print('imageUrl: ${userData['imageUrl']}');
      print('Datos Firebase (personales):');
      print('ciudad: ${datosPersonales[AppConstants.ciudad]}');
      print('descripción: ${datosPersonales[AppConstants.descripcion]}');
      print('ocupación: ${datosPersonales[AppConstants.ocupacion]}');
      print('teléfono: ${datosPersonales[AppConstants.telefono]}');
      print(
        'fecha_nacimiento: ${datosPersonales[AppConstants.fecha_nacimiento]}',
      );
      print('========================================');

      setState(() {}); // Forzar rebuild con los datos cargados
    } catch (e) {
      print('Error cargando datos en EditProfilePage: $e');
    }
  }

  Future<void> _changeProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _isUploadingImage = true;
      });

      try {
        final userId = await _sharedPrefService.getUserId();
        if (userId != null) {
          final imageUrl = await _profileController.updateProfileImage(
            userId,
            image,
          );

          if (imageUrl != null) {
            setState(() {
              _currentImageUrl = imageUrl;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.green,
                content: Text('Imagen actualizada exitosamente'),
              ),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error al cambiar imagen: $e'),
          ),
        );
      } finally {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_ciudadController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La ciudad es obligatoria'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_nameController.text.isEmpty || _usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nombre y apodo son obligatorios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await _sharedPrefService.getUserId();
      if (userId != null) {
        // Asegurar que los valores de dropdowns no sean nulos
        final safeGenero = _generoSeleccionado ?? 'Prefiero no decir';
        final safeEstudios = _estudiosSeleccionado ?? 'Otro';
        final safeEstadoRelacion =
            _estadoRelacionSeleccionado ?? 'Prefiero no decir';

        // 1. Actualizar datos personales en Firebase
        final updatedPersonalData = {
          AppConstants.ciudad: _ciudadController.text,
          AppConstants.descripcion: _descripcionController.text,
          AppConstants.genero: safeGenero,
          AppConstants.telefono: _telefonoController.text,
          AppConstants.estudios: safeEstudios,
          AppConstants.ocupacion: _ocupacionController.text,
          AppConstants.estado_relacion: safeEstadoRelacion,
          AppConstants.fecha_nacimiento: _fechaNacimientoController.text,
          'updatedAt': DateTime.now(),
        };

        await _databaseService.updateDatosPersonales(
          userId,
          updatedPersonalData,
        );

        // 2. Actualizar datos básicos en SharedPreferences
        await _sharedPrefService.saveUserData(
          displayName: _nameController.text,
          email: _emailController.text,
          userId: userId,
          username: _usernameController.text,
          imageUrl: _currentImageUrl ?? '',
        );

        // 3. Actualizar datos básicos en Firebase (users collection)
        final updatedUserData = {
          'Name': _nameController.text,
          'username': _usernameController.text,
          'Email': _emailController.text,
          'SearchKey': _usernameController.text.substring(0, 1).toUpperCase(),
          'Image': _currentImageUrl,
          'updatedAt': DateTime.now(),
        };

        await _databaseService.updateUserData(userId, updatedUserData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onProfileUpdated();
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _fechaNacimientoController.text =
            "${picked.day.toString().padLeft(2, '0')}/"
            "${picked.month.toString().padLeft(2, '0')}/"
            "${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 156, 50, 50),
      appBar: AppBar(
        title: const Text("Editar Perfil",
        style: TextStyle(
            color: Colors.white, // O el color que prefieras
            fontWeight: FontWeight.bold,
        ),
        ),
        backgroundColor: const Color.fromARGB(255, 156, 50, 50),
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _saveProfile),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.only(
                    bottom: 40,
                    left: 20,
                    right: 20,
                  ),
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Foto de perfil editable
                      GestureDetector(
                        onTap: _changeProfileImage,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: const Color.fromARGB(255, 156, 50, 50),
                              width: 5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(3),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(80),
                                child: _isUploadingImage
                                    ? Container(
                                        width: 120,
                                        height: 120,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : Image.network(
                                        _currentImageUrl ?? '',
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                width: 120,
                                                height: 120,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                      ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // CAMPOS BÁSICOS
                      _buildEditableField(
                        'Email:',
                        _emailController,
                        isEditable: false,
                      ),
                      const SizedBox(height: 20),

                      _buildEditableField(
                        'Nombre:',
                        _nameController,
                        isEditable: true,
                      ),
                      const SizedBox(height: 20),

                      _buildEditableField(
                        'Apodo:',
                        _usernameController,
                        isEditable: true,
                      ),
                      const SizedBox(height: 20),

                      // CAMPOS ADICIONALES
                      _buildAdditionalField('Ciudad:', _ciudadController),
                      const SizedBox(height: 20),

                      _buildAdditionalField('Ocupación:', _ocupacionController),
                      const SizedBox(height: 20),

                      _buildAdditionalField(
                        'Teléfono:',
                        _telefonoController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),

                      // Fecha de Nacimiento
                      _buildDateField(),
                      const SizedBox(height: 20),

                      // Descripción
                      _buildDescriptionField(),
                      const SizedBox(height: 20),

                      // Dropdowns
                      _buildDropdownField(
                        'Género',
                        _generos,
                        _generoSeleccionado,
                        (value) {
                          setState(() {
                            _generoSeleccionado = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      _buildDropdownField(
                        'Estudios',
                        _nivelesEstudios,
                        _estudiosSeleccionado,
                        (value) {
                          setState(() {
                            _estudiosSeleccionado = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      _buildDropdownField(
                        'Estado de relación',
                        _estadosRelacion,
                        _estadoRelacionSeleccionado,
                        (value) {
                          setState(() {
                            _estadoRelacionSeleccionado = value;
                          });
                        },
                      ),

                      const SizedBox(height: 30),

                      // BOTÓN GUARDAR
                      GestureDetector(
                        onTap: _saveProfile,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.save, color: Colors.white),
                                    SizedBox(width: 10),
                                    Text(
                                      'Guardar cambios',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // MÉTODO EXACTO DE ProfilePage
  Widget _buildEditableField(
    String title,
    TextEditingController controller, {
    required bool isEditable,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 156, 50, 50),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: isEditable ? Colors.white : Colors.grey[200],
            borderRadius: BorderRadius.circular(15),
            border: isEditable ? Border.all(color: Colors.blue) : null,
          ),
          child: isEditable
              ? TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                )
              : Text(
                  controller.text.isEmpty ? 'No disponible' : controller.text,
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                ),
        ),
      ],
    );
  }

  // Método para campos adicionales
  Widget _buildAdditionalField(
    String title,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 156, 50, 50),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  // Método para campo de descripción
  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Descripción:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 156, 50, 50),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue),
          ),
          child: TextField(
            controller: _descripcionController,
            maxLines: 3,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: const InputDecoration(
              hintText: 'Cuéntanos sobre ti...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  // Método para campo de fecha
  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Fecha de Nacimiento:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 156, 50, 50),
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _fechaNacimientoController.text.isEmpty
                        ? 'Selecciona tu fecha de nacimiento'
                        : _fechaNacimientoController.text,
                    style: TextStyle(
                      fontSize: 16,
                      color: _fechaNacimientoController.text.isEmpty
                          ? Colors.grey
                          : Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today, color: Colors.blue),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Método para dropdowns
  Widget _buildDropdownField(
    String title,
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    final safeValue = value ?? items.first;
    final currentValue = items.contains(safeValue) ? safeValue : items.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 156, 50, 50),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue),
          ),
          child: DropdownButton<String>(
            value: currentValue,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: const TextStyle(fontSize: 16)),
              );
            }).toList(),
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox(),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _ciudadController.dispose();
    _descripcionController.dispose();
    _ocupacionController.dispose();
    _telefonoController.dispose();
    _fechaNacimientoController.dispose();
    super.dispose();
  }
}
