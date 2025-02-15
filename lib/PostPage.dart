import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

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
  File? _imageFile;
  bool _isLoading = false;

  final List<String> _categories = ['Électronique', 'Mode', 'Immobilier', 'Automobile', 'Maison', 'Loisirs'];
  final List<String> _conditions = ['Neuf', 'Occasion'];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _postAnnonce() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty || _priceController.text.isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs et ajouter une image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference storageRef = FirebaseStorage.instance.ref().child('annonces/$fileName');
    UploadTask uploadTask = storageRef.putFile(_imageFile!);
    TaskSnapshot snapshot = await uploadTask;
    String imageUrl = await snapshot.ref.getDownloadURL();

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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Annonce publiée"),
        content: const Text("Votre annonce a été publiée avec succès."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Retour à l'accueil"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Continuer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publier une annonce')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedCategory,
              items: _categories.map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Titre')),
            TextField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
            DropdownButton<String>(
              value: _selectedCondition,
              items: _conditions.map((condition) => DropdownMenuItem(value: condition, child: Text(condition))).toList(),
              onChanged: (value) => setState(() => _selectedCondition = value!),
            ),
            TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix (€)')),
            const SizedBox(height: 10),
            _imageFile == null ? const Text("Aucune image sélectionnée") : Image.file(_imageFile!, height: 200, fit: BoxFit.cover),
            ElevatedButton(onPressed: _pickImage, child: const Text("Ajouter une image")),
            _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _postAnnonce, child: const Text("Publier l'annonce")),
          ],
        ),
      ),
    );
  }
}
