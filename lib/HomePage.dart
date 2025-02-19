import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AnnoncePage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String searchQuery = '';
  String selectedCategory = 'Toutes';
  String selectedSort = 'Plus récent';

  final List<String> categories = ['Toutes', 'Électronique', 'Mode', 'Immobilier', 'Automobile', 'Maison', 'Loisirs'];
  final List<String> sortOptions = ['Plus récent', 'Moins récent', 'Prix croissant', 'Prix décroissant'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      body: Column(
        children: [
          /// ✅ **Barre de recherche + Filtre + Tri**
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                TextField(
                  onChanged: (query) => setState(() => searchQuery = query),
                  decoration: InputDecoration(
                    labelText: 'Rechercher une annonce...',
                    border: OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /// ✅ **Filtre par catégorie**
                    DropdownButton<String>(
                      value: selectedCategory,
                      items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (value) => setState(() => selectedCategory = value!),
                    ),

                    /// ✅ **Tri des annonces**
                    DropdownButton<String>(
                      value: selectedSort,
                      items: sortOptions.map((sort) => DropdownMenuItem(value: sort, child: Text(sort))).toList(),
                      onChanged: (value) => setState(() => selectedSort = value!),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// ✅ **Affichage dynamique des annonces**
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('annonces').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Aucune annonce disponible.'));
                }

                List<QueryDocumentSnapshot> annonces = snapshot.data!.docs;

                /// ✅ **Application du filtre par catégorie**
                if (selectedCategory != 'Toutes') {
                  annonces = annonces.where((doc) => doc['categorie'] == selectedCategory).toList();
                }

                /// ✅ **Application du filtre par recherche**
                if (searchQuery.isNotEmpty) {
                  annonces = annonces.where((doc) {
                    final String titre = doc['titre']?.toLowerCase() ?? "";
                    return titre.contains(searchQuery.toLowerCase());
                  }).toList();
                }

                /// ✅ **Application du tri**
                if (selectedSort == 'Plus récent') {
                  annonces.sort((a, b) => (b['date'] as Timestamp).compareTo(a['date'] as Timestamp));
                } else if (selectedSort == 'Moins récent') {
                  annonces.sort((a, b) => (a['date'] as Timestamp).compareTo(b['date'] as Timestamp));
                } else if (selectedSort == 'Prix croissant') {
                  annonces.sort((a, b) => (a['prix'] as num).compareTo(b['prix'] as num));
                } else if (selectedSort == 'Prix décroissant') {
                  annonces.sort((a, b) => (b['prix'] as num).compareTo(a['prix'] as num));
                }

                return ListView(
                  children: annonces.map((doc) {
                    final annonce = doc.data() as Map<String, dynamic>;

                    // ✅ **Sécurisation des données**
                    final String imageUrl = annonce['imageUrl'] ?? "https://via.placeholder.com/200";
                    final String titre = annonce['titre'] ?? "Titre non disponible";
                    final String categorie = annonce['categorie'] ?? "Non catégorisé";
                    final Timestamp? timestamp = annonce['date'];
                    final String vendeurId = annonce['userId'] ?? "";
                    final double prix = (annonce['prix'] is int)
                        ? (annonce['prix'] as int).toDouble()
                        : (annonce['prix'] is double)
                            ? annonce['prix']
                            : double.tryParse(annonce['prix'].toString()) ?? 0.0;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(vendeurId).get(),
                      builder: (context, userSnapshot) {
                        String vendeurPseudo = "Vendeur inconnu";
                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          vendeurPseudo = userData['username'] ?? "Vendeur inconnu";
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AnnoncePage(annonceId: doc.id)),
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
                                      const SizedBox(height: 5),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("Par $vendeurPseudo", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                          Text(timestamp != null
                                              ? "${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}"
                                              : "Date inconnue", style: const TextStyle(color: Colors.grey)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
