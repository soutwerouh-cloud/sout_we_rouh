import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'subscription_screen.dart';
import 'main_navigation_screen.dart';
import 'chat_radio_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyC0hhgt0mrzLN8d7dujnAcqmanAket4F24",
        authDomain: "sout-we-rouh.firebaseapp.com",
        projectId: "sout-we-rouh",
        storageBucket: "sout-we-rouh.firebasestorage.app",
        messagingSenderId: "250882692779",
        appId: "1:250882692779:web:36db079bd5ae62064549ee",
      ),
    );
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }
  
  runApp(const SoutWeRouhApp());
}

class SoutWeRouhApp extends StatelessWidget {
  const SoutWeRouhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'صوت وروح',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: const Color(0xFF6A1B9A),
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final ap.AudioPlayer _globalAudioPlayer = ap.AudioPlayer();
  int _lastKnownUnapprovedCount = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // مراقبة الطلبات لتعمل بشكل دقيق
    FirebaseFirestore.instance.collection('talents').snapshots().listen((snapshot) {
      int currentCount = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isApproved'] == false || data['isApproved'] == null;
      }).length;

      if (_lastKnownUnapprovedCount != -1 && currentCount > _lastKnownUnapprovedCount) {
        _globalAudioPlayer.play(ap.UrlSource('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'));
      }
      _lastKnownUnapprovedCount = currentCount;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _globalAudioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 180,
                  height: 180,
                ),
                const SizedBox(height: 15),
                const Text(
                  'أهلاً بكم في تطبيق',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'صوت وروح ✨',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'منصتكم الأولى لاكتشاف ودعم أروع المواهب في الغناء، الشعر، والتلحين.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 35),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF6A1B9A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
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
                      'تسجيل موهبة جديدة (مع الاشتراك)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
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
                      'تصفح التطبيق مباشرة',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () => showChatRadioLoginDialog(context),
                    child: const Text(
                      '📻 استماع راديو نجوم إف إم والشات',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return FractionalTranslation(
                          translation: Offset(-_controller.value, 0),
                          child: const Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                '🎶 اكتشف أروع المواهب الغنائية والشعرية • شارك إبداعاتك معنا الآن في راديو وشات صوت وروح ✨ صوتك ينبض بالحياة 🎵',
                                style: TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}