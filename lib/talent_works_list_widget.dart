import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TalentWorksListWidget extends StatelessWidget {
  final List<QueryDocumentSnapshot> works;
  final String? currentlyPlayingWorkId;
  final Function(String workId, String audioUrl) onPlayAudio;
  final Function(String workId, String currentTitle, String currentContent) onEditWork;
  final Function(String workId) onDeleteWork;
  final Function(String workId, int currentLikes) onLikeWork;

  const TalentWorksListWidget({
    super.key,
    required this.works,
    required this.currentlyPlayingWorkId,
    required this.onPlayAudio,
    required this.onEditWork,
    required this.onDeleteWork,
    required this.onLikeWork,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: ListView.builder(
        itemCount: works.length,
        itemBuilder: (context, index) {
          var workDoc = works[index];
          var workData = workDoc.data() as Map<String, dynamic>;
          int likes = workData['likesCount'] ?? 0;
          String? audioUrl = workData['audioUrl'];
          var timestamp = workData['timestamp'] as Timestamp?;
          String dateStr = timestamp != null 
              ? "${timestamp.toDate().year}/${timestamp.toDate().month}/${timestamp.toDate().day}" 
              : 'منذ قليل';

          bool isPlaying = currentlyPlayingWorkId == workDoc.id;

          return Center(
            child: SizedBox(
              width: 420,
              child: Card(
                elevation: 1.5,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              workData['title'] ?? '', 
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF7B1FA2)),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                tooltip: 'حذف العمل',
                                onPressed: () => onDeleteWork(workDoc.id),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 16),
                                tooltip: 'تعديل العمل',
                                onPressed: () => onEditWork(workDoc.id, workData['title'], workData['content']),
                              ),
                              const SizedBox(width: 4),
                              // زر التشغيل والإيقاف الواضح والصريح
                              InkWell(
                                onTap: () {
                                  String targetUrl = '';
                                  if (audioUrl != null && audioUrl.isNotEmpty) {
                                    targetUrl = audioUrl;
                                  } else {
                                    targetUrl = workData['content'] ?? '';
                                  }
                                  onPlayAudio(workDoc.id, targetUrl);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                    color: isPlaying ? Colors.red : const Color(0xFF7B1FA2),
                                    size: 28, // حجم كبير وواضح جداً للعين
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        workData['content'] ?? '', 
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => onLikeWork(workDoc.id, likes),
                                child: const Icon(Icons.favorite, color: Colors.red, size: 13),
                              ),
                              const SizedBox(width: 3),
                              Text('$likes إعجاب', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}