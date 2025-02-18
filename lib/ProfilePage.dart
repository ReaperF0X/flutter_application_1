import 'dart:io'; // ✅ Pour Mobile
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html; // ✅ Pour Web
import 'package:flutter/foundation.dart' show kIsWeb; // ✅ Pour détecter Web

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
      });
    }
  }

  /// ✅ Sélectionne une image
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
            _imageUrl = reader.result as String;
          });
        });
      });
    } else {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  /// ✅ Téléverse la photo de profil
  Future<void> _uploadImage() async {
    if (_imageFile == null && _imageUrl.isEmpty) return;

    setState(() => _isLoading = true);

    String? imageUrl;
    if (_imageFile != null) {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child('profile_pictures/$fileName');
      UploadTask uploadTask = storageRef.putFile(_imageFile!);
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
    } else {
      imageUrl = _imageUrl;
    }

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'photoUrl': imageUrl,
    });

    setState(() {
      _imageUrl = imageUrl!;
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
              // ✅ Cercle pour la photo de profil
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _imageUrl.isNotEmpty ? NetworkImage(_imageUrl) : null,
                    child: _imageUrl.isEmpty ? const Icon(Icons.person, size: 50) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.blue),
                    onPressed: _pickImage,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _uploadImage,
                child: const Text("Mettre à jour la photo"),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (context) => const EditProfilePage()),
                ),
                child: const Text('Modifier le profil'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                ),
                child: const Text('Changer le mot de passe'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (context) => const MesAnnoncesPage()),
                ),
                child: const Text('Mes annonces'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
