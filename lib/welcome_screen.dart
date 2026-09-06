import 'package:flutter/material.dart';
import 'subscription_screen.dart';
import 'main_navigation_screen.dart';
import 'artists_feed_screen.dart';
import 'radio_and_public_chat_screen.dart';
import 'privacy_screen.dart';
import 'about_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // خلفية بيضاء نقية ومشرقة تماماً
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 5),
                // اللوجو
                Image.asset(
                  'assets/logo.png',
                  height: 140,
                  width: 140,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.mic_rounded,
                    size: 70,
                    color: Color(0xFF5E35B1),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "أهلاً بكم في تطبيق",
                  style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("✨", style: TextStyle(fontSize: 14)),
                    SizedBox(width: 5),
                    Text(
                      "صوت وروح",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5E35B1), // بنفسجي ملكي راقي
                      ),
                    ),
                    SizedBox(width: 5),
                    Text("✨", style: TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  "منصتكم الأولى لاكتشاف ودعم أروع المواهب في الغناء، الشعر، والتلحين.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 18),
                
                // 1. زر تسجيل موهبة جديدة (بنفسجي ملكي)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5E35B1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "تسجيل موهبة جديدة (مع الاشتراك)",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 2. زر تصفح التطبيق مباشرة (إطار بنفسجي أنيق)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF5E35B1), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainNavigationScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "تصفح التطبيق مباشرة",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5E35B1)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 3. زر راديو نجوم إف إم والشات (تيركواز هادئ ومريح)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () {
                      showChatRadioLoginDialog(context);
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "استماع راديو نجوم إف إم والشات",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Text("📻", style: TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 4. زر اكتشف المواهب
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3E5F5), // خلفية بنفسجية فاتحة جداً تكسر حدة الأبيض
                      foregroundColor: const Color(0xFF5E35B1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArtistsScreen(), 
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("🎵", style: TextStyle(fontSize: 15)),
                        SizedBox(width: 8),
                        Text(
                          "اكتشف أروع المواهب الغنائية والشعرية",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // البريد الإلكتروني الثابت
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.email_outlined, color: Colors.grey, size: 14),
                    SizedBox(width: 6),
                    Text(
                      "soutwerouh@gmail.com",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // أزرار السوشيال ميديا
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6.0,
                    runSpacing: 6.0,
                    children: [
                      ActionChip(
                        backgroundColor: const Color(0xFF1877F2),
                        avatar: const Icon(Icons.facebook, color: Colors.white, size: 16),
                        label: const Text('فيسبوك', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () => _launchURL('https://www.facebook.com/soutwerouh.official'),
                      ),
                      ActionChip(
                        backgroundColor: const Color(0xFFE4405F),
                        avatar: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                        label: const Text('إنستجرام', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () => _launchURL('https://www.instagram.com/soutwerouh.official/'),
                      ),
                      ActionChip(
                        backgroundColor: Colors.black87,
                        avatar: const Icon(Icons.music_note, color: Colors.white, size: 14),
                        label: const Text('تيك توك', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () => _launchURL('https://www.tiktok.com/@soutwerouh'),
                      ),
                      ActionChip(
                        backgroundColor: const Color(0xFFE53935),
                        avatar: const Icon(Icons.video_library, color: Colors.white, size: 14),
                        label: const Text('يوتيوب', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () => _launchURL('https://www.youtube.com/@soutwerouh'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // روابط من نحن وسياسة الخصوصية
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
                      },
                      child: const Text('من نحن', style: TextStyle(color: Color(0xFF5E35B1), fontSize: 12, decoration: TextDecoration.underline)),
                    ),
                    const Text('•', style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyScreen()));
                      },
                      child: const Text('سياسة الخصوصية', style: TextStyle(color: Color(0xFF5E35B1), fontSize: 12, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// نافذة تسجيل الدخول للشات والراديو
void showChatRadioLoginDialog(BuildContext context) {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: const Text('دخول غرفة الشات والراديو 🎧', style: TextStyle(color: Color(0xFF5E35B1), fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'اسمك الحقيقي المسجل', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'كلمة المرور الشخصية للحساب', border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5E35B1)),
          onPressed: () async {
            String enteredName = nameController.text.trim();
            String enteredPassword = passwordController.text.trim();

            if (enteredName.isEmpty || enteredPassword.isEmpty) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('الرجاء إدخال الاسم وكلمة المرور ❌'), backgroundColor: Colors.red),
              );
              return;
            }

            var querySnapshot = await FirebaseFirestore.instance
                .collection('talents')
                .where('name', isEqualTo: enteredName)
                .get();

            if (!dialogContext.mounted) return;

            if (querySnapshot.docs.isNotEmpty) {
              var talentData = querySnapshot.docs.first.data() as Map<String, dynamic>;
              String savedPassword = (talentData['password'] ?? '').toString().trim();
              bool isApproved = talentData['isApproved'] ?? false;

              if (!isApproved) {
                ScaffoldMessenger.of(dialogContext.mounted ? dialogContext : context).showSnackBar(
                  const SnackBar(content: Text('هذا الحساب قيد المراجعة أو غير مفعل من الأدمن ⏳'), backgroundColor: Colors.orange),
                );
                return;
              }

              if (savedPassword == enteredPassword) {
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatRadioScreen(currentUserName: enteredName),
                  ),
                );
              } else {
                ScaffoldMessenger.of(dialogContext.mounted ? dialogContext : context).showSnackBar(
                  const SnackBar(content: Text('كلمة المرور غير صحيحة ❌'), backgroundColor: Colors.red),
                );
              }
            } else {
              ScaffoldMessenger.of(dialogContext.mounted ? dialogContext : context).showSnackBar(
                const SnackBar(content: Text('لم يتم العثور على اسم الموهبة بهذا الاسم ❌'), backgroundColor: Colors.red),
              );
            }
          },
          child: const Text('دخول 🚀', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}