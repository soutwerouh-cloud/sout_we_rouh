import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:url_launcher/url_launcher.dart';
import 'talent_model.dart';
import 'talent_detail_screen.dart';
import 'shared_widgets.dart';

class ArtistsScreen extends StatefulWidget {
  const ArtistsScreen({super.key});

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  final ap.AudioPlayer _feedAudioPlayer = ap.AudioPlayer();
  String? _playingFeedWorkId;

  @override
  void dispose() {
    _feedAudioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playFeedAudio(String workId, String audioUrl) async {
    try {
      if (audioUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا يوجد رابط صوتي لهذا العمل ❌'), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      if (audioUrl.contains('youtube.com') || audioUrl.contains('youtu.be') || audioUrl.contains('facebook.com')) {
        final Uri uri = Uri.parse(audioUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        return;
      }

      if (_playingFeedWorkId == workId) {
        await _feedAudioPlayer.stop();
        if (mounted) setState(() => _playingFeedWorkId = null);
        return;
      }

      await _feedAudioPlayer.stop();
      if (mounted) setState(() => _playingFeedWorkId = workId);

      if (audioUrl.startsWith('http')) {
        await _feedAudioPlayer.play(ap.UrlSource(audioUrl));
      }

      _feedAudioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playingFeedWorkId = null);
      });
    } catch (e) {
      if (mounted) setState(() => _playingFeedWorkId = null);
    }
  }

  void _navigateToTalentProfile(String artistName) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('talents')
          .where('name', isEqualTo: artistName.trim())
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        var data = doc.data() as Map<String, dynamic>;
        var talent = TalentModel.fromMap(data, doc.id);

        IconData talentIcon = Icons.star;
        if (talent.category.contains('غناء')) talentIcon = Icons.mic;
        if (talent.category.contains('شعر')) talentIcon = Icons.book;
        if (talent.category.contains('تلحين')) talentIcon = Icons.music_note;

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TalentDetailScreen(talent: talent, icon: talentIcon),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('عذراً، ملف الموهبة غير متوفر ❌'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      // تجاهل الخطأ
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar('أحدث الأعمال المضافة 🌟'),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('artist_works').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('لا توجد أعمال منشورة حتى الآن 🎵', style: TextStyle(color: Colors.black54, fontSize: 16)),
            );
          }

          var works = snapshot.data!.docs.toList();

          works.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            Timestamp? timeA = dataA['timestamp'] as Timestamp?;
            Timestamp? timeB = dataB['timestamp'] as Timestamp?;

            if (timeA == null && timeB == null) return 0;
            if (timeA == null) return 1;
            if (timeB == null) return -1;
            return timeB.compareTo(timeA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: works.length,
            itemBuilder: (context, index) {
              var workDoc = works[index];
              var workData = workDoc.data() as Map<String, dynamic>;

              String title = workData['title'] ?? 'بدون عنوان';
              String artistName = workData['artistName'] ?? 'موهبة';
              String category = workData['category'] ?? 'عام';
              String content = workData['content'] ?? '';
              String audioUrl = workData['audioUrl'] ?? '';
              int likes = workData['likesCount'] ?? 0;
              var timestamp = workData['timestamp'] as Timestamp?;
              String dateStr = timestamp != null 
                  ? "${timestamp.toDate().year}/${timestamp.toDate().month}/${timestamp.toDate().day}" 
                  : 'منذ قليل';

              bool isPlaying = _playingFeedWorkId == workDoc.id;

              return Center(
                child: SizedBox(
                  width: 600,
                  child: Card(
                    elevation: 2,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _navigateToTalentProfile(artistName),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF7B1FA2)),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(category, style: const TextStyle(color: Color(0xFF7B1FA2), fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('الموهبة: $artistName 👆 (اضغط للانتقال للصفحة وقراءة العمل كاملاً)', style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            if (content.isNotEmpty)
                              Text(
                                content,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // زر التشغيل والإيقاف الواضح والصريح
                                    InkWell(
                                      onTap: () {
                                        String targetUrl = audioUrl.isNotEmpty ? audioUrl : content;
                                        _playFeedAudio(workDoc.id, targetUrl);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Icon(
                                          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                          color: isPlaying ? Colors.red : const Color(0xFF7B1FA2),
                                          size: 28, // حجم واضح وبارز
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    InkWell(
                                      onTap: () async {
                                        await FirebaseFirestore.instance
                                            .collection('artist_works')
                                            .doc(workDoc.id)
                                            .update({'likesCount': likes + 1});
                                      },
                                      child: const Icon(Icons.favorite, color: Colors.red, size: 18),
                                    ),
                                    const SizedBox(width: 4),
                                    Text('$likes إعجاب', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}