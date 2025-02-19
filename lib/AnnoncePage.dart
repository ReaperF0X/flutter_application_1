import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ProfilVendeurPage.dart';
import 'LoginPage.dart'; // ✅ Importation de la page de connexion

class AnnoncePage extends StatefulWidget {
  final String annonceId;

  const AnnoncePage({super.key, required this.annonceId});

  @override
  _AnnoncePageState createState() => _AnnoncePageState();
}

class _AnnoncePageState extends State<AnnoncePage> {
  bool isFavorite = false;
  String? userId;
  Map<String, dynamic>? annonceData;
  String vendeurNom = "Vendeur inconnu";
  String datePublication = "";

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    _loadAnnonceData();
    _checkIfFavorite();
  }

  /// ✅ Charge les détails de l'annonce et récupère le nom du vendeur
  Future<void> _loadAnnonceData() async {
    final doc = await FirebaseFirestore.instance.collection('annonces').doc(widget.annonceId).get();
    if (doc.exists) {
      final data = doc.data()!;
      final vendeurId = data['userId'];

      // ✅ Récupérer le nom du vendeur
      final vendeurDoc = await FirebaseFirestore.instance.collection('users').doc(vendeurId).get();
      if (vendeurDoc.exists) {
        setState(() {
          vendeurNom = vendeurDoc.data()?['username'] ?? "Vendeur inconnu";
        });
      }

      // ✅ Convertir la date Firebase en format lisible
      final Timestamp timestamp = data['date'];
      final DateTime date = timestamp.toDate();
      datePublication = "${date.day}/${date.month}/${date.year}";

      setState(() {
        annonceData = data;
      });
    }
  }

  /// ✅ Vérifie si l'annonce est déjà en favori
  Future<void> _checkIfFavorite() async {
    if (userId == null) return;

    final favQuery = await FirebaseFirestore.instance
        .collection('favoris')
        .where('userId', isEqualTo: userId)
        .where('annonceId', isEqualTo: widget.annonceId)
        .get();

    setState(() {
      isFavorite = favQuery.docs.isNotEmpty;
    });
  }

  /// ✅ Ajoute ou supprime l'annonce des favoris
  Future<void> _toggleFavorite() async {
    if (userId == null) {
      _redirectToLogin();
      return;
    }

    if (isFavorite) {
      final favQuery = await FirebaseFirestore.instance
          .collection('favoris')
          .where('userId', isEqualTo: userId)
          .where('annonceId', isEqualTo: widget.annonceId)
          .get();

      for (var doc in favQuery.docs) {
        await FirebaseFirestore.instance.collection('favoris').doc(doc.id).delete();
      }
    } else {
      await FirebaseFirestore.instance.collection('favoris').add({
        'userId': userId,
        'annonceId': widget.annonceId,
      });
    }

    setState(() {
      isFavorite = !isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isFavorite ? "Ajouté aux favoris !" : "Retiré des favoris")),
    );
  }

  /// ✅ Redirige les utilisateurs non connectés vers la page de connexion
  void _redirectToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Détail de l'annonce")),
      body: annonceData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Image de l'annonce
                  Image.network(
                    annonceData!['imageUrl'],
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),

                  // ✅ Informations sur l'annonce
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          annonceData!['titre'],
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${annonceData!['prix']} €",
                          style: const TextStyle(fontSize: 20, color: Colors.green),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Catégorie: ${annonceData!['categorie']}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "État: ${annonceData!['etat']}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Publié le: $datePublication",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          annonceData!['description'],
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),

                        // ✅ Nom du vendeur et redirection vers son profil
                        Row(
                          children: [
                            const Icon(Icons.account_circle, size: 20),
                            const SizedBox(width: 5),
                            Text(
                              vendeurNom,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfilVendeurPage(vendeurId: annonceData!['userId']),
                              ),
                            );
                          },
                          child: const Text("Voir le profil du vendeur"),
                        ),
                        const SizedBox(height: 10),

                        // ✅ Gestion des favoris
                        IconButton(
                          icon: Icon(Icons.favorite, color: isFavorite ? Colors.red : Colors.grey),
                          onPressed: _toggleFavorite,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            userId == null ? _redirectToLogin() : Navigator.pushReplacementNamed(context, '/favoris');
          } else if (index == 2) {
            userId == null ? _redirectToLogin() : Navigator.pushReplacementNamed(context, '/post');
          } else if (index == 3) {
            userId == null ? _redirectToLogin() : Navigator.pushReplacementNamed(context, '/messages');
          } else if (index == 4) {
            userId == null ? _redirectToLogin() : Navigator.pushReplacementNamed(context, '/profile');
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
