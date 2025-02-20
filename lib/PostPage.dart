import 'dart:io'; // ✅ Pour Mobile
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // ✅ Vérification Web

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String _selectedCategory = 'Électronique';
  String _selectedCondition = 'Neuf';

  File? _imageFile; // ✅ Pour Mobile
  String _imageFileUrl = ""; // ✅ Pour Web

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = ['Électronique', 'Mode', 'Immobilier', 'Automobile', 'Maison', 'Loisirs', 'Autres'];
  final List<String> _conditions = ['Neuf', 'Occasion'];

  /// ✅ Sélectionner une image pour Web et Mobile
  Future<void> _pickImage() async {
    if (kIsWeb) {
      print("Sélection d'une image pour le Web non prise en charge ici.");
      return;
    } else {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  /// ✅ Téléverser l'image sur Firebase Storage
  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child('annonces/$fileName');
      UploadTask uploadTask = storageRef.putFile(_imageFile!);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du téléversement de l\'image : $e')),
      );
      return null;
    }
  }

  /// ✅ Publier une annonce
  Future<void> _postAnnonce() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty || _priceController.text.isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs et ajouter une image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté pour poster une annonce')),
      );
      return;
    }

    String? imageUrl = await _uploadImage();
    if (imageUrl == null) {
      setState(() => _isLoading = false);
      return;
    }

    await FirebaseFirestore.instance.collection('annonces').add({
      'titre': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'prix': double.parse(_priceController.text.trim()),
      'categorie': _selectedCategory,
      'etat': _selectedCondition,
      'imageUrl': imageUrl,
      'userId': user.uid,
      'date': Timestamp.now(),
    });

    setState(() {
      _isLoading = false;
      _titleController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _imageFile = null;
    });

    // ✅ Redirection après publication
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publier une annonce')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              DropdownButton<String>(
                value: _selectedCondition,
                isExpanded: true,
                items: _conditions.map((condition) => DropdownMenuItem(value: condition, child: Text(condition))).toList(),
                onChanged: (value) => setState(() => _selectedCondition = value!),
              ),
              const SizedBox(height: 16),

              TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix (€)')),
              const SizedBox(height: 16),

              _imageFile == null
                  ? const Text('Aucune image sélectionnée')
                  : Image.file(_imageFile!, height: 200, fit: BoxFit.cover),
              const SizedBox(height: 8),

              ElevatedButton(onPressed: _pickImage, child: const Text('Ajouter une image')),
              const SizedBox(height: 24),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(onPressed: _postAnnonce, child: const Text('Publier l\'annonce')),
            ],
          ),
        ),
      ),
    );
  }
}
