// lib/views/pages/story_view_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_3/controllers/story_controller.dart';
import 'package:timeago/timeago.dart' as timeago;

class StoryViewPage extends StatefulWidget {
  final String userId;
  const StoryViewPage({super.key, required this.userId});

  @override
  State<StoryViewPage> createState() => _StoryViewPageState();
}

class _StoryViewPageState extends State<StoryViewPage> {
  final StoryController _storyController = StoryController();
  final PageController _pageController = PageController();
  List<DocumentSnapshot> _stories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    try {
      final snapshot = await _storyController.getActiveStoriesStream(widget.userId).first;
      setState(() {
        _stories = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print("Error cargando historias: $e");
      Navigator.pop(context); // Salir si hay error
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stories.isEmpty
              ? const Center(child: Text("No hay historias", style: TextStyle(color: Colors.white)))
              : PageView.builder(
                  controller: _pageController,
                  itemCount: _stories.length,
                  itemBuilder: (context, index) {
                    return _buildStoryItem(_stories[index]);
                  },
                ),
    );
  }

  Widget _buildStoryItem(DocumentSnapshot storyDoc) {
    final data = storyDoc.data() as Map<String, dynamic>;
    final storyType = data['type'] ?? 'text';
    final mediaUrl = data['mediaUrl'];
    final text = data['text'] ?? '';
    final username = data['username'] ?? '...';
    final userImageUrl = data['userImageUrl'] ?? '';
    final timeAgo = timeago.format((data['createdAt'] as Timestamp).toDate(), locale: 'es');

    return GestureDetector(
      // Lógica simple de navegación
      onTapUp: (details) {
        final width = MediaQuery.of(context).size.width;
        if (details.globalPosition.dx < width / 3) {
          // Tap Izquierda: Anterior
          if (_pageController.page! > 0) {
            _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
          }
        } else {
          // Tap Derecha: Siguiente
          if (_pageController.page! < _stories.length - 1) {
            _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
          } else {
            Navigator.pop(context); // Última historia, salir
          }
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo (Imagen o Color)
          if (storyType == 'image' && mediaUrl != null)
            Image.network(
              mediaUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            )
          else
            Container(color: Colors.deepPurple), // Color de fondo para historias de texto

          // Contenido (Texto)
          if (text.isNotEmpty)
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: storyType == 'image' ? Colors.black.withOpacity(0.5) : Colors.transparent,
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          
          // Header (Info del usuario)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: userImageUrl.isNotEmpty ? NetworkImage(userImageUrl) : null,
                      child: userImageUrl.isEmpty ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 10),
                    Text(username, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Text(timeAgo, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}