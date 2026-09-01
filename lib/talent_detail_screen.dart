import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

import 'talent_model.dart';
import 'talent_messages_screen.dart';
import 'talent_messaging_helper.dart';
import 'shared_widgets.dart';

// استيراد الملفات المقسمة
import 'talent_header_widget.dart';
import 'talent_work_form_widget.dart';
import 'talent_works_list_widget.dart';

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
  final TextEditingController _audioLinkController = TextEditingController();
  final TextEditingController _passVerifyController = TextEditingController();
  String _currentProfileImage = '';

  PlatformFile? _selectedPlatformFile;
  bool _isUploadingAudio = false;
  bool _isAuthorized = false;

  final ap.AudioPlayer _workAudioPlayer = ap.AudioPlayer();
  String? _currentlyPlayingWorkId;

  // تخزين العمل المحدد حالياً لعرضه في مساحة العرض الرئيسية فوق
  Map<String, dynamic>? _selectedWorkData;
  String? _selectedWorkId;

  @override
  void initState() {
    super.initState();
    _currentProfileImage = widget.talent.profileImage;
    _fetchLatestProfileImage();
  }

  @override
  void dispose() {
    _workAudioPlayer.dispose();
    _workTitleController.dispose();
    _workContentController.dispose();
    _audioLinkController.dispose();
    _passVerifyController.dispose();
    super.dispose();
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
      // تجاهل
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
            const SnackBar(content: Text('تم تثبيت الصورة الشخصية بنجاح ✅'), backgroundColor: Colors.green),
          );
        }
      }
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        setState(() {
          _selectedPlatformFile = file;
          _audioLinkController.text = ""; 
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم اختيار ملف الأغنية بنجاح 🎵'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في اختيار الملف: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String?> _uploadAudioToCloudinary(PlatformFile file) async {
    try {
      String cloudName = "rvqk2t1a";
      String uploadPreset = "sout_preset";

      Uri uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/auto/upload");
      var request = http.MultipartRequest("POST", uri);
      request.fields['upload_preset'] = uploadPreset;

      if (file.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));
      } else if (file.path != null) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path!));
      } else {
        return null;
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        return responseData['secure_url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _playAudioFromUrl(String workId, String audioUrl) async {
    try {
      if (audioUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('عذراً، لا يوجد رابط أو ملف صوتي مرفق لهذا العمل ❌'), backgroundColor: Colors.orange),
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

      if (_currentlyPlayingWorkId == workId) {
        await _workAudioPlayer.stop();
        if (mounted) {
          setState(() {
            _currentlyPlayingWorkId = null;
          });
        }
        return;
      }

      await _workAudioPlayer.stop();
      if (mounted) {
        setState(() {
          _currentlyPlayingWorkId = workId;
        });
      }

      if (audioUrl.startsWith('http')) {
        await _workAudioPlayer.play(ap.UrlSource(audioUrl));
      }

      _workAudioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _currentlyPlayingWorkId = null;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentlyPlayingWorkId = null;
        });
      }
    }
  }

  void _addNewWork() async {
    if (_workTitleController.text.isEmpty || (_selectedPlatformFile == null && _audioLinkController.text.isEmpty && _workContentController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال عنوان العمل ووضع الملف أو الرابط ❌'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isUploadingAudio = true;
    });

    try {
      String audioDownloadUrl = '';
      if (_selectedPlatformFile != null) {
        String? uploadedUrl = await _uploadAudioToCloudinary(_selectedPlatformFile!);
        if (uploadedUrl != null) {
          audioDownloadUrl = uploadedUrl;
        } else {
          setState(() {
            _isUploadingAudio = false;
          });
          return;
        }
      } else if (_audioLinkController.text.isNotEmpty) {
        audioDownloadUrl = _audioLinkController.text.trim();
      }

      await FirebaseFirestore.instance.collection('artist_works').add({
        'artistName': widget.talent.name.trim(),
        'artistEmail': widget.talent.email.trim(),
        'category': widget.talent.category,
        'title': _workTitleController.text.trim(),
        'content': _workContentController.text.trim(),
        'audioUrl': audioDownloadUrl,
        'likesCount': 0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _workTitleController.clear();
      _workContentController.clear();
      _audioLinkController.clear();
      setState(() {
        _selectedPlatformFile = null;
        _isUploadingAudio = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نشر العمل بنجاح ✅'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingAudio = false;
      });
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
            TextField(controller: editTitleController, decoration: const InputDecoration(labelText: 'عنوان العمل', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: editContentController, maxLines: 4, decoration: const InputDecoration(labelText: 'محتوى العمل', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
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
            TalentHeaderWidget(
              talent: widget.talent,
              icon: widget.icon,
              currentProfileImage: _currentProfileImage,
              onPickImage: () => _checkPasswordAndExecute(_pickAndUploadImage),
              onOpenMessages: () {
                _checkPasswordAndExecute(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TalentMessagesScreen(talentName: widget.talent.name)),
                  );
                });
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

            // **مساحة العرض الرئيسية (Master-Detail View)**: تظهر فوق عند الضغط على أي عمل من القائمة لتشغيله أو قراءته بالكامل
            if (_selectedWorkData != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade300, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(isPoet ? Icons.menu_book : Icons.music_note, color: const Color(0xFF7B1FA2)),
                            const SizedBox(width: 8),
                            Text(
                              _selectedWorkData!['title'] ?? '',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7B1FA2)),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _selectedWorkData = null;
                              _selectedWorkId = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    // لو القسم شعر، اعرض الكلمات الكاملة بوضوح
                    if (isPoet && (_selectedWorkData!['content'] ?? '').isNotEmpty) ...[
                      Text(
                        _selectedWorkData!['content'],
                        style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.8),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 16),
                    ],
                    // لو القسم غناء/تلحين، اعرض زر التشغيل والمحتوى الصوتي بشكل بارز
                    if (!isPoet && (_selectedWorkData!['audioUrl'] ?? '').isNotEmpty) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B1FA2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () {
                          if (_selectedWorkId != null) {
                            _playAudioFromUrl(_selectedWorkId!, _selectedWorkData!['audioUrl']);
                          }
                        },
                        icon: Icon(_currentlyPlayingWorkId == _selectedWorkId ? Icons.pause : Icons.play_arrow),
                        label: Text(_currentlyPlayingWorkId == _selectedWorkId ? 'إيقاف الصوت ⏹' : 'استماع للعمل الصوتي 🎧'),
                      ),
                      const SizedBox(height: 12),
                      if ((_selectedWorkData!['content'] ?? '').isNotEmpty)
                        Text(
                          _selectedWorkData!['content'],
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                          textAlign: TextAlign.right,
                        ),
                    ],
                  ],
                ),
              ),
            ],

            TalentWorkFormWidget(
              isPoet: isPoet,
              isAuthorized: _isAuthorized,
              isUploadingAudio: _isUploadingAudio,
              workTitleController: _workTitleController,
              audioLinkController: _audioLinkController,
              workContentController: _workContentController,
              selectedPlatformFile: _selectedPlatformFile,
              onPickAudioFile: () => _checkPasswordAndExecute(_pickAudioFile),
              onAddNewWork: () => _checkPasswordAndExecute(_addNewWork),
              onRequireAuth: () => _checkPasswordAndExecute(() {}),
            ),
            const Divider(height: 40),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('الأعمال المنشورة للموهبة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7B1FA2))),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
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

                return TalentWorksListWidget(
                  works: works,
                  currentlyPlayingWorkId: _currentlyPlayingWorkId,
                  onPlayAudio: (workId, url) => _playAudioFromUrl(workId, url),
                  onSelectWork: (workId, workData) {
                    setState(() {
                      _selectedWorkId = workId;
                      _selectedWorkData = workData;
                    });
                  },
                  onEditWork: (id, title, content) {
                    _checkPasswordAndExecute(() {
                      _showEditWorkDialog(id, title, content);
                    });
                  },
                  onDeleteWork: (id) {
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
                        await FirebaseFirestore.instance.collection('artist_works').doc(id).delete();
                        if (_selectedWorkId == id) {
                          setState(() {
                            _selectedWorkData = null;
                            _selectedWorkId = null;
                          });
                        }
                      }
                    });
                  },
                  onLikeWork: (id, currentLikes) async {
                    await FirebaseFirestore.instance.collection('artist_works').doc(id).update({
                      'likesCount': currentLikes + 1,
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}