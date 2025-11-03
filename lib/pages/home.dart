import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3/pages/chat_page.dart';
import 'package:flutter_application_3/pages/profile.dart';
import 'package:flutter_application_3/services/database.dart';
import 'package:flutter_application_3/services/shared_pref.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? myUsername, myName, myEmail, mypicture;
  Stream? chatRoomsStream;

  getthesahredpref() async {
    myUsername = await SharedpreferencesHelper().getUserName();
    myName = await SharedpreferencesHelper().getUserDisplayName();
    myEmail = await SharedpreferencesHelper().getUserEmail();
    mypicture = await SharedpreferencesHelper().getUserImage();
    print(myUsername);
    setState(() {});
  }

  ontheload() async {
    await getthesahredpref();
    chatRoomsStream = await DatabaseMethods().getChatRooms();
    setState(() {});
  }

  @override
  void initState() {
    ontheload();
    super.initState();
  }

  // Función que construye la lista de chats
Widget chatRoomList() {
  return StreamBuilder(
    stream: chatRoomsStream,
    builder: (context, AsyncSnapshot snapshot) {
      // Revisamos si la conexión está esperando
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      // Verificamos si no hay datos o si la lista está vacía
      if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
        return Center(child: Text("No tienes chats disponibles"));
      }

      // Imprimimos los datos de snapshot para depuración
      print('snapshot.data.docs: ${snapshot.data.docs}');
      
      return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: snapshot.data.docs.length,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          DocumentSnapshot ds = snapshot.data.docs[index];
          
          // Imprimimos la información de cada chat para depuración
          print('Chat ${index + 1}: ${ds.id} | Último mensaje: ${ds["lastMessage"]} | Hora: ${ds["lastMessageSendTs"]}');

          return ChatRoomListTile(
            chatRoomId: ds.id,
            lastMessage: ds["lastMessage"],
            myUsername: myUsername!,
            time: ds["lastMessageSendTs"],  // Verifica si esta propiedad existe en Firestore
          );
        },
      );
    },
  );
}


  TextEditingController searchController = TextEditingController();
  bool search = false;

  var queryResultSet = [];
  var tempSearchStore = [];
  String lastSearchKey = "";

  getChatRoomIdbyUsername(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  initializeSearch(String value) {
    if (value.isEmpty) {
      setState(() {
        queryResultSet = [];
        tempSearchStore = [];
        search = false;
        lastSearchKey = "";
      });
      return;
    }

    setState(() {
      search = true;
    });

    String searchKey = value.substring(0, 1).toUpperCase();
    String upperValue = value.toUpperCase();

    if (lastSearchKey != searchKey || queryResultSet.isEmpty) {
      DatabaseMethods().Search(value).then((QuerySnapshot docs) {
        queryResultSet.clear();
        for (int i = 0; i < docs.docs.length; ++i) {
          queryResultSet.add(docs.docs[i].data());
        }

        setState(() {
          tempSearchStore = queryResultSet.where((element) {
            return element['username'].startsWith(upperValue);
          }).toList();
        });
      });
    } else {
      setState(() {
        tempSearchStore = queryResultSet.where((element) {
          return element['username'].startsWith(upperValue);
        }).toList();
      });
    }

    setState(() {
      lastSearchKey = searchKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 79, 191, 219),
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
                ],
              ),
            ),
            const SizedBox(height: 10.0),

            // TITULO
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
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Row(
                children: [
                  const Text(
                    "AquiNomas",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
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
                ],
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
                        controller: searchController,
                        onChanged: (value) {
                          initializeSearch(value.toUpperCase());
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
                      child: search
                          ? ListView(
                              padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                              primary: false,
                              shrinkWrap: true,
                              children: tempSearchStore.map((element) {
                                return buildResultCard(element, context);
                              }).toList(),
                            )
                          : chatRoomList(), // Mostrar los chats recientes
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MÉTODO PARA CREAR UNA TARJETA DE CADA CHAT
  Widget buildResultCard(Map<String, dynamic> data, BuildContext context) {
    return GestureDetector(
      onTap: () async {
        setState(() {
          search = false;
          searchController.clear();
        });

        var chatRoomId = getChatRoomIdbyUsername(myUsername!, data["username"]);

        Map<String, dynamic> chatInfoMap = {
          "users": [myUsername, data["username"]],
        };
        await DatabaseMethods().createChatRoom(chatRoomId, chatInfoMap);
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
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Material(
          elevation: 5.0,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.all(18),
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
                  ),
                ),
                SizedBox(
                  width: 20.0,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data["Name"],
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                    SizedBox(
                      height: 8.0,
                    ),
                    Text(
                      data["username"],
                      style: TextStyle(
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
}




class ChatRoomListTile extends StatefulWidget {
  final String lastMessage, chatRoomId, myUsername, time;

  ChatRoomListTile({
    required this.chatRoomId,
    required this.lastMessage,
    required this.myUsername,
    required this.time,
  });

  @override
  State<ChatRoomListTile> createState() => _ChatRoomListTileState();
}

class _ChatRoomListTileState extends State<ChatRoomListTile> {
  String profilePicUrl = "", name = "", username = "", id = "";

 @override
  void initState() {
    super.initState();
    getthisUserInfo(); // Llama a la función para obtener los datos al cargar el widget
  }

  // Método para obtener la información del usuario en el chat
getthisUserInfo() async {
  username = widget.chatRoomId.replaceAll("_", "").replaceAll(widget.myUsername, "");
  QuerySnapshot querySnapshot = await DatabaseMethods().getUserInfo(username);
  if (!mounted) return;  // Verifica si el widget está montado antes de llamar a setState()
  name = querySnapshot.docs[0]["Name"];
  profilePicUrl = querySnapshot.docs[0]["Image"];
  id = querySnapshot.docs[0]["Id"];
  setState(() {});  // Actualiza el estado si el widget está montado
}

 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Cuando se hace tap en un chat, navega a la página del chat específico
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              name: name,
              profileurl: profilePicUrl,
              username: username,
            ),
          ),
        );
      },
      child: Material(
        elevation: 3.0,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          width: MediaQuery.of(context).size.width,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Muestra la imagen de perfil si está disponible
              profilePicUrl == ""
                  ? const CircularProgressIndicator() // Si no hay foto, muestra un loader
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Image.network(
                        profilePicUrl,
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
              const SizedBox(width: 20.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10.0),
                  Text(
                    name, // Muestra el nombre del usuario
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.lastMessage, // Muestra el último mensaje
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color.fromARGB(151, 0, 0, 0),
                      fontSize: 18.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                widget.time, // Muestra la hora del último mensaje
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
