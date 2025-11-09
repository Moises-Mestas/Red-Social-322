// lib/views/widgets/followers_list_dialog.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_3/controllers/followers_controller.dart';
import 'package:flutter_application_3/views/pages/user_profile_page.dart';

class FollowersListDialog extends StatelessWidget {
  final String userId;
  final bool isFollowers; // true si es lista de seguidores, false si es de seguidos
  final FollowersController followController;

  const FollowersListDialog({
    super.key,
    required this.userId,
    required this.isFollowers,
    required this.followController,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isFollowers ? 'Seguidores' : 'Siguiendo'),
      content: Container(
        width: double.maxFinite,
        height: 300, // Altura fija para el diálogo
        child: StreamBuilder<QuerySnapshot>(
          stream: isFollowers
              ? followController.getFollowersStream(userId)
              : followController.getFollowingStream(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text(isFollowers ? 'Nadie te sigue.' : 'No sigues a nadie.'));
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var doc = snapshot.data!.docs[index];
                var data = doc.data() as Map<String, dynamic>; // <-- Convertir a Map
                
                String username = data['username'];
                
                // --- INICIO DE LA MODIFICACIÓN ---
                // Lee la URL de la imagen. Si no existe (ej. en la lista de 'Siguiendo'), usa un string vacío.
                String imageUrl = data.containsKey('userImageUrl') 
                                    ? data['userImageUrl'] ?? '' 
                                    : '';
                // --- FIN DE LA MODIFICACIÓN ---

                return ListTile(
                  // --- MODIFICADO: Ahora usa CircleAvatar con NetworkImage ---
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: imageUrl.isNotEmpty 
                        ? NetworkImage(imageUrl) 
                        : null,
                    child: imageUrl.isEmpty 
                        ? const Icon(Icons.person, color: Colors.white) 
                        : null,
                  ),
                  // --- FIN DE LA MODIFICACIÓN ---
                  title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    // Cierra el diálogo
                    Navigator.pop(context);
                    // Navega al perfil de ese usuario
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfilePage(username: username),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}