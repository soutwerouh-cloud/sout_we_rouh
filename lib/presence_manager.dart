import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // تحديث حالة المستخدم إلى متصل فقط دون إرسال رسائل ثابتة للشات
  static Future<void> setOnline(String userName) async {
    if (userName.isEmpty || userName == "مستخدم") return;
    try {
      String cleanName = userName.trim().toLowerCase();
      var snapshot = await _firestore.collection('talents').get();
      
      for (var doc in snapshot.docs) {
        String dbName = (doc.data()['name'] ?? '').toString().trim().toLowerCase();
        if (dbName == cleanName) {
          await doc.reference.update({
            'isOnline': true,
            'lastSeen': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint("خطأ في تحديث الحالة إلى متصل: $e");
    }
  }

  // تحديث حالة المستخدم إلى غير متصل فقط دون إرسال رسائل ثابتة للشات
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
    } catch (e) {
      debugPrint("خطأ في تحديث الحالة إلى غير متصل: $e");
    }
  }
}