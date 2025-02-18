import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ChangePasswordPage.dart';
import 'EditProfilePage.dart';
import 'MesAnnoncesPage.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  /// ✅ Récupération des informations de l'utilisateur connecté
  Future<Map<String, dynamic>> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return doc.exists ? doc.data() ?? {} : {};
    }
    return {};
  }

  /// ✅ Déconnexion de l'utilisateur
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final userData = snapshot.data ?? {};
          final username = userData['username'] ?? 'Utilisateur inconnu';
          final email = userData['email'] ?? 'Aucun email';
          final photoUrl = userData['photoUrl'] ?? '';

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ Image de profil ou icône par défaut
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: (photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl.isEmpty)
                        ? const Icon(Icons.person, size: 50) // Icône par défaut si pas de photo
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // ✅ Nom d'utilisateur
                  Text(
                    username,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  // ✅ Email de l'utilisateur
                  Text(
                    email,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),

                  const SizedBox(height: 32),

                  // ✅ Bouton pour gérer les annonces
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (context) => const MesAnnoncesPage()),
                    ),
                    child: const Text('Gérer mes annonces'),
                  ),

                  const SizedBox(height: 16),

                  // ✅ Bouton pour modifier le profil
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (context) => const EditProfilePage()),
                    ),
                    child: const Text('Modifier le profil'),
                  ),

                  const SizedBox(height: 16),

                  // ✅ Bouton pour changer le mot de passe
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                    ),
                    child: const Text('Changer le mot de passe'),
                  ),

                  const SizedBox(height: 16),

                  // ✅ Bouton de déconnexion
                  ElevatedButton(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
