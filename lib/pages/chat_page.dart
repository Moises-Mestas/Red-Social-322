import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String username;  // Recibe el username del otro usuario

  // Constructor para recibir el username
  const ChatPage({super.key, required this.username});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff703eff),
        title: Text(widget.username), // Muestra el username de la persona con la que chateas
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Vuelve a la página anterior
          },
        ),
      ),
      body: Column(
        children: [
          // Aquí iría la lista de mensajes, por ahora está vacío
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              color: const Color(0xFFececf8), // Color de fondo de los mensajes
              child: ListView(), // Aquí se mostrarían los mensajes
            ),
          ),

          // Barra de texto para escribir el mensaje
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Icono de micrófono dentro de un círculo con fondo, ahora clickeable
                GestureDetector(
                  onTap: () {
                    // Lógica del micrófono (por ahora solo muestra un mensaje en la consola)
                    print("Micrófono presionado");
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xff703eff), // Fondo morado
                      shape: BoxShape.circle, // Forma circular
                    ),
                    child: const Icon(
                      Icons.mic,
                      size: 28.0,
                      color: Colors.white, // Color del ícono
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),

                // Contenedor para la barra de texto
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFececf8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [

                        Expanded(
                          child: TextField(
                            controller: messageController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Escribe un mensaje...",
                            ),
                          ),
                        ),
                        // Botón de clip dentro del campo de texto
                        GestureDetector(
                          onTap: () {
                            // Aquí se manejaría la acción para cargar imágenes
                            print("Botón de cargar imagen presionado");
                          },
                          child: const Icon(
                            Icons.attach_file,
                            color: Color(0xff703eff),
                          ),
                        ),
                        const SizedBox(width: 10.0), // Espacio entre el clip y el campo de texto

                        // Campo de texto para escribir el mensaje
                        
                      ],
                    ),
                  ),
                ),
                // Icono de enviar mensaje
                IconButton(
                  onPressed: () {
                    // Aquí irá la lógica para enviar el mensaje, por ahora no hace nada
                    print("Mensaje enviado: ${messageController.text}");
                    messageController.clear(); // Limpia el campo de texto
                  },
                  icon: const Icon(Icons.send, color: Color(0xff703eff)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
