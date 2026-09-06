import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('من نحن - صوت وروح', style: TextStyle(color: Colors.white)),
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
              'عن منصة "صوت وروح"',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF7B1FA2)),
            ),
            SizedBox(height: 12),
            Text(
              'منصة "صوت وروح" هي وجهتك الأولى والأبرز لاكتشاف، دعم، وتسليط الضوء على أروع المواهب الفنية في مجالات الغناء، الشعر، والتلحين. نؤمن بأن كل صوت حقيقي يمتلك حكاية تستحق أن تُسمع، وهدفنا هو بناء مجتمع فني راقٍ يجمع المواهب الصاعدة عشاق الفن الراقي.',
              style: TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
            ),
            SizedBox(height: 20),
            Text(
              'ماذا نقدم؟',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 8),
            Text(
              '• مساحة آمنة للمواهب لتسجيل وعرض أعمالهم الفنية.\n• راديو تفاعلي وغرفة شات لمتابعة كل جديد في عالم الطرب والفن.\n• جسر تواصل مباشر بين الفنانين والجمهور المهتم بالثقافة والموسيقى.',
              style: TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}