import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart' as ap;

import 'talents_category_screens.dart';
import 'artists_feed_screen.dart';
import 'guide_and_account_screens.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 4;
  final ap.AudioPlayer _globalAudioPlayer = ap.AudioPlayer();
  int _lastKnownUnapprovedCount = 0;

  @override
  void dispose() {
    _globalAudioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playGlobalNotificationSound() async {
    try {
      await _globalAudioPlayer.play(ap.UrlSource('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'));
    } catch (e) {
      debugPrint("خطأ في تشغيل صوت التنبيه العام: $e");
    }
  }

  final List<Widget> _screens = const [
    SingingScreen(),
    PoetryScreen(),
    ComposingScreen(),
    ArtistsScreen(),
    GuideScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('talents').snapshots(),
      builder: (context, globalSnapshot) {
        if (globalSnapshot.hasData) {
          int unapprovedCount = globalSnapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isApproved'] == false || data['isApproved'] == null;
          }).length;

          if (unapprovedCount > _lastKnownUnapprovedCount) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _playGlobalNotificationSound();
            });
          }
          _lastKnownUnapprovedCount = unapprovedCount;
        }

        return Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF7B1FA2),
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'الغناء'),
              BottomNavigationBarItem(icon: Icon(Icons.book), label: 'الشعر'),
              BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'التلحين'),
              BottomNavigationBarItem(icon: Icon(Icons.star), label: 'أحدث الأعمال'),
              BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'الدليل'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
            ],
          ),
        );
      },
    );
  }
}