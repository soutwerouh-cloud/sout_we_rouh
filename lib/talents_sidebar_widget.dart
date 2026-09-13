import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TalentsSidebarWidget extends StatelessWidget {
  final String activeUserName;
  final Function(String) onOpenPrivateChat;
  final bool isMobile;

  const TalentsSidebarWidget({
    super.key,
    required this.activeUserName,
    required this.onOpenPrivateChat,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.purple.shade100,
            child: const Row(
              children: [
                Icon(Icons.people, color: Colors.purple, size: 20),
                SizedBox(width: 8),
                Text("قائمة الأعضاء والمواهب", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore.collection('talents').where('isApproved', isEqualTo: true).snapshots(),
              builder: (context, talentSnapshot) {
                final memberDocs = talentSnapshot.hasData ? talentSnapshot.data!.docs : [];

                return StreamBuilder<QuerySnapshot>(
                  stream: firestore.collection('inbox').where('receiver', isEqualTo: activeUserName).where('isRead', isEqualTo: false).snapshots(),
                  builder: (context, inboxSnapshot) {
                    final unreadDocs = inboxSnapshot.hasData ? inboxSnapshot.data!.docs : [];
                    
                    final Set<String> sendersWithUnread = unreadDocs.map((doc) {
                      return (doc.data() as Map<String, dynamic>)['sender'] as String? ?? '';
                    }).toSet();

                    return ListView.builder(
                      itemCount: memberDocs.length,
                      itemBuilder: (context, index) {
                        final memberData = memberDocs[index].data() as Map<String, dynamic>;
                        final memberName = memberData["name"] ?? "مستخدم";
                        final talentType = memberData["talentType"] ?? "موهبة جديدة";
                        
                        final Timestamp? lastSeenTime = memberData["lastSeen"] as Timestamp?;
                        final bool isOnline = (memberData["isOnline"] == true) && 
                            (lastSeenTime != null && DateTime.now().difference(lastSeenTime.toDate()).inSeconds < 90);

                        if (memberName == activeUserName) return const SizedBox.shrink();

                        final bool hasNewMessage = sendersWithUnread.contains(memberName);

                        return Container(
                          color: hasNewMessage ? Colors.purple.shade50 : Colors.transparent,
                          child: ListTile(
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  backgroundColor: hasNewMessage ? Colors.purple.shade700 : Colors.purple.shade200,
                                  child: Text(memberName.isNotEmpty ? memberName[0] : "", style: const TextStyle(color: Colors.white)),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: isOnline ? Colors.greenAccent.shade400 : Colors.redAccent.shade200,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              memberName, 
                              style: TextStyle(
                                fontSize: 13, 
                                fontWeight: hasNewMessage ? FontWeight.w900 : FontWeight.bold,
                                color: hasNewMessage ? Colors.purple.shade900 : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              hasNewMessage ? "رسالة جديدة 💌" : talentType, 
                              style: TextStyle(
                                fontSize: 11, 
                                color: hasNewMessage ? Colors.purple.shade700 : Colors.grey,
                                fontWeight: hasNewMessage ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: hasNewMessage 
                                ? Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: const Text("!", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  )
                                : const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.purple),
                            onTap: () {
                              if (isMobile) {
                                Navigator.pop(context); 
                              }
                              onOpenPrivateChat(memberName);
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}