import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TalentMessagesScreen extends StatelessWidget {
  final String talentName;

  const TalentMessagesScreen({super.key, required this.talentName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('رسائل: $talentName ✉️', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF7B1FA2),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('inbox')
            .where('receiver', isEqualTo: talentName.trim())
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('لا توجد رسائل واردة حتى الآن 📭', style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          var messages = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              var msgData = messages[index].data() as Map<String, dynamic>;
              String sender = msgData['sender'] ?? 'مجهول';
              String text = msgData['text'] ?? '';
              var timestamp = msgData['timestamp'] as Timestamp?;
              String dateStr = timestamp != null
                  ? "${timestamp.toDate().year}/${timestamp.toDate().month}/${timestamp.toDate().day}"
                  : 'منذ قليل';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('من: $sender', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7B1FA2), fontSize: 15)),
                          Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(text, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}