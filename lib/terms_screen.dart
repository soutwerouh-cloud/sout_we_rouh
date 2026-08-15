import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // نفس لون خلفية التطبيق
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/logo.png',
                width: 35,
                height: 35,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.star, color: Color(0xFF7B1FA2), size: 28),
              ),
            ),
            const SizedBox(width: 10),
            const Text('الشروط والأحكام', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text(
              "شروط وأحكام تطبيق صوت وروح",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7B1FA2),
              ),
            ),
            SizedBox(height: 16),
            _TermItem(text: "استخدامك للتطبيق يُعد موافقة صريحة على الشروط، وفي حال عدم الموافقة يجب التوقف عن الاستخدام فوراً."),
            _TermItem(text: "المحتوى الذي ترفعه الموهبة على صفحتها هو ملكية حصرية لها، ويُحظر تماماً رفع أي محتوى مسروق أو منتهك لحقوق الآخرين."),
            _TermItem(text: "المستخدم هو المسؤول الوحيد عن أي محتوى أو تعليقات يكتبها، والتطبيق غير مسؤول عن الآراء الشخصية."),
            _TermItem(text: "التحويلات المالية طوعية، ويتم الاسترداد خلال 48 ساعة للأخطاء التقنية بإثبات صحيح، ولا يُسترد المبلغ بعد البدء في معالجة الطلب."),
            _TermItem(text: "جميع محتويات التطبيق الأساسية من أغانٍ وألحان وتصميمات وأكواد هي ملكية حصرية، ويحظر نسخها أو استغلالها دون إذن."),
            _TermItem(text: "يُمنع نشر أي محتوى مسيء أو خادش للحياء، وللإدارة الحق في حذف المخالفات أو إنهاء الحسابات فوراً."),
            _TermItem(text: "تلتزم المنصة بالحفاظ على سرية البيانات الأساسية للمستخدمين وعدم مشاركتها مع أطراف خارجية."),
            _TermItem(text: "المنصة لا تضمن خلو التطبيق تماماً من الأخطاء التقنية أو التوقفات المفاجئة، وغير مسؤولة عن الروابط الخارجية."),
            _TermItem(text: "يحق للإدارة تعديل الشروط في أي وقت، ويعتبر استمرار الاستخدام موافقة صريحة على التحديثات."),
          ],
        ),
      ),
    );
  }
}

class _TermItem extends StatelessWidget {
  final String text;
  const _TermItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7B1FA2))),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}