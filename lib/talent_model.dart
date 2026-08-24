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
  final String phone;
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
    this.phone = '',
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
      'phone': phone,
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
      phone: map['phone'] ?? map['transactionRef'] ?? '',
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

// دالة إرسال رسالة مباشرة مخصصة للمشتركين والمواهب المفعلة فقط مع التحقق من الحساب وكلمة المرور
void showDirectMessageDialog(BuildContext context, String recipientName) {
  final TextEditingController senderNameController = TextEditingController();
  final TextEditingController senderPasswordController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('مراسلة إلى: $recipientName ✉️', style: const TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold, fontSize: 16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'المراسلة مخصصة للمشتركين والمواهب المفعلة فقط. يرجى إدخال بيانات حسابك:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: senderNameController,
              decoration: const InputDecoration(labelText: 'اسم حسابك المسجل (المرسل)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: senderPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة مرور حسابك', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'اكتب رسالتك هنا...', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B1FA2)),
          onPressed: () async {
            String senderName = senderNameController.text.trim();
            String senderPass = senderPasswordController.text.trim();
            String msg = messageController.text.trim();

            if (senderName.isEmpty || senderPass.isEmpty || msg.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('الرجاء إدخال اسمك، كلمة المرور، ومحتوى الرسالة ❌'), backgroundColor: Colors.red),
              );
              return;
            }

            // التحقق من وجود الحساب وحالته وكلمة المرور في قاعدة البيانات
            var querySnapshot = await FirebaseFirestore.instance
                .collection('talents')
                .where('name', isEqualTo: senderName)
                .get();

            if (querySnapshot.docs.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('اسم الحساب غير مسجل في المواهب المفعلة ❌'), backgroundColor: Colors.red),
              );
              return;
            }

            var talentData = querySnapshot.docs.first.data() as Map<String, dynamic>;
            String savedPassword = (talentData['password'] ?? '').toString().trim();
            bool isApproved = talentData['isApproved'] ?? false;

            if (!isApproved) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('حسابك غير مفعل حتى الآن من قبل الأدمن ⏳'), backgroundColor: Colors.orange),
              );
              return;
            }

            if (savedPassword != senderPass) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('كلمة المرور الخاصة بحسابك غير صحيحة ❌'), backgroundColor: Colors.red),
              );
              return;
            }

            // الإرسال الناجح باسم الموهبة الحقيقية وفي الكوليكشن المنفصل الخاص بالمواهب
            await FirebaseFirestore.instance.collection('talent_direct_messages').add({
              "sender": senderName,
              "receiver": recipientName.trim(),
              "text": msg,
              "isImage": false,
              "isVoice": false,
              "isRead": false,
              "timestamp": FieldValue.serverTimestamp(),
            });

            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إرسال الرسالة بنجاح باسم حسابك المفعل ✅'), backgroundColor: Colors.green),
            );
          },
          child: const Text('إرسال 🚀', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}