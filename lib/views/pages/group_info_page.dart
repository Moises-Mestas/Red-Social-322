// lib/views/pages/group_info_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_3/controllers/group_controller.dart';
import 'package:flutter_application_3/services/shared_pref_service.dart';
import 'package:flutter_application_3/views/pages/home_page.dart';
import 'package:flutter_application_3/views/pages/user_profile_page.dart';
import 'package:image_picker/image_picker.dart';

class GroupInfoPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupInfoPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  final GroupController _groupController = GroupController();
  final SharedPrefService _sharedPrefService = SharedPrefService();
  final ImagePicker _picker = ImagePicker();
  
  // --- AÑADIDO ---
  final TextEditingController _nameEditController = TextEditingController();

  String? _myUsername;
  Stream<DocumentSnapshot>? _groupStream;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  // --- AÑADIDO ---
  @override
  void dispose() {
    _nameEditController.dispose();
    super.dispose();
  }

  void _loadData() async {
    setState(() {
      _isLoading = true;
    });
    _myUsername = await _sharedPrefService.getUserName();
    _groupStream = _groupController.getGroupDetailsStream(widget.groupId);
    setState(() {
      _isLoading = false;
    });
  }

  // --- AÑADIDO ---
  Future<void> _showEditNameDialog(String currentName) async {
    _nameEditController.text = currentName; 

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar nombre del grupo'),
        content: TextField(
          controller: _nameEditController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nuevo nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (_nameEditController.text.isNotEmpty) {
                Navigator.pop(context, _nameEditController.text);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      setState(() { _isLoading = true; });
      try {
        await _groupController.updateGroupName(widget.groupId, newName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nombre actualizado'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }
  // --- FIN DE AÑADIDO ---

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;

    setState(() { _isLoading = true; });
    try {
      await _groupController.updateGroupPhoto(widget.groupId, File(image.path));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto del grupo actualizada'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _kickUser(String username) async {
    final confirm = await _showConfirmationDialog(
      '¿Expulsar a $username?',
      'Esta acción no se puede deshacer.',
    );
    if (confirm != true) return;

    setState(() { _isLoading = true; });
    try {
      await _groupController.removeUserFromGroup(widget.groupId, username);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$username ha sido expulsado'), backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      // (manejo de error)
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _leaveGroup() async {
    final confirm = await _showConfirmationDialog(
      '¿Salir del grupo?',
      'No podrás ver más mensajes de este grupo.',
    );
    if (confirm != true || _myUsername == null) return;

    setState(() { _isLoading = true; });
    try {
      await _groupController.removeUserFromGroup(widget.groupId, _myUsername!);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      // (manejo de error)
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<bool?> _showConfirmationDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // El título se actualizará automáticamente
        title: StreamBuilder<DocumentSnapshot>(
          stream: _groupStream,
          builder: (context, snapshot) {
             if (snapshot.hasData && snapshot.data!.exists) {
                var data = snapshot.data!.data() as Map<String, dynamic>;
                return Text(data['name'] ?? widget.groupName);
             }
             return Text(widget.groupName);
          }
        ),
        centerTitle: true,
      ),
      body: _isLoading || _groupStream == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DocumentSnapshot>(
              stream: _groupStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Este grupo ya no existe.'));
                }

                var data = snapshot.data!.data() as Map<String, dynamic>;
                List<String> users = List<String>.from(data['users'] ?? []);
                String creator = users.isNotEmpty ? users[0] : 'N/A';
                String imageUrl = data['imageUrl'] ?? '';
                String groupName = data['name'] ?? widget.groupName; // <-- Obtener nombre
                bool amICreator = (_myUsername == creator);

                return ListView(
                  children: [
                    _buildGroupHeader(imageUrl, groupName, amICreator),
                    const Divider(height: 1),
                    _buildCreatorSection(creator),
                    const Divider(height: 1),
                    _buildParticipantsSection(users.sublist(1), amICreator),
                    const Divider(height: 1),
                    _buildLeaveButton(),
                  ],
                );
              },
            ),
    );
  }

  // --- WIDGET MODIFICADO ---
  Widget _buildGroupHeader(String imageUrl, String name, bool amICreator) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: amICreator ? _pickAndUploadImage : null,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  backgroundColor: Colors.grey[300],
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.group, size: 60, color: Colors.grey)
                      : null,
                ),
                if (amICreator)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // --- INICIO DE LA MODIFICACIÓN ---
          GestureDetector(
            onTap: amICreator ? () => _showEditNameDialog(name) : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, 
              children: [
                Flexible(
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (amICreator)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.edit, size: 20, color: Colors.grey),
                  ),
              ],
            ),
          ),
          // --- FIN DE LA MODIFICACIÓN ---
        ],
      ),
    );
  }

  Widget _buildCreatorSection(String creator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Creador',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xffD32323)),
          ),
        ),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(creator),
          subtitle: const Text('Administrador'),
          onTap: () => _navigateToProfile(creator),
        ),
      ],
    );
  }

  Widget _buildParticipantsSection(List<String> participants, bool amICreator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Participantes (${participants.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: participants.length,
          itemBuilder: (context, index) {
            final username = participants[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(username),
              onTap: () => _navigateToProfile(username),
              trailing: (amICreator && !_isLoading)
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      tooltip: 'Expulsar',
                      onPressed: () => _kickUser(username),
                    )
                  : null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildLeaveButton() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.exit_to_app, color: Colors.red),
        label: const Text(
          'Salir del Grupo',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isLoading ? null : _leaveGroup,
      ),
    );
  }

  // --- LÓGICA DE NAVEGACIÓN CORREGIDA ---
  void _navigateToProfile(String username) {
    // Esta es tu lógica original, que funciona y no da errores.
    if (username == _myUsername) {
      // Si es mi perfil, podemos usar UserProfilePage también.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfilePage(username: username),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfilePage(username: username),
        ),
      );
    }
  }
}