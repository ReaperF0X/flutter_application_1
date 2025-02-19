import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'HomePage.dart';
import 'FavoritePage.dart';
import 'PostPage.dart';
import 'MessagesPage.dart';
import 'ProfilePage.dart';
import 'LoginPage.dart';
import 'RegisterPage.dart';
import 'ChangePasswordPage.dart';
import 'EditProfilePage.dart';
import 'AnnoncePage.dart';
import 'ProfilVendeurPage.dart';
import 'MesAnnoncesPage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ICAM Marketplace',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      initialRoute: '/', // ✅ Définit la route principale
      routes: {
        '/': (context) => const NavigationWrapper(),
        '/login': (context) => const LoginPage(), // ✅ Redirige directement vers LoginPage
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const NavigationWrapper(),
        '/change-password': (context) => const ChangePasswordPage(),
        '/edit-profile': (context) => const EditProfilePage(),
        '/post': (context) => const NavigationWrapper(initialIndex: 2),
        '/annonce': (context) => const NavigationWrapper(initialIndex: 6),
        '/vendeur': (context) => const NavigationWrapper(initialIndex: 7),
        '/mes-annonces': (context) => const MesAnnoncesPage(),
        //'/mes-annonces': (context) => NavigationWrapper(),
        '/favoris': (context) => const FavoritePage(),
        '/messages': (context) => const MessagesPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}

/// ✅ **Gestion centralisée de la navigation avec le ruban**
class NavigationWrapper extends StatefulWidget {
  final int initialIndex;

  const NavigationWrapper({super.key, this.initialIndex = 0});

  @override
  _NavigationWrapperState createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    const HomePage(), // ✅ Accessible sans connexion
    const FavoritePage(), // 🔒 Protégé
    const PostPage(), // 🔒 Protégé
    const MessagesPage(), // 🔒 Protégé
    const ProfilePage(), // 🔒 Protégé
    const AnnoncePage(annonceId: ""), // ✅ Page annonce libre
    const ProfilVendeurPage(vendeurId: ""), // ✅ Page vendeur libre
    const LoginPage(),
  ];

  void _onItemTapped(int index) {
    final user = FirebaseAuth.instance.currentUser;

    // ✅ Redirection vers Login si une action protégée est tentée sans connexion
    if ((index == 1 || index == 2 || index == 3 || index == 4) && user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login'); // ✅ Redirige vers login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('ICAM Marketplace'),
        actions: [
          if (FirebaseAuth.instance.currentUser != null)
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.red),
            ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmarks), label: 'Favoris'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Publier'),
          BottomNavigationBarItem(icon: Icon(Icons.question_answer), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profil'),
        ],
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.black54,
      ),
    );
  }
}
