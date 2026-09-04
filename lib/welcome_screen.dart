import 'package:flutter/material.dart';
import 'subscription_screen.dart';
import 'main_navigation_screen.dart';
import 'artists_feed_screen.dart';
import 'radio_and_public_chat_screen.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // دالة لفتح الروابط الخارجية
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
        backgroundColor: const Color(0xFF7B1FA2),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // اللوجو لوحده وبحجم أكبر وواضح
                Image.asset(
                  'assets/logo.png',
                  height: 200, 
                  width: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.mic_rounded,
                    size: 90,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  "أهلاً بكم في تطبيق",
                  style: TextStyle(fontSize: 17, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("✨", style: TextStyle(fontSize: 17)),
                    SizedBox(width: 5),
                    Text(
                      "صوت وروح",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 5),
                    Text("✨", style: TextStyle(fontSize: 17)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  "منصتكم الأولى لاكتشاف ودعم أروع المواهب في الغناء، الشعر، والتلحين.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.3),
                ),
                const SizedBox(height: 25),
                
                // 1. زر تسجيل موهبة جديدة
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF7B1FA2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 3,
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
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. زر تصفح التطبيق مباشرة
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white, width: 1.5),
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
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. زر راديو نجوم إف إم والشات
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 3,
                    ),
                    onPressed: () {
                      showChatRadioLoginDialog(context);
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "استماع راديو نجوم إف إم والشات",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Text("📻", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 4. زر اكتشف المواهب
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(74, 20, 140, 0.6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      side: const BorderSide(color: Colors.purple, width: 1),
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
                        Text("🎵", style: TextStyle(fontSize: 16)),
                        SizedBox(width: 8),
                        Text(
                          "اكتشف أروع المواهب الغنائية والشعرية",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // البريد الإلكتروني الثابت بأسفل الشاشة
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.email_outlined, color: Colors.white70, size: 16),
                    SizedBox(width: 6),
                    Text(
                      "soutwerouh@gmail.com",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // أزرار منصات التواصل الاجتماعي بألوان مميزة وتصميم احترافي
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      // فيسبوك
                      ActionChip(
                        backgroundColor: const Color(0xFF1877F2),
                        avatar: const Icon(Icons.facebook, color: Colors.white, size: 18),
                        label: const Text('فيسبوك', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () => _launchURL('https://www.facebook.com/soutwerouh.official'),
                      ),
                      // إنستجرام
                      ActionChip(
                        backgroundColor: const Color(0xFFE4405F),
                        avatar: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        label: const Text('إنستجرام', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () => _launchURL('https://www.instagram.com/soutwerouh.official/'),
                      ),
                      // تيك توك
                      ActionChip(
                        backgroundColor: Colors.black,
                        avatar: const Icon(Icons.music_note, color: Colors.white, size: 16),
                        label: const Text('تيك توك', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () => _launchURL('https://www.tiktok.com/@soutwerouh'),
                      ),
                      // يوتيوب
                      ActionChip(
                        backgroundColor: const Color(0xFFFF0000),
                        avatar: const Icon(Icons.video_library, color: Colors.white, size: 16),
                        label: const Text('يوتيوب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () => _launchURL('https://www.youtube.com/@soutwerouh'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// نافذة تسجيل الدخول للشات والراديو مربوطة بالشاشة الجديدة
void showChatRadioLoginDialog(BuildContext context) {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: const Text('دخول غرفة الشات والراديو 🎧', style: TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold)),
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
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B1FA2)),
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