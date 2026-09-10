import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// دالة تنظيف الرسائل الخاصة بالمواهب (الاحتفاظ بآخر 30 رسالة لكل مستخدم وحذف الباقي تلقائياً)
Future<void> _cleanupTalentDirectMessages(String senderName, String recipientName) async {
  try {
    var snapshot = await FirebaseFirestore.instance
        .collection('talent_direct_messages')
        .orderBy('timestamp', descending: true)
        .get();

    var conversationDocs = snapshot.docs.where((doc) {
      final data = doc.data();
      String sender = data['sender'] ?? '';
      String receiver = data['receiver'] ?? '';
      return (sender == senderName && receiver == recipientName) ||
             (sender == recipientName && receiver == senderName);
    }).toList();

    if (conversationDocs.length > 30) {
      for (int i = 30; i < conversationDocs.length; i++) {
        await conversationDocs[i].reference.delete();
      }
    }
  } catch (e) {
    debugPrint("خطأ تنظيف رسائل المواهب المباشرة: $e");
  }
}

// دالة إرسال رسالة مباشرة مخصصة للمشتركين والمواهب المفعلة مع التوجيه الذكي (أونلاين/أوفلاين)
void showDirectMessageDialog(BuildContext context, String recipientName) {
  final TextEditingController senderNameController = TextEditingController();
  final TextEditingController senderPasswordController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => Padding(
      // هذا السطر يرفع الديالوج بالكامل فوق لوحة المفاتيح فور ظهورها
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: AlertDialog(
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
              String recipientClean = recipientName.trim();

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

              // 1. فحص حالة المستقبل (هل هو Online أم Offline) من مجموعة المواهب أو الحضور
              var recipientQuery = await FirebaseFirestore.instance
                  .collection('talents')
                  .where('name', isEqualTo: recipientClean)
                  .get();

              bool isRecipientOnline = false;
              if (recipientQuery.docs.isNotEmpty) {
                var recipientData = recipientQuery.docs.first.data();
                isRecipientOnline = recipientData['isOnline'] ?? false;
              }

              // 2. تطبيق التوجيه الذكي: لو أونلاين تذهب للمحادثة المباشرة الفورية، لو أوفلاين تحول لصندوق البريد
              String targetCollection = isRecipientOnline ? 'talent_direct_messages' : 'inbox_messages';

              await FirebaseFirestore.instance.collection(targetCollection).add({
                "sender": senderName,
                "receiver": recipientClean,
                "text": msg,
                "isImage": false,
                "isVoice": false,
                "isRead": false,
                "timestamp": FieldValue.serverTimestamp(),
              });

              if (isRecipientOnline) {
                // تفعيل التنظيف التلقائي فقط لو كانت رسالة شات مباشر
                await _cleanupTalentDirectMessages(senderName, recipientClean);
              }

              if (!context.mounted) return;
              Navigator.pop(context);
              
              String successMsg = isRecipientOnline 
                  ? 'تم إرسال الرسالة مباشرة لشات المستخدم ✅' 
                  : 'المستخدم غير متصل، تم إرسال رسالتك إلى صندوق البريد بنجاح 📥';

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(successMsg), backgroundColor: Colors.green),
              );
            },
            child: const Text('إرسال 🚀', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}