import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3/pages/chat_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];

  // Función para buscar usuarios en la base de datos
  void searchUser(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = []; // Si no hay texto, no mostrar resultados
      });
      return;
    }

    // Consulta en Firestore buscando el 'username'
    final usersCollection = FirebaseFirestore.instance.collection('users');
    
    // Realiza la consulta para obtener usuarios cuyo 'username' contenga el texto ingresado
    var result = await usersCollection
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: query + '\uf8ff') // Para buscar coincidencias completas
        .get();

    setState(() {
      // Almacena los resultados en la lista
      searchResults = result.docs.map((doc) => doc.data()).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff703eff),
      body: Container(
        margin: const EdgeInsets.only(top: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    "HELLO,",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    " Moises",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 24.0, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(5),
                    margin: const EdgeInsets.only(right: 20.0),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.person, color: Color(0xff703eff), size: 30.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10.0),
            const Padding(
              padding: EdgeInsets.only(left: 20.0),
              child: Text(
                "Bienvenido a:",
                style: TextStyle(color: Color.fromARGB(195, 255, 255, 255), fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 20.0),
              child: Text(
                "ChatUp",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 40.0, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30.0),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(left: 30.0, right: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
                child: Column(
                  children: [
                    const SizedBox(height: 30.0),
                    Container(
                      decoration: BoxDecoration(color: const Color(0xFFececf8), borderRadius: BorderRadius.circular(10)),
                      child: TextField(
                        controller: searchController,
                        onChanged: searchUser, // Llama a la función de búsqueda cada vez que el texto cambia
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search),
                          hintText: "Buscar Nombre...",
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Expanded(
                    child: ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            // Aquí navegamos a la página de chat pasando el username del usuario seleccionado
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(username: searchResults[index]['username']),
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
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(60),
                                    child: Image.network(
                                      searchResults[index]['Image'], // Imagen del usuario
                                      height: 70,
                                      width: 70,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 10.0),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        searchResults[index]['Name'], // Nombre del usuario
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        searchResults[index]['Email'], // Correo electrónico del usuario
                                        style: const TextStyle(
                                          color: Color.fromARGB(190, 0, 0, 0),
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
