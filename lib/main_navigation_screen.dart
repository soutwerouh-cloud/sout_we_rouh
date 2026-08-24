import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'dart:convert';
import 'talent_model.dart';
import 'talent_messages_screen.dart';

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
              BottomNavigationBarItem(icon: Icon(Icons.star), label: 'الفنانين'),
              BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'الدليل'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
            ],
          ),
        );
      },
    );
  }
}

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

class TalentDetailScreen extends StatefulWidget {
  final TalentModel talent;
  final IconData icon;

  const TalentDetailScreen({super.key, required this.talent, required this.icon});

  @override
  State<TalentDetailScreen> createState() => _TalentDetailScreenState();
}

class _TalentDetailScreenState extends State<TalentDetailScreen> {
  final TextEditingController _workTitleController = TextEditingController();
  final TextEditingController _workContentController = TextEditingController();
  final TextEditingController _passVerifyController = TextEditingController();
  String _currentProfileImage = '';
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _currentProfileImage = widget.talent.profileImage;
    _fetchLatestProfileImage();
  }

  void _fetchLatestProfileImage() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('talents')
          .where('name', isEqualTo: widget.talent.name.trim())
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        if (data.containsKey('profileImage') && data['profileImage'] != null && data['profileImage'].toString().length > 10) {
          setState(() {
            _currentProfileImage = data['profileImage'];
          });
        }
      }
    } catch (e) {
      // تجاهل الخطأ
    }
  }

  void _checkPasswordAndExecute(VoidCallback onSuccess) {
    if (_isAuthorized) {
      onSuccess();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('كلمة المرور مطلوبة 🔐', style: TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _passVerifyController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'أدخل كلمة مرور صفحتك الشخصية',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _passVerifyController.clear();
              Navigator.pop(context);
            },
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B1FA2)),
            onPressed: () async {
              String targetName = widget.talent.name.trim();

              var querySnapshot = await FirebaseFirestore.instance
                  .collection('talents')
                  .where('name', isEqualTo: targetName)
                  .get();

              if (querySnapshot.docs.isNotEmpty) {
                var talentData = querySnapshot.docs.first.data() as Map<String, dynamic>;
                String savedPassword = (talentData['password'] ?? '').toString().trim();
                String enteredPassword = _passVerifyController.text.trim();

                if (savedPassword == enteredPassword) {
                  _passVerifyController.clear();
                  Navigator.pop(context);
                  setState(() {
                    _isAuthorized = true;
                  });
                  onSuccess();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('كلمة المرور غير صحيحة ❌'), backgroundColor: Colors.red),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('لم يتم العثور على بيانات الموهبة ❌'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('تحقق ودخول', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      Uint8List imageBytes = await image.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      var querySnapshot = await FirebaseFirestore.instance
          .collection('talents')
          .where('name', isEqualTo: widget.talent.name.trim())
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String docId = querySnapshot.docs.first.id;
        await FirebaseFirestore.instance.collection('talents').doc(docId).update({
          'profileImage': base64Image,
        });

        setState(() {
          _currentProfileImage = base64Image;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تثبيت الصورة الشخصية بنجاح ولن تختفي ✅'), backgroundColor: Colors.green),
          );
        }
      }
    }
  }

  void _addNewWork() async {
    if (_workTitleController.text.isEmpty || _workContentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال عنوان العمل والمحتوى ❌'), backgroundColor: Colors.red),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('artist_works').add({
      'artistName': widget.talent.name.trim(),
      'artistEmail': widget.talent.email.trim(),
      'category': widget.talent.category,
      'title': _workTitleController.text.trim(),
      'content': _workContentController.text.trim(),
      'likesCount': 0,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _workTitleController.clear();
    _workContentController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ ونشر العمل بنجاح ✅'), backgroundColor: Colors.green),
      );
    }
  }

  void _showEditWorkDialog(String workId, String currentTitle, String currentContent) {
    TextEditingController editTitleController = TextEditingController(text: currentTitle);
    TextEditingController editContentController = TextEditingController(text: currentContent);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل العمل المنشور ✏️', style: TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editTitleController,
              decoration: const InputDecoration(labelText: 'عنوان العمل', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: editContentController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'محتوى أو كلمات العمل', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B1FA2)),
            onPressed: () async {
              if (editTitleController.text.isNotEmpty && editContentController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('artist_works').doc(workId).update({
                  'title': editTitleController.text.trim(),
                  'content': editContentController.text.trim(),
                });
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تعديل العمل بنجاح ✅'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('حفظ التعديلات', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isPoet = widget.talent.category.contains('شعر') || widget.talent.category.contains('شع');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar(widget.talent.name),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Stack(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('talents')
                      .where('name', isEqualTo: widget.talent.name.trim())
                      .snapshots(),
                  builder: (context, snapshot) {
                    String imgPath = _currentProfileImage;
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      var data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                      if (data.containsKey('profileImage') && data['profileImage'] != null && data['profileImage'].toString().length > 10) {
                        imgPath = data['profileImage'];
                      }
                    }

                    ImageProvider? provider;
                    if (imgPath.isNotEmpty) {
                      try {
                        provider = MemoryImage(base64Decode(imgPath));
                      } catch (e) {
                        provider = null;
                      }
                    }

                    return CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF7B1FA2).withOpacity(0.1),
                      backgroundImage: provider,
                      child: provider == null
                          ? Icon(widget.icon, size: 50, color: const Color(0xFF7B1FA2))
                          : null,
                    );
                  },
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: InkWell(
                    onTap: () => _checkPasswordAndExecute(_pickAndUploadImage),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF7B1FA2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.talent.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B1FA2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.mail, size: 16, color: Colors.white),
                  label: const Text('مراسلة', style: TextStyle(color: Colors.white, fontSize: 12)),
                  onPressed: () => showDirectMessageDialog(context, widget.talent.name),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B1FA2),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.mark_email_read, size: 18, color: Colors.white),
              label: const Text('فتح صندوق الرسائل والوارد 📬', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              onPressed: () {
                _checkPasswordAndExecute(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TalentMessagesScreen(talentName: widget.talent.name),
                    ),
                  );
                });
              },
            ),

            const SizedBox(height: 6),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('talents')
                  .where('name', isEqualTo: widget.talent.name.trim())
                  .snapshots(),
              builder: (context, snapshot) {
                String joinedText = "عضو في صوت وروح";
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  var data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  if (data.containsKey('joinedAt') && data['joinedAt'] != null) {
                    Timestamp t = data['joinedAt'];
                    joinedText = "عضو منذ: ${t.toDate().year}/${t.toDate().month}/${t.toDate().day}";
                  }
                }
                return Text(
                  joinedText,
                  style: const TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                );
              },
            ),

            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('نبذة عن الموهبة / العمل:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7B1FA2))),
                  const SizedBox(height: 8),
                  Text(widget.talent.bio.isNotEmpty ? widget.talent.bio : 'لا توجد نبذة مسجلة', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 12),
                  Text('القسم: ${widget.talent.category}', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ExpansionTile(
              title: Text(
                isPoet ? '📜 إضافة قصيدة أو عمل كتابي جديد' : '🎵 إضافة رابط صوتي أو لحن (MP3)',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7B1FA2)),
              ),
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: _workTitleController,
                  readOnly: !_isAuthorized,
                  onTap: () {
                    if (!_isAuthorized) {
                      _checkPasswordAndExecute(() {});
                    }
                  },
                  decoration: const InputDecoration(labelText: 'عنوان العمل (مثلاً: اسم الأغنية أو القصيدة)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _workContentController,
                  readOnly: !_isAuthorized,
                  onTap: () {
                    if (!_isAuthorized) {
                      _checkPasswordAndExecute(() {});
                    }
                  },
                  maxLines: isPoet ? 4 : 1,
                  decoration: InputDecoration(
                    labelText: isPoet ? 'اكتب كلمات الشعر والقصيدة هنا...' : 'أدخل رابط الصوت أو الـ MP3 (SoundCloud / YouTube)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B1FA2)),
                  onPressed: () => _checkPasswordAndExecute(_addNewWork),
                  child: const Text('حفظ ونشر العمل 🚀', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
              ],
            ),
            const Divider(height: 40),
            
            const Align(
              alignment: Alignment.centerRight,
              child: Text('الأعمال المنشورة للموهبة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7B1FA2))),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              height: 350,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('artist_works')
                    .where('artistName', isEqualTo: widget.talent.name.trim())
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('لا توجد أعمال منشورة حتى الآن', style: TextStyle(color: Colors.grey)));
                  }

                  var works = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: works.length,
                    itemBuilder: (context, index) {
                      var workDoc = works[index];
                      var workData = workDoc.data() as Map<String, dynamic>;
                      int likes = workData['likesCount'] ?? 0;
                      var timestamp = workData['timestamp'] as Timestamp?;
                      String dateStr = timestamp != null 
                          ? "${timestamp.toDate().year}/${timestamp.toDate().month}/${timestamp.toDate().day}" 
                          : 'منذ قليل';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(workData['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF7B1FA2))),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                        tooltip: 'تعديل العمل',
                                        onPressed: () {
                                          _checkPasswordAndExecute(() {
                                            _showEditWorkDialog(workDoc.id, workData['title'], workData['content']);
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        tooltip: 'حذف العمل',
                                        onPressed: () {
                                          _checkPasswordAndExecute(() async {
                                            bool? confirm = await showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('تأكيد الحذف 🗑️'),
                                                content: const Text('هل أنت متأكد من حذف هذا العمل نهائياً؟'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                    onPressed: () => Navigator.pop(context, true),
                                                    child: const Text('حذف', style: TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              await FirebaseFirestore.instance.collection('artist_works').doc(workDoc.id).delete();
                                              if (!mounted) return;
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('تم حذف العمل بنجاح 🗑️'), backgroundColor: Colors.red),
                                                );
                                              }
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(workData['content'] ?? '', style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.favorite, color: Colors.red),
                                        onPressed: () async {
                                          await FirebaseFirestore.instance
                                              .collection('artist_works')
                                              .doc(workDoc.id)
                                              .update({'likesCount': likes + 1});
                                        },
                                      ),
                                      Text('$likes إعجاب', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
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
          padding: const EdgeInsets.all(16.0),
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

                return Card(
                  elevation: 2,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(icon, color: const Color(0xFF7B1FA2)),
                                const SizedBox(width: 8),
                                Text(talent.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            Text(talent.category, style: const TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(worksText, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.purple, fontSize: 13)),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7B1FA2),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              ),
                              icon: const Icon(Icons.mail, size: 14, color: Colors.white),
                              label: const Text('مراسلة الموهبة ✉️', style: TextStyle(color: Colors.white, fontSize: 11)),
                              onPressed: () => showDirectMessageDialog(context, talent.name),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF7B1FA2)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                );
              },
            );
          },
        );
      },
    ),
  );
}

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

