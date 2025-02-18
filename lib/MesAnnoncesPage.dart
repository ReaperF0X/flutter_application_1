import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MesAnnoncesPage extends StatelessWidget {
  const MesAnnoncesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Mes annonces")),
        body: const Center(child: Text("Veuillez vous connecter pour voir vos annonces.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Mes annonces")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('annonces').where('userId', isEqualTo: user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final annonces = snapshot.data!.docs;

          return ListView.builder(
            itemCount: annonces.length,
            itemBuilder: (context, index) {
              final data = annonces[index].data() as Map<String, dynamic>;

              return ListTile(
                leading: Image.network(data['imageUrl'], width: 50, height: 50, fit: BoxFit.cover),
                title: Text(data['titre']),
                subtitle: Text("${data['prix']} €"),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // ✅ Ajout d'une future page pour modifier l'annonce
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
