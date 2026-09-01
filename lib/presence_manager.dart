import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // تحديث حالة المستخدم إلى متصل وإرسال رسالة ترحيبية في الشات العام
  static Future<void> setOnline(String userName) async {
    if (userName.isEmpty || userName == "مستخدم") return;
    try {
      String cleanName = userName.trim().toLowerCase();
      var snapshot = await _firestore.collection('talents').get();
      
      bool updated = false;
      for (var doc in snapshot.docs) {
        String dbName = (doc.data()['name'] ?? '').toString().trim().toLowerCase();
        if (dbName == cleanName) {
          await doc.reference.update({
            'isOnline': true,
            'lastSeen': FieldValue.serverTimestamp(),
          });
          updated = true;
        }
      }

      // إرسال رسالة نظام ترحيبية تلقائية عند دخول المستخدم للشات
      if (updated || userName.isNotEmpty) {
        await _firestore.collection('messages').add({
          "sender": "نظام الشات 🤖",
          "text": "منور الشات يا $userName 👋✨ أهلاً بيك معنا!",
          "isImage": false,
          "isVoice": false,
          "timestamp": FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("خطأ في تحديث الحالة إلى متصل: $e");
    }
  }

  // تحديث حالة المستخدم إلى غير متصل وإرسال رسالة مغادرة في الشات العام
  static Future<void> setOffline(String userName) async {
    if (userName.isEmpty || userName == "مستخدم") return;
    try {
      String cleanName = userName.trim().toLowerCase();
      var snapshot = await _firestore.collection('talents').get();
      
      for (var doc in snapshot.docs) {
        String dbName = (doc.data()['name'] ?? '').toString().trim().toLowerCase();
        if (dbName == cleanName) {
          await doc.reference.update({
            'isOnline': false,
            'lastSeen': FieldValue.serverTimestamp(),
          });
        }
      }

      // إرسال رسالة نظام تلقائية عند خروج المستخدم من الشات
      await _firestore.collection('messages').add({
        "sender": "نظام الشات 🤖",
        "text": "غادر الغرفة $userName 👋 ننتظر عودتك قريبًا 🌸",
        "isImage": false,
        "isVoice": false,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("خطأ في تحديث الحالة إلى غير متصل: $e");
    }
  }
}