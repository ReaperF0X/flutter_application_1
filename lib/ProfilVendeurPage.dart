import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AnnoncePage.dart';

class ProfilVendeurPage extends StatefulWidget {
  final String vendeurId;

  const ProfilVendeurPage({super.key, required this.vendeurId});

  @override
  _ProfilVendeurPageState createState() => _ProfilVendeurPageState();
}

class _ProfilVendeurPageState extends State<ProfilVendeurPage> {
  Map<String, dynamic>? vendeurData;
  int totalLikes = 0;
  int totalDislikes = 0;
  bool hasLiked = false;
  bool hasDisliked = false;
  String? userComment;

  @override
  void initState() {
    super.initState();
    _loadVendeurData();
    _checkUserInteraction();
  }

  /// ✅ Charge les infos du vendeur et ses likes/dislikes
  Future<void> _loadVendeurData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.vendeurId).get();
    if (doc.exists) {
      setState(() {
        vendeurData = doc.data();
      });
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('annonces')
        .where('userId', isEqualTo: widget.vendeurId)
        .get();

    int likes = 0;
    int dislikes = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      int likesValue = (data['likes'] is int) ? data['likes'] as int : (data['likes'] ?? 0).toDouble().toInt();
      int dislikesValue = (data['dislikes'] is int) ? data['dislikes'] as int : (data['dislikes'] ?? 0).toDouble().toInt();
      likes += likesValue;
      dislikes += dislikesValue;
    }

    setState(() {
      totalLikes = likes;
      totalDislikes = dislikes;
    });
  }

  /// ✅ Vérifie si l'utilisateur a déjà liké/disliké/commenté une annonce de ce vendeur
  Future<void> _checkUserInteraction() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final interactionDoc = await FirebaseFirestore.instance
        .collection('interactions')
        .doc('${widget.vendeurId}_$userId')
        .get();

    if (interactionDoc.exists) {
      final data = interactionDoc.data();
      setState(() {
        hasLiked = data?['liked'] ?? false;
        hasDisliked = data?['disliked'] ?? false;
        userComment = data?['comment'];
      });
    }
  }

  /// ✅ Gère les likes/dislikes avec bascule automatique
  Future<void> _handleVote(bool isLike) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      if (isLike) {
        if (hasDisliked) totalDislikes--; 
        totalLikes += hasLiked ? -1 : 1;
        hasLiked = !hasLiked;
        hasDisliked = false;
      } else {
        if (hasLiked) totalLikes--;
        totalDislikes += hasDisliked ? -1 : 1;
        hasDisliked = !hasDisliked;
        hasLiked = false;
      }
    });

    await FirebaseFirestore.instance.collection('interactions').doc('${widget.vendeurId}_$userId').set({
      'liked': hasLiked,
      'disliked': hasDisliked,
    }, SetOptions(merge: true));

    _loadVendeurData();
  }

  /// ✅ Ajoute un commentaire unique
  Future<void> _addComment(String comment) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userComment != null) return; 

    setState(() => userComment = comment);

    await FirebaseFirestore.instance.collection('interactions').doc('${widget.vendeurId}_$userId').set({
      'comment': comment,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil du vendeur")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          if (vendeurData != null) ...[
            CircleAvatar(radius: 50, backgroundImage: NetworkImage(vendeurData!['photoUrl'] ?? "")),
            Text(vendeurData!['username'] ?? "Utilisateur inconnu", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: Icon(Icons.thumb_up, color: hasLiked ? Colors.green : Colors.grey), onPressed: () => _handleVote(true)),
                Text("$totalLikes"),
                IconButton(icon: Icon(Icons.thumb_down, color: hasDisliked ? Colors.red : Colors.grey), onPressed: () => _handleVote(false)),
                Text("$totalDislikes"),
              ],
            ),
            if (userComment == null) ...[
              TextField(
                onSubmitted: _addComment,
                decoration: const InputDecoration(labelText: "Ajouter un commentaire"),
              ),
            ] else ...[
              Text("Commentaire: $userComment"),
            ],
          ],
        ]),
      ),
    );
  }
}
