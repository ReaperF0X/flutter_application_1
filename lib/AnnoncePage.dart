import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ProfilVendeurPage.dart';

class AnnoncePage extends StatefulWidget {
  final String annonceId;

  const AnnoncePage({super.key, required this.annonceId});

  @override
  _AnnoncePageState createState() => _AnnoncePageState();
}

class _AnnoncePageState extends State<AnnoncePage> {
  bool isFavorite = false;
  String? userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    _checkIfFavorite();
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
    if (userId == null) return;

    if (isFavorite) {
      // Supprimer des favoris
      final favQuery = await FirebaseFirestore.instance
          .collection('favoris')
          .where('userId', isEqualTo: userId)
          .where('annonceId', isEqualTo: widget.annonceId)
          .get();

      for (var doc in favQuery.docs) {
        await FirebaseFirestore.instance.collection('favoris').doc(doc.id).delete();
      }
    } else {
      // Ajouter aux favoris
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Détail de l'annonce")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('annonces').doc(widget.annonceId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Annonce introuvable."));
          }

          final annonce = snapshot.data!.data() as Map<String, dynamic>;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(annonce['imageUrl'], height: 250, fit: BoxFit.cover),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(annonce['titre'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text("${annonce['prix']} €", style: const TextStyle(fontSize: 20, color: Colors.green)),
                    Text("Catégorie: ${annonce['categorie']}", style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 10),
                    Text(annonce['description']),
                    const SizedBox(height: 10),

                    // ✅ Bouton pour voir le profil du vendeur
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => ProfilVendeurPage(vendeurId: annonce['userId']),
                        ));
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
          );
        },
      ),
    );
  }
}
