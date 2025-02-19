import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AnnoncePage.dart'; // ✅ Importation de la page des détails d'annonce
import 'LoginPage.dart'; // ✅ Importation de la page de connexion

class AnnonceVendeurPage extends StatelessWidget {
  final String vendeurId;

  const AnnonceVendeurPage({super.key, required this.vendeurId});

  /// ✅ Redirige les utilisateurs non connectés vers la page de connexion
  void _redirectToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Annonces du vendeur")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('annonces')
            .where('userId', isEqualTo: vendeurId) // ✅ Filtre les annonces du vendeur
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final annonces = snapshot.data!.docs;

          if (annonces.isEmpty) {
            return const Center(child: Text("Aucune annonce publiée par ce vendeur."));
          }

          return ListView.builder(
            itemCount: annonces.length,
            itemBuilder: (context, index) {
              final annonce = annonces[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: annonce['imageUrl'] != null
                      ? Image.network(annonce['imageUrl'], width: 80, height: 80, fit: BoxFit.cover)
                      : const Icon(Icons.image, size: 50),
                  title: Text(annonce['titre'] ?? "Titre inconnu"),
                  subtitle: Text("${annonce['prix']?.toStringAsFixed(2) ?? "0.00"} €"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnnoncePage(annonceId: annonces[index].id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // L'index dépend de l'endroit où vous vous trouvez
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            userId == null ? _redirectToLogin(context) : Navigator.pushReplacementNamed(context, '/favoris');
          } else if (index == 2) {
            userId == null ? _redirectToLogin(context) : Navigator.pushReplacementNamed(context, '/post');
          } else if (index == 3) {
            userId == null ? _redirectToLogin(context) : Navigator.pushReplacementNamed(context, '/messages');
          } else if (index == 4) {
            userId == null ? _redirectToLogin(context) : Navigator.pushReplacementNamed(context, '/profile');
          }
        },
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
