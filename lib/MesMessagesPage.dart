/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ChatPage.dart'; // ✅ Importation de la page de discussion

class MesMessagesPage extends StatefulWidget {
  final String userId;

  const MesMessagesPage({super.key, required this.userId});

  @override
  _MesMessagesPageState createState() => _MesMessagesPageState();
}

class _MesMessagesPageState extends State<MesMessagesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mes Messages")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages')
            .where('participants', arrayContains: widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final conversations = snapshot.data!.docs;

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              var convo = conversations[index];
              var participants = List<String>.from(convo['participants']);
              participants.remove(widget.userId);
              String otherUserId = participants.isNotEmpty ? participants.first : "Inconnu";

              return ListTile(
                title: Text("Conversation avec $otherUserId"),
                subtitle: Text(convo['lastMessage'] ?? "Aucun message"),
                leading: const Icon(Icons.message),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(chatId: convo.id, userId: widget.userId, otherUserId: otherUserId),
                    ),
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
*/