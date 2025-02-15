import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AnnoncePage.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('annonces').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aucune annonce disponible.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final annonce = doc.data() as Map<String, dynamic>;

              // ✅ Vérification et valeurs par défaut pour éviter les erreurs
              final String imageUrl = annonce['imageUrl'] ?? "https://via.placeholder.com/200"; // Image par défaut
              final String titre = annonce['titre'] ?? "Titre non disponible";
              final String categorie = annonce['categorie'] ?? "Non catégorisé";
              
              // ✅ Correction de l'erreur `toDouble()` avec conversion sécurisée
              double prix;
              if (annonce['prix'] is int) {
                prix = (annonce['prix'] as int).toDouble(); // Conversion int -> double
              } else if (annonce['prix'] is double) {
                prix = annonce['prix']; // Déjà un double
              } else if (annonce['prix'] is String) {
                prix = double.tryParse(annonce['prix']) ?? 0.0; // Conversion String -> double sécurisé
              } else {
                prix = 0.0; // Valeur par défaut si null
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnnoncePage(annonceId: doc.id),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network("https://via.placeholder.com/200"); // ✅ Image par défaut si erreur
                        }
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(titre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("$prix €", style: const TextStyle(fontSize: 16, color: Colors.green)),
                            Text(categorie, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
