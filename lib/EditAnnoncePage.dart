import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  final List<String> _categories = ['Électronique', 'Mode', 'Immobilier', 'Automobile', 'Maison', 'Loisirs'];
  final List<String> _conditions = ['Neuf', 'Occasion'];

  @override
  void initState() {
    super.initState();
    _loadAnnonceData();
  }

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
      });
    }
  }

  Future<void> _updateAnnonce() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);

    await FirebaseFirestore.instance.collection('annonces').doc(widget.annonceId).update({
      'titre': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'prix': double.parse(_priceController.text.trim()),
      'categorie': _selectedCategory,
      'etat': _selectedCondition,
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
            : Column(
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

                  ElevatedButton(onPressed: _updateAnnonce, child: const Text('Mettre à jour')),
                ],
              ),
      ),
    );
  }
}
