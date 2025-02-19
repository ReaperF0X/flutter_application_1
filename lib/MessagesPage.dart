import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ChatPage.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Center(child: Text("Veuillez vous connecter pour voir vos messages."));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Messages")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
            //.where('users', arrayContains: userId)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final messages = snapshot.data!.docs;

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final data = messages[index].data() as Map<String, dynamic>;
              final List<dynamic> users = data['users'];
              final String otherUserId = users.firstWhere((id) => id != userId);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const ListTile(title: Text("Chargement..."));

                  final otherUserData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final String otherUserName = otherUserData['username'] ?? "Utilisateur inconnu";

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: otherUserData['photoUrl'] != null
                          ? NetworkImage(otherUserData['photoUrl'])
                          : null,
                      child: otherUserData['photoUrl'] == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(otherUserName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(data['lastMessage'] ?? "Aucun message"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            chatId: messages[index].id,
                            userId: userId!,
                            otherUserId: otherUserId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
