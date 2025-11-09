import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3/services/database_service.dart';
import './views/pages/home_page.dart';
import './views/pages/onboarding_page.dart';
import 'views/pages/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquiNomas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthGate(),
      routes: {
        '/home': (_) => const HomePage(),
        '/login': (_) => const LoginPage(),
      },
    );
  }
}

// --- INICIO DE LA MODIFICACIÓN (Convertir a StatefulWidget) ---

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

// Añadimos 'with WidgetsBindingObserver' para detectar el estado de la app
class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  final DatabaseService _databaseService = DatabaseService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Inicia el observador
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Limpia el observador
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_currentUserId == null) return; // No hacer nada si no hay usuario logueado

    if (state == AppLifecycleState.resumed) {
      // App en primer plano = ONLINE
      _databaseService.updateUserPresence(_currentUserId!, true);
    } else {
      // App en segundo plano, inactiva o cerrada = OFFLINE
      _databaseService.updateUserPresence(_currentUserId!, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          
          // Guardar userId y marcar como online por primera vez
          if (_currentUserId != snapshot.data!.uid) {
             _currentUserId = snapshot.data!.uid;
             _databaseService.updateUserPresence(_currentUserId!, true);
          }
          
          return const HomePage(); // Ya autenticado
        }
        
        // Marcar como offline al cerrar sesión
        if (_currentUserId != null) {
          _databaseService.updateUserPresence(_currentUserId!, false);
          _currentUserId = null;
        }
        
        return const OnboardingPage(); // No autenticado
      },
    );
  }
}