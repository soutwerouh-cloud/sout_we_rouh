import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سياسة الخصوصية - صوت وروح', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF7B1FA2),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'سياسة الخصوصية لمنصة صوت وروح',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF7B1FA2)),
            ),
            SizedBox(height: 12),
            Text(
              'مرحباً بكِ/بكم في منصة "صوت وروح". نحن نولي اهتماماً بالغاً بخصوصية زوارنا ومستخدمينا. توضح وثيقة سياسة الخصوصية هذه أنواع المعلومات التي يتم جمعها وكيفية استخدامها وحمايتها.',
              style: TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
            ),
            SizedBox(height: 20),
            Text(
              '1. ملفات تعريف الارتباط (Google Analytics & AdSense):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 8),
            Text(
              'نستخدم خدمات تحليلات جوجل (Google Analytics) لفهم كيفية تفاعل الزوار مع المنصة لتحسين تجربة الاستخدام. كما قد تستخدم شركات الإعلانات الطرف الثالث (مثل Google AdSense) ملفات تعريف الارتباط لعرض إعلانات بناءً على زيارات المستخدمين السابقة للموقع.',
              style: TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
            ),
            SizedBox(height: 20),
            Text(
              '2. حماية البيانات:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 8),
            Text(
              'نلتزم باتخاذ كافة التدابير الأمنية المناسبة لحماية المعلومات والبيانات الشخصية وضمان عدم الوصول إليها بشكل غير مبرر.',
              style: TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
            ),
            SizedBox(height: 20),
            Text(
              '3. التعديلات على السياسة:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 8),
            Text(
              'يحق لنا تحديث سياسة الخصوصية من وقت لآخر، وسيتم نشر أي تغيرات على هذه الصفحة.',
              style: TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}