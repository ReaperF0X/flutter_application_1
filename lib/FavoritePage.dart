import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AnnoncePage.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Connectez-vous pour voir vos favoris"));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Favoris")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('favoris')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aucune annonce en favori"));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final annonceId = doc['annonceId'];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('annonces').doc(annonceId).get(),
                builder: (context, annonceSnapshot) {
                  if (!annonceSnapshot.hasData || !annonceSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final annonce = annonceSnapshot.data!.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: Image.network(
                      annonce['imageUrl'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
                    ),
                    title: Text(annonce['titre']),
                    subtitle: Text("${annonce['prix']} €"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        FirebaseFirestore.instance.collection('favoris').doc(doc.id).delete();
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AnnoncePage(annonceId: annonceId)),
                      );
                    },
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
