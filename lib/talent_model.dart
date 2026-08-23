import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// نموذج الموهبة
class TalentModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final IconData icon;
  final Color themeColor;
  final String paymentMethod;
  final String transactionRef;
  int likesCount;
  bool isLiked;
  bool isApproved;
  final String email;
  final String bio;
  final String password;
  final String profileImage;

  TalentModel({
    this.id = '',
    required this.name,
    required this.category,
    this.description = '',
    this.icon = Icons.mic,
    this.themeColor = Colors.deepPurple,
    this.paymentMethod = 'Vodafone Cash',
    this.transactionRef = '',
    this.likesCount = 12,
    this.isLiked = false,
    this.isApproved = false,
    this.email = '',
    this.bio = '',
    this.password = '',
    this.profileImage = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'paymentMethod': paymentMethod,
      'transactionRef': transactionRef,
      'likesCount': likesCount,
      'isLiked': isLiked,
      'isApproved': isApproved,
      'email': email,
      'bio': bio,
      'password': password,
      'profileImage': profileImage,
    };
  }

  factory TalentModel.fromMap(Map<String, dynamic> map, String docId) {
    IconData defaultIcon = Icons.mic;
    Color defaultColor = Colors.deepPurple;
    
    if (map['category'] == 'poetry') {
      defaultIcon = Icons.history_edu;
      defaultColor = Colors.purple;
    } else if (map['category'] == 'composing') {
      defaultIcon = Icons.music_note;
      defaultColor = Colors.indigo;
    }

    return TalentModel(
      id: docId,
      name: map['name'] ?? '',
      category: map['category'] ?? 'singing',
      description: map['description'] ?? '',
      icon: defaultIcon,
      themeColor: defaultColor,
      paymentMethod: map['paymentMethod'] ?? 'Vodafone Cash',
      transactionRef: map['transactionRef'] ?? '',
      likesCount: map['likesCount'] ?? 0,
      isLiked: map['isLiked'] ?? false,
      isApproved: map['isApproved'] ?? false,
      email: map['email'] ?? '',
      bio: map['description'] ?? '',
      password: map['password'] ?? '',
      profileImage: map['profileImage'] ?? '',
    );
  }
}

// دالة مساعدة لإرسال رسالة مباشرة لأي موهبة
void showDirectMessageDialog(BuildContext context, String recipientName) {
  final TextEditingController senderController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('إرسال رسالة إلى: $recipientName ✉️', style: const TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: senderController,
            decoration: const InputDecoration(labelText: 'اسمك الحقيقي (المرسل)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: messageController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'اكتب رسالتك هنا...', border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B1FA2)),
          onPressed: () async {
            String sender = senderController.text.trim();
            String msg = messageController.text.trim();

            if (sender.isEmpty || msg.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('الرجاء إدخال اسمك ومحتوى الرسالة ❌'), backgroundColor: Colors.red),
              );
              return;
            }

            await FirebaseFirestore.instance.collection('inbox').add({
              "sender": sender,
              "receiver": recipientName,
              "text": msg,
              "isImage": false,
              "isVoice": false,
              "isRead": false,
              "timestamp": FieldValue.serverTimestamp(),
            });

            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إرسال الرسالة إلى صندوق بريد الموهبة بنجاح ✅'), backgroundColor: Colors.green),
            );
          },
          child: const Text('إلغاء', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}