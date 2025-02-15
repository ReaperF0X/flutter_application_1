import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePostPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onPostCreated;
  final Map<String, dynamic>? annonce;

  const CreatePostPage({super.key, required this.onPostCreated, this.annonce});

  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();

  final List<String> categories = ['Vêtements', 'Électronique', 'Mobilier', 'Sports', 'Jouets'];
  final List<String> etats = ['Neuf', 'Bon état', 'Usé'];
  String selectedCategory = 'Vêtements';
  String selectedEtat = 'Neuf';
  File? _image;

  @override
  void initState() {
    super.initState();
    if (widget.annonce != null) {
      _titreController.text = widget.annonce!['titre'] ?? '';
      _descriptionController.text = widget.annonce!['description'] ?? '';
      _prixController.text = widget.annonce!['prix']?.toString() ?? '';
      selectedCategory = widget.annonce!['categorie'] ?? 'Vêtements';
      selectedEtat = widget.annonce!['etat'] ?? 'Neuf';
      _image = widget.annonce!['image'];
    }
  }

  // ✅ Sélection d'une image depuis la galerie
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // ✅ Fonction pour enregistrer l'annonce dans Firestore
  Future<void> _saveAnnonceToFirestore(Map<String, dynamic> annonce) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté pour publier une annonce')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('annonces').add({
      'titre': annonce['titre'],
      'description': annonce['description'],
      'prix': double.parse(annonce['prix']),
      'categorie': annonce['categorie'],
      'etat': annonce['etat'],
      'image': annonce['image'], // ✅ L'image doit être uploadée dans Firebase Storage
      'userId': user.uid,
      'likes': 0,
      'dislikes': 0,
      'date': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Annonce publiée avec succès !')),
    );

    Navigator.pop(context);
  }

  // ✅ Publier l'annonce
  void _publierAnnonce() {
    if (_titreController.text.isEmpty || _prixController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    final annonce = {
      'titre': _titreController.text,
      'description': _descriptionController.text,
      'prix': _prixController.text,
      'categorie': selectedCategory,
      'etat': selectedEtat,
      'image': _image,
    };

    widget.onPostCreated(annonce);
    _saveAnnonceToFirestore(annonce); // ✅ Ajout dans Firestore
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.annonce == null ? 'Créer une annonce' : 'Modifier l\'annonce'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Catégorie et État
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Catégorie', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedCategory = newValue!;
                          });
                        },
                        items: categories.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('État', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: selectedEtat,
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedEtat = newValue!;
                          });
                        },
                        items: etats.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ✅ Titre
            const Text('Titre de l\'annonce', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _titreController, decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 20),

            // ✅ Prix
            const Text('Prix (€)', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
                controller: _prixController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 20),

            // ✅ Description
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 20),

            // ✅ Image
            const Text('Image (aperçu)', style: TextStyle(fontWeight: FontWeight.bold)),
            _image != null
                ? Image.file(_image!, width: 100, height: 100, fit: BoxFit.cover)
                : Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Ajouter une image'),
            ),
            const SizedBox(height: 20),

            // ✅ Bouton publier
            ElevatedButton(
              onPressed: _publierAnnonce,
              child: Text(widget.annonce == null ? 'Publier l\'annonce' : 'Modifier l\'annonce'),
            ),
          ],
        ),
      ),
    );
  }
}
