import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'EditAnnoncePage.dart';

class MesAnnoncesPage extends StatefulWidget {
  const MesAnnoncesPage({super.key});

  @override
  _MesAnnoncesPageState createState() => _MesAnnoncesPageState();
}

class _MesAnnoncesPageState extends State<MesAnnoncesPage> {
  String? userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
  }

  /// ✅ Supprime une annonce de Firebase
  Future<void> _deleteAnnonce(String annonceId) async {
    await FirebaseFirestore.instance.collection('annonces').doc(annonceId).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Annonce supprimée avec succès")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Mes annonces")),
        body: const Center(child: Text("Veuillez vous connecter pour voir vos annonces.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Mes annonces")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('annonces')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Vous n'avez publié aucune annonce."));
          }

          final annonces = snapshot.data!.docs;

          return ListView.builder(
            itemCount: annonces.length,
            itemBuilder: (context, index) {
              final annonce = annonces[index].data() as Map<String, dynamic>;
              final annonceId = annonces[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Image.network(annonce['imageUrl'], width: 60, height: 60, fit: BoxFit.cover),
                  title: Text(annonce['titre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${annonce['prix']} € - ${annonce['categorie']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EditAnnoncePage(annonceId: annonceId)),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteAnnonce(annonceId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
