import 'dart:io'; // ✅ Pour Mobile
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // ✅ Pour vérifier si c'est Web

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? userId;
  String _imageUrl = "";
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    _getUserData();
  }

  /// ✅ Récupère les infos de l'utilisateur actuel
  Future<void> _getUserData() async {
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      final userData = doc.data();
      setState(() {
        _usernameController.text = userData?['username'] ?? "";
        _emailController.text = userData?['email'] ?? "";
        _imageUrl = userData?['photoUrl'] ?? "";
      });
    }
  }

  /// ✅ Sélectionne une image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  /// ✅ Téléverse la nouvelle image sur Firebase Storage
  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference storageRef = FirebaseStorage.instance.ref().child('profile_pictures/$fileName');
    UploadTask uploadTask = storageRef.putFile(_imageFile!);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// ✅ Met à jour les informations du profil
  Future<void> _updateProfile() async {
    if (userId == null) return;

    String? imageUrl = await _uploadImage();

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'username': _usernameController.text.trim(),
      'email': _emailController.text.trim(),
      if (imageUrl != null) 'photoUrl': imageUrl,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profil mis à jour avec succès !")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le profil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: _imageUrl.isNotEmpty ? NetworkImage(_imageUrl) : null,
              child: _imageUrl.isEmpty ? const Icon(Icons.person, size: 50) : null,
            ),
            ElevatedButton(onPressed: _pickImage, child: const Text('Changer la photo')),
            TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Nom d\'utilisateur')),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
            _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _updateProfile, child: const Text('Mettre à jour')),
          ],
        ),
      ),
    );
  }
}
