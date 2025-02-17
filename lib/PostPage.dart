import 'dart:io'; // ✅ Pour Mobile
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // ✅ Pour détecter Web
import 'dart:html' as html; // ✅ Pour gérer les fichiers Web
import 'HomePage.dart';

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

  File? _imageFile; // ✅ Pour mobile
  String _imageFileUrl = ""; // ✅ Pour stocker l'URL d'image (Web & Mobile)

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = ['Électronique', 'Mode', 'Immobilier', 'Automobile', 'Maison', 'Loisirs'];
  final List<String> _conditions = ['Neuf', 'Occasion'];

  // ✅ Sélectionner une image pour Web et Mobile
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
            _imageFileUrl = reader.result as String; // ✅ Stocke l'image sous forme de Data URL (Base64)
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

  // ✅ Téléverser l'image sur Firebase Storage
  Future<String?> _uploadImage() async {
    try {
      if (kIsWeb) {
        return _imageFileUrl; 
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

  // ✅ Publier une annonce avec un bouton pour retourner à l'accueil
  Future<void> _postAnnonce() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty || _priceController.text.isEmpty || (_imageFile == null && _imageFileUrl.isEmpty)) {
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
      'likes': 0,    
      'dislikes': 0,  
    });

    setState(() {
      _isLoading = false;
      _titleController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _imageFile = null;
      _imageFileUrl = "";
      _selectedCategory = 'Électronique';
      _selectedCondition = 'Neuf';
    });

    // ✅ Ajout d’un dialogue pour revenir à l'accueil
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Annonce publiée"),
        content: const Text("Votre annonce a été publiée avec succès."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home'); // ✅ Garde le ruban
            },
            child: const Text("Retour à l'accueil"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/post'); // ✅ Reste sur PostPage
            },
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
        child: SingleChildScrollView(
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

              _imageFile == null && _imageFileUrl.isEmpty
                  ? const Text('Aucune image sélectionnée')
                  : kIsWeb
                      ? Image.network(_imageFileUrl, height: 200, fit: BoxFit.cover)
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
