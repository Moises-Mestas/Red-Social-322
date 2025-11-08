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
  final int? initialIndex;
  // --- MODIFICADO ---
  // El índice 2 es ahora la HomePage (chats)
  const HomePage({super.key, this.initialIndex = 2});
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

  List<Map<String, dynamic>> _chatPartnersData = []; 
  List<Map<String, dynamic>> _filteredChatPartners = [];
  bool _isPartnerListLoading = true; 
  
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // --- MODIFICADO ---
    // El índice por defecto de esta página ahora es 2
    _selectedIndex = widget.initialIndex ?? 2;
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
      chatRoomsStream = _databaseService.getUserChatRooms(myUsername!); 
      await _loadChatPartnersData(); 
      setState(() {});
    }
  }

  Future<void> _loadChatPartnersData() async {
    if (myUsername == null) return;

    setState(() { _isPartnerListLoading = true; });

    try {
      QuerySnapshot chatRoomSnapshot = await _databaseService.getUserChatRooms(myUsername!).first;
      
      List<Future<QuerySnapshot>> userFutures = [];
      
      for (var doc in chatRoomSnapshot.docs) {
        String otherUsername = doc.id.replaceAll("_", "").replaceAll(myUsername!, "");
        userFutures.add(_databaseService.getUserInfo(otherUsername));
      }

      List<QuerySnapshot> userSnapshots = await Future.wait(userFutures);

      List<Map<String, dynamic>> partners = [];
      for (var userDoc in userSnapshots) {
        if (userDoc.docs.isNotEmpty) {
          partners.add(userDoc.docs.first.data() as Map<String, dynamic>);
        }
      }

      setState(() {
        _chatPartnersData = partners;
        _isPartnerListLoading = false;
      });
    } catch (e) {
      print("Error cargando compañeros de chat: $e");
      setState(() { _isPartnerListLoading = false; });
    }
  }

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
      _filteredChatPartners = _chatPartnersData.where((element) {
        return element['username'].toString().startsWith(upperValue);
      }).toList();
    });
  }

  // --- NAVEGACIÓN COMPLETAMENTE ACTUALIZADA ---
  void _onItemTapped(int index) {
    // Si ya estamos en la pestaña, no hacemos nada
    if (_selectedIndex == index) return;

    if (index == 1 && myUsername == null) {
          return; 
        }
    setState(() {
      _selectedIndex = index;
    });

    // Usamos Navigator.pushReplacement para no apilar páginas
    // y PageRouteBuilder para que el cambio sea instantáneo
    switch (index) {
      case 0: // Muro Principal
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, a, b) => const PrincipalPage(),
            transitionDuration: Duration.zero,
          ),
        );
        break;
      case 1: // Mi Perfil (Tablero)
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, a, b) => UserProfilePage(username: myUsername!),
            transitionDuration: Duration.zero,
          ),
        );
        break;
      case 2: // Chats (Esta página)
        // Ya estamos aquí, no es necesario navegar
        // Pero si vienes de otra pestaña, esto te trae de vuelta
         Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, a, b) => const HomePage(),
            transitionDuration: Duration.zero,
          ),
        );
        break;
      case 3: // Grupos
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, a, b) => const GruposPage(),
            transitionDuration: Duration.zero,
          ),
        );
        break;
      case 4: // Ajustes (ProfilePage)
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, a, b) => const ProfilePage(),
            transitionDuration: Duration.zero,
          ),
        );
        break;
    }
  }
  // ---------------------------------------------

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
      backgroundColor: const Color(0xffD32323), // <-- Color de fondo cambiado
      body: Container(
        margin: const EdgeInsets.only(top: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER MODIFICADO (Botones eliminados) ---
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
                    " ", // Eliminado "Hola, "
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    myUsername?? "...", // Muestra el apodo
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // <-- BOTONES DE PERFIL Y GRUPOS ELIMINADOS
                ],
              ),
            ),
            const SizedBox(height: 10.0),
            
            // --- TÍTULOS ELIMINADOS ---
            // (Se eliminó "Bienvenido a:" y "AquiNomas")
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
                                _initializeSearch(value); 
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.search),
                                hintText: "Buscar en mis chats...",
                              ),
                            ),
                          ),
                          const SizedBox(height: 20.0),

                          // LISTA DE RESULTADOS O CHATS
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
                                : _chatRoomList(),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
      
      // --- BARRA DE NAVEGACIÓN ACTUALIZADA ---
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xffD32323), // Color cambiado
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.5),
        currentIndex: _selectedIndex, // <-- Se actualizará a 2
        onTap: _onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home), // Icono 1: Muro
            label: 'Muro',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), // Icono 2: Mi Perfil (Tablero)
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble), // Icono 3: Chats (Esta página)
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group), // Icono 4: Grupos
            label: 'Grupos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings), // Icono 5: Ajustes
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}