import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3/controllers/chat_controller.dart';
import 'package:flutter_application_3/services/database_service.dart';
import 'package:flutter_application_3/services/shared_pref_service.dart';
import 'package:flutter_application_3/views/pages/chat_page.dart';
import 'package:flutter_application_3/views/pages/edit_profile_page.dart';
import 'package:flutter_application_3/views/pages/grupos_page.dart';
import 'package:flutter_application_3/views/pages/principal_page.dart';
import 'package:flutter_application_3/views/pages/profile_page.dart';
import 'package:flutter_application_3/views/pages/tablero.dart';
import 'package:flutter_application_3/views/pages/user_profile_page.dart';
import 'package:flutter_application_3/views/widgets/chat_room_list_tile.dart';

class HomePage extends StatefulWidget {
  final int? initialIndex;
  const HomePage({super.key, this.initialIndex = 2});

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
    _selectedIndex = widget.initialIndex ?? 2;
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

    setState(() {
      _isPartnerListLoading = true;
    });

    try {
      QuerySnapshot chatRoomSnapshot =
          await _databaseService.getUserChatRooms(myUsername!).first;

      List<Future<QuerySnapshot>> userFutures = [];

      for (var doc in chatRoomSnapshot.docs) {
        String otherUsername =
            doc.id.replaceAll("_", "").replaceAll(myUsername!, "");
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
      setState(() {
        _isPartnerListLoading = false;
      });
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

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    if (index == 1 && myUsername == null) {
      return;
    }
    setState(() {
      _selectedIndex = index;
    });

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
      case 1: // Mi Perfil (UserProfilePage)
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, a, b) => UserProfilePage(username: myUsername!),
            transitionDuration: Duration.zero,
          ),
        );
        break;
      case 2: // Chats (Esta página)
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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 156, 50, 50), // Tu rojo original
                  Color.fromARGB(255, 211, 38, 38), // Un rojo más oscuro
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // --- INICIO DE LA MODIFICACIÓN ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Row(
                    children: [
                      // 1. Foto de Perfil (con borde blanco)
                      CircleAvatar(
                        radius: 32, // Radio exterior (borde)
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 28, // Radio interior (imagen)
                          backgroundColor: Colors.white.withOpacity(0.3),
                          backgroundImage: (myPicture != null && myPicture!.isNotEmpty)
                              ? NetworkImage(myPicture!)
                              : null,
                          child: (myPicture == null || myPicture!.isEmpty)
                              ? const Icon(Icons.person, size: 28, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 15.0),
                      
                      // 2. Texto de Saludo
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hola de nuevo,",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16.0,
                            ),
                          ),
                          Text(
                            myUsername ?? "...", // <-- MUESTRA EL APODO
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                // --- FIN DE LA MODIFICACIÓN ---

                const SizedBox(height: 20.0), 

                // PRINCIPAL CONTAINER
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 20.0,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                              
                              const Text(
                                "Mensajes",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 10.0),

                              // LISTA DE RESULTADOS O CHATS
                              Expanded(
                                child: _search
                                    ? ListView.builder(
                                        padding: EdgeInsets.zero,
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
        ],
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 156, 50, 50)
,
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
            icon: Icon(Icons.home),
            label: 'Muro',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Grupos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}