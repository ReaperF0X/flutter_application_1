import 'dart:io'; // ✅ Pour Mobile
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // ✅ Pour vérifier si c'est Web

import 'ChangePasswordPage.dart';
import 'EditProfilePage.dart';
import 'MesAnnoncesPage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? userId;
  String _imageUrl = "";
  String _username = "Chargement...";
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    _getUserData();
  }

  /// ✅ Récupère les infos de l'utilisateur
  Future<void> _getUserData() async {
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      setState(() {
        _imageUrl = doc.data()?['photoUrl'] ?? "";
        _username = doc.data()?['username'] ?? "Utilisateur inconnu";
      });
    }
  }

  /// ✅ Sélectionne une image pour mise à jour
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  /// ✅ Téléverse la photo de profil
  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() => _isLoading = true);

    String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference storageRef = FirebaseStorage.instance.ref().child('profile_pictures/$fileName');
    UploadTask uploadTask = storageRef.putFile(_imageFile!);
    TaskSnapshot snapshot = await uploadTask;
    String imageUrl = await snapshot.ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'photoUrl': imageUrl,
    });

    setState(() {
      _imageUrl = imageUrl;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Photo de profil mise à jour !")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: _imageUrl.isNotEmpty ? NetworkImage(_imageUrl) : null,
                child: _imageUrl.isEmpty ? const Icon(Icons.person, size: 50) : null,
              ),
              const SizedBox(height: 16),
              Text(
                _username,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _pickImage, child: const Text("Changer la photo")),
              ElevatedButton(onPressed: _uploadImage, child: const Text("Mettre à jour la photo")),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilePage())),
                child: const Text('Modifier le profil'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordPage())),
                child: const Text('Changer le mot de passe'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MesAnnoncesPage())),
                child: const Text('Mes annonces'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
