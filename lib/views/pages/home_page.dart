import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3/controllers/chat_controller.dart';
import 'package:flutter_application_3/services/database_service.dart';
import 'package:flutter_application_3/services/shared_pref_service.dart';
import 'package:flutter_application_3/views/pages/chat_page.dart';
import 'package:flutter_application_3/views/pages/grupos_page.dart';
import 'package:flutter_application_3/views/pages/principal_page.dart';
import 'package:flutter_application_3/views/pages/profile_page.dart';
import 'package:flutter_application_3/views/pages/tablero.dart';
import 'package:flutter_application_3/views/pages/user_profile_page.dart';
import 'package:flutter_application_3/views/widgets/chat_room_list_tile.dart';

class HomePage extends StatefulWidget {
  // --- MODIFICADO ---
  // Añadido para que puedas navegar a una pestaña específica desde otra página
  final int? initialIndex;
  const HomePage({super.key, this.initialIndex});
  // ------------------

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final ChatController _chatController = ChatController();
  final DatabaseService _databaseService = DatabaseService();
  final SharedPrefService _sharedPrefService = SharedPrefService();

  String? myUsername, myName, myEmail, myPicture;
  Stream? chatRoomsStream;
  bool _search = false;

  // --- VARIABLES DE BÚSQUEDA MODIFICADAS ---
  // Lista que guarda los datos de los usuarios con los que chateas
  List<Map<String, dynamic>> _chatPartnersData = []; 
  // Lista que guarda los resultados filtrados de la búsqueda local
  List<Map<String, dynamic>> _filteredChatPartners = [];
  // Estado de carga para la lista de compañeros de chat
  bool _isPartnerListLoading = true; 
  // ----------------------------------------

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // --- MODIFICADO ---
    // Si se pasa un initialIndex, úsalo
    if (widget.initialIndex != null) {
      _selectedIndex = widget.initialIndex!;
    }
    // ------------------
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await _sharedPrefService.getAllUserData();
    setState(() {
      myUsername = userData['username'];
      myName = userData['displayName'];
      myEmail = userData['email'];
      myPicture = userData['imageUrl'];
    });

