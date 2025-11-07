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
import 'package:flutter_application_3/views/widgets/chat_room_list_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final ChatController _chatController = ChatController();
  // final SearchController _searchControllerInstance = SearchController(); // No parece usarse, comentado para evitar warnings
  final DatabaseService _databaseService = DatabaseService();
  final SharedPrefService _sharedPrefService = SharedPrefService();

  String? myUsername, myName, myEmail, myPicture;
  Stream? chatRoomsStream;
  bool _search = false;
  List<Map<String, dynamic>> _tempSearchStore = [];
  String _lastSearchKey = "";

  // Índice para controlar qué botón de la barra inferior está activo
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
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
      setState(() {});
    }
  }

  void _initializeSearch(String value) {
    if (value.isEmpty) {
      setState(() {
        _tempSearchStore.clear();
        _search = false;
        _lastSearchKey = "";
      });
      return;
    }

    setState(() {
      _search = true;
    });

    String searchKey = value.substring(0, 1).toUpperCase();
    String upperValue = value.toUpperCase();

    if (_lastSearchKey != searchKey || _tempSearchStore.isEmpty) {
      _databaseService.searchUser(value).then((QuerySnapshot docs) {
        List<Map<String, dynamic>> queryResultSet = [];
        for (var doc in docs.docs) {
          queryResultSet.add(doc.data() as Map<String, dynamic>);
        }

        setState(() {
          _tempSearchStore = queryResultSet.where((element) {
            return element['username'].toString().startsWith(upperValue);
          }).toList();
        });
      });
    } else {
      setState(() {
        _tempSearchStore = _tempSearchStore.where((element) {
          return element['username'].toString().startsWith(upperValue);
        }).toList();
      });
    }

    setState(() {
      _lastSearchKey = searchKey;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PrincipalPage()),
      );
    }
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TableroPage()),
      );
    }
    // Aquí podrías añadir 'else if' para los otros botones (Mapa, Notificaciones, etc.)
    // else if (index == 1) {
    //   Navigator.push(context, MaterialPageRoute(builder: (context) => const MapaPage()));
    // }
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
      onTap: () async {
        setState(() {
          _search = false;
          _searchController.clear();
        });

        final chatRoomId = await _chatController.getOrCreateChatRoom(
          data["username"],
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              name: data["Name"],
              profileurl: data["Image"],
              username: data["username"],
            ),
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
                child: Column(
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
                          _initializeSearch(value.toUpperCase());
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search),
                          hintText: "Buscar Nombre...",
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // LISTA DE RESULTADOS DE BÚSQUEDA O CHATS
                    Expanded(
                      child: _search
                          ? ListView(
                              padding: const EdgeInsets.only(
                                left: 10.0,
                                right: 10.0,
                              ),
                              primary: false,
                              shrinkWrap: true,
                              children: _tempSearchStore.map((element) {
                                return _buildResultCard(element, context);
                              }).toList(),
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
      // BARRA DE NAVEGACIÓN INFERIOR AGREGADA
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 79, 191, 219),
        type: BottomNavigationBarType
            .fixed, // Necesario para más de 3 items con color fijo
        selectedItemColor: Colors.white, // Color del ícono activo
        unselectedItemColor: Colors.white.withOpacity(
          0.5,
        ), // Color de íconos inactivos
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        showSelectedLabels: false, // Ocultar etiquetas para un look más limpio
        showUnselectedLabels: false,
        elevation: 0, // Elimina la sombra superior si lo deseas más plano
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notificaciones',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
