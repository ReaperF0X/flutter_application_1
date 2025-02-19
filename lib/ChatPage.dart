import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String userId;
  final String otherUserId;

  const ChatPage({super.key, required this.chatId, required this.userId, required this.otherUserId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  String otherUserName = "Chargement..."; // ✅ Pseudo de l'autre utilisateur

  @override
  void initState() {
    super.initState();
    _fetchOtherUserName(); // ✅ Récupérer le pseudo au lancement
  }

  /// ✅ Récupère le pseudo de l'autre utilisateur depuis Firestore
  Future<void> _fetchOtherUserName() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.otherUserId).get();
    if (doc.exists) {
      setState(() {
        otherUserName = doc.data()?['username'] ?? "Utilisateur inconnu";
      });
    }
  }

  /// ✅ Fonction pour envoyer un message
  Future<void> _sendMessage() async {
    String messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    await FirebaseFirestore.instance.collection('messages').doc(widget.chatId).collection('chats').add({
      'senderId': widget.userId,
      'receiverId': widget.otherUserId,
      'message': messageText,
      'timestamp': FieldValue.serverTimestamp(),
    });

    /// ✅ Met à jour le dernier message dans la liste des conversations
    await FirebaseFirestore.instance.collection('messages').doc(widget.chatId).update({
      'lastMessage': messageText,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Discussion avec $otherUserName")), // ✅ Affichage du pseudo
      body: Column(
        children: [
          /// ✅ **Affichage des messages en temps réel**
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .doc(widget.chatId)
                  .collection('chats')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                return ListView(
                  reverse: true, // ✅ Permet d'afficher les messages du bas vers le haut
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == widget.userId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blueAccent : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['message'],
                              style: TextStyle(color: isMe ? Colors.white : Colors.black),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              data['timestamp'] != null
                                  ? DateTime.fromMillisecondsSinceEpoch(
                                          data['timestamp'].seconds * 1000)
                                      .toLocal()
                                      .toString()
                                  : "Envoi en cours...",
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          /// ✅ **Zone d'entrée de texte et bouton d'envoi**
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Écrire un message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
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
