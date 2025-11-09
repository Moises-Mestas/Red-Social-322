// lib/views/pages/onboarding_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_3/controllers/datos_controller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/constants/app_constants.dart';
import '../../views/pages/home_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final ProfileDataController _profileController = ProfileDataController();
  final PageController _pageController = PageController();
  bool _isLoading = false;
  int _currentPage = 0;
  bool _usandoUbicacionActual = false;

  final TextEditingController _ciudadController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _fechaNacimientoController =
      TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _ocupacionController = TextEditingController();

  String? _generoSeleccionado;
  String? _estudiosSeleccionado;
  String? _estadoRelacionSeleccionado;

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

  final List<String> _ciudadesPopulares = [
    'Lima', 'Arequipa', 'Trujillo', 'Chiclayo', 'Piura', 'Iquitos',
    'Cusco', 'Chimbote', 'Huancayo', 'Tacna', 'Ica', 'Juliaca',
    'Sullana', 'Chincha Alta', 'Huanuco', 'Ayacucho', 'Cajamarca',
    'Pucallpa', 'Tumbes', 'Talara', 'Huaraz', 'Puno', 'Tarapoto',
    'Huaral', 'Cerro de Pasco', 'Chulucanas', 'Huaquillas', 'Huacho',
    'Jaén', 'Moyobamba', 'Lambayeque', 'Pisco', 'Barranca', 'Chepén',
    'Yurimaguas', 'Huánuco', 'Virú', 'Catacaos', 'Tarma', 'La Unión',
    'Chocope', 'Sechura', 'Moche', 'Ilave', 'Azángaro', 'Moquegua',
    'Casma', 'Mala', 'Santiago de Cao', 'Huamachuco',
  ];

  @override
  void initState() {
    super.initState();
    _checkIfProfileExists();
  }

  Future<void> _checkIfProfileExists() async {
    try {
      final hasData = await _profileController.hasProfileData();
      if (hasData && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      print("Error verificando perfil: $e");
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage--;
      });
    }
  }

  Future<void> _guardarPerfil() async {
    if (_ciudadController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona tu ubicación'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _profileController.saveAllProfileData(
        ciudad: _ciudadController.text,
        descripcion: _descripcionController.text,
        fechaNacimiento: _fechaNacimientoController.text,
        genero: _generoSeleccionado ?? '',
        telefono: _telefonoController.text,
        estudios: _estudiosSeleccionado ?? '',
        ocupacion: _ocupacionController.text,
        estadoRelacion: _estadoRelacionSeleccionado ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Perfil completado!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        _fechaNacimientoController.text =
            "${picked.day.toString().padLeft(2, '0')}/"
            "${picked.month.toString().padLeft(2, '0')}/"
            "${picked.year}";
      });
    }
  }

  // ========== MÉTODOS DE UBICACIÓN ==========

  Future<void> _obtenerUbicacionActual() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('El servicio de ubicación está desactivado');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permisos de ubicación denegados permanentemente');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String ciudad =
            placemark.locality ??
            placemark.administrativeArea ??
            'Ubicación desconocida';

        setState(() {
          _ciudadController.text = ciudad;
          _usandoUbicacionActual = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ubicación detectada: $ciudad'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error obteniendo ubicación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarSeleccionCiudad() {
    TextEditingController searchController = TextEditingController();
    List<String> ciudadesFiltradas = List.from(_ciudadesPopulares);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Selecciona tu ciudad',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar ciudad en Perú...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          ciudadesFiltradas = _ciudadesPopulares
                              .where(
                                (ciudad) => ciudad.toLowerCase().contains(
                                      value.toLowerCase(),
                                    ),
                              )
                              .toList();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: ciudadesFiltradas.length,
                  itemBuilder: (context, index) {
                    final ciudad = ciudadesFiltradas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      elevation: 1,
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 156, 50, 50).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: const Color.fromARGB(255, 156, 50, 50),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          ciudad,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text(
                          'Perú',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          setState(() {
                            _ciudadController.text = ciudad;
                            _usandoUbicacionActual = false;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: const Color.fromARGB(255, 156, 50, 50),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousPage,
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildProgressIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [_buildPage1(), _buildPage2(), _buildPage3()],
                  ),
                ),
              ],
            ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentPage) {
      case 0:
        return 'Ubicación';
      case 1:
        return 'Información Personal';
      case 2:
        return 'Sobre Ti';
      default:
        return 'Completa tu Perfil';
    }
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentPage + 1) / 3,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 156, 50, 50)),
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 10),
          Text(
            'Paso ${_currentPage + 1} de 3',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Página 1: Ubicación
  Widget _buildPage1() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            icon: Icons.location_on,
            title: '¿Dónde vives?',
            subtitle:
                'Selecciona tu ubicación para conectar con personas cercanas',
          ),
          const SizedBox(height: 40),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _usandoUbicacionActual
                      ? const Color.fromARGB(255, 156, 50, 50).withOpacity(0.2)
                      : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.my_location,
                  color: _usandoUbicacionActual
                      ? const Color.fromARGB(255, 156, 50, 50)
                      : Colors.grey,
                ),
              ),
              title: const Text(
                'Usar mi ubicación actual',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Detectar automáticamente tu ciudad',
                style: TextStyle(fontSize: 12),
              ),
              trailing: _usandoUbicacionActual
                  ? const Icon(Icons.check_circle, color: Color.fromARGB(255, 156, 50, 50))
                  : const Icon(Icons.chevron_right),
              onTap: _obtenerUbicacionActual,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      !_usandoUbicacionActual &&
                              _ciudadController.text.isNotEmpty
                          ? const Color.fromARGB(255, 156, 50, 50).withOpacity(0.2)
                          : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search,
                  color:
                      !_usandoUbicacionActual &&
                              _ciudadController.text.isNotEmpty
                          ? const Color.fromARGB(255, 156, 50, 50)
                          : Colors.grey,
                ),
              ),
              title: const Text(
                'Buscar ciudad manualmente',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                _ciudadController.text.isEmpty
                    ? 'Selecciona de una lista'
                    : _ciudadController.text,
                style: TextStyle(
                  fontSize: 12,
                  color: _ciudadController.text.isEmpty
                      ? Colors.grey
                      : const Color.fromARGB(255, 156, 50, 50),
                ),
              ),
              trailing:
                  !_usandoUbicacionActual && _ciudadController.text.isNotEmpty
                      ? const Icon(Icons.check_circle, color: Color.fromARGB(255, 156, 50, 50))
                      : const Icon(Icons.chevron_right),
              onTap: _mostrarSeleccionCiudad,
            ),
          ),
          const SizedBox(height: 20),
          if (_ciudadController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 156, 50, 50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color.fromARGB(255, 156, 50, 50).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _usandoUbicacionActual
                        ? Icons.my_location
                        : Icons.location_on,
                    color: const Color.fromARGB(255, 156, 50, 50),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _usandoUbicacionActual
                              ? 'Ubicación detectada'
                              : 'Ciudad seleccionada',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _ciudadController.text,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 156, 50, 50),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() {
                        _ciudadController.clear();
                        _usandoUbicacionActual = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          const Spacer(),
          _buildNextButton(
            onPressed: _ciudadController.text.isEmpty ? null : _nextPage,
            text: 'Continuar',
          ),
        ],
      ),
    );
  }

  // Página 2: Información Personal
  Widget _buildPage2() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            icon: Icons.person_outline,
            title: 'Información Personal',
            subtitle: 'Esta información nos ayuda a conocerte mejor',
          ),
          const SizedBox(height: 30),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDateField(),
                  const SizedBox(height: 20),
                  _buildDropdown(
                    value: _generoSeleccionado,
                    items: _generos,
                    label: 'Género (Opcional)',
                    hint: 'Selecciona tu género',
                    icon: Icons.person,
                    onChanged: (value) {
                      setState(() {
                        _generoSeleccionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _telefonoController,
                    label: 'Teléfono (Opcional)',
                    hint: 'Ej: +51 123 456 789',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  _buildDropdown(
                    value: _estudiosSeleccionado,
                    items: _nivelesEstudios,
                    label: 'Nivel de Estudios (Opcional)',
                    hint: 'Selecciona tu nivel',
                    icon: Icons.school,
                    onChanged: (value) {
                      setState(() {
                        _estudiosSeleccionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _ocupacionController,
                    label: 'Ocupación (Opcional)',
                    hint: 'Ej: Desarrollador, Estudiante, etc.',
                    icon: Icons.work,
                  ),
                  // --- INICIO DE LA MODIFICACIÓN ---
                  const SizedBox(height: 120), // <-- Espacio blanco añadido
                  // --- FIN DE LA MODIFICACIÓN ---
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildNavigationButtons(onNext: _nextPage, showPrevious: true),
        ],
      ),
    );
  }

  // Página 3: Sobre Ti
  Widget _buildPage3() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            icon: Icons.favorite_outline,
            title: 'Sobre Ti',
            subtitle: 'Cuéntanos más sobre tus intereses y estilo de vida',
          ),
          const SizedBox(height: 30),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDropdown(
                    value: _estadoRelacionSeleccionado,
                    items: _estadosRelacion,
                    label: 'Estado de Relación (Opcional)',
                    hint: 'Selecciona tu estado',
                    icon: Icons.favorite,
                    onChanged: (value) {
                      setState(() {
                        _estadoRelacionSeleccionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildDescriptionField(),
                  // --- INICIO DE LA MODIFICACIÓN ---
                  const SizedBox(height: 20), // <-- Espacio blanco añadido
                  // --- FIN DE LA MODIFICACIÓN ---
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildFinishButton(),
        ],
      ),
    );
  }

  Widget _buildPageHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 50, color: const Color.fromARGB(255, 156, 50, 50).withOpacity(0.8)),
        const SizedBox(height: 15),
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fecha de Nacimiento (Opcional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _fechaNacimientoController,
          readOnly: true,
          onTap: _seleccionarFecha,
          decoration: InputDecoration(
            hintText: 'Selecciona tu fecha de nacimiento',
            prefixIcon: const Icon(
              Icons.calendar_today,
              color: Color.fromARGB(255, 156, 50, 50),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color.fromARGB(255, 156, 50, 50), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color.fromARGB(255, 156, 50, 50)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color.fromARGB(255, 156, 50, 50), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required String hint,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: onChanged,
          // --- INICIO DE LA MODIFICACIÓN ---
          menuMaxHeight: 1000.0, // <-- Limita la altura del menú
          // --- FIN DE LA MODIFICACIÓN ---
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color.fromARGB(255, 156, 50, 50)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color.fromARGB(255, 156, 50, 50), width: 2),
            ),
          ),
          isExpanded: true,
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descripción (Opcional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descripcionController,
          maxLines: 4,
          maxLength: 300,
          decoration: InputDecoration(
            hintText:
                'Cuéntanos sobre tus intereses, hobbies, lo que te apasiona...',
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color.fromARGB(255, 156, 50, 50), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // --- INICIO DE LA MODIFICACIÓN (AÑADIR PADDING) ---
  Widget _buildNextButton({VoidCallback? onPressed, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0), // <-- Padding inferior
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 156, 50, 50),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons({
    required VoidCallback onNext,
    bool showPrevious = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0), // <-- Padding inferior
      child: Row(
        children: [
          if (showPrevious)
            Expanded(
              child: SizedBox(
                height: 55,
                child: OutlinedButton(
                  onPressed: _previousPage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color.fromARGB(255, 156, 50, 50),
                    side: const BorderSide(color: Color.fromARGB(255, 156, 50, 50)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Atrás',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          if (showPrevious) const SizedBox(width: 15),
          Expanded(
            child: SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 156, 50, 50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  'Siguiente',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0), // <-- Padding inferior
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: _guardarPerfil,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 156, 50, 50),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Finalizar Perfil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
  // --- FIN DE LA MODIFICACIÓN ---

  @override
  void dispose() {
    _pageController.dispose();
    _ciudadController.dispose();
    _descripcionController.dispose();
    _fechaNacimientoController.dispose();
    _telefonoController.dispose();
    _ocupacionController.dispose();
    super.dispose();
  }
}