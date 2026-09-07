import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سياسة الخصوصية - صوت وروح', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF7B1FA2),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8E44AD),
                Color(0xFF9B59B6),
                Color(0xFFE08283),
                Color(0xFF512DA8),
              ],
              stops: [0.0, 0.3, 0.65, 1.0],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'سياسة الخصوصية لمنصة "صوت وروح"',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'مرحباً بك/بكم في منصة "صوت وروح". نحن نولي اهتماماً بالغاً بخصوصية زوارنا ومستخدمينا. توضح وثيقة سياسة الخصوصية هذه أنواع المعلومات التي يتم جمعها وكيفية استخدامها وحمايتها.',
                    style: TextStyle(fontSize: 14, color: Colors.white, height: 1.6, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '1. ملفات تعريف الارتباط والإعلانات (Google AdSense & Analytics)',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• نستخدم خدمات تحليلات جوجل (Google Analytics) لفهم كيفية تفاعل الزوار مع المنصة لتحسين تجربة الاستخدام.\n'
                    '• تستخدم شركة Google بصفتها مورداً خارجياً ملفات تعريف الارتباط (Cookies) لعرض الإعلانات على موقعنا.\n'
                    '• يتيح استخدام Google لملف تعريف الارتباط DART عرض الإعلانات للمستخدمين بناءً على زيارتهم لموقعنا أو المواقع الأخرى على الإنترنت.\n'
                    '• يمكن للمستخدمين إلغاء استخدام ملف تعريف الارتباط DART عن طريق زيارة سياسة الخصوصية الخاصة بإعلانات جوجل وشبكة المحتوى.',
                    style: TextStyle(fontSize: 14, color: Colors.white, height: 1.6, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '2. حماية البيانات وأمن المعلومات',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'نلتزم باتخاذ كافة التدابير التقنية والأمنية المناسبة لحماية المعلومات والبيانات الشخصية وضمان عدم الوصول إليها أو تعديلها أو الإفصاح عنها بشكل غير مبرر.',
                    style: TextStyle(fontSize: 14, color: Colors.white, height: 1.6, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '3. التعديلات على سياسة الخصوصية',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'يحق لنا تحديث سياسة الخصوصية من وقت لآخر لتتوافق مع المتطلبات التقنية أو القانونية، وسيتم نشر أي تغييرات جديدة على هذه الصفحة.',
                    style: TextStyle(fontSize: 14, color: Colors.white, height: 1.6, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '4. اتصل بنا',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'إذا كان لديك أي استفسارات بخصوص سياسة الخصوصية هذه، يمكنك مراسلتنا عبر البريد الإلكتروني الرسمي للمنصة: soutwerouh@gmail.com',
                    style: TextStyle(fontSize: 14, color: Colors.white, height: 1.6, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}