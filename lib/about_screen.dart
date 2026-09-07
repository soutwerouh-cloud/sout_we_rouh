import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('من نحن - صوت وروح', style: TextStyle(color: Colors.white)),
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
                    'عن منصة "صوت وروح"',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'تُعد منصة "صوت وروح" وجهتك الأولى والأبرز عالمياً وعربياً لاكتشاف، دعم، وتسليط الضوء على أروع المواهب الفنية في مجالات الغناء الأصيل، إلقاء الشعر، والتلحين الإبداعي. نحن نؤمن بأن كل صوت حقيقي يمتلك حكاية تستحق أن تُسمع، وأن الفن الراقي هو اللغة التي تجمع القلوب وترتقي بالمجتمعات. تأسست المنصة لتكون حاضنة رقمية متكاملة تتيح للمبدعين الشباب فرصة عرض أعمالهم الفنية على نطاق واسع، والوصول إلى جمهور مهتم بالثقافة والموسيقى الأصيلة.',
                    style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'رسالتنا ورؤيتنا',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '• تمكين المواهب: توفير مساحة آمنة وداعمة للمواهب الصاعدة لعرض إبداعاتهم الصوتية والشعرية بكل سهولة واحترافية.\n'
                    '• إثراء المحتوى الفني: بناء مجتمع فني راقٍ يجمع بين صناع الموسيقى، الشعراء، والجمهور الذواق.\n'
                    '• التواصل الفعال: خلق جسر تواصل مباشر ومستمر بين الفنانين والجمهور المهتم بالثقافة والموسيقى من خلال ميزات تفاعلية متطورة مثل راديو المنصة وغرف الدردشة الفنية.',
                    style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.6),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'ماذا تقدم منصة "صوت وروح"؟',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '• مساحة مخصصة لعرض الأعمال: تمكين الموهوبين من تسجيل وعرض أعمالهم الغنائية والشعرية والترويج لها.\n'
                    '• راديو وشات تفاعلي: تجربة استماع فريدة لأجمل الأغاني والأعمال الفنية مع إمكانية التواصل الحي والمباشر بين عشاق الفن.\n'
                    '• منصة اكتشاف ودعم: نافذة متجددة تتيح للجمهور اكتشاف أحدث المواهب الصاعدة ومتابعة مسيرتهم الفنية خطوة بخطوة.',
                    style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.6),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'نحن نلتزم بتقديم محتوى هادف، ومحترم يليق بذائقة الجمهور العربي، ونسعى دائماً لتطوير منصتنا لتكون البيت الدائم لكل صاحب صوت حقيقي وروح فنية مبدعة.',
                    style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
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