import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'talent_model.dart';
import 'talent_messaging_helper.dart';
import 'talent_detail_screen.dart';

PreferredSizeWidget customAppBar(String titleText) {
  return AppBar(
    title: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            'assets/logo.png',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.star, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(width: 12),
        Text(titleText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    ),
    backgroundColor: const Color(0xFF7B1FA2),
    iconTheme: const IconThemeData(color: Colors.white),
    elevation: 2,
  );
}

Widget buildTalentListWithAllWorks(BuildContext context, String categoryKeyword, IconData icon, String appBarTitle) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: customAppBar(appBarTitle),
    body: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('talents').where('isApproved', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('لا توجد مواهب مفعلة حتى الآن', style: TextStyle(color: Colors.black54, fontSize: 16)));
        }

        var docs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String cat = data['category'] ?? '';
          return cat.contains(categoryKeyword);
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text('لا توجد مواهب مفعلة في هذا القسم حتى الآن', style: TextStyle(color: Colors.black54, fontSize: 16)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            var data = doc.data() as Map<String, dynamic>;
            var talent = TalentModel.fromMap(data, doc.id);

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('artist_works')
                  .where('artistName', isEqualTo: talent.name.trim())
                  .snapshots(),
              builder: (context, workSnapshot) {
                List<String> workTitles = [];
                if (workSnapshot.hasData) {
                  for (var wDoc in workSnapshot.data!.docs) {
                    var wData = wDoc.data() as Map<String, dynamic>;
                    if (wData['title'] != null) {
                      workTitles.add(wData['title']);
                    }
                  }
                }

                String worksText = workTitles.isNotEmpty 
                    ? 'الأعمال: ${workTitles.join(' - ')}' 
                    : 'لا توجد أعمال منشورة';

                return Center(
                  child: SizedBox(
                    width: 600,
                    child: Card(
                      elevation: 1.5,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0), // تصغير الحشو الداخلي
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end, // اسم الموهبة وأيقونتها على اليمين بالكامل بدون تصنيف
                              children: [
                                Text(talent.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF7B1FA2))),
                                const SizedBox(width: 8),
                                Icon(icon, color: const Color(0xFF7B1FA2), size: 20),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(worksText, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.purple, fontSize: 12)),
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7B1FA2),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: const Icon(Icons.mail, size: 12, color: Colors.white),
                                  label: const Text('مراسلة ✉️', style: TextStyle(color: Colors.white, fontSize: 11)),
                                  onPressed: () => showDirectMessageDialog(context, talent.name),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF7B1FA2)),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => TalentDetailScreen(talent: talent, icon: icon)));
                                  },
                                  child: const Text('التفاصيل 📖', style: TextStyle(color: Color(0xFF7B1FA2), fontSize: 11)),
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
            );
          },
        );
      },
    ),
  );
}