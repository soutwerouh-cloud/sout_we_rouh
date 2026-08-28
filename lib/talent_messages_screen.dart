import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TalentMessagesScreen extends StatelessWidget {
  final String talentName;

  const TalentMessagesScreen({super.key, required this.talentName});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('رسائل: $talentName ✉️', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF7B1FA2),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.inbox), text: 'صندوق الوارد 📥'),
              Tab(icon: Icon(Icons.send), text: 'البريد المرسل 📤'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // تبويب صندوق الوارد
            _MessagesList(talentName: talentName, isInbox: true),
            // تبويب البريد المرسل
            _MessagesList(talentName: talentName, isInbox: false),
          ],
        ),
      ),
    );
  }
}

class _MessagesList extends StatefulWidget {
  final String talentName;
  final bool isInbox;

  const _MessagesList({required this.talentName, required this.isInbox});

  @override
  State<_MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends State<_MessagesList> {
  @override
  void initState() {
    super.initState();
    if (widget.isInbox) {
      _markMessagesAsRead();
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      var unreadDocs = await FirebaseFirestore.instance
          .collection('talent_direct_messages')
          .where('receiver', isEqualTo: widget.talentName.trim())
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadDocs.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      // تجاهل
    }
  }

  Future<void> _deleteMessage(String docId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف 🗑️', style: TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من حذف هذه الرسالة نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('talent_direct_messages')
            .doc(docId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الرسالة بنجاح 🗑️'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل في حذف الرسالة ❌'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String queryField = widget.isInbox ? 'receiver' : 'sender';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('talent_direct_messages')
          .where(queryField, isEqualTo: widget.talentName.trim())
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              widget.isInbox ? 'لا توجد رسائل واردة حتى الآن 📭' : 'لا توجد رسائل مرسلة حتى الآن 📭',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        var messages = snapshot.data!.docs.toList();

        messages.sort((a, b) {
          var timeA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          var timeB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          if (timeA == null || timeB == null) return 0;
          return timeB.compareTo(timeA);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            var messageDoc = messages[index];
            var msgData = messageDoc.data() as Map<String, dynamic>;
            String targetName = widget.isInbox ? (msgData['sender'] ?? 'مجهول') : (msgData['receiver'] ?? 'مجهول');
            String text = msgData['text'] ?? '';

            if (text.startsWith('data:image') || text.length > 500) {
              text = '[محتوى مرئي أو مرفق]';
            }

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
                        Text(
                          widget.isInbox ? 'مرسل من: $targetName' : 'مرسل إلى: $targetName',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7B1FA2), fontSize: 15),
                        ),
                        Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(text, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                    const Divider(height: 20),
                    // سطر خاص بزر الحذف بوضوح تام أسفل الكارت
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _deleteMessage(messageDoc.id),
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          label: const Text('حذف الرسالة', style: TextStyle(color: Colors.red, fontSize: 13)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            backgroundColor: Colors.red.shade50,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}