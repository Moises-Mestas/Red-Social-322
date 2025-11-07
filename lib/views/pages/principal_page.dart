// lib/views/pages/principal_page.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3/controllers/post_controller.dart';
import 'package:flutter_application_3/models/comment_model.dart'; // <-- AÑADIDO
import 'package:flutter_application_3/models/post_model.dart';
import 'package:flutter_application_3/services/shared_pref_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key});

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  final PostController _postController = PostController();
  final SharedPrefService _sharedPrefService = SharedPrefService();
  final ImagePicker _picker = ImagePicker();

  String? _myUserId;
  File? _imageToPost;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMyUserId();
    // Configurar 'timeago' para español
    timeago.setLocaleMessages('es', timeago.EsMessages());
  }

  void _loadMyUserId() async {
    _myUserId = await _sharedPrefService.getUserId();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Muro'),
        backgroundColor: const Color.fromARGB(255, 79, 191, 219),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildFeed(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostModal,
        backgroundColor: const Color.fromARGB(255, 79, 191, 219),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Widget que construye el feed
  Widget _buildFeed() {
    if (_myUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _postController.getPostsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No hay publicaciones. ¡Sé el primero!"));
        }

        // Tenemos datos, construimos la lista
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            PostModel post = PostModel.fromMap(snapshot.data!.docs[index]);
            return _buildPostWidget(post);
          },
        );
      },
    );
  }

  // Widget que construye CADA publicación
  Widget _buildPostWidget(PostModel post) {
    bool isLiked = post.likes.contains(_myUserId);
    String timeAgo = timeago.format(post.createdAt.toDate(), locale: 'es');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER (Foto, Nombre, Hora) ---
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(post.userImageUrl.isNotEmpty
                      ? post.userImageUrl
                      : 'https://via.placeholder.com/150'), // una imagen placeholder
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),

            // --- CUERPO (Texto e Imagen) ---
            if (post.text.isNotEmpty)
              Text(post.text, style: const TextStyle(fontSize: 16)),
            
            if (post.imageUrl != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ],
            const SizedBox(height: 10),
            Divider(),

            // --- FOOTER (Like y Comentario) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.start, // <-- MODIFICADO
              children: [
                // --- Botón de Like ---
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        // ¡Aquí está la lógica de like!
                        _postController.toggleLike(post.id, post.likes);
                      },
                    ),
                    Text("${post.likes.length}"), // <-- MODIFICADO
                  ],
                ),
                const SizedBox(width: 20),

                // --- NUEVO: Botón de Comentario ---
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.mode_comment_outlined, color: Colors.grey),
                      onPressed: () {
                        // Función que abre el modal
                        _showCommentsModal(context, post.id); 
                      },
                    ),
                  Text("${post.commentCount}"),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Método para mostrar el modal de crear publicación
  void _showCreatePostModal() {
    // Limpiamos los campos anteriores
    _textController.clear();
    setState(() {
      _imageToPost = null;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Para que el teclado no tape
      builder: (context) {
        // Usamos un StatefulWidget para el modal, para manejar el estado de la imagen
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Crear Publicación", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: "¿Qué estás pensando?",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 10),
                  
                  // Mostrar la imagen seleccionada
                  if (_imageToPost != null)
                    Image.file(
                      _imageToPost!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.image),
                        label: const Text("Adjuntar Imagen"),
                        onPressed: () async {
                          final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            modalSetState(() { // Actualiza solo el modal
                              _imageToPost = File(image.path);
                            });
                          }
                        },
                      ),
                      ElevatedButton(
                        child: const Text("Publicar"),
                        onPressed: () async {
                          if (_textController.text.isEmpty && _imageToPost == null) {
                            // No publicar si está vacío
                            return;
                          }
                          
                          // Mostrar Carga
                          Navigator.pop(context); // Cierra el modal
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Publicando..."))
                          );
                          
                          // Llamar al controlador
                          await _postController.createPost(
                            _textController.text,
                            _imageToPost,
                          );
                          
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- NUEVA FUNCIÓN: Mostrar Modal de Comentarios ---
  void _showCommentsModal(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Importante para que el modal suba con el teclado
      backgroundColor: Colors.transparent, // Para bordes redondeados
      builder: (context) {
        // Usamos un DraggableScrollableSheet para un modal que ocupe 
        // la mayor parte de la pantalla y sea "scrollable"
        return DraggableScrollableSheet(
          initialChildSize: 0.8, // Ocupa el 80% de la pantalla
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            // Devolvemos nuestro nuevo widget Stateful
            return _CommentsModalContent(
              postId: postId,
              postController: _postController,
              myUserId: _myUserId!,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }
} // --- FIN DE LA CLASE _PrincipalPageState ---


// --- NUEVO WIDGET INTERNO PARA MANEJAR EL MODAL DE COMENTARIOS ---
// (Puesto aquí, al final del archivo)
//
class _CommentsModalContent extends StatefulWidget {
  final String postId;
  final PostController postController;
  final String myUserId;
  final ScrollController scrollController;

  const _CommentsModalContent({
    required this.postId,
    required this.postController,
    required this.myUserId,
    required this.scrollController,
  });

  @override
  State<_CommentsModalContent> createState() => _CommentsModalContentState();
}

class _CommentsModalContentState extends State<_CommentsModalContent> {
  final TextEditingController _commentController = TextEditingController();
  
  // Estado para manejar a quién estamos respondiendo
  String? _replyingToCommentId; // ID del comentario al que respondemos
  String? _replyingToUserName; // Nombre del usuario al que respondemos

  // Cancela el modo "Respuesta"
  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
      _commentController.clear();
    });
  }

  // Envía el comentario o la respuesta
  void _sendComment() {
    if (_commentController.text.isEmpty) return;

    widget.postController.addComment(
      postId: widget.postId,
      text: _commentController.text,
      parentCommentId: _replyingToCommentId, // Será null o un ID
    );
    
    // Limpiar
    _cancelReply();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // --- Header del Modal ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Comentarios",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          Divider(height: 1),

          // --- Lista de Comentarios ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.postController.getCommentsStream(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No hay comentarios."));
                }

                // --- Lógica para agrupar comentarios y respuestas ---
                final allComments = snapshot.data!.docs
                    .map((doc) => CommentModel.fromMap(doc))
                    .toList();

                final topLevelComments = allComments
                    .where((c) => c.parentCommentId == null)
                    .toList();
                
                final replies = allComments
                    .where((c) => c.parentCommentId != null)
                    .toList();

                // Agrupamos las respuestas por su 'parentCommentId'
                final Map<String, List<CommentModel>> repliesMap = {};
                for (var reply in replies) {
                  if (!repliesMap.containsKey(reply.parentCommentId)) {
                    repliesMap[reply.parentCommentId!] = [];
                  }
                  repliesMap[reply.parentCommentId!]!.add(reply);
                }
                // --- Fin de la lógica de agrupación ---

                return ListView.builder(
                  controller: widget.scrollController,
                  itemCount: topLevelComments.length,
                  itemBuilder: (context, index) {
                    final comment = topLevelComments[index];
                    final commentReplies = repliesMap[comment.id] ?? []; 

                    return _buildCommentTile(
                      comment,
                      commentReplies, // Pasamos las respuestas
                    );
                  },
                );
              },
            ),
          ),

          // --- Input para Comentar/Responder ---
          _buildCommentInputArea(),
        ],
      ),
    );
  }

  // Widget para CADA comentario (y sus respuestas anidadas)
  Widget _buildCommentTile(CommentModel comment, List<CommentModel> replies) {
    bool isLiked = comment.likes.contains(widget.myUserId);
    String timeAgo = timeago.format(comment.createdAt.toDate(), locale: 'es');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- El comentario principal ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(comment.userImageUrl.isNotEmpty
                    ? comment.userImageUrl
                    : 'https://via.placeholder.com/150'), // Placeholder
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(comment.text),
                    Row(
                      children: [
                        Text(timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            // Al tocar "Responder", actualizamos el estado
                            setState(() {
                              _replyingToCommentId = comment.id;
                              _replyingToUserName = comment.userName;
                            });
                          },
                          child: const Text("Responder", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Like del comentario
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                      size: 16,
                    ),
                    onPressed: () {
                      widget.postController.toggleCommentLike(
                        postId: widget.postId, 
                        commentId: comment.id, 
                        currentLikes: comment.likes
                      );
                    },
                  ),
                  Text(comment.likes.length.toString(), style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          
          // --- Las respuestas a ese comentario ---
          if (replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40.0, top: 8.0),
              child: Column(
                children: replies.map((reply) => _buildReplyTile(reply)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // Widget para CADA respuesta (más simple)
  Widget _buildReplyTile(CommentModel reply) {
    bool isLiked = reply.likes.contains(widget.myUserId);
    String timeAgo = timeago.format(reply.createdAt.toDate(), locale: 'es');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: NetworkImage(reply.userImageUrl.isNotEmpty
                ? reply.userImageUrl
                : 'https://via.placeholder.com/150'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reply.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(reply.text, style: const TextStyle(fontSize: 13)),
                Text(timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
          // Like de la respuesta
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.grey,
                  size: 14,
                ),
                onPressed: () {
                  widget.postController.toggleCommentLike(
                    postId: widget.postId, 
                    commentId: reply.id, 
                    currentLikes: reply.likes
                  );
                },
              ),
              Text(reply.likes.length.toString(), style: const TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
  
  // Widget para el área de input de texto en el modal
  Widget _buildCommentInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, 
        right: 8, 
        top: 8, 
        bottom: 8 + MediaQuery.of(context).viewInsets.bottom, // Sube con el teclado
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Muestra a quién estás respondiendo
          if (_replyingToCommentId != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Respondiendo a $_replyingToUserName...",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: _cancelReply,
                )
              ],
            ),
          // El campo de texto y botón de enviar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: _replyingToCommentId != null 
                        ? "Escribe tu respuesta..."
                        : "Añade un comentario...",
                    border: InputBorder.none,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Color.fromARGB(255, 79, 191, 219)),
                onPressed: _sendComment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}