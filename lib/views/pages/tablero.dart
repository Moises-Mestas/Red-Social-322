import 'package:flutter/material.dart';
import 'package:flutter_application_3/services/shared_pref_service.dart';
import 'package:flutter_application_3/services/database_service.dart';
import 'package:flutter_application_3/core/constants/app_constants.dart';

class TableroPage extends StatefulWidget {
  const TableroPage({super.key});

  @override
  State<TableroPage> createState() => _TableroPageState();
}

class _TableroPageState extends State<TableroPage> {
  final SharedPrefService _sharedPrefService = SharedPrefService();
  final DatabaseService _databaseService = DatabaseService();

  String? myUsername, myName, myEmail, myPicture;
  Map<String, dynamic> _datosPersonales = {};
  int _selectedTab = 0;
  bool _isLoading = true;

  // Estadísticas (podemos conectarlas a datos reales después)
  int _postsCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;

  // Posts de ejemplo (luego conectaremos con posts reales)
  final List<Map<String, dynamic>> _myPosts = [
    {
      'image':
          'https://images.unsplash.com/photo-1682687220742-aba13b6e50ba?w=300',
      'likes': 124,
      'comments': 23,
    },
    {
      'image':
          'https://images.unsplash.com/photo-1682687220067-dced9a881b56?w=300',
      'likes': 89,
      'comments': 12,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _sharedPrefService.getAllUserData();

      final userId = await _sharedPrefService.getUserId();
      if (userId != null) {
        final datosSnapshot = await _databaseService.getDatosCollection(userId);
        if (datosSnapshot.exists) {
          _datosPersonales = datosSnapshot.data() as Map<String, dynamic>;
        }
      }

      setState(() {
        myUsername = userData['username'] ?? 'usuario';
        myName = userData['displayName'] ?? 'Nombre Usuario';
        myEmail = userData['email'] ?? '';
        myPicture =
            userData['imageUrl'] ??
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150';
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos del perfil: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _buildBio() {
    String bio = '';

    // Ciudad (obligatorio)
    if (_datosPersonales[AppConstants.ciudad] != null &&
        _datosPersonales[AppConstants.ciudad].toString().isNotEmpty) {
      bio += '📍 ${_datosPersonales[AppConstants.ciudad]}\n';
    }

    // Ocupación
    if (_datosPersonales[AppConstants.ocupacion] != null &&
        _datosPersonales[AppConstants.ocupacion].toString().isNotEmpty) {
      bio += '💼 ${_datosPersonales[AppConstants.ocupacion]}\n';
    }

    // Estudios
    if (_datosPersonales[AppConstants.estudios] != null &&
        _datosPersonales[AppConstants.estudios].toString().isNotEmpty) {
      bio += '🎓 ${_datosPersonales[AppConstants.estudios]}\n';
    }

    // Descripción personal
    if (_datosPersonales[AppConstants.descripcion] != null &&
        _datosPersonales[AppConstants.descripcion].toString().isNotEmpty) {
      bio += '${_datosPersonales[AppConstants.descripcion]}\n';
    }

    // Estado de relación
    if (_datosPersonales[AppConstants.estado_relacion] != null &&
        _datosPersonales[AppConstants.estado_relacion].toString().isNotEmpty) {
      bio += '💑 ${_datosPersonales[AppConstants.estado_relacion]}\n';
    }

    // Si no hay datos, mostrar bio por defecto
    if (bio.isEmpty) {
      bio = '✨ Bienvenido a AquiNomas\n📱 Conectando personas\n📍 Perú';
    }

    return bio;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            Text(
              myUsername ?? 'usuario',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.keyboard_arrow_down, size: 20),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, size: 26),
            onPressed: () {},
          ),
          IconButton(icon: const Icon(Icons.menu, size: 26), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // INFORMACIÓN DEL PERFIL
              _buildProfileInfo(),

              // BIO CON DATOS REALES
              _buildBioSection(),

              // BOTONES DE ACCIÓN
              _buildActionButtons(),

              // TABS (POSTS, REELS, TAGS)
              _buildProfileTabs(),

              // CONTENIDO DE LOS TABS
              _buildTabContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // FOTO DE PERFIL
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundImage: NetworkImage(myPicture!),
                  backgroundColor: Colors.grey[300],
                ),
              ),
              // Badge para agregar story
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),

          const SizedBox(width: 20),

          // ESTADÍSTICAS
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(_postsCount, 'Publicaciones'),
                _buildStatItem(_followersCount, 'Seguidores'),
                _buildStatItem(_followingCount, 'Siguiendo'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(int count, String label) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBioSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NOMBRE REAL DEL USUARIO
          Text(
            myName ?? 'Nombre Usuario',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),

          const SizedBox(height: 4),

          // BIO CON DATOS REALES
          Text(_buildBio(), style: const TextStyle(fontSize: 14, height: 1.4)),

          const SizedBox(height: 8),

          // INFORMACIÓN ADICIONAL (email)
          if (myEmail != null && myEmail!.isNotEmpty)
            Text(
              '📧 $myEmail',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),

          const SizedBox(height: 8),

          // DATOS PERSONALES ADICIONALES
          _buildAdditionalInfo(),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    final additionalInfo = <String>[];

    // Género
    if (_datosPersonales[AppConstants.genero] != null &&
        _datosPersonales[AppConstants.genero].toString().isNotEmpty) {
      additionalInfo.add(_datosPersonales[AppConstants.genero]);
    }

    // Teléfono
    if (_datosPersonales[AppConstants.telefono] != null &&
        _datosPersonales[AppConstants.telefono].toString().isNotEmpty) {
      additionalInfo.add('📱 ${_datosPersonales[AppConstants.telefono]}');
    }

    // Fecha de nacimiento
    if (_datosPersonales[AppConstants.fecha_nacimiento] != null &&
        _datosPersonales[AppConstants.fecha_nacimiento].toString().isNotEmpty) {
      additionalInfo.add(
        '🎂 ${_datosPersonales[AppConstants.fecha_nacimiento]}',
      );
    }

    if (additionalInfo.isEmpty) {
      return const SizedBox();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: additionalInfo.map((info) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            info,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // BOTÓN EDITAR PERFIL
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Editar perfil',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // BOTÓN COMPARTIR PERFIL
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_add_outlined, size: 20),
          ),

          const SizedBox(width: 8),

          // BOTÓN MÁS OPCIONES
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.expand_more, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
          _buildTabItem(0, Icons.grid_on, 'PUBLICACIONES'),
          _buildTabItem(1, Icons.video_library, 'REELS'),
          _buildTabItem(2, Icons.assignment_ind, 'ETIQUETADAS'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.black : Colors.grey,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0: // Posts
        return _buildPostsGrid();
      case 1: // Reels
        return _buildReelsTab();
      case 2: // Tags
        return _buildTagsTab();
      default:
        return _buildPostsGrid();
    }
  }

  Widget _buildPostsGrid() {
    if (_myPosts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(50),
        child: Column(
          children: [
            const Icon(Icons.photo_library, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'Comparte tus momentos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Cuando publiques fotos, aparecerán aquí',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _myPosts.length,
      itemBuilder: (context, index) {
        final post = _myPosts[index];
        return _buildPostGridItem(post, index);
      },
    );
  }

  Widget _buildPostGridItem(Map<String, dynamic> post, int index) {
    return GestureDetector(
      onTap: () {
        // Aquí puedes navegar a la vista completa del post
      },
      child: Stack(
        children: [
          Image.network(
            post['image'],
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          // Overlay para mostrar stats
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const SizedBox.expand(),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    post['likes'].toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.chat_bubble, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    post['comments'].toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReelsTab() {
    return Container(
      padding: const EdgeInsets.all(50),
      child: Column(
        children: [
          const Icon(Icons.video_library, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'Tus Reels',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Los reels que crees aparecerán aquí',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTagsTab() {
    return Container(
      padding: const EdgeInsets.all(50),
      child: Column(
        children: [
          const Icon(Icons.assignment_ind, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'Fotos en las que estás etiquetado',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Cuando la gente te etiquete en fotos, aparecerán aquí',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
