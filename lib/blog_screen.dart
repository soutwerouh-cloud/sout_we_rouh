import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("مدونة صوت وروح", style: TextStyle(color: Colors.white, fontSize: 16)),
          backgroundColor: Colors.purple.shade800,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          color: Colors.grey.shade100,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('blog_posts').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final posts = snapshot.hasData ? snapshot.data!.docs : [];
              if (posts.isEmpty) {
                return const Center(child: Text("لا توجد مقالات منشورة حالياً", style: TextStyle(color: Colors.grey)));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index].data() as Map<String, dynamic>;
                  
                  // تنسيق التاريخ والوقت بـ Dart البحت دون أخطاء
                  String formattedDate = '';
                  if (post['timestamp'] != null) {
                    Timestamp t = post['timestamp'] as Timestamp;
                    DateTime dt = t.toDate();
                    String hour = dt.hour > 12 ? '${dt.hour - 12}' : '${dt.hour}';
                    String period = dt.hour >= 12 ? 'مساءً' : 'صباحاً';
                    formattedDate = '${dt.year}/${dt.month}/${dt.day} - $hour:${dt.minute.toString().padLeft(2, '0')} $period';
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      title: Text(
                        post['title'] ?? '',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.purple.shade900),
                      ),
                      subtitle: formattedDate.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                "نُشر في: $formattedDate",
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            )
                          : null,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.purple),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlogPostDetailScreen(post: post, formattedDate: formattedDate),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// شاشة تفاصيل المقال المنفصلة
class BlogPostDetailScreen extends StatelessWidget {
  final Map<String, dynamic> post;
  final String formattedDate;
  const BlogPostDetailScreen({super.key, required this.post, required this.formattedDate});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(post['title'] ?? 'مقال', style: const TextStyle(color: Colors.white, fontSize: 15)),
          backgroundColor: Colors.purple.shade800,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: [
                Text(
                  post['title'] ?? '',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple.shade900, height: 1.4),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "الكاتب: ${post['author'] ?? 'إدارة منصة صوت وروح'}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    if (formattedDate.isNotEmpty)
                      Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
                const Divider(height: 24, thickness: 1),
                Text(
                  post['content'] ?? '',
                  style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}