    if (myUsername != null) {
      // Mantenemos el stream para la lista de chats en tiempo real
      chatRoomsStream = _databaseService.getUserChatRooms(myUsername!); 
      // --- NUEVO ---
      // Cargamos los datos de los compañeros de chat para la búsqueda
      await _loadChatPartnersData(); 
      // -------------
      setState(() {});
    }
  }

  // --- NUEVO MÉTODO PARA CARGAR LOS DATOS DE LOS COMPAÑEROS DE CHAT ---
  Future<void> _loadChatPartnersData() async {
    if (myUsername == null) return;

    setState(() { _isPartnerListLoading = true; });

    try {
      // 1. Obtenemos la lista actual de chatrooms
      QuerySnapshot chatRoomSnapshot = await _databaseService.getUserChatRooms(myUsername!).first;
      
      // 2. Preparamos una lista de "futuros" para buscar la info de cada usuario
      List<Future<QuerySnapshot>> userFutures = [];
      
      for (var doc in chatRoomSnapshot.docs) {
        // Extraemos el apodo del otro usuario
        String otherUsername = doc.id.replaceAll("_", "").replaceAll(myUsername!, "");
        userFutures.add(_databaseService.getUserInfo(otherUsername));
      }

      // 3. Ejecutamos todas las consultas a la vez (mucho más rápido)
      List<QuerySnapshot> userSnapshots = await Future.wait(userFutures);

      List<Map<String, dynamic>> partners = [];
      for (var userDoc in userSnapshots) {
        if (userDoc.docs.isNotEmpty) {
          partners.add(userDoc.docs.first.data() as Map<String, dynamic>);
        }
      }

      // 4. Guardamos los datos en nuestro estado local
      setState(() {
        _chatPartnersData = partners;
        _isPartnerListLoading = false;
      });
    } catch (e) {
      print("Error cargando compañeros de chat: $e");
      setState(() { _isPartnerListLoading = false; });
    }
  }
  // -----------------------------------------------------------------

  // --- LÓGICA DE BÚSQUEDA MODIFICADA ---
  void _initializeSearch(String value) {
    if (value.isEmpty) {
      setState(() {
        _search = false;
        _filteredChatPartners.clear();
      });
      return;
    }

    String upperValue = value.toUpperCase();

    setState(() {
      _search = true;
      // Filtramos la lista LOCAL (_chatPartnersData) en lugar de consultar Firestore
      _filteredChatPartners = _chatPartnersData.where((element) {
        return element['username'].toString().startsWith(upperValue);
      }).toList();
    });
  }
  // -------------------------------------

  void _onItemTapped(int index) {
    // --- MODIFICADO ---
    // Si ya estamos en la pestaña, no hacemos nada
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    // Usamos Navigator.pushReplacement para no apilar páginas
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, a, b) => const PrincipalPage(),
          transitionDuration: Duration.zero,
        ),
      );
    }
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, a, b) => const TableroPage(),
          transitionDuration: Duration.zero,
        ),
      );
    }
    // ... puedes añadir más 'else if' para los otros índices
  }
  // --------------------

  Widget _chatRoomList() {
    return StreamBuilder(
      stream: chatRoomsStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
          return const Center(child: Text("No tienes chats disponibles"));
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: snapshot.data.docs.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data.docs[index];

            return ChatRoomListTile(
              chatRoomId: ds.id,
              lastMessage: ds["lastMessage"] ?? "",
              myUsername: myUsername!,
              time: ds["lastMessageSendTs"]?.toString() ?? "",
            );
          },
        );
      },
    );
  }

  Widget _buildResultCard(Map<String, dynamic> data, BuildContext context) {
    // Este widget ya está perfecto, navega a UserProfilePage
    return GestureDetector(
      onTap: () {
        setState(() {
          _search = false;
          _searchController.clear();
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                UserProfilePage(username: data["username"] ?? ""),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Material(
          elevation: 5.0,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: Image.network(
                    data["Image"],
                    height: 70,
                    width: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 20.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data["Name"],
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      data["username"],
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 79, 191, 219),
      body: Container(
        margin: const EdgeInsets.only(top: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Row(
                children: [
                  Image.asset(
                    "images/wave.png",
                    height: 40,
                    width: 40,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 10.0),
                  const Text(
                    "Hola, ",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    myName ?? "...",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Botón de Perfil
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color.fromARGB(255, 79, 191, 219),
                          size: 30.0,
                        ),
                      ),
                    ),
                  ),
                  // Botón de Grupos
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GruposPage(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.group,
                          color: Color.fromARGB(255, 79, 191, 219),
                          size: 30.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10.0),

            // TITULO "Bienvenido a:"
            const Padding(
              padding: EdgeInsets.only(left: 20.0),
              child: Text(
                "Bienvenido a:",
                style: TextStyle(
                  color: Color.fromARGB(195, 255, 255, 255),
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // TÍTULO "AquiNomas"
            const Padding(
              padding: EdgeInsets.only(left: 20.0),
              child: Text(
                "AquiNomas",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30.0),

            // PRINCIPAL CONTAINER
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(
                  left: 30.0,
                  right: 20.0,
                  top: 30.0,
                ),
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                // --- MODIFICADO: Añadido chequeo de carga ---
                child: _isPartnerListLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          const SizedBox(height: 30.0),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFececf8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                // Aquí llamamos a la nueva función de búsqueda
                                _initializeSearch(value); 
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.search),
                                hintText: "Buscar en mis chats...", // Texto de hint actualizado
                              ),
                            ),
                          ),
                          const SizedBox(height: 20.0),

                          // --- MODIFICADO: Muestra resultados o lista de chat ---
                          Expanded(
                            child: _search
                                ? ListView.builder(
                                    padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                                    primary: false,
                                    shrinkWrap: true,
                                    itemCount: _filteredChatPartners.length,
                                    itemBuilder: (context, index) {
                                      return _buildResultCard(
                                          _filteredChatPartners[index], context);
                                    },
                                  )
                                : _chatRoomList(), // Muestra la lista de chats normal
                          ),
                          // ----------------------------------------------------
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
      // BARRA DE NAVEGACIÓN INFERIOR
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 79, 191, 219),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.5),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map), // <-- CAMBIADO A ÍNDICE 1
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications), // <-- CAMBIADO A ÍNDICE 2
            label: 'Notificaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings), // <-- CAMBIADO A ÍNDICE 3
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}