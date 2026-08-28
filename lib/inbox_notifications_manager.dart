import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InboxNotificationsManager {
  static void showInboxDialog(BuildContext context, String activeUserName, Function(String) onOpenPrivateChat) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("صندوق البريد الخاص ✉️", style: TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 480,
            height: 380,
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('inbox').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final inboxDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['receiver'] == activeUserName;
                }).toList();

                if (inboxDocs.isEmpty) {
                  return const Center(
                    child: Text("لا توجد رسائل خاصة جديدة 📭", style: TextStyle(color: Colors.grey, fontSize: 15)),
                  );
                }

                final Map<String, DocumentSnapshot> latestMessagePerSender = {};
                for (var doc in inboxDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final sender = data["sender"] ?? "مجهول";
                  
                  if (!latestMessagePerSender.containsKey(sender)) {
                    latestMessagePerSender[sender] = doc;
                  } else {
                    var existingTime = (latestMessagePerSender[sender]!.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                    var currentTime = data['timestamp'] as Timestamp?;
                    if (currentTime != null && (existingTime == null || currentTime.compareTo(existingTime) > 0)) {
                      latestMessagePerSender[sender] = doc;
                    }
                  }
                }

                final uniqueSendersDocs = latestMessagePerSender.values.toList();

                uniqueSendersDocs.sort((a, b) {
                  var timeA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  var timeB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  if (timeA == null || timeB == null) return 0;
                  return timeB.compareTo(timeA);
                });

                return ListView.builder(
                  itemCount: uniqueSendersDocs.length,
                  itemBuilder: (context, index) {
                    final doc = uniqueSendersDocs[index];
                    final msgData = doc.data() as Map<String, dynamic>;
                    final senderName = msgData["sender"] ?? "مجهول";
                    final messageText = msgData["text"] ?? "";
                    
                    final unreadCount = inboxDocs.where((d) {
                      final dData = d.data() as Map<String, dynamic>;
                      return dData['sender'] == senderName && (dData['isRead'] == false || dData['isRead'] == null);
                    }).length;

                    var timestamp = msgData['timestamp'] as Timestamp?;
                    String dateStr = 'منذ قليل';
                    if (timestamp != null) {
                      DateTime dt = timestamp.toDate();
                      String hour = dt.hour > 12 ? '${dt.hour - 12}' : '${dt.hour == 0 ? 12 : dt.hour}';
                      String minute = dt.minute.toString().padLeft(2, '0');
                      String period = dt.hour >= 12 ? 'م' : 'ص';
                      dateStr = '${dt.year}/${dt.month}/${dt.day} - $hour:$minute $period';
                    }

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          final batch = firestore.batch();
                          for (var d in inboxDocs) {
                            final dData = d.data() as Map<String, dynamic>;
                            if (dData['sender'] == senderName && (dData['isRead'] == false || dData['isRead'] == null)) {
                              batch.update(d.reference, {'isRead': true});
                            }
                          }
                          await batch.commit();

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          onOpenPrivateChat(senderName);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFFF3E5F5),
                                    child: Icon(Icons.chat_bubble, color: Color(0xFF7B1FA2), size: 20),
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          senderName,
                                          style: TextStyle(
                                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                                            fontSize: 14,
                                            color: const Color(0xFF7B1FA2),
                                          ),
                                        ),
                                        Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      messageText.startsWith('data:image') ? '[محتوى مرئي]' : messageText,
                                      style: TextStyle(fontSize: 12, color: unreadCount > 0 ? Colors.black : Colors.black87, fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // زر الحذف مع النص الواضح
                              InkWell(
                                onTap: () async {
                                  bool? confirm = await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('حذف المحادثة 🗑️'),
                                      content: Text('هل تريد حذف المحادثة مع $senderName بالكامل؟'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('حذف', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    final batch = firestore.batch();
                                    for (var d in inboxDocs) {
                                      final dData = d.data() as Map<String, dynamic>;
                                      if (dData['sender'] == senderName || dData['receiver'] == senderName) {
                                        batch.delete(d.reference);
                                      }
                                    }
                                    await batch.commit();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.delete_outline, color: Colors.red, size: 16),
                                      SizedBox(width: 4),
                                      Text('حذف', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إغلاق", style: TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}