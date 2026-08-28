import 'package:flutter/material.dart';
import 'shared_widgets.dart';

class SingingScreen extends StatelessWidget {
  const SingingScreen({super.key});
  @override
  Widget build(BuildContext context) => buildTalentListWithAllWorks(context, 'غناء', Icons.mic, 'مواهب الغناء 🎤');
}

class PoetryScreen extends StatelessWidget {
  const PoetryScreen({super.key});
  @override
  Widget build(BuildContext context) => buildTalentListWithAllWorks(context, 'شعر', Icons.book, 'مواهب الشعر 📜');
}

class ComposingScreen extends StatelessWidget {
  const ComposingScreen({super.key});
  @override
  Widget build(BuildContext context) => buildTalentListWithAllWorks(context, 'تلحين', Icons.music_note, 'مواهب التلحين 🎼');
}