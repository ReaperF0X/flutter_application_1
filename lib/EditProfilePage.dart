import 'dart:io'; // ✅ Pour Mobile
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html; // ✅ Pour Web
import 'package:flutter/foundation.dart' show kIsWeb; // ✅ Pour détecter Web

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

  /// ✅ Sélectionne une image pour mise à jour du profil
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

  /// ✅ Téléverse la nouvelle image sur Firebase Storage
  Future<String?> _uploadImage() async {
    if (_imageFile == null && _imageUrl.isEmpty) return null;

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

    setState(() {
      _imageUrl = imageUrl!;
      _isLoading = false;
    });

    return imageUrl;
  }

  /// ✅ Met à jour les informations du profil dans Firebase
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ✅ Affichage de la photo de profil avec bouton d'édition
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

              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Nom d\'utilisateur'),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _updateProfile,
                      child: const Text('Mettre à jour'),
                    ),
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
