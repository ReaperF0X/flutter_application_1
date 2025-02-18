import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AnnoncePage.dart'; // ✅ Importation de la page des détails d'annonce

class AnnonceVendeurPage extends StatelessWidget {
  final String vendeurId;

  const AnnonceVendeurPage({super.key, required this.vendeurId});

  @override
  Widget build(BuildContext context) {
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
    );
  }
}
