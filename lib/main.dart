import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'welcome_screen.dart';

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