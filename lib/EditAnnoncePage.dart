import 'dart:io'; // ✅ Pour Mobile
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // ✅ Pour détecter Web
import 'dart:html' as html; // ✅ Pour Web

class EditAnnoncePage extends StatefulWidget {
  final String annonceId;

  const EditAnnoncePage({super.key, required this.annonceId});

  @override
  _EditAnnoncePageState createState() => _EditAnnoncePageState();
}

class _EditAnnoncePageState extends State<EditAnnoncePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String _selectedCategory = 'Électronique';
  String _selectedCondition = 'Neuf';

  bool _isLoading = false;
  String _imageUrl = ""; // ✅ URL de l'image actuelle
  File? _imageFile; // ✅ Image sélectionnée (Mobile)
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = ['Électronique', 'Mode', 'Immobilier', 'Automobile', 'Maison', 'Loisirs'];
  final List<String> _conditions = ['Neuf', 'Occasion'];

  @override
  void initState() {
    super.initState();
    _loadAnnonceData();
  }

  /// ✅ Charge les infos de l'annonce
  Future<void> _loadAnnonceData() async {
    final doc = await FirebaseFirestore.instance.collection('annonces').doc(widget.annonceId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _titleController.text = data['titre'];
        _descriptionController.text = data['description'];
        _priceController.text = data['prix'].toString();
        _selectedCategory = data['categorie'];
        _selectedCondition = data['etat'];
        _imageUrl = data['imageUrl'] ?? ""; // ✅ Charge l'URL de l'image actuelle
      });
    }
  }

  /// ✅ Sélectionne une nouvelle image
  Future<void> _pickImage() async {
    if (kIsWeb) {
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement()..accept = 'image/*';
      uploadInput.click();
      uploadInput.onChange.listen((event) async {
        final file = uploadInput.files!.first;
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((event) {
          setState(() {
            _imageUrl = reader.result as String; // ✅ Stocke l'image sous forme de Data URL (Base64)
          });
        });
      });
    } else {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path); // ✅ Stocke l'image locale pour Mobile
        });
      }
    }
  }

  /// ✅ Téléverse l'image sélectionnée sur Firebase Storage
  Future<String?> _uploadImage() async {
    try {
      if (_imageFile == null && _imageUrl.isEmpty) return null;

      if (kIsWeb) {
        return _imageUrl; // ✅ Web : On garde l'URL de l'image
      } else {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child('annonces/$fileName');
        UploadTask uploadTask = storageRef.putFile(_imageFile!);
        TaskSnapshot snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du téléversement de l\'image : $e')),
      );
      return null;
    }
  }

  /// ✅ Met à jour l'annonce
  Future<void> _updateAnnonce() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? imageUrl = await _uploadImage(); // ✅ Téléverse l'image et récupère l'URL
    if (imageUrl == null) {
      setState(() => _isLoading = false);
      return;
    }

    await FirebaseFirestore.instance.collection('annonces').doc(widget.annonceId).update({
      'titre': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'prix': double.parse(_priceController.text.trim()),
      'categorie': _selectedCategory,
      'etat': _selectedCondition,
      'imageUrl': imageUrl, // ✅ Met à jour l'URL de l'image
    });

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Annonce modifiée avec succès !')),
    );

    Navigator.pop(context); // Retour à la page précédente
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modifier l'annonce")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Catégorie', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      items: _categories.map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
                      onChanged: (value) => setState(() => _selectedCategory = value!),
                    ),
                    const SizedBox(height: 16),

                    TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Titre')),
                    const SizedBox(height: 16),

                    TextField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                    const SizedBox(height: 16),

                    const Text('État du produit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: _selectedCondition,
                      isExpanded: true,
                      items: _conditions.map((condition) => DropdownMenuItem(value: condition, child: Text(condition))).toList(),
                      onChanged: (value) => setState(() => _selectedCondition = value!),
                    ),
                    const SizedBox(height: 16),

                    TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix (€)')),
                    const SizedBox(height: 16),

                    /// ✅ **Affichage de l'image actuelle**
                    if (_imageUrl.isNotEmpty)
                      Image.network(_imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 100);
                        },
                      ),
                    const SizedBox(height: 8),

                    /// ✅ **Bouton pour changer l'image**
                    ElevatedButton(onPressed: _pickImage, child: const Text('Modifier l\'image')),
                    const SizedBox(height: 16),

                    ElevatedButton(onPressed: _updateAnnonce, child: const Text('Mettre à jour')),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // L'index dépend de l'endroit où vous vous trouvez
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/favoris');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/post');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/messages');
          } else if (index == 4) {
            Navigator.pushReplacementNamed(context, '/profile');
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
