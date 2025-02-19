import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AnnonceVendeurPage.dart';
import 'ChatPage.dart';

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
  String? userName;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVendeurData();
    _checkUserInteraction();
    _getUserInfo();
  }

  /// ✅ Récupère les infos de l'utilisateur connecté
  Future<void> _getUserInfo() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      setState(() {
        userName = userDoc.data()?['username'] ?? "Utilisateur inconnu";
      });
    }
  }

  /// ✅ Charge les infos du vendeur
  Future<void> _loadVendeurData() async {
    final vendeurDoc = await FirebaseFirestore.instance.collection('users').doc(widget.vendeurId).get();
    if (vendeurDoc.exists) {
      setState(() {
        vendeurData = vendeurDoc.data();
        totalLikes = vendeurData?['totalLikes'] ?? 0;
        totalDislikes = vendeurData?['totalDislikes'] ?? 0;
      });
    }
  }

  /// ✅ Vérifie si l'utilisateur a déjà liké/disliké/commenté
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

  /// ✅ Gère les likes/dislikes
  Future<void> _handleVote(bool isLike) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      Navigator.pushNamed(context, '/login'); 
      return;
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(widget.vendeurId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final docSnapshot = await transaction.get(docRef);
      if (!docSnapshot.exists) return;

      final data = docSnapshot.data()!;
      int likes = data['totalLikes'] ?? 0;
      int dislikes = data['totalDislikes'] ?? 0;

      if (isLike) {
        if (hasDisliked) dislikes = dislikes > 0 ? dislikes - 1 : 0;
        likes = hasLiked ? likes - 1 : likes + 1;
        hasLiked = !hasLiked;
        hasDisliked = false;
      } else {
        if (hasLiked) likes = likes > 0 ? likes - 1 : 0;
        dislikes = hasDisliked ? dislikes - 1 : dislikes + 1;
        hasDisliked = !hasDisliked;
        hasLiked = false;
      }

      transaction.update(docRef, {
        'totalLikes': likes,
        'totalDislikes': dislikes,
      });
    });

    await FirebaseFirestore.instance.collection('interactions').doc('${widget.vendeurId}_$userId').set({
      'liked': hasLiked,
      'disliked': hasDisliked,
    }, SetOptions(merge: true));

    _loadVendeurData();
  }

  /// ✅ Création de la discussion privée
  void _startChat() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId == widget.vendeurId) return;

    String chatId = userId.hashCode <= widget.vendeurId.hashCode
        ? '$userId-${widget.vendeurId}'
        : '${widget.vendeurId}-$userId';

    await FirebaseFirestore.instance.collection('messages').doc(chatId).set({
      'users': [userId, widget.vendeurId],
      'lastMessage': "",
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(chatId: chatId, userId: userId, otherUserId: widget.vendeurId),
      ),
    );
  }

  /// ✅ Ajoute ou modifie un commentaire
  Future<void> _addOrUpdateComment() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    String comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    setState(() {
      userComment = comment;
      _commentController.clear();
    });

    await FirebaseFirestore.instance.collection('Commentaires').doc('${widget.vendeurId}_$userId').set({
      'comment': comment,
      'username': userName,
    }, SetOptions(merge: true));
  }

   /// ✅ Supprime un commentaire
  Future<void> _deleteComment() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance.collection('Commentaires').doc('${widget.vendeurId}_$userId').update({
      'comment': FieldValue.delete(),
    });

    setState(() {
      userComment = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil du vendeur")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          if (vendeurData != null) ...[
            CircleAvatar(
              radius: 50,
              backgroundImage: vendeurData!['photoUrl'] != null
                  ? NetworkImage(vendeurData!['photoUrl'])
                  : null,
              child: vendeurData!['photoUrl'] == null ? const Icon(Icons.person, size: 50) : null,
            ),
            Text(vendeurData!['username'] ?? "Utilisateur inconnu",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: Icon(Icons.thumb_up, color: hasLiked ? Colors.green : Colors.grey), onPressed: () => _handleVote(true)),
                Text("$totalLikes"),
                IconButton(icon: Icon(Icons.thumb_down, color: hasDisliked ? Colors.red : Colors.grey), onPressed: () => _handleVote(false)),
                Text("$totalDislikes"),
              ],
            ),
            ElevatedButton(
              onPressed: _startChat,
              child: const Text("Envoyer un message"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnnonceVendeurPage(vendeurId: widget.vendeurId),
                  ),
                );
              },
              child: const Text("Voir les annonces du vendeur"),
            ),
          ],
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Commentaires').where('comment', isNotEqualTo: null).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final comments = snapshot.data!.docs.where((doc) => doc.id.startsWith(widget.vendeurId)).toList();

                return ListView(
                  children: comments.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    bool isOwner = data['username'] == userName;
                    return ListTile(
                      leading: const Icon(Icons.comment),
                      title: Text(data['comment'] ?? ""),
                      subtitle: Text("Par ${data['username'] ?? "Utilisateur inconnu"}"),
                      trailing: isOwner
                          ? Row(mainAxisSize: MainAxisSize.min, children: [
                              //IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: _addOrUpdateComment),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _deleteComment),
                            ])
                          : null,
                    );
                  }).toList(),
                );  
              },
            ),
          ),
          TextField(controller: _commentController, decoration: const InputDecoration(labelText: "Ajouter un commentaire ou le modifier")),
          ElevatedButton(onPressed: _addOrUpdateComment, child: const Text("Poster le commentaire")),
        ]),
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