class ArtistsScreen extends StatelessWidget {
  const ArtistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar('الفنانين المعروفين ⭐'),
      body: const Center(
        child: Text('لا توجد مواهب مفعلة في هذا القسم حالياً', style: TextStyle(color: Colors.black54, fontSize: 16)),
      ),
    );
  }
}

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar('دليل كل المواهب 📖'),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('talents').where('isApproved', isEqualTo: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(top: 50.0),
              child: Center(child: Text('الدليل فارغ حالياً، بانتظار تفعيل المواهب', style: TextStyle(color: Colors.black54))),
            );
          }

          var docs = snapshot.data!.docs;
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const TextField(
                decoration: InputDecoration(
                  hintText: 'ابحث عن اسم موهبة أو عمل...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ...docs.map((doc) {
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
                        if (wData['title'] != null) workTitles.add(wData['title']);
                      }
                    }

                    String worksText = workTitles.isNotEmpty ? 'الأعمال: ${workTitles.join(' - ')}' : 'لا توجد أعمال';

                    return Card(
                      color: Colors.white,
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(talent.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                                Text(talent.category, style: const TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(worksText, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.purple, fontSize: 13)),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7B1FA2),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                  icon: const Icon(Icons.mail, size: 16, color: Colors.white),
                                  label: const Text('مراسلة الموهبة ✉️', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  onPressed: () => showDirectMessageDialog(context, talent.name),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF7B1FA2)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TalentDetailScreen(
                                          talent: talent, 
                                          icon: Icons.menu_book,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('التفاصيل 📖', style: TextStyle(color: Color(0xFF7B1FA2), fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isAuthenticated = false;
  final TextEditingController _passwordController = TextEditingController();
  final String _adminPassword = "125587";

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _showSmallMessage(BuildContext context, String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: customAppBar('حماية لوحة الأدمن 🔐'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Color(0xFF7B1FA2)),
                const SizedBox(height: 20),
                const Text(
                  'هذه الصفحة محمية ولا يمكن الوصول إليها\nالرجاء إدخال كلمة المرور للمتابعة',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'كلمة المرور...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.key, color: Color(0xFF7B1FA2)),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B1FA2),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (_passwordController.text == _adminPassword) {
                      setState(() {
                        _isAuthenticated = true;
                      });
                    } else {
                      _showSmallMessage(context, 'كلمة المرور غير صحيحة ❌');
                    }
                  },
                  child: const Text('دخول', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'للاستفسار أو استعادة كلمة المرور، تواصل عبر:\nhayamahmoud049@gmail.com',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: customAppBar('حسابي والأدمن 👤'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(radius: 40, backgroundColor: Color(0xFF7B1FA2), child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.white)),
            const SizedBox(height: 10),
            const Text('مي محمود (أدمن التطبيق 👑)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const Text('hayamahmoud049@gmail.com', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerRight,
              child: Text('طلبات الاشتراك والتحقق من الدفع (للأدمن فقط):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15)),
            ),
            const Divider(color: Colors.grey),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('talents').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('لا توجد أي طلبات اشتراك مسجلة حتى الآن', style: TextStyle(color: Colors.black54)));
                  }

                  var docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var doc = docs[index];
                      var data = doc.data() as Map<String, dynamic>;

                      String name = data['name'] ?? 'بدون اسم';
                      String category = data['category'] ?? 'غناء';
                      String email = data['email'] ?? '';
                      String phone = data['transactionRef'] ?? '';
                      bool isApproved = data['isApproved'] ?? false;
                      
                      Timestamp? joinedTimestamp = data['joinedAt'] as Timestamp?;
                      String adminDateStr = joinedTimestamp != null 
                          ? "تاريخ الانضمام: ${joinedTimestamp.toDate().year}/${joinedTimestamp.toDate().month}/${joinedTimestamp.toDate().day}" 
                          : "غير مسجل التاريخ";

                      return Card(
                        elevation: 2,
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('القسم: $category'),
                              if (email.isNotEmpty)
                                Text('البريد: $email', style: const TextStyle(color: Colors.grey)),
                              Text('الهاتف المحول منه: $phone', style: const TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold)),
                              Text('الحالة: ${isApproved ? "مفعل ✅" : "قيد المراجعة للتحقق من الدفع ⏳"}', 
                                  style: TextStyle(color: isApproved ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                              Text(adminDateStr, style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isApproved)
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  tooltip: 'تفعيل الموهبة',
                                  onPressed: () async {
                                    await FirebaseFirestore.instance.collection('talents').doc(doc.id).update({
                                      'isApproved': true,
                                      'joinedAt': FieldValue.serverTimestamp(),
                                    });
                                    if (!mounted) return;
                                    _showSmallMessage(context, 'تم تفعيل الموهبة بنجاح ✅', isError: false);
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'حذف الطلب',
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('talents').doc(doc.id).delete();
                                  if (!mounted) return;
                                  _showSmallMessage(context, 'تم حذف الطلب 🗑️');
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}