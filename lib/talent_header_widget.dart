import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'talent_model.dart';
import 'talent_messaging_helper.dart';

class TalentHeaderWidget extends StatelessWidget {
  final TalentModel talent;
  final IconData icon;
  final String currentProfileImage;
  final VoidCallback onPickImage;
  final VoidCallback onOpenMessages;

  const TalentHeaderWidget({
    super.key,
    required this.talent,
    required this.icon,
    required this.currentProfileImage,
    required this.onPickImage,
    required this.onOpenMessages,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF7B1FA2).withOpacity(0.1),
              child: Icon(icon, size: 50, color: const Color(0xFF7B1FA2)),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: InkWell(
                onTap: onPickImage,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF7B1FA2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              talent.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B1FA2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.mail, size: 16, color: Colors.white),
              label: const Text('مراسلة', style: TextStyle(color: Colors.white, fontSize: 12)),
              onPressed: () => showDirectMessageDialog(context, talent.name),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // StreamBuilder لعرض عدد الرسائل الجديدة (غير المقروءة) على زر الصندوق
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('talent_direct_messages')
              .where('receiver', isEqualTo: talent.name.trim())
              .where('isRead', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            int unreadCount = 0;
            if (snapshot.hasData) {
              unreadCount = snapshot.data!.docs.length;
            }

            return ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: unreadCount > 0 ? Colors.red.shade700 : const Color(0xFF7B1FA2),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.mark_email_read, size: 18, color: Colors.white),
              label: Text(
                unreadCount > 0 
                    ? 'فتح صندوق الرسائل والوارد ($unreadCount) 📬' 
                    : 'فتح صندوق الرسائل والوارد 📬',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: onOpenMessages,
            );
          },
        ),
      ],
    );
  }
}