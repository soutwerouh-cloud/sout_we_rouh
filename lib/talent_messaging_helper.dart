import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